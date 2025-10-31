import 'package:flutter/foundation.dart';

class NotificationService {
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Placeholder for requesting permissions and configuring local
    // notifications. Keeping a short delay to mimic async initialization.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _isInitialized = true;
  }

  Future<void> showAlert({
    required String title,
    required String body,
    required bool sound,
    required bool vibration,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Until the real notification plugin is wired, surface alerts through the
    // debug console so that testers can still follow the flow.
    debugPrint(
      'NotificationService -> $title | $body | sound=$sound | vibration=$vibration',
    );
  }

  bool get isInitialized => _isInitialized;
}
