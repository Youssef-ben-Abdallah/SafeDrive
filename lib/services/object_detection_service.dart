import 'package:google_mlkit_commons/google_mlkit_commons.dart';
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
        final label = category.label.toLowerCase();
        final confidence = category.confidence.clamp(0, 1);

        if (_matchesPhone(label)) {
          final event = DetectionEvent(
            timestamp: DateTime.now(),
            type: DetectionEventType.distraction,
            confidence: confidence,
            reason: 'Phone detected in rear camera view',
          );
          bestEvent = _pickHigherConfidence(bestEvent, event);
        } else if (_matchesHazard(label)) {
          final event = DetectionEvent(
            timestamp: DateTime.now(),
            type: DetectionEventType.distraction,
            confidence: confidence,
            reason: 'Potential hazard detected (${category.label})',
          );
          bestEvent = _pickHigherConfidence(bestEvent, event);
        }
      }
    }

    return bestEvent;
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
