import 'package:flutter/material.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:global_smart_education_platform/features/education/presentation/screens/alternative_teacher_screen.dart';

class LessonsPage extends StatefulWidget {
  const LessonsPage({super.key});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  final EducationRepository _repository = getIt<EducationRepository>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'الدروس المتاحة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<Lesson>>(
        stream: _repository.watchLessons(),
        builder: (context, lessonSnapshot) {
          if (lessonSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lessons = lessonSnapshot.data ?? [];
          if (lessons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد دروس متاحة حالياً',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<List<Progress>>(
            stream: _repository.watchProgresses(),
            builder: (context, progressSnapshot) {
              final progresses = progressSnapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  // Find progress for this lesson, returning empty if not found
                  final progress = progresses.firstWhere(
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
                  return _buildLessonCard(context, lesson, progress);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    Lesson lesson,
    Progress progress,
  ) {
    final theme = Theme.of(context);
    final isCompleted = progress.progressPercent >= 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => AlternativeTeacherScreen(lesson: lesson),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon / Image placeholder
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.play_lesson_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lesson.durationMinutes} دقيقة',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Progress Indicator
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.progressPercent / 100,
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ],
                ),

                // Start Quiz Button removed
              ],
            ),
          ),
        ),
      ),
    );
  }
}
