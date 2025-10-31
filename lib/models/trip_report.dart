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

  int get totalAlerts => events.length;
}
