import 'package:flutter/material.dart';

import '../models/detection_event.dart';

class DetectionEventTile extends StatelessWidget {
  const DetectionEventTile({super.key, required this.event});

  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    final color = _colorForEventType(event.type);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            _iconForEventType(event.type),
            color: Colors.white,
          ),
        ),
        title: Text(event.typeLabel),
        subtitle: Text(_buildSubtitle(event)),
      ),
    );
  }

  IconData _iconForEventType(DetectionEventType type) {
    switch (type) {
      case DetectionEventType.drowsiness:
        return Icons.bedtime;
      case DetectionEventType.distraction:
        return Icons.phone_android;
      case DetectionEventType.regulation:
        return Icons.rule;
    }
  }

  Color _colorForEventType(DetectionEventType type) {
    switch (type) {
      case DetectionEventType.drowsiness:
        return Colors.redAccent;
      case DetectionEventType.distraction:
        return Colors.orangeAccent;
      case DetectionEventType.regulation:
        return Colors.lightBlueAccent;
    }
  }

  String _buildSubtitle(DetectionEvent event) {
    final hours = event.timestamp.hour.toString().padLeft(2, '0');
    final minutes = event.timestamp.minute.toString().padLeft(2, '0');
    final seconds = event.timestamp.second.toString().padLeft(2, '0');
    final confidence = (event.confidence * 100).toStringAsFixed(0);
    return 'Confidence $confidence% • $hours:$minutes:$seconds';
  }
}
