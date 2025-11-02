import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/detection_event.dart';
import '../models/emergency_contact.dart';

typedef EmergencyDispatchHandler = Future<void> Function(
    EmergencyDispatchMessage message);

class EmergencyDispatchService {
  EmergencyDispatchService({
    GeolocatorPlatform? geolocator,
    http.Client? httpClient,
    List<EmergencyContact>? contacts,
    Uri? smsGateway,
    Uri? emailGateway,
    EmergencyDispatchHandler? onDispatch,
  })  : _geolocator = geolocator ?? GeolocatorPlatform.instance,
        _httpClient = httpClient ?? http.Client(),
        _contacts = contacts ??
            const [
              EmergencyContact(
                name: 'Primary Contact',
                phoneNumber: '+15555550123',
                email: 'safety-contact@example.com',
              ),
            ],
        _smsGateway = smsGateway,
        _emailGateway = emailGateway,
        _customDispatchHandler = onDispatch;

  final GeolocatorPlatform _geolocator;
  final http.Client _httpClient;
  final List<EmergencyContact> _contacts;
  final Uri? _smsGateway;
  final Uri? _emailGateway;
  final EmergencyDispatchHandler? _customDispatchHandler;

  bool _locationPermissionGranted = false;
  bool _isInitialized = false;
  DateTime? _lastDispatch;
  static const Duration _dispatchCooldown = Duration(minutes: 1);

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      final serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('EmergencyDispatchService: Location services disabled.');
      }

      var permission = await _geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocator.requestPermission();
      }

      _locationPermissionGranted =
          permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;
    } catch (error, stackTrace) {
      debugPrint('EmergencyDispatchService.initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _locationPermissionGranted = false;
    }

    _isInitialized = true;
  }

  Future<void> dispose() async {
    _httpClient.close();
    _isInitialized = false;
  }

  Future<void> dispatchEmergencyAlert({
    required DetectionEvent event,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final now = DateTime.now();
    if (_lastDispatch != null &&
        now.difference(_lastDispatch!) < _dispatchCooldown) {
      return;
    }

    _lastDispatch = now;

    double? latitude;
    double? longitude;
    if (_locationPermissionGranted) {
      try {
        final position = await _geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 5),
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (error, stackTrace) {
        debugPrint('EmergencyDispatchService location lookup failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final buffer = StringBuffer()
      ..writeln('SafeDrive detected a potential emergency:')
      ..writeln(event.reason)
      ..writeln('Timestamp: ${now.toIso8601String()}');

    if (event.metadata != null) {
      final severity = event.metadata?['severity'] ?? event.metadata?['gForce'];
      if (severity != null) {
        buffer.writeln('Severity: $severity');
      }
    }

    if (latitude != null && longitude != null) {
      buffer
        ..writeln('Location: $latitude, $longitude')
        ..writeln(
            'Google Maps: https://maps.google.com/?q=$latitude,$longitude');
    } else {
      buffer.writeln('Location: unavailable');
    }

    final messageBody = buffer.toString();

    await Future.wait(
      _contacts.expand((contact) sync* {
        if (contact.hasPhone) {
          yield _deliver(
            message: EmergencyDispatchMessage(
              contact: contact,
              channel: 'sms',
              body: messageBody,
              generatedAt: now,
              latitude: latitude,
              longitude: longitude,
            ),
          );
        }
        if (contact.hasEmail) {
          yield _deliver(
            message: EmergencyDispatchMessage(
              contact: contact,
              channel: 'email',
              body: messageBody,
              generatedAt: now,
              latitude: latitude,
              longitude: longitude,
            ),
          );
        }
      }).toList(),
    );
  }

  Future<void> _deliver({required EmergencyDispatchMessage message}) async {
    if (_customDispatchHandler != null) {
      await _customDispatchHandler!(message);
      return;
    }

    try {
      if (message.channel == 'sms' && _smsGateway != null) {
        await _httpClient.post(_smsGateway!, body: {
          'to': message.contact.phoneNumber,
          'message': message.body,
        });
        return;
      }

      if (message.channel == 'email' && _emailGateway != null) {
        await _httpClient.post(_emailGateway!, body: {
          'to': message.contact.email,
          'subject': 'SafeDrive emergency alert',
          'message': message.body,
        });
        return;
      }

      debugPrint(
        'EmergencyDispatchService ${message.channel} -> '
        '${message.contact.name}:\n${message.body}',
      );
    } catch (error, stackTrace) {
      debugPrint('EmergencyDispatchService delivery failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
