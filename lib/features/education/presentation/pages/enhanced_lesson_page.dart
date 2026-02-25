import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/lesson_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/enhanced_lesson_content.dart';

/// صفحة الدرس المحسّنة مع دعم الوسائط
class EnhancedLessonPage extends StatelessWidget {
  const EnhancedLessonPage({
    super.key,
    required this.lessonId,
    required this.userId,
  });

  final String lessonId;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LessonCubit>(
          create: (_) => getIt<LessonCubit>()
            ..loadLesson(
              lessonId: lessonId,
              userId: userId,
            ),
        ),
      ],
      child: const _EnhancedLessonPageBody(),
    );
  }
}

class _EnhancedLessonPageBody extends StatelessWidget {
  const _EnhancedLessonPageBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonCubit, LessonState>(
      builder: (context, state) => switch (state) {
        LessonInitial() ||
        LessonLoading() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        LessonError(message: final msg) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(msg)),
        ),
        LessonLoaded(
          lesson: final lesson,
          isCompleted: final completed,
        ) =>
          EnhancedLessonContent(
            lesson: lesson,
            isCompleted: completed,
          ),
      },
    );
  }
}
