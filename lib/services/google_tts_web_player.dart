import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class GoogleTtsWebPlayer {
  static bool get isSupported => html.window.speechSynthesis != null;

  static void speak(String text, VoidCallback onComplete, VoidCallback onError) {
    try {
      final synth = html.window.speechSynthesis;
      if (synth == null) {
        onError();
        return;
      }

      // Cancel any ongoing speech
      synth.cancel();

      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.lang = 'vi-VN';
      
      utterance.onEnd.listen((event) {
        onComplete();
      });

      utterance.onError.listen((event) {
        onError();
      });

      synth.speak(utterance);
    } catch (e) {
      print("Error in HTML SpeechSynthesis: $e");
      onError();
    }
  }

  static void pause() {
    try {
      html.window.speechSynthesis?.pause();
    } catch (e) {
      print("Error pausing HTML SpeechSynthesis: $e");
    }
  }

  static void resume() {
    try {
      html.window.speechSynthesis?.resume();
    } catch (e) {
      print("Error resuming HTML SpeechSynthesis: $e");
    }
  }

  static void stop() {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (e) {
      print("Error stopping HTML SpeechSynthesis: $e");
    }
  }
}
