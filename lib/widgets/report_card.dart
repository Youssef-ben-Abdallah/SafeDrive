import 'package:flutter/material.dart';

import '../models/detection_event.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.event,
  });

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
        subtitle: Text(
          'Confidence ${(event.confidence * 100).toStringAsFixed(0)}% • '
          '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
