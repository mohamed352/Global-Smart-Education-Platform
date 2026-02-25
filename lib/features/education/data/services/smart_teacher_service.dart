import 'package:injectable/injectable.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/services/gemma_service.dart';

/// خدمة محسّنة للترجمة الصوتية والتحسينات الذكية
@lazySingleton
class SmartTeacherService {
  SmartTeacherService(this._gemmaService);

  final GemmaService _gemmaService;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      log.i('Initializing SmartTeacherService');
      _initialized = true;
    } catch (e) {
      log.e(
        'Failed to initialize SmartTeacherService',
        error: e,
      );
    }
  }

  /// الحصول على شرح مفصل للدرس
  Future<String> getDetailedExplanation(
    String lessonContent, {
    String? difficulty, // easy, medium, hard
    int maxLength = 500,
  }) async {
    try {
      final prompt = _buildDetailedPrompt(
        lessonContent,
        difficulty,
      );
      return await _gemmaService.getExplanation(prompt);
    } catch (e) {
      log.e('Failed to get detailed explanation', error: e);
      rethrow;
    }
  }

  /// الحصول على ملخص قصير للدرس
  Future<String> getSummary(String lessonContent) async {
    try {
      final prompt =
          '''اكتب ملخصاً قصيراً (3-4 نقاط) لمحتوى الدرس التالي:

$lessonContent

الملخص:''';
      return await _gemmaService.getExplanation(prompt);
    } catch (e) {
      log.e('Failed to get summary', error: e);
      rethrow;
    }
  }

  /// إنشاء أسئلة اختبار من محتوى الدرس
  Future<String> generateQuestions(
    String lessonContent, {
    int count = 5,
  }) async {
    try {
      final prompt =
          '''اكتب $count أسئلة اختبار متعددة الخيارات بناءً على محتوى الدرس التالي:

$lessonContent

الأسئلة:''';
      return await _gemmaService.getExplanation(prompt);
    } catch (e) {
      log.e('Failed to generate questions', error: e);
      rethrow;
    }
  }

  /// تحويل النص إلى كلام (stub)
  Future<void> speak(String text) async {
    try {
      log.i('Speaking text length: ${text.length}');
      // في المستقبل: استخدم flutter_tts أو خدمة أخرى
      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );
    } catch (e) {
      log.e('Failed to speak', error: e);
    }
  }

  /// إيقاف الكلام
  Future<void> stopSpeaking() async {
    try {
      log.i('Speech stopped');
    } catch (e) {
      log.e('Failed to stop speaking', error: e);
    }
  }

  /// توقيف مؤقت للكلام
  Future<void> pauseSpeaking() async {
    try {
      log.i('Speech paused');
    } catch (e) {
      log.e('Failed to pause speaking', error: e);
    }
  }

  /// الإجابة على سؤال محدد
  Future<String> answerQuestion(
    String lessonContent,
    String question, {
    int maxLength = 300,
  }) async {
    try {
      final prompt =
          '''بناءً على محتوى الدرس التالي:

$lessonContent

أجب على السؤال التالي بإيجاز:
$question

الإجابة:''';
      return await _gemmaService.getExplanation(prompt);
    } catch (e) {
      log.e('Failed to answer question', error: e);
      rethrow;
    }
  }

  /// تحليل المستوى التعليمي
  Future<String> analyzeLearningLevel(
    String lessonContent,
    String studentAnswer,
  ) async {
    try {
      final prompt =
          '''قيّم إجابة الطالب التالية على أساس محتوى الدرس:

محتوى الدرس:
$lessonContent

إجابة الطالب:
$studentAnswer

التقييم والتعليقات:''';
      return await _gemmaService.getExplanation(prompt);
    } catch (e) {
      log.e('Failed to analyze learning level', error: e);
      rethrow;
    }
  }

  /// الحصول على نصائح دراسية
  Future<String> getStudyTips(String topic) async {
    try {
      final prompt =
          '''اكتب نصائح دراسية عملية فعالة لفهم موضوع: $topic

النصائح:''';
      return await _gemmaService.getExplanation(prompt);
    } catch (e) {
      log.e('Failed to get study tips', error: e);
      rethrow;
    }
  }

  String _buildDetailedPrompt(
    String lessonContent,
    String? difficulty,
  ) {
    final difficultyText = difficulty == null
        ? ''
        : '\nمستوى التفصيل: $difficulty (سهل = شرح بسيط، صعب = شرح معمّق)';

    return '''اشرح محتوى الدرس التالي بطريقة واضحة وسهلة الفهم:

$lessonContent$difficultyText

الشرح:''';
  }

  Future<void> dispose() async {
    try {
      log.i('SmartTeacherService disposed');
    } catch (e) {
      log.e(
        'Error disposing SmartTeacherService',
        error: e,
      );
    }
  }
}
