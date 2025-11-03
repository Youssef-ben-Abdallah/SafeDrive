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
          const Divider(),
          ListTile(
            title: const Text('Emergency Contact'),
            subtitle: Text(
              settings.emergencyContactName != null
                  ? '${settings.emergencyContactName}\n${settings.emergencyContactPhone}'
                  : 'Add someone to contact automatically when danger is detected.',
            ),
            isThreeLine: settings.emergencyContactName != null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showEmergencyContactDialog(context, settings),
          ),
          if (settings.emergencyContactName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    settings.clearEmergencyContact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Emergency contact removed.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove contact'),
                ),
              ),
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

  Future<void> _showEmergencyContactDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nameController =
        TextEditingController(text: settings.emergencyContactName ?? '');
    final phoneController =
        TextEditingController(text: settings.emergencyContactPhone ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Contact name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '+1 555 0100',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Please provide both a name and phone number.'),
                  ),
                );
                return;
              }

              settings.setEmergencyContact(name: name, phone: phone);
              Navigator.pop(dialogContext);
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Emergency contact saved.')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    phoneController.dispose();
  }
}
