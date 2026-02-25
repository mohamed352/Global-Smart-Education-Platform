import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/enhanced_dashboard_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/enhanced_dashboard_state.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';
import 'package:global_smart_education_platform/features/education/presentation/pages/lesson_page.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/lesson_card.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/sync_status_icon.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/user_card.dart';

/// لوحة التحكم المحسّنة
class EnhancedDashboardPage extends StatelessWidget {
  const EnhancedDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            BlocSelector<
              EnhancedDashboardCubit,
              EnhancedDashboardState,
              String
            >(
              selector: (state) => state.users.isNotEmpty
                  ? state.users.first.name
                  : 'جاري التحميل...',
              builder: (context, userName) =>
                  Text('المعلم الذكي - $userName'),
            ),
        centerTitle: true,
        elevation: 0,
        actions: <Widget>[
          _HeaderSyncIcon(),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'مزامنة الآن',
            onPressed: () => context
                .read<EnhancedDashboardCubit>()
                .triggerSync(),
          ),
        ],
      ),
      body: _EnhancedDashboardBody(),
    );
  }
}

class _HeaderSyncIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      EnhancedDashboardCubit,
      EnhancedDashboardState,
      ({ConnectivityState c, SyncEngineStatus s, int p})
    >(
      selector: (state) => (
        c: state.connectivity,
        s: state.syncStatus,
        p: state.pendingSyncCount,
      ),
      builder: (context, data) => SyncStatusIcon(
        connectivity: data.c,
        syncStatus: data.s,
        pendingCount: data.p,
      ),
    );
  }
}

class _EnhancedDashboardBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      EnhancedDashboardCubit,
      EnhancedDashboardState
    >(
      builder: (context, state) {
        if (state.lessons.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final cubit = context
            .read<EnhancedDashboardCubit>();
        final userId = state.users.isNotEmpty
            ? state.users.first.id
            : '';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بطاقة معلومات الطالب
            if (state.users.isNotEmpty) ...[
              Text(
                'ملف الطالب',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              UserCard(user: state.users.first),
              const SizedBox(height: 24),
            ],

            // بطاقات الإحصائيات
            Text(
              'إحصائيات التعلم',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildStatisticsGrid(context, state),
            const SizedBox(height: 24),

            // الدروس المميزة
            Text(
              'الدروس المميزة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...cubit.getFeaturedLessons().map((lesson) {
              return _buildLessonTile(
                context,
                lesson,
                userId,
                cubit,
              );
            }),
            const SizedBox(height: 24),

            // جميع الدروس
            Text(
              'جميع الدروس',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...state.lessons.map((lesson) {
              final progressId = cubit.getProgressId(
                userId,
                lesson.id,
              );
              return LessonCard(
                lesson: lesson,
                progressPercent: cubit.getProgressPercent(
                  userId,
                  lesson.id,
                ),
                syncStatus: cubit.getProgressSyncStatus(
                  userId,
                  lesson.id,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LessonPage(
                      lessonId: lesson.id,
                      userId: userId,
                    ),
                  ),
                ),
                onUpdateOffline: userId.isNotEmpty
                    ? () => cubit.updateProgress(
                        userId: userId,
                        lessonId: lesson.id,
                      )
                    : null,
                onSimulateConflict: progressId != null
                    ? () {
                        cubit.simulateRemoteConflict(
                          progressId,
                        );
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم تسجيل تعارض في البيانات.',
                            ),
                          ),
                        );
                      }
                    : null,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildStatisticsGrid(
    BuildContext context,
    EnhancedDashboardState state,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          context,
          'الدروس المكملة',
          state.completedLessonsCount.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'متوسط التقدم',
          '${state.averageProgressPercent}%',
          Icons.trending_up,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'ساعات التعلم',
          state.totalLearningHours.toString(),
          Icons.timer,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'إجمالي الدروس',
          state.lessons.length.toString(),
          Icons.school,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTile(
    BuildContext context,
    dynamic lesson,
    String userId,
    EnhancedDashboardCubit cubit,
  ) {
    final lessonId = lesson.id as String;
    final lessonTitle = lesson.title as String;
    final progressPercent = cubit.getProgressPercent(
      userId,
      lessonId,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: progressPercent == 100
              ? Colors.green
              : Colors.blue,
          child: Icon(
            progressPercent == 100
                ? Icons.check
                : Icons.school,
            color: Colors.white,
          ),
        ),
        title: Text(lessonTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text('$progressPercent% مكتمل'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LessonPage(
              lessonId: lessonId,
              userId: userId,
            ),
          ),
        ),
      ),
    );
  }
}
