part of 'quiz_cubit.dart';

@freezed
class QuizState with _$QuizState {
  const factory QuizState.initial() = _Initial;
  const factory QuizState.loading() = _Loading;
  const factory QuizState.active({
    required List<QuizQuestion> questions,
    required int currentIndex,
    required Map<int, String> answers,
    required String attemptId,
    required String lessonTitle,
  }) = _Active;
  const factory QuizState.submitting() = _Submitting;
  const factory QuizState.completed({
    required int score,
    required String masteryLevel,
    required int totalQuestions,
    required int correctAnswers,
  }) = _Completed;
  const factory QuizState.error(String message) = _Error;
}
