import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

import '../models/detection_event.dart';

typedef MotionEventCallback = void Function(DetectionEvent event);

class MotionDetectionService {
  MotionDetectionService();

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  MotionEventCallback? _onEvent;
  bool _isListening = false;
  DateTime? _lastTrigger;

  static const double _impactThreshold = 18.0; // m/s^2
  static const Duration _cooldown = Duration(seconds: 10);

  bool get isListening => _isListening;

  Future<void> start({required MotionEventCallback onEvent}) async {
    if (_isListening) {
      return;
    }

    _onEvent = onEvent;
    _subscription = userAccelerometerEvents.listen(_handleEvent);
    _isListening = true;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _onEvent = null;
    _isListening = false;
  }

  void _handleEvent(UserAccelerometerEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    if (magnitude < _impactThreshold) {
      return;
    }

    final now = DateTime.now();
    if (_lastTrigger != null && now.difference(_lastTrigger!) < _cooldown) {
      return;
    }
    _lastTrigger = now;

    final callback = _onEvent;
    if (callback == null) {
      return;
    }

    final gForce = magnitude / 9.80665;
    final confidence = (magnitude / _impactThreshold).clamp(0.0, 1.5).toDouble();

    callback(
      DetectionEvent(
        timestamp: now,
        type: DetectionEventType.emergency,
        confidence: confidence > 1.0 ? 1.0 : confidence,
        reason: 'Severe movement detected — possible collision or accident.',
        label: 'Severe movement',
        metadata: {
          'tag': 'severe_motion',
          'gForce': gForce.toStringAsFixed(2),
          'severity': magnitude.toStringAsFixed(2),
        },
      ),
    );
  }
}
