import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../models/detection_event.dart';

class ObjectDetectionService {
  ObjectDetectionService()
      : _objectDetector = ObjectDetector(
          options: ObjectDetectorOptions(
            mode: DetectionMode.stream,
            classifyObjects: true,
            multipleObjects: true,
          ),
        );

  final ObjectDetector _objectDetector;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;

    await _objectDetector.close();
    _isInitialized = false;
  }

  Future<DetectionEvent?> processImage(InputImage image) async {
    if (!_isInitialized) {
      return null;
    }

    final objects = await _objectDetector.processImage(image);
    if (objects.isEmpty) {
      return null;
    }

    DetectionEvent? bestEvent;

    for (final detectedObject in objects) {
      for (final category in detectedObject.labels) {
        final normalizedLabel = category.text.toLowerCase();
        final confidence = category.confidence.clamp(0.0, 1.0).toDouble();

        final event = _eventForLabel(
          originalLabel: category.text,
          normalizedLabel: normalizedLabel,
          confidence: confidence,
        );

        if (event != null) {
          bestEvent = _pickHigherConfidence(bestEvent, event);
        }
      }
    }

    return bestEvent;
  }

  DetectionEvent? _eventForLabel({
    required String originalLabel,
    required String normalizedLabel,
    required double confidence,
  }) {
    if (_matchesStopSign(normalizedLabel)) {
      return DetectionEvent(
        timestamp: DateTime.now(),
        type: DetectionEventType.regulation,
        confidence: confidence,
        reason: 'Stop sign detected — ensure a complete stop.',
      );
    }

    if (_matchesTrafficLight(normalizedLabel)) {
      return _buildTrafficLightEvent(
        label: originalLabel,
        confidence: confidence,
      );
    }

    if (_matchesPhone(normalizedLabel)) {
      return DetectionEvent(
        timestamp: DateTime.now(),
        type: DetectionEventType.distraction,
        confidence: confidence,
        reason: 'Phone detected in rear camera view',
      );
    }

    if (_matchesHazard(normalizedLabel)) {
      return DetectionEvent(
        timestamp: DateTime.now(),
        type: DetectionEventType.distraction,
        confidence: confidence,
        reason: 'Potential hazard detected ($originalLabel)',
      );
    }

    return null;
  }

  DetectionEvent _buildTrafficLightEvent({
    required String label,
    required double confidence,
  }) {
    final normalized = label.toLowerCase();
    final String state;
    if (normalized.contains('red')) {
      state = 'red';
    } else if (normalized.contains('yellow') || normalized.contains('amber')) {
      state = 'yellow';
    } else if (normalized.contains('green')) {
      state = 'green';
    } else {
      state = 'unknown';
    }

    final reason = switch (state) {
      'red' => 'Red light detected — stop immediately.',
      'yellow' => 'Yellow light detected — prepare to stop safely.',
      'green' => 'Traffic light detected — proceed only when the way is clear.',
      _ => 'Traffic signal detected — follow road regulations.',
    };

    return DetectionEvent(
      timestamp: DateTime.now(),
      type: DetectionEventType.regulation,
      confidence: confidence,
      reason: reason,
    );
  }

  DetectionEvent? _pickHigherConfidence(DetectionEvent? current, DetectionEvent candidate) {
    if (current == null || candidate.confidence > current.confidence) {
      return candidate;
    }
    return current;
  }

  bool _matchesPhone(String label) {
    const phoneKeywords = <String>['phone', 'mobile', 'cell'];
    return phoneKeywords.any(label.contains);
  }

  bool _matchesStopSign(String label) {
    const stopKeywords = <String>['stop sign', 'stop-sign', 'stop signal'];
    return stopKeywords.any(label.contains);
  }

  bool _matchesTrafficLight(String label) {
    const trafficLightKeywords = <String>[
      'traffic light',
      'stoplight',
      'signal light',
      'traffic signal',
      'red light',
      'green light',
      'yellow light',
    ];
    return trafficLightKeywords.any(label.contains);
  }

  bool _matchesHazard(String label) {
    const hazardKeywords = <String>[
      'car',
      'vehicle',
      'truck',
      'bus',
      'person',
      'pedestrian',
      'bicycle',
      'motorcycle',
      'traffic',
    ];
    return hazardKeywords.any(label.contains);
  }

  bool get isInitialized => _isInitialized;
}
