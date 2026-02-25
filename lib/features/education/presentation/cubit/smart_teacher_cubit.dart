import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:global_smart_education_platform/features/education/data/services/smart_teacher_service.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'smart_teacher_state.dart';

@injectable
class SmartTeacherCubit extends Cubit<SmartTeacherState> {
  SmartTeacherCubit(this._smartTeacherService)
    : super(const SmartTeacherInitial());

  final SmartTeacherService _smartTeacherService;

  /// الحصول على شرح تفصيلي
  Future<void> getDetailedExplanation(
    String lessonContent, {
    String? difficulty,
  }) async {
    emit(const SmartTeacherLoading());
    try {
      final explanation = await _smartTeacherService
          .getDetailedExplanation(
            lessonContent,
            difficulty: difficulty,
          );
      emit(SmartTeacherExplanation(explanation));
    } catch (e) {
      log.e('Failed to get detailed explanation', error: e);
      emit(
        SmartTeacherError(
          'فشل الحصول على الشرح: ${e.toString()}',
        ),
      );
    }
  }

  /// الحصول على ملخص
  Future<void> getSummary(String lessonContent) async {
    emit(const SmartTeacherLoading());
    try {
      final summary = await _smartTeacherService.getSummary(
        lessonContent,
      );
      emit(SmartTeacherExplanation(summary));
    } catch (e) {
      log.e('Failed to get summary', error: e);
      emit(
        const SmartTeacherError('فشل الحصول على الملخص'),
      );
    }
  }

  /// إنشاء أسئلة اختبار
  Future<void> generateQuestions(
    String lessonContent, {
    int count = 5,
  }) async {
    emit(const SmartTeacherLoading());
    try {
      final questions = await _smartTeacherService
          .generateQuestions(lessonContent, count: count);
      emit(SmartTeacherQuestions(questions));
    } catch (e) {
      log.e('Failed to generate questions', error: e);
      emit(const SmartTeacherError('فشل إنشاء الأسئلة'));
    }
  }

  /// الإجابة على سؤال
  Future<void> answerQuestion(
    String lessonContent,
    String question,
  ) async {
    emit(const SmartTeacherLoading());
    try {
      final answer = await _smartTeacherService
          .answerQuestion(lessonContent, question);
      emit(SmartTeacherAnswer(answer));
    } catch (e) {
      log.e('Failed to answer question', error: e);
      emit(
        const SmartTeacherError('فشل الحصول على الإجابة'),
      );
    }
  }

  /// تحويل النص إلى كلام
  Future<void> speak(String text) async {
    try {
      await _smartTeacherService.speak(text);
      emit(const SmartTeacherSpeaking());
    } catch (e) {
      log.e('Failed to speak', error: e);
      emit(
        const SmartTeacherError('فشل تحويل النص إلى كلام'),
      );
    }
  }

  /// إيقاف الكلام
  Future<void> stopSpeaking() async {
    try {
      await _smartTeacherService.stopSpeaking();
      emit(const SmartTeacherInitial());
    } catch (e) {
      log.e('Failed to stop speaking', error: e);
    }
  }

  /// توقيف مؤقت
  Future<void> pauseSpeaking() async {
    try {
      await _smartTeacherService.pauseSpeaking();
      emit(const SmartTeacherPaused());
    } catch (e) {
      log.e('Failed to pause speaking', error: e);
    }
  }

  /// تحليل مستوى التعلم
  Future<void> analyzeLearningLevel(
    String lessonContent,
    String studentAnswer,
  ) async {
    emit(const SmartTeacherLoading());
    try {
      final analysis = await _smartTeacherService
          .analyzeLearningLevel(
            lessonContent,
            studentAnswer,
          );
      emit(SmartTeacherFeedback(analysis));
    } catch (e) {
      log.e('Failed to analyze learning level', error: e);
      emit(
        const SmartTeacherError('فشل تحليل مستوى التعلم'),
      );
    }
  }

  /// الحصول على نصائح دراسية
  Future<void> getStudyTips(String topic) async {
    emit(const SmartTeacherLoading());
    try {
      final tips = await _smartTeacherService.getStudyTips(
        topic,
      );
      emit(SmartTeacherStudyTips(tips));
    } catch (e) {
      log.e('Failed to get study tips', error: e);
      emit(
        const SmartTeacherError(
          'فشل الحصول على نصائح الدراسة',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _smartTeacherService.dispose();
    return super.close();
  }
}
