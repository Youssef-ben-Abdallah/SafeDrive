import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _soundAlertsEnabled = true;
  bool _vibrationAlertsEnabled = true;
  String _language = 'en';
  String? _emergencyContactName;
  String? _emergencyContactPhone;

  bool get isDarkMode => _isDarkMode;
  bool get soundAlertsEnabled => _soundAlertsEnabled;
  bool get vibrationAlertsEnabled => _vibrationAlertsEnabled;
  String get language => _language;
  String? get emergencyContactName => _emergencyContactName;
  String? get emergencyContactPhone => _emergencyContactPhone;

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

  void setEmergencyContact({required String name, required String phone}) {
    if (_emergencyContactName == name && _emergencyContactPhone == phone) {
      return;
    }
    _emergencyContactName = name;
    _emergencyContactPhone = phone;
    notifyListeners();
  }

  void clearEmergencyContact() {
    if (_emergencyContactName == null && _emergencyContactPhone == null) {
      return;
    }
    _emergencyContactName = null;
    _emergencyContactPhone = null;
    notifyListeners();
  }
}
