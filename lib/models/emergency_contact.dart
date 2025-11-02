class EmergencyContact {
  const EmergencyContact({
    required this.name,
    this.phoneNumber,
    this.email,
  });

  final String name;
  final String? phoneNumber;
  final String? email;

  bool get hasPhone => phoneNumber != null && phoneNumber!.trim().isNotEmpty;

  bool get hasEmail => email != null && email!.trim().isNotEmpty;
}

class EmergencyDispatchMessage {
  EmergencyDispatchMessage({
    required this.contact,
    required this.channel,
    required this.body,
    required this.generatedAt,
    this.latitude,
    this.longitude,
  });

  final EmergencyContact contact;
  final String channel;
  final String body;
  final DateTime generatedAt;
  final double? latitude;
  final double? longitude;
}
