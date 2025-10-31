import 'package:flutter/material.dart';

import '../widgets/custom_button.dart';
import 'about_screen.dart';
import 'detection_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeDrive'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            CustomButton(
              label: 'Start Detection',
              icon: Icons.videocam,
              onPressed: () => Navigator.pushNamed(context, DetectionScreen.routeName),
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'View Reports',
              icon: Icons.bar_chart,
              onPressed: () => Navigator.pushNamed(context, ReportScreen.routeName),
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Settings',
              icon: Icons.settings,
              onPressed: () => Navigator.pushNamed(context, SettingsScreen.routeName),
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'About',
              icon: Icons.info_outline,
              onPressed: () => Navigator.pushNamed(context, AboutScreen.routeName),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
