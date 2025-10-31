enum DetectionEventType { drowsiness, distraction }

class DetectionEvent {
  DetectionEvent({
    required this.timestamp,
    required this.type,
    required this.confidence,
  });

  final DateTime timestamp;
  final DetectionEventType type;
  final double confidence;

  String get typeLabel {
    switch (type) {
      case DetectionEventType.drowsiness:
        return 'Drowsiness';
      case DetectionEventType.distraction:
        return 'Distraction';
    }
  }
}
