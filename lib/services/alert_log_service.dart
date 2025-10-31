import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/detection_event.dart';
import '../models/trip_report.dart';

class AlertLogService {
  AlertLogService({SharedPreferences? preferences})
      : _preferencesFuture = preferences != null
            ? Future<SharedPreferences>.value(preferences)
            : SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferencesFuture;

  static const String _alertsKey = 'alert_log';
  static const String _reportsKey = 'trip_reports';

  Future<List<DetectionEvent>> loadAlerts() async {
    final prefs = await _preferencesFuture;
    final raw = prefs.getString(_alertsKey);
    if (raw == null || raw.isEmpty) {
      return <DetectionEvent>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(DetectionEvent.fromJson)
        .toList(growable: false);
  }

  Future<void> persistAlerts(List<DetectionEvent> alerts) async {
    final prefs = await _preferencesFuture;
    final serialised = jsonEncode(alerts.map((event) => event.toJson()).toList());
    await prefs.setString(_alertsKey, serialised);
  }

  Future<List<TripReport>> loadReports() async {
    final prefs = await _preferencesFuture;
    final raw = prefs.getString(_reportsKey);
    if (raw == null || raw.isEmpty) {
      return <TripReport>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TripReport.fromJson)
        .toList(growable: false);
  }

  Future<void> persistReports(List<TripReport> reports) async {
    final prefs = await _preferencesFuture;
    final serialised = jsonEncode(reports.map((report) => report.toJson()).toList());
    await prefs.setString(_reportsKey, serialised);
  }
}
