import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/quiz_repository.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';

part 'quiz_state.dart';
part 'quiz_cubit.freezed.dart';

@injectable
class QuizCubit extends Cubit<QuizState> {
  QuizCubit(this._quizRepository, this._educationRepository)
    : super(const QuizState.initial());

  final QuizRepository _quizRepository;
  final EducationRepository _educationRepository;

  late String _lessonId;
  late String _userId;

  /// Load quiz for a lesson. Restores in-progress attempt if one exists.
  Future<void> loadQuiz(
    String lessonId,
    String lessonTitle, {
    String userId = 'current-user-id',
  }) async {
    emit(const QuizState.loading());
    _lessonId = lessonId;
    _userId = userId;

    try {
      final questions = await _quizRepository.getQuestionsForLesson(lessonId);
      if (questions.isEmpty) {
        emit(const QuizState.error('لا توجد أسئلة لهذا الدرس'));
        return;
      }

      final attempt = await _quizRepository.getOrCreateAttempt(
        userId,
        lessonId,
      );

      // Parse saved answers
      final Map<String, dynamic> savedAnswersRaw =
          jsonDecode(attempt.answers) as Map<String, dynamic>;
      final Map<int, String> answers = {};
      for (final entry in savedAnswersRaw.entries) {
        answers[int.parse(entry.key)] = entry.value.toString();
      }

      emit(
        QuizState.active(
          questions: questions,
          currentIndex: attempt.currentIndex,
          answers: answers,
          attemptId: attempt.id,
          lessonTitle: lessonTitle,
        ),
      );
    } catch (e) {
      emit(QuizState.error('حدث خطأ: $e'));
    }
  }

  /// Save answer for current question (auto-save).
  Future<void> answerQuestion(int questionIndex, String answer) async {
    final current = state;
    if (current is! _Active) return;

    final newAnswers = Map<int, String>.from(current.answers);
    newAnswers[questionIndex] = answer;

    // Emit updated state immediately
    emit(current.copyWith(answers: newAnswers));

    // Auto-save to DB
    await _quizRepository.saveAnswer(
      current.attemptId,
      questionIndex,
      answer,
      current.currentIndex,
      jsonEncode(newAnswers.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  /// Navigate to next question.
  void goToNext() {
    final current = state;
    if (current is! _Active) return;
    if (current.currentIndex >= current.questions.length - 1) return;

    emit(current.copyWith(currentIndex: current.currentIndex + 1));
  }

  /// Navigate to previous question.
  void goToPrevious() {
    final current = state;
    if (current is! _Active) return;
    if (current.currentIndex <= 0) return;

    emit(current.copyWith(currentIndex: current.currentIndex - 1));
  }

  /// Check if all required questions are answered.
  bool get allAnswered {
    final current = state;
    if (current is! _Active) return false;
    return current.answers.length >= current.questions.length;
  }

  /// Submit the quiz and calculate the score.
  Future<void> submitQuiz() async {
    final current = state;
    if (current is! _Active) return;

    emit(const QuizState.submitting());

    try {
      final answersJson = jsonEncode(
        current.answers.map((k, v) => MapEntry(k.toString(), v)),
      );

      final result = await _quizRepository.submitQuiz(
        current.attemptId,
        answersJson,
        current.questions,
      );

      // Update progress in education repository
      await _educationRepository.updateProgress(
        userId: _userId,
        lessonId: _lessonId,
        incrementBy: 0, // Don't change progress percent
        score: result.score,
        masteryLevel: result.masteryLevel,
      );

      // Count correct answers
      final Map<String, dynamic> answers =
          jsonDecode(answersJson) as Map<String, dynamic>;
      int correct = 0;
      for (int i = 0; i < current.questions.length; i++) {
        final userAnswer = answers[i.toString()]
            ?.toString()
            .trim()
            .toLowerCase();
        final correctAnswer = current.questions[i].correctAnswer
            .trim()
            .toLowerCase();
        if (userAnswer == correctAnswer) correct++;
      }

      emit(
        QuizState.completed(
          score: result.score,
          masteryLevel: result.masteryLevel,
          totalQuestions: current.questions.length,
          correctAnswers: correct,
        ),
      );
    } catch (e) {
      emit(QuizState.error('حدث خطأ أثناء التقييم: $e'));
    }
  }
}
