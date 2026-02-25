import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';

/// Offline text-to-speech service for the AI Teacher.
/// Uses the device's built-in TTS engine — no internet required.
@lazySingleton
class TeacherTtsService {
  TeacherTtsService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();

  /// Whether TTS is currently speaking
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  /// Whether the user has muted voice output
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  Future<void> _init() async {
    try {
      await _tts.setLanguage('ar');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        isSpeaking.value = true;
        log.d('TTS started speaking', tag: LogTags.app);
      });

      _tts.setCompletionHandler(() {
        isSpeaking.value = false;
        log.d('TTS finished speaking', tag: LogTags.app);
      });

      _tts.setCancelHandler(() {
        isSpeaking.value = false;
        log.d('TTS cancelled', tag: LogTags.app);
      });

      _tts.setErrorHandler((dynamic msg) {
        isSpeaking.value = false;
        log.e('TTS error: $msg', tag: LogTags.error);
      });

      log.i('TTS initialized (Arabic, offline)', tag: LogTags.app);
    } catch (e) {
      log.e('TTS init error', tag: LogTags.error, error: e);
    }
  }

  /// Speak text aloud (respects mute state)
  Future<void> speak(String text) async {
    if (_isMuted) {
      log.d('TTS muted — skipping', tag: LogTags.app);
      return;
    }
    try {
      final String cleanText = text
          .replaceAll(RegExp(r'[^\u0600-\u06FF\u0750-\u077F\s\d.,!?؟،؛]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleanText.isEmpty) return;

      await _tts.stop();
      await _tts.speak(cleanText);
    } catch (e) {
      log.e('TTS speak error', tag: LogTags.error, error: e);
      isSpeaking.value = false;
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _tts.stop();
      isSpeaking.value = false;
    } catch (e) {
      log.e('TTS stop error', tag: LogTags.error, error: e);
    }
  }

  /// Toggle mute state
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stop();
    }
    log.i('TTS mute: $_isMuted', tag: LogTags.app);
  }

  /// Set mute state directly
  set isMutedValue(bool value) {
    _isMuted = value;
    if (_isMuted) {
      stop();
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    isSpeaking.dispose();
  }
}
