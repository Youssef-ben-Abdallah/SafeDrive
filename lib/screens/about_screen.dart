import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const routeName = '/about';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'SafeDrive',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'SafeDrive leverages on-device AI to detect signs of drowsiness and distraction. '
              'This early version focuses on preparing the app structure before integrating Firebase ML Kit.',
            ),
            SizedBox(height: 24),
            Text(
              'Technologies (planned): Flutter, Firebase ML Kit, Provider, Hive/SharedPreferences.',
            ),
          ],
        ),
      ),
    );
  }
}
