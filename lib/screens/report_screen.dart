import 'package:flutter/material.dart';

import '../models/detection_event.dart';
import '../widgets/report_card.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  static const routeName = '/reports';

  @override
  Widget build(BuildContext context) {
    final events = <DetectionEvent>[
      DetectionEvent(
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: DetectionEventType.drowsiness,
        confidence: 0.82,
      ),
      DetectionEvent(
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        type: DetectionEventType.distraction,
        confidence: 0.76,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => ReportCard(event: events[index]),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: events.length,
      ),
    );
  }
}
