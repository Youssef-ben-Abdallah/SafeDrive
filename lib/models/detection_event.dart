enum DetectionEventType { drowsiness, distraction }

class DetectionEvent {
  DetectionEvent({
    required this.timestamp,
    required this.type,
    required this.confidence,
    required this.reason,
  });

  final DateTime timestamp;
  final DetectionEventType type;
  final double confidence;
  final String reason;

  String get typeLabel {
    switch (type) {
      case DetectionEventType.drowsiness:
        return 'Drowsiness';
      case DetectionEventType.distraction:
        return 'Distraction';
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'confidence': confidence,
        'reason': reason,
      };

  static DetectionEvent fromJson(Map<String, dynamic> json) {
    return DetectionEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: DetectionEventType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => DetectionEventType.distraction,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? 'Unknown reason',
    );
  }
}
