import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../models/detection_event.dart';
import '../models/trip_report.dart';
import '../services/alert_log_service.dart';
import '../services/face_detection_service.dart';
import '../services/notification_service.dart';
import '../services/object_detection_service.dart';

class DetectionProvider extends ChangeNotifier {
  DetectionProvider({
    FaceDetectionService? faceDetectionService,
    ObjectDetectionService? objectDetectionService,
    NotificationService? notificationService,
    AlertLogService? alertLogService,
  })  : _faceDetectionService = faceDetectionService ?? FaceDetectionService(),
        _objectDetectionService =
            objectDetectionService ?? ObjectDetectionService(),
        _notificationService = notificationService ?? NotificationService(),
        _alertLogService = alertLogService ?? AlertLogService() {
    unawaited(_restorePersistedData());
  }

  final FaceDetectionService _faceDetectionService;
  final ObjectDetectionService _objectDetectionService;
  final NotificationService _notificationService;
  final AlertLogService _alertLogService;

  bool _isInitializing = false;
  bool _isMonitoring = false;
  bool _isProcessingFrame = false;
  bool _soundAlertsEnabled = true;
  bool _vibrationAlertsEnabled = true;
  String _statusMessage = 'Detector is idle.';
  String? _lastAlertMessage;
  DateTime? _sessionStartTime;
  DateTime? _lastAlertTimestamp;
  CameraLensDirection? _activeLensDirection;

  final List<DetectionEvent> _sessionEvents = [];
  final List<DetectionEvent> _alertLog = [];
  final List<TripReport> _reports = [];

  static const Duration _alertCooldown = Duration(seconds: 5);
  static const int _maxAlertLogEntries = 200;

  bool get isInitializing => _isInitializing;
  bool get isMonitoring => _isMonitoring;
  String get statusMessage => _statusMessage;
  String? get lastAlertMessage => _lastAlertMessage;
  DateTime? get sessionStartTime => _sessionStartTime;
  List<DetectionEvent> get events => List.unmodifiable(_sessionEvents);
  List<TripReport> get reports => List.unmodifiable(_reports);
  List<DetectionEvent> get alertLog => List.unmodifiable(_alertLog);
  DetectionEvent? get latestEvent =>
      _sessionEvents.isEmpty ? null : _sessionEvents.first;

  int get drowsinessCount => _sessionEvents
      .where((event) => event.type == DetectionEventType.drowsiness)
      .length;

  int get distractionCount => _sessionEvents
      .where((event) => event.type == DetectionEventType.distraction)
      .length;

  Future<void> startMonitoring({
    required bool soundAlertsEnabled,
    required bool vibrationAlertsEnabled,
    required CameraLensDirection lensDirection,
  }) async {
    if (_isInitializing) {
      return;
    }

    if (_isMonitoring) {
      await stopMonitoring();
    }

    _isInitializing = true;
    _statusMessage = 'Preparing detection services…';
    notifyListeners();

    await _notificationService.initialize();
    if (lensDirection == CameraLensDirection.front) {
      await _faceDetectionService.initialize();
    } else {
      await _objectDetectionService.initialize();
    }

    _soundAlertsEnabled = soundAlertsEnabled;
    _vibrationAlertsEnabled = vibrationAlertsEnabled;
    _sessionEvents.clear();
    _lastAlertMessage = null;
    _sessionStartTime = DateTime.now();
    _lastAlertTimestamp = null;
    _activeLensDirection = lensDirection;

    _isInitializing = false;
    _isMonitoring = true;
    _statusMessage = lensDirection == CameraLensDirection.front
        ? 'Monitoring driver attentiveness…'
        : 'Monitoring surroundings for hazards…';
    notifyListeners();
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring && !_isInitializing) {
      return;
    }

    _isMonitoring = false;
    _isInitializing = false;

    final endTime = DateTime.now();
    if (_sessionStartTime != null && _sessionEvents.isNotEmpty) {
      final report = TripReport(
        startTime: _sessionStartTime!,
        endTime: endTime,
        events: List<DetectionEvent>.from(_sessionEvents.reversed),
      );
      _reports.insert(0, report);
      await _alertLogService.persistReports(_reports);
    }

    _sessionEvents.clear();
    _sessionStartTime = null;
    _activeLensDirection = null;
    _statusMessage = 'Detection paused.';
    _lastAlertMessage = null;
    _lastAlertTimestamp = null;
    notifyListeners();
  }

  void updateAlertPreferences({
    required bool soundAlertsEnabled,
    required bool vibrationAlertsEnabled,
  }) {
    _soundAlertsEnabled = soundAlertsEnabled;
    _vibrationAlertsEnabled = vibrationAlertsEnabled;
  }

  Future<void> handleCameraImage({
    required CameraImage image,
    required CameraDescription description,
  }) async {
    if (!_isMonitoring || _isProcessingFrame) {
      return;
    }

    if (_activeLensDirection == null ||
        description.lensDirection != _activeLensDirection) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final inputImage = _convertToInputImage(image, description);

      DetectionEvent? event;
      if (_activeLensDirection == CameraLensDirection.front) {
        event = await _faceDetectionService.processImage(inputImage);
      } else {
        event = await _objectDetectionService.processImage(inputImage);
      }

      if (event != null) {
        _registerEvent(event);
      } else {
        _updateIdleStatus();
      }
    } catch (error) {
      debugPrint('DetectionProvider.handleCameraImage error: $error');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _restorePersistedData() async {
    try {
      final alerts = await _alertLogService.loadAlerts();
      final reports = await _alertLogService.loadReports();

      _alertLog
        ..clear()
        ..addAll(alerts);
      _reports
        ..clear()
        ..addAll(reports);
      notifyListeners();
    } catch (error) {
      debugPrint('DetectionProvider._restorePersistedData error: $error');
    }
  }

  void _registerEvent(DetectionEvent event) {
    final now = event.timestamp;
    if (_lastAlertTimestamp != null &&
        now.difference(_lastAlertTimestamp!) < _alertCooldown) {
      return;
    }

    _lastAlertTimestamp = now;

    _sessionEvents.insert(0, event);
    if (_sessionEvents.length > 50) {
      _sessionEvents.removeLast();
    }

    _alertLog.insert(0, event);
    if (_alertLog.length > _maxAlertLogEntries) {
      _alertLog.removeRange(_maxAlertLogEntries, _alertLog.length);
    }

    _lastAlertMessage =
        '${event.typeLabel} – ${(event.confidence * 100).toStringAsFixed(0)}%';
    _statusMessage = event.reason;
    notifyListeners();

    unawaited(
      _notificationService.showAlert(
        title: 'SafeDrive Alert',
        body: event.reason,
        sound: _soundAlertsEnabled,
        vibration: _vibrationAlertsEnabled,
      ),
    );

    unawaited(_alertLogService.persistAlerts(_alertLog));
  }

  void _updateIdleStatus() {
    if (_activeLensDirection == null) {
      return;
    }

    final DateTime? lastAlert = _lastAlertTimestamp;
    final bool canUpdateIdle = lastAlert == null ||
        DateTime.now().difference(lastAlert) > const Duration(seconds: 2);

    if (!canUpdateIdle) {
      return;
    }

    final idleMessage = _activeLensDirection == CameraLensDirection.front
        ? 'Monitoring active — no signs of drowsiness.'
        : 'Monitoring active — surroundings clear.';

    if (_statusMessage != idleMessage) {
      _statusMessage = idleMessage;
      notifyListeners();
    }
  }

  InputImage _convertToInputImage(
    CameraImage image,
    CameraDescription description,
  ) {
    final WriteBuffer buffer = WriteBuffer();
    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    final ui.Size imageSize = ui.Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final InputImageRotation? rotation =
        InputImageRotationValue.fromRawValue(description.sensorOrientation);
    final InputImageFormat? format =
        InputImageFormatValue.fromRawValue(image.format.raw);
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation ?? InputImageRotation.rotation0deg,
        format: format ?? InputImageFormat.nv21,
        bytesPerRow:
            image.planes.isNotEmpty ? image.planes.first.bytesPerRow : 0,
      ),
    );
  }

  @override
  void dispose() {
    _faceDetectionService.dispose();
    _objectDetectionService.dispose();
    super.dispose();
  }
}
