import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';

part 'lesson_state.freezed.dart';

@freezed
sealed class LessonState with _$LessonState {
  const factory LessonState.initial() = LessonInitial;
  const factory LessonState.loading() = LessonLoading;
  const factory LessonState.loaded({
    required Lesson lesson,
    required bool isCompleted,
  }) = LessonLoaded;
  const factory LessonState.error(String message) = LessonError;
}
