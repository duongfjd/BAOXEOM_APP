import 'package:flutter/foundation.dart';

class GoogleTtsWebPlayer {
  static bool get isSupported => false;

  static void speak(String text, VoidCallback onComplete, VoidCallback onError) {
    throw UnsupportedError('SpeechSynthesis is only supported on Web');
  }

  static void pause() {}
  static void resume() {}
  static void stop() {}
}
