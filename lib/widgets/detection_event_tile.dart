import 'package:flutter/material.dart';

import '../models/detection_event.dart';

class DetectionEventTile extends StatelessWidget {
  const DetectionEventTile({super.key, required this.event});

  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    final color = event.type == DetectionEventType.drowsiness
        ? Colors.redAccent
        : Colors.orangeAccent;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            event.type == DetectionEventType.drowsiness
                ? Icons.bedtime
                : Icons.phone_android,
            color: Colors.white,
          ),
        ),
        title: Text(event.typeLabel),
        subtitle: Text(_buildSubtitle(event)),
      ),
    );
  }

  String _buildSubtitle(DetectionEvent event) {
    final hours = event.timestamp.hour.toString().padLeft(2, '0');
    final minutes = event.timestamp.minute.toString().padLeft(2, '0');
    final seconds = event.timestamp.second.toString().padLeft(2, '0');
    final confidence = (event.confidence * 100).toStringAsFixed(0);
    return 'Confidence $confidence% • $hours:$minutes:$seconds';
  }
}
