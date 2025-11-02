import 'package:flutter/material.dart';

class CameraOverlay extends StatelessWidget {
  const CameraOverlay({
    super.key,
    required this.isMonitoring,
    required this.statusMessage,
    required this.drowsinessCount,
    required this.distractionCount,
    required this.regulationCount,
    required this.sessionStart,
    required this.lastAlertMessage,
  });

  final bool isMonitoring;
  final String statusMessage;
  final int drowsinessCount;
  final int distractionCount;
  final int regulationCount;
  final DateTime? sessionStart;
  final String? lastAlertMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMonitoring ? Icons.podcasts : Icons.pause_circle,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                isMonitoring ? 'Monitoring active' : 'Monitoring paused',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(statusMessage),
          if (sessionStart != null) ...[
            const SizedBox(height: 4),
            Text(
              'Session started at ${_formatTime(sessionStart!)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (lastAlertMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.error.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(lastAlertMessage!)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _buildStatChip(
                context,
                label: 'Drowsiness',
                value: drowsinessCount,
                color: Colors.redAccent,
              ),
              _buildStatChip(
                context,
                label: 'Distraction',
                value: distractionCount,
                color: Colors.orangeAccent,
              ),
              _buildStatChip(
                context,
                label: 'Regulation',
                value: regulationCount,
                color: Colors.lightBlueAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Chip(
      backgroundColor: color.withValues(alpha: 0.12),
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          value.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      label: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    final seconds = time.second.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
