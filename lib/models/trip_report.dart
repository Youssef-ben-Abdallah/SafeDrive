import 'detection_event.dart';

class TripReport {
  TripReport({
    required this.startTime,
    required this.endTime,
    required List<DetectionEvent> events,
  }) : events = List.unmodifiable(events);

  final DateTime startTime;
  final DateTime endTime;
  final List<DetectionEvent> events;

  Duration get duration => endTime.difference(startTime);

  int get drowsinessCount =>
      events.where((event) => event.type == DetectionEventType.drowsiness).length;

  int get distractionCount =>
      events.where((event) => event.type == DetectionEventType.distraction).length;

  int get regulationCount =>
      events.where((event) => event.type == DetectionEventType.regulation).length;

  int get totalAlerts => events.length;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'events': events.map((event) => event.toJson()).toList(),
      };

  static TripReport fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List<dynamic>? ?? <dynamic>[];
    return TripReport(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      events: eventsJson
          .whereType<Map<String, dynamic>>()
          .map(DetectionEvent.fromJson)
          .toList(),
    );
  }
}
