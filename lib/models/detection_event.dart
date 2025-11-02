enum DetectionEventType { drowsiness, distraction, regulation, posture, emergency }

class DetectionEvent {
  DetectionEvent({
    required this.timestamp,
    required this.type,
    required this.confidence,
    required this.reason,
    this.label,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata == null ? null : Map.unmodifiable(metadata);

  final DateTime timestamp;
  final DetectionEventType type;
  final double confidence;
  final String reason;
  final String? label;
  final Map<String, dynamic>? metadata;

  String get typeLabel {
    switch (type) {
      case DetectionEventType.drowsiness:
        return 'Drowsiness';
      case DetectionEventType.distraction:
        return 'Distraction';
      case DetectionEventType.regulation:
        return 'Regulation';
      case DetectionEventType.posture:
        return 'Posture';
      case DetectionEventType.emergency:
        return 'Emergency';
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'confidence': confidence,
        'reason': reason,
        if (label != null) 'label': label,
        if (metadata != null) 'metadata': metadata,
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
      label: json['label'] as String?,
      metadata: (json['metadata'] as Map<Object?, Object?>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }
}
