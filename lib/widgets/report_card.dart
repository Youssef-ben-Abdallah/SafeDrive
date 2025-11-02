import 'package:flutter/material.dart';

import '../models/detection_event.dart';
import '../models/trip_report.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
  });

  final TripReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.directions_car),
        title: Text(
          'Trip on ${_formatDate(report.startTime)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Duration ${_formatDuration(report.duration)} • ${report.totalAlerts} alert(s)',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  context,
                  label: 'Drowsiness alerts',
                  value: report.drowsinessCount,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  label: 'Distraction alerts',
                  value: report.distractionCount,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  label: 'Regulation alerts',
                  value: report.regulationCount,
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  label: 'Stop signs observed',
                  value: report.stopSignCount,
                  color: Colors.purpleAccent,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  label: 'Traffic lights observed',
                  value: report.trafficSignalCount,
                  color: Colors.tealAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Timeline',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (report.events.isEmpty)
                  const Text('No alerts recorded during this trip.')
                else
                  ...report.events.map(
                    (event) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _iconForEventType(event.type),
                        color: _colorForEventType(event.type),
                      ),
                      title: Text(event.label ?? event.typeLabel),
                      subtitle: Text(
                        '${event.reason}\n'
                        'Confidence ${(event.confidence * 100).toStringAsFixed(0)}% • '
                        '${_formatTime(event.timestamp)}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
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

  Widget _buildStatRow(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value.toString(),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDate(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final year = time.year;
    return '$year-$month-$day';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final buffer = <String>[];
    if (hours > 0) {
      buffer.add('${hours}h');
    }
    if (minutes > 0) {
      buffer.add('${minutes}m');
    }
    if (seconds > 0 || buffer.isEmpty) {
      buffer.add('${seconds}s');
    }
    return buffer.join(' ');
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    final seconds = time.second.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
