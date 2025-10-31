import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/detection_event.dart';
import '../models/trip_report.dart';
import '../services/face_detection_service.dart';
import '../services/notification_service.dart';
import '../services/object_detection_service.dart';

class DetectionProvider extends ChangeNotifier {
  DetectionProvider({
    FaceDetectionService? faceDetectionService,
    ObjectDetectionService? objectDetectionService,
    NotificationService? notificationService,
  })  : _faceDetectionService = faceDetectionService ?? FaceDetectionService(),
        _objectDetectionService =
            objectDetectionService ?? ObjectDetectionService(),
        _notificationService = notificationService ?? NotificationService();

  final FaceDetectionService _faceDetectionService;
  final ObjectDetectionService _objectDetectionService;
  final NotificationService _notificationService;
  final Random _random = Random();

  Timer? _eventTimer;
  bool _isInitializing = false;
  bool _isMonitoring = false;
  bool _soundAlertsEnabled = true;
  bool _vibrationAlertsEnabled = true;
  String _statusMessage = 'Detector is idle.';
  String? _lastAlertMessage;
  DateTime? _sessionStartTime;

  final List<DetectionEvent> _events = [];
  final List<TripReport> _reports = [];

  bool get isInitializing => _isInitializing;
  bool get isMonitoring => _isMonitoring;
  String get statusMessage => _statusMessage;
  String? get lastAlertMessage => _lastAlertMessage;
  DateTime? get sessionStartTime => _sessionStartTime;
  List<DetectionEvent> get events => List.unmodifiable(_events);
  List<TripReport> get reports => List.unmodifiable(_reports);
  DetectionEvent? get latestEvent => _events.isEmpty ? null : _events.first;

  int get drowsinessCount =>
      _events.where((event) => event.type == DetectionEventType.drowsiness).length;

  int get distractionCount =>
      _events.where((event) => event.type == DetectionEventType.distraction).length;

  Future<void> startMonitoring({
    required bool soundAlertsEnabled,
    required bool vibrationAlertsEnabled,
  }) async {
    if (_isInitializing || _isMonitoring) {
      return;
    }

    _isInitializing = true;
    _statusMessage = 'Preparing detection services…';
    notifyListeners();

    await Future.wait([
      _faceDetectionService.initialize(),
      _objectDetectionService.initialize(),
      _notificationService.initialize(),
    ]);

    _soundAlertsEnabled = soundAlertsEnabled;
    _vibrationAlertsEnabled = vibrationAlertsEnabled;
    _events.clear();
    _lastAlertMessage = null;
    _sessionStartTime = DateTime.now();

    _isInitializing = false;
    _isMonitoring = true;
    _statusMessage = 'Monitoring active. Stay focused!';
    notifyListeners();

    _eventTimer?.cancel();
    _eventTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _simulateDetectionCycle(),
    );
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring && !_isInitializing) {
      return;
    }

    _eventTimer?.cancel();
    _eventTimer = null;

    final endTime = DateTime.now();
    if (_sessionStartTime != null) {
      _reports.insert(
        0,
        TripReport(
          startTime: _sessionStartTime!,
          endTime: endTime,
          events: List<DetectionEvent>.from(_events.reversed),
        ),
      );
    }

    _events.clear();
    _isMonitoring = false;
    _isInitializing = false;
    _sessionStartTime = null;
    _statusMessage = 'Detection paused.';
    _lastAlertMessage = null;
    notifyListeners();

    await Future.wait([
      _faceDetectionService.dispose(),
      _objectDetectionService.dispose(),
    ]);
  }

  void updateAlertPreferences({
    required bool soundAlertsEnabled,
    required bool vibrationAlertsEnabled,
  }) {
    _soundAlertsEnabled = soundAlertsEnabled;
    _vibrationAlertsEnabled = vibrationAlertsEnabled;
  }

  void _simulateDetectionCycle() {
    if (!_isMonitoring) {
      return;
    }

    final now = DateTime.now();
    final roll = _random.nextDouble();

    // Simulate a detection event roughly 40% of the time.
    if (roll < 0.4) {
      final isDrowsiness = roll < 0.2;
      final event = DetectionEvent(
        timestamp: now,
        type: isDrowsiness
            ? DetectionEventType.drowsiness
            : DetectionEventType.distraction,
        confidence: 0.7 + _random.nextDouble() * 0.3,
      );

      _events.insert(0, event);
      if (_events.length > 20) {
        _events.removeLast();
      }

      _lastAlertMessage = '${event.typeLabel} detected at ${_formatTime(now)}.';
      _statusMessage = _lastAlertMessage!;
      notifyListeners();

      _notificationService.showAlert(
        title: 'SafeDrive Alert',
        body: event.type == DetectionEventType.drowsiness
            ? 'Drowsiness detected. Please take a break!'
            : 'Distraction detected. Keep your eyes on the road.',
        sound: _soundAlertsEnabled,
        vibration: _vibrationAlertsEnabled,
      );
    } else {
      _statusMessage = 'Monitoring active — no anomalies detected.';
      notifyListeners();
    }
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    final seconds = time.second.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _eventTimer?.cancel();
    _faceDetectionService.dispose();
    _objectDetectionService.dispose();
    super.dispose();
  }
}
