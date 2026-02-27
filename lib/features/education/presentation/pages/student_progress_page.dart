import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/core/widgets/error_boundary.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/student_progress_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/mastery_chart_widget.dart';

class StudentProgressPage extends StatelessWidget {
  const StudentProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppErrorBoundary(
      child: BlocProvider(
        create: (context) =>
            getIt<StudentProgressCubit>()..initialize('current-user-id'),
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: const Text(
              'تقدم الطالب',
              style: TextStyle(fontWeight: FontWeight.bold),

            ),
            centerTitle: true,
            elevation: 0,
        scrolledUnderElevation: 2,
            backgroundColor: theme.colorScheme.surface,

          ),
          body: BlocBuilder<StudentProgressCubit, StudentProgressState>(
            builder: (context, state) {
              return state.map(
                initial: (_) => const SizedBox.shrink(),
                loading: (_) =>
                    const Center(child: CircularProgressIndicator()),
                loaded: (s) => _buildDashboard(
                  context,
                  s.stats,
                  s.lessonProgress,
                  s.lessons,
                  s.overallMastery,
                ),
                error: (e) => Center(child: Text('خطأ: ${e.message}')),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    Map<String, dynamic> stats,
    List<Progress> progressList,
    List<Lesson> lessons,
    String overallMastery,
  ) {
    final theme = Theme.of(context);

    final double overallProgress = progressList.isEmpty
        ? 0
        : progressList.map((p) => p.progressPercent).reduce((a, b) => a + b) /
              (lessons.length * 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, stats, overallProgress, overallMastery),
          const SizedBox(height: 24),

          Text(
            'دروسك',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...lessons.map((lesson) {
            final progress = progressList.firstWhere(
              (p) => p.lessonId == lesson.id,
              orElse: () => Progress(
                id: '',
                userId: '',
                lessonId: lesson.id,
                progressPercent: 0,
                score: 0,
                masteryLevel: 'beginner',
                updatedAt: DateTime.now(),
                syncStatus: 'synced',
              ),
            );
            return _buildLessonProgressItem(context, lesson, progress);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Map<String, dynamic> stats,
    double overallProgress,
    String overallMastery,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المستوى العام',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _translateMastery(overallMastery),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatItem(
                  context,
                  Icons.school,
                  'الدروس المكتملة',
                  '${stats['completedLessons']}/${stats['totalLessons']}',
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  context,
                  Icons.help_outline,
                  'الأسئلة',
                  '${stats['totalQuestions'] ?? 0}',
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  context,
                  Icons.star,
                  'متوسط الدرجة',
                  '${((stats['avgScore'] as num?) ?? 0).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
          MasteryChartWidget(
            progress: overallProgress.clamp(0.0, 1.0),
            masteryLevel: overallMastery,
            size: 120,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonProgressItem(
    BuildContext context,
    Lesson lesson,
    Progress progress,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  lesson.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${progress.score} نقطة',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Animated progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.progressPercent / 100),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                minHeight: 8,
              );
            },
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم: ${progress.progressPercent}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _translateMastery(progress.masteryLevel),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _translateMastery(String level) {
    switch (level.toLowerCase()) {
      case 'expert':
        return 'خبير';
      case 'advanced':
        return 'متقدم';
      case 'intermediate':
        return 'متوسط';
      case 'beginner':
        return 'مبتدئ';
      default:
        return 'مبتدئ';
    }
  }
}
