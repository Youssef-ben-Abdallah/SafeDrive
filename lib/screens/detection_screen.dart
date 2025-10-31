import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'lens_detection_screen.dart';

class DetectionScreen extends StatelessWidget {
  const DetectionScreen({super.key});

  static const routeName = '/detection';

  void _openLens(BuildContext context, CameraLensDirection lensDirection) {
    Navigator.pushNamed(
      context,
      LensDetectionScreen.routeName,
      arguments: LensDetectionScreenArguments(lensDirection),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Setup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose a camera to start detection',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select which camera you want to use for the detection session.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _CameraChoiceCard(
                title: 'Front camera',
                subtitle: 'Use the front-facing camera to monitor the driver.',
                icon: Icons.camera_front,
                onTap: () => _openLens(context, CameraLensDirection.front),
              ),
              const SizedBox(height: 20),
              _CameraChoiceCard(
                title: 'Rear camera',
                subtitle:
                    'Use the rear-facing camera to analyse what happens on the road.',
                icon: Icons.camera_rear,
                onTap: () => _openLens(context, CameraLensDirection.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraChoiceCard extends StatelessWidget {
  const _CameraChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(icon, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
