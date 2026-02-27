import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';

part 'student_progress_state.dart';
part 'student_progress_cubit.freezed.dart';

@injectable
class StudentProgressCubit extends Cubit<StudentProgressState> {
  StudentProgressCubit(this._repository)
    : super(const StudentProgressState.initial());

  final EducationRepository _repository;
  StreamSubscription<List<Progress>>? _progressSubscription;

  void initialize(String userId) {
    emit(const StudentProgressState.loading());

    // Watch for progress changes to update dashboard in real-time
    _progressSubscription = _repository.watchProgresses().listen((_) {
      _loadDashboardData(userId);
    });

    _loadDashboardData(userId);
  }

  Future<void> _loadDashboardData(String userId) async {
    try {
      final stats = await _repository.getSummaryStats(userId);
      final lessonProgress = await _repository.getProgresses();
      final lessons = await _repository.getLessons();

      final overallMastery = _calculateOverallMastery(stats);

      emit(
        StudentProgressState.loaded(
          stats: stats,
          lessonProgress: lessonProgress,
          lessons: lessons,
          overallMastery: overallMastery,
        ),
      );
    } catch (e) {
      emit(StudentProgressState.error(e.toString()));
    }
  }

  String _calculateOverallMastery(Map<String, dynamic> stats) {
    final int completed = stats['completedLessons'] as int? ?? 0;
    final int total = stats['totalLessons'] as int? ?? 0;
    final int questions = stats['totalQuestions'] as int? ?? 0;
    final double avgScore = (stats['avgScore'] as num? ?? 0.0).toDouble();

    if (completed == total && questions > 15 && avgScore > 80) return 'expert';
    if (completed >= total / 2 && questions > 8 && avgScore > 60) {
      return 'advanced';
    }
    if (completed > 0 || questions > 2) return 'intermediate';
    return 'beginner';
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    return super.close();
  }
}
