import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/detection_provider.dart';
import '../widgets/report_card.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  static const routeName = '/reports';

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<DetectionProvider>().reports;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: reports.isEmpty
          ? const _EmptyReportsState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => ReportCard(report: reports[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: reports.length,
            ),
    );
  }
}

class _EmptyReportsState extends StatelessWidget {
  const _EmptyReportsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.insights, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No trips recorded yet.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Start a monitoring session to generate your first driving safety report.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
