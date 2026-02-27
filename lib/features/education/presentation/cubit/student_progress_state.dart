part of 'student_progress_cubit.dart';

@freezed
class StudentProgressState with _$StudentProgressState {
  const factory StudentProgressState.initial() = _Initial;
  const factory StudentProgressState.loading() = _Loading;
  const factory StudentProgressState.loaded({
    required Map<String, dynamic> stats,
    required List<Progress> lessonProgress,
    required List<Lesson> lessons,
    required String overallMastery,
  }) = _Loaded;
  const factory StudentProgressState.error(String message) = _Error;
}
