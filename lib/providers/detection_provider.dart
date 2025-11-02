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

class _DetectionProfile {
  const _DetectionProfile({
    required this.scene,
    required this.useFaceDetection,
    required this.useObjectDetection,
    required this.allowedTypes,
    required this.allowedTagPatterns,
    required this.startStatusMessage,
    required this.idleStatusMessage,
  });

  final DetectionScene scene;
  final bool useFaceDetection;
  final bool useObjectDetection;
  final Set<DetectionEventType> allowedTypes;
  final List<Pattern> allowedTagPatterns;
  final String startStatusMessage;
  final String idleStatusMessage;

  bool allowsEvent(DetectionEvent event) {
    if (!allowedTypes.contains(event.type)) {
      return false;
    }

    if (allowedTagPatterns.isEmpty) {
      return true;
    }

    final tag = event.metadata?['tag'];
    if (tag is! String) {
      return false;
    }

    for (final pattern in allowedTagPatterns) {
      if (pattern is RegExp && pattern.hasMatch(tag)) {
        return true;
      }
      if (pattern is String && pattern == tag) {
        return true;
      }
    }

    return false;
  }
}

const _DetectionProfile _frontCameraProfile = _DetectionProfile(
  scene: DetectionScene.driver,
  useFaceDetection: true,
  useObjectDetection: true,
  allowedTypes: {
    DetectionEventType.drowsiness,
    DetectionEventType.distraction,
  },
  allowedTagPatterns: <Pattern>[
    RegExp(r'^drowsiness_'),
    RegExp(r'^phone_driver$'),
  ],
  startStatusMessage: 'Monitoring driver attentiveness…',
  idleStatusMessage: 'Monitoring active — no signs of drowsiness.',
);

const _DetectionProfile _rearCameraProfile = _DetectionProfile(
  scene: DetectionScene.road,
  useFaceDetection: false,
  useObjectDetection: true,
  allowedTypes: {
    DetectionEventType.regulation,
    DetectionEventType.distraction,
  },
  allowedTagPatterns: <Pattern>[
    RegExp(r'^stop_sign$'),
    RegExp(r'^traffic_light_'),
    RegExp(r'^road_hazard$'),
  ],
  startStatusMessage: 'Monitoring road environment for hazards…',
  idleStatusMessage: 'Monitoring active — road environment clear.',
);

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
  _DetectionProfile? _activeProfile;

  final List<DetectionEvent> _sessionEvents = [];
  final List<DetectionEvent> _alertLog = [];
  final List<TripReport> _reports = [];
  final Map<String, _PendingEventState> _pendingEvents = {};

  static const Duration _alertCooldown = Duration(seconds: 5);
  static const int _maxAlertLogEntries = 200;
  static const Duration _pendingEventExpiry = Duration(seconds: 2);

  bool get isInitializing => _isInitializing;
  bool get isMonitoring => _isMonitoring;
  String get statusMessage => _statusMessage;
  String? get lastAlertMessage => _lastAlertMessage;
  DateTime? get sessionStartTime => _sessionStartTime;
  CameraLensDirection? get activeLensDirection => _activeLensDirection;
  List<DetectionEvent> get events => List.unmodifiable(_sessionEvents);
  List<TripReport> get reports => List.unmodifiable(_reports);
  List<DetectionEvent> get alertLog => List.unmodifiable(_alertLog);
  DetectionEvent? get latestEvent =>
      _sessionEvents.isEmpty ? null : _sessionEvents.first;

  _DetectionProfile _profileForLens(CameraLensDirection lensDirection) {
    if (lensDirection == CameraLensDirection.front) {
      return _frontCameraProfile;
    }
    return _rearCameraProfile;
  }

  int get drowsinessCount => _sessionEvents
      .where((event) => event.type == DetectionEventType.drowsiness)
      .length;

  int get distractionCount => _sessionEvents
      .where((event) => event.type == DetectionEventType.distraction)
      .length;

  int get regulationCount => _sessionEvents
      .where((event) => event.type == DetectionEventType.regulation)
      .length;

  int get stopSignCount =>
      _sessionEvents.where((event) => event.metadata?['tag'] == 'stop_sign').length;

  int get trafficSignalCount => _sessionEvents
      .where((event) =>
          (event.metadata?['tag'] as String?)?.startsWith('traffic_light') ??
          false)
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

    final profile = _profileForLens(lensDirection);
    _activeProfile = profile;

    await _notificationService.initialize();

    if (profile.useFaceDetection) {
      await _faceDetectionService.initialize();
    } else {
      await _faceDetectionService.dispose();
    }

    if (profile.useObjectDetection) {
      await _objectDetectionService.initialize();
    } else {
      await _objectDetectionService.dispose();
    }

    _soundAlertsEnabled = soundAlertsEnabled;
    _vibrationAlertsEnabled = vibrationAlertsEnabled;
    _sessionEvents.clear();
    _lastAlertMessage = null;
    _sessionStartTime = DateTime.now();
    _lastAlertTimestamp = null;
    _activeLensDirection = lensDirection;
    _pendingEvents.clear();

    _isInitializing = false;
    _isMonitoring = true;
    _statusMessage = profile.startStatusMessage;
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
    _activeProfile = null;
    _statusMessage = 'Detection paused.';
    _lastAlertMessage = null;
    _lastAlertTimestamp = null;
    _pendingEvents.clear();
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
      final profile = _activeProfile;
      if (profile == null) {
        return;
      }

      final inputImage = _convertToInputImage(image, description);
      final List<DetectionEvent> allowedEvents = [];

      if (profile.useFaceDetection) {
        final faceEvent = await _faceDetectionService.processImage(inputImage);
        if (faceEvent != null && profile.allowsEvent(faceEvent)) {
          allowedEvents.add(faceEvent);
        }
      }

      if (profile.useObjectDetection) {
        final objectEvent = await _objectDetectionService.processImage(
          inputImage,
          scene: profile.scene,
        );
        if (objectEvent != null && profile.allowsEvent(objectEvent)) {
          allowedEvents.add(objectEvent);
        }
      }

      DetectionEvent? event;
      for (final candidate in allowedEvents) {
        event = _selectBestEvent(event, candidate);
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
    final profile = _activeProfile;
    if (profile != null && !profile.allowsEvent(event)) {
      return;
    }

    _expireStalePendingEvents();

    if (_requiresStabilization(event)) {
      final key = _pendingEventKey(event);
      final existingState = _pendingEvents[key];
      final pendingState = existingState ?? _PendingEventState(event);
      if (existingState == null) {
        _pendingEvents[key] = pendingState;
      } else {
        pendingState.update(event);
      }

      final int? requiredObservations = _requiredObservations(event);
      final Duration? requiredDuration = _requiredDuration(event);
      final bool hasObservationSupport = requiredObservations == null ||
          pendingState.observationCount >= requiredObservations;
      final bool hasDurationSupport = requiredDuration == null ||
          pendingState.elapsed >= requiredDuration;

      if (hasObservationSupport && hasDurationSupport) {
        _pendingEvents.remove(key);
        _commitEvent(pendingState.bestEvent);
      }
      return;
    }

    _commitEvent(event);
  }

  void _commitEvent(DetectionEvent event) {
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

    _expireStalePendingEvents();

    final DateTime? lastAlert = _lastAlertTimestamp;
    final bool canUpdateIdle = lastAlert == null ||
        DateTime.now().difference(lastAlert) > const Duration(seconds: 2);

    if (!canUpdateIdle) {
      return;
    }

    final idleMessage =
        _activeProfile?.idleStatusMessage ?? 'Monitoring active.';

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

  void _expireStalePendingEvents() {
    if (_pendingEvents.isEmpty) {
      return;
    }

    final now = DateTime.now();
    _pendingEvents.removeWhere(
      (_, state) => now.difference(state.lastSeen) > _pendingEventExpiry,
    );
  }

  DetectionEvent? _selectBestEvent(
    DetectionEvent? primary,
    DetectionEvent? secondary,
  ) {
    if (primary == null) {
      return secondary;
    }
    if (secondary == null) {
      return primary;
    }

    return primary.confidence >= secondary.confidence ? primary : secondary;
  }

  bool _requiresStabilization(DetectionEvent event) {
    final metadata = event.metadata;
    if (metadata == null) {
      return false;
    }

    return metadata.containsKey('minObservations') ||
        metadata.containsKey('minDurationMs');
  }

  int? _requiredObservations(DetectionEvent event) {
    final value = event.metadata?['minObservations'];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  Duration? _requiredDuration(DetectionEvent event) {
    final value = event.metadata?['minDurationMs'];
    if (value is int) {
      return Duration(milliseconds: value);
    }
    if (value is num) {
      return Duration(milliseconds: value.toInt());
    }
    return null;
  }

  String _pendingEventKey(DetectionEvent event) {
    final buffer = StringBuffer(event.type.name);
    final tag = event.metadata?['tag'];
    if (tag is String && tag.isNotEmpty) {
      buffer.write('::$tag');
    } else {
      buffer.write('::${event.reason}');
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _faceDetectionService.dispose();
    _objectDetectionService.dispose();
    super.dispose();
  }
}

class _PendingEventState {
  _PendingEventState(DetectionEvent event)
      : bestEvent = event,
        firstSeen = event.timestamp,
        lastSeen = event.timestamp,
        observationCount = 1;

  DetectionEvent bestEvent;
  final DateTime firstSeen;
  DateTime lastSeen;
  int observationCount;

  Duration get elapsed => lastSeen.difference(firstSeen);

  void update(DetectionEvent event) {
    observationCount += 1;
    lastSeen = event.timestamp;
    if (event.confidence >= bestEvent.confidence) {
      bestEvent = event;
    }
  }
}
