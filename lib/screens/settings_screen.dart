import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark themes'),
            value: settings.isDarkMode,
            onChanged: settings.setDarkMode,
          ),
          SwitchListTile(
            title: const Text('Sound Alerts'),
            subtitle: const Text('Enable or disable audible warnings'),
            value: settings.soundAlertsEnabled,
            onChanged: settings.setSoundAlerts,
          ),
          SwitchListTile(
            title: const Text('Vibration Alerts'),
            subtitle: const Text('Enable or disable vibration feedback'),
            value: settings.vibrationAlertsEnabled,
            onChanged: settings.setVibrationAlerts,
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(settings.language.toUpperCase()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguagePicker(context, settings),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('English'),
            onTap: () {
              settings.setLanguage('en');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Français'),
            onTap: () {
              settings.setLanguage('fr');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('العربية'),
            onTap: () {
              settings.setLanguage('ar');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
