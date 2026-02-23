import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/lesson_state.dart';

export 'lesson_state.dart';

@injectable
class LessonCubit extends Cubit<LessonState> {
  LessonCubit(this._repository) : super(const LessonState.initial());

  final EducationRepository _repository;

  String? _currentUserId;
  String? _currentLessonId;

  Future<void> loadLesson({
    required String lessonId,
    required String userId,
  }) async {
    _currentUserId = userId;
    _currentLessonId = lessonId;

    emit(const LessonState.loading());

    try {
      final Lesson? lesson = await _repository.getLessonById(lessonId);
      if (lesson == null) {
        emit(const LessonState.error('Lesson not found'));
        return;
      }

      final Progress? progress = await _repository
          .getProgressByUserAndLesson(userId, lessonId);
      final bool isCompleted = (progress?.progressPercent ?? 0) >= 100;

      emit(LessonState.loaded(lesson: lesson, isCompleted: isCompleted));
      log.i(
        'Lesson loaded: ${lesson.title} (completed=$isCompleted)',
        tag: LogTags.bloc,
      );
    } catch (e, s) {
      log.e('Failed to load lesson', tag: LogTags.bloc, error: e, stackTrace: s);
      emit(const LessonState.error('Failed to load lesson'));
    }
  }

  Future<void> markCompleted() async {
    final String? userId = _currentUserId;
    final String? lessonId = _currentLessonId;
    if (userId == null || lessonId == null) return;

    final LessonState currentState = state;
    if (currentState is LessonLoaded && currentState.isCompleted) return;

    try {
      await _repository.markLessonCompleted(
        userId: userId,
        lessonId: lessonId,
      );

      if (currentState is LessonLoaded) {
        emit(currentState.copyWith(isCompleted: true));
      }

      log.i(
        'Lesson marked as completed (lesson=$lessonId, user=$userId)',
        tag: LogTags.bloc,
      );
    } catch (e, s) {
      log.e(
        'Failed to mark lesson completed',
        tag: LogTags.bloc,
        error: e,
        stackTrace: s,
      );
    }
  }
}
