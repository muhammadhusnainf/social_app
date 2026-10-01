import 'package:flutter/services.dart';

class Sounds {
  Sounds._();

  static bool enabled = true;

  static void _play(SystemSoundType type, Future<void> Function() haptic) {
    if (!enabled) return;
    try {
      SystemSound.play(type);
      haptic();
    } catch (_) {}
  }

  static void tap() => _play(SystemSoundType.click, HapticFeedback.selectionClick);

  static void success() => _play(SystemSoundType.click, HapticFeedback.lightImpact);

  static void message() => _play(SystemSoundType.alert, HapticFeedback.mediumImpact);
}