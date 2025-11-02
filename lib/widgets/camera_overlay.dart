import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraOverlay extends StatelessWidget {
  const CameraOverlay({
    super.key,
    required this.isMonitoring,
    required this.statusMessage,
    required this.drowsinessCount,
    required this.distractionCount,
    required this.regulationCount,
    required this.stopSignCount,
    required this.trafficSignalCount,
    required this.sessionStart,
    required this.lastAlertMessage,
    required this.activeLensDirection,
  });

  final bool isMonitoring;
  final String statusMessage;
  final int drowsinessCount;
  final int distractionCount;
  final int regulationCount;
  final int stopSignCount;
  final int trafficSignalCount;
  final DateTime? sessionStart;
  final String? lastAlertMessage;
  final CameraLensDirection? activeLensDirection;

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
              for (final stat in _statsForLens(activeLensDirection))
                _buildStatChip(
                  context,
                  label: stat.label,
                  value: stat.value,
                  color: stat.color,
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

  List<_ResolvedOverlayStat> _statsForLens(CameraLensDirection? lensDirection) {
    if (lensDirection == CameraLensDirection.front) {
      return [
        _ResolvedOverlayStat(
          label: 'Drowsiness',
          value: drowsinessCount,
          color: Colors.redAccent,
        ),
        _ResolvedOverlayStat(
          label: 'Distraction',
          value: distractionCount,
          color: Colors.orangeAccent,
        ),
      ];
    }

    return [
      _ResolvedOverlayStat(
        label: 'Regulation',
        value: regulationCount,
        color: Colors.lightBlueAccent,
      ),
      _ResolvedOverlayStat(
        label: 'Stop signs',
        value: stopSignCount,
        color: Colors.purpleAccent,
      ),
      _ResolvedOverlayStat(
        label: 'Traffic lights',
        value: trafficSignalCount,
        color: Colors.tealAccent,
      ),
      _ResolvedOverlayStat(
        label: 'Hazards',
        value: distractionCount,
        color: Colors.orangeAccent,
      ),
    ];
  }
}

class _ResolvedOverlayStat {
  const _ResolvedOverlayStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}
