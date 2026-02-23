import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/dashboard_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/dashboard_state.dart';
import 'package:global_smart_education_platform/features/education/presentation/pages/lesson_page.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/lesson_card.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/sync_status_icon.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/user_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<DashboardCubit, DashboardState, String>(
          selector: (state) => state.users.isNotEmpty ? state.users.first.name : 'Loading...',
          builder: (context, userName) => Text('Education POC - $userName'),
        ),
        actions: <Widget>[
          _HeaderSyncIcon(),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Force Sync',
            onPressed: () => context.read<DashboardCubit>().triggerSync(),
          ),
        ],
      ),
      body: _DashboardBody(),
    );
  }
}

class _HeaderSyncIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<DashboardCubit, DashboardState, ({ConnectivityState c, SyncEngineStatus s, int p})>(
      selector: (state) => (c: state.connectivity, s: state.syncStatus, p: state.pendingSyncCount),
      builder: (context, data) => SyncStatusIcon(
        connectivity: data.c,
        syncStatus: data.s,
        pendingCount: data.p,
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.lessons.isEmpty) return const Center(child: CircularProgressIndicator());
        
        final cubit = context.read<DashboardCubit>();
        final userId = state.users.isNotEmpty ? state.users.first.id : '';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.users.isNotEmpty) ...[
              Text('Student Info', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              UserCard(user: state.users.first),
              const SizedBox(height: 24),
            ],
            Text('Available Lessons', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...state.lessons.map((lesson) {
              final progressId = cubit.getProgressId(userId, lesson.id);
              return LessonCard(
                lesson: lesson,
                progressPercent: cubit.getProgressPercent(userId, lesson.id),
                syncStatus: cubit.getProgressSyncStatus(userId, lesson.id),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => LessonPage(lessonId: lesson.id, userId: userId)),
                ),
                onUpdateOffline: userId.isNotEmpty ? () => cubit.updateProgress(userId: userId, lessonId: lesson.id) : null,
                onSimulateConflict: progressId != null ? () {
                  cubit.simulateRemoteConflict(progressId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conflict queued.')));
                } : null,
              );
            }),
          ],
        );
      },
    );
  }
}
