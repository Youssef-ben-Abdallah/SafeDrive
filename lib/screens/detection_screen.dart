import 'package:flutter/material.dart';

import '../widgets/camera_overlay.dart';

class DetectionScreen extends StatelessWidget {
  const DetectionScreen({super.key});

  static const routeName = '/detection';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Camera preview placeholder',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const CameraOverlay(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Real-time alerts will appear here when signs of drowsiness or distraction are detected.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
