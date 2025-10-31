import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/detection_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/camera_overlay.dart';
import '../widgets/detection_event_tile.dart';

class DetectionScreen extends StatelessWidget {
  const DetectionScreen({super.key});

  static const routeName = '/detection';

  @override
  Widget build(BuildContext context) {
    final detection = context.watch<DetectionProvider>();
    final settings = context.watch<SettingsProvider>();

    detection.updateAlertPreferences(
      soundAlertsEnabled: settings.soundAlertsEnabled,
      vibrationAlertsEnabled: settings.vibrationAlertsEnabled,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Camera preview placeholder',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                if (detection.isInitializing)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CameraOverlay(
            isMonitoring: detection.isMonitoring,
            statusMessage: detection.statusMessage,
            drowsinessCount: detection.drowsinessCount,
            distractionCount: detection.distractionCount,
            sessionStart: detection.sessionStartTime,
            lastAlertMessage: detection.lastAlertMessage,
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: detection.events.isEmpty
                  ? const _EmptyEventsState()
                  : ListView.separated(
                      itemBuilder: (context, index) => DetectionEventTile(
                        event: detection.events[index],
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: detection.events.length,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: detection.isInitializing
                      ? null
                      : detection.isMonitoring
                          ? () {
                              detection.stopMonitoring();
                            }
                          : () {
                              detection.startMonitoring(
                                soundAlertsEnabled: settings.soundAlertsEnabled,
                                vibrationAlertsEnabled:
                                    settings.vibrationAlertsEnabled,
                              );
                            },
                icon: Icon(
                  detection.isMonitoring ? Icons.stop : Icons.play_arrow,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    detection.isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.local_shipping, size: 48, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          'No alerts yet. Stay focused and we\'ll keep watching for signs of fatigue or distraction.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
