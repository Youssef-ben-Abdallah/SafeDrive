import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter/services.dart';

class NotificationService {
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
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

    debugPrint('NotificationService -> $title | $body');

    if (sound) {
      final FlutterRingtonePlayer ringtonePlayer = FlutterRingtonePlayer();

      await ringtonePlayer.play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: false,
        volume: 0.8,
        asAlarm: true,
      );

      unawaited(
        Future<void>.delayed(const Duration(seconds: 3)).then((_) {
          return ringtonePlayer.stop();
        }),
      );
    }

    if (vibration) {
      await _triggerVibrationPattern();
    }
  }

  bool get isInitialized => _isInitialized;

  Future<void> _triggerVibrationPattern() async {
    try {
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.vibrate();
    } catch (error, stackTrace) {
      debugPrint('NotificationService vibration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
