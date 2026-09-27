import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class HapticService {
  static Future<void> light() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> success() async {
    if (kIsWeb) return;
    await HapticFeedback.vibrate();
  }

  static Future<void> error() async {
    if (kIsWeb) return;
    // Custom pattern for error
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(pattern: [0, 50, 100, 50], intensities: [0, 255, 0, 255]);
      }
    } catch (_) {}
  }
}
