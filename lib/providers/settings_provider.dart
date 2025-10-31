import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _soundAlertsEnabled = true;
  bool _vibrationAlertsEnabled = true;
  String _language = 'en';

  bool get isDarkMode => _isDarkMode;
  bool get soundAlertsEnabled => _soundAlertsEnabled;
  bool get vibrationAlertsEnabled => _vibrationAlertsEnabled;
  String get language => _language;

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }

  void setSoundAlerts(bool value) {
    if (_soundAlertsEnabled == value) return;
    _soundAlertsEnabled = value;
    notifyListeners();
  }

  void setVibrationAlerts(bool value) {
    if (_vibrationAlertsEnabled == value) return;
    _vibrationAlertsEnabled = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    if (_language == value) return;
    _language = value;
    notifyListeners();
  }
}
