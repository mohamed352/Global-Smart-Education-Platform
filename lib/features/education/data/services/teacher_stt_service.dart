import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';

@lazySingleton
class TeacherSttService {
  final SpeechToText _speechToText = SpeechToText();
  final AppLogger log = AppLogger.instance;
  static const String _logTag = 'STT_SERVICE';

  final ValueNotifier<bool> _isListening = ValueNotifier<bool>(false);
  final ValueNotifier<String> _recognizedText = ValueNotifier<String>('');

  ValueListenable<bool> get isListening => _isListening;
  ValueListenable<String> get recognizedText => _recognizedText;

  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          log.e('STT Error: ${error.errorMsg}', tag: _logTag);
          _isListening.value = false;
        },
        onStatus: (status) {
          log.i('STT Status: $status', tag: _logTag);
          if (status == 'listening') {
            _isListening.value = true;
          } else if (status == 'notListening' || status == 'done') {
            _isListening.value = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      log.e('STT Initialization failed: $e', tag: _logTag);
      return false;
    }
  }

  Future<void> startListening({
    required void Function(String) onResult,
    String? localeId,
  }) async {
    final bool available = await initialize();
    if (!available) {
      log.w('STT not available', tag: _logTag);
      return;
    }

    _recognizedText.value = '';

    // Default to Arabic (Egypt) if not specified
    final String targetLocale = localeId ?? 'ar_EG';

    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _recognizedText.value = result.recognizedWords;
          if (result.finalResult) {
            onResult(result.recognizedWords);
            _isListening.value = false;
          }
        },
        localeId: targetLocale,
        // ignore: deprecated_member_use
        listenMode: ListenMode.dictation,
        // ignore: deprecated_member_use
        cancelOnError: true,
      );
      _isListening.value = true;
      log.i('STT listening started ($targetLocale)', tag: _logTag);
    } catch (e) {
      log.e('Error starting STT: $e', tag: _logTag);
      _isListening.value = false;
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening.value = false;
    log.i('STT listening stopped', tag: _logTag);
  }

  Future<void> cancelListening() async {
    await _speechToText.cancel();
    _isListening.value = false;
    log.i('STT listening cancelled', tag: _logTag);
  }
}
