import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  bool _isInitialized = false;
  bool _hasVibrator = false;
  bool _hasCustomVibrationSupport = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _hasVibrator = (await Vibration.hasVibrator()) ?? false;
    _hasCustomVibrationSupport = (await Vibration.hasCustomVibrationsSupport()) ?? false;
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
      FlutterRingtonePlayer.playAlarm(volume: 0.8);
      Future<void>.delayed(const Duration(seconds: 3)).then((_) {
        FlutterRingtonePlayer.stop();
      });
    }

    if (vibration && _hasVibrator) {
      if (_hasCustomVibrationSupport) {
        await Vibration.vibrate(pattern: [0, 500, 150, 500]);
      } else {
        await Vibration.vibrate(duration: 800);
      }
    }
  }

  bool get isInitialized => _isInitialized;
}
