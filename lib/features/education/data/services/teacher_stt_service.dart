import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';

/// Offline-first speech-to-text service for student voice input
/// Uses device's built-in speech recognition — works offline when supported
@lazySingleton
class TeacherSttService {
  TeacherSttService();

  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;

  /// Whether the service is currently listening
  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);

  /// The recognised text from the current session
  final ValueNotifier<String> recognizedText = ValueNotifier<String>('');

  /// Whether STT is available on this device
  bool get isAvailable => _isInitialized;

  /// Initialize STT — call once before first use
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _stt.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      log.i('STT initialized: $_isInitialized', tag: LogTags.app);
      return _isInitialized;
    } catch (e) {
      log.e('STT init error', tag: LogTags.error, error: e);
      return false;
    }
  }

  /// Start listening for speech input (Arabic)
  Future<void> startListening({
    required void Function(String finalText) onResult,
  }) async {
    if (!_isInitialized) {
      final bool ready = await initialize();
      if (!ready) {
        log.w('STT not available on this device', tag: LogTags.app);
        return;
      }
    }

    recognizedText.value = '';
    isListening.value = true;

    await _stt.listen(
      onResult: (result) {
        recognizedText.value = result.recognizedWords;
        if (result.finalResult) {
          isListening.value = false;
          final String text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            onResult(text);
          }
          log.i('STT final result: $text', tag: LogTags.app);
        }
      },
      localeId: 'ar',
      listenMode: ListenMode.dictation,
      cancelOnError: true,
      partialResults: true,
    );

    log.i('STT listening started (Arabic)', tag: LogTags.app);
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _stt.stop();
    isListening.value = false;
    log.i('STT listening stopped', tag: LogTags.app);
  }

  /// Cancel listening without processing
  Future<void> cancelListening() async {
    await _stt.cancel();
    isListening.value = false;
    recognizedText.value = '';
    log.i('STT listening cancelled', tag: LogTags.app);
  }

  void _onStatus(String status) {
    log.d('STT status: $status', tag: LogTags.app);
    if (status == 'done' || status == 'notListening') {
      isListening.value = false;
    }
  }

  void _onError(dynamic error) {
    log.e('STT error: $error', tag: LogTags.error);
    isListening.value = false;
  }

  /// Dispose resources
  void dispose() {
    _stt.cancel();
    isListening.dispose();
    recognizedText.dispose();
  }
}
