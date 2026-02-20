import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:global_smart_education_platform/core/constants/sync_constants.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/dashboard_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/dashboard_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<DashboardCubit, DashboardState, String>(
          selector: (DashboardState state) =>
              state.users.isNotEmpty ? state.users.first.name : 'Loading...',
          builder: (BuildContext context, String userName) {
            return Text('Education POC - $userName');
          },
        ),
        actions: <Widget>[
          BlocSelector<
            DashboardCubit,
            DashboardState,
            ({ConnectivityState c, SyncEngineStatus s, int p})
          >(
            selector: (DashboardState state) => (
              c: state.connectivity,
              s: state.syncStatus,
              p: state.pendingSyncCount,
            ),
            builder:
                (
                  BuildContext context,
                  ({ConnectivityState c, SyncEngineStatus s, int p}) data,
                ) {
                  return _SyncStatusIcon(
                    connectivity: data.c,
                    syncStatus: data.s,
                    pendingCount: data.p,
                  );
                },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Force Sync',
            onPressed: () => context.read<DashboardCubit>().triggerSync(),
          ),
        ],
      ),
      body:
          BlocSelector<
            DashboardCubit,
            DashboardState,
            ({List<Lesson> lessons, List<Progress> progresses, String userId})
          >(
            selector: (DashboardState state) => (
              lessons: state.lessons,
              progresses: state.progresses,
              userId: state.users.isNotEmpty ? state.users.first.id : '',
            ),
            builder:
                (
                  BuildContext context,
                  ({
                    List<Lesson> lessons,
                    List<Progress> progresses,
                    String userId,
                  })
                  data,
                ) {
                  final DashboardCubit cubit = context.read<DashboardCubit>();

                  if (data.lessons.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.lessons.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Lesson lesson = data.lessons[index];
                      final int progressPercent = cubit.getProgressPercent(
                        data.userId,
                        lesson.id,
                      );
                      final String syncStatus = cubit.getProgressSyncStatus(
                        data.userId,
                        lesson.id,
                      );

                      final String? progressId = cubit.getProgressId(
                        data.userId,
                        lesson.id,
                      );

                      return _LessonCard(
                        lesson: lesson,
                        progressPercent: progressPercent,
                        syncStatus: syncStatus,
                        onUpdateOffline: data.userId.isNotEmpty
                            ? () => cubit.updateProgress(
                                userId: data.userId,
                                lessonId: lesson.id,
                              )
                            : null,
                        onSimulateConflict: progressId != null
                            ? () async {
                                await cubit.simulateRemoteConflict(progressId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Conflict seeded in Firestore (100%, +1h). '
                                        'Tap Sync to see LWW resolution.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                      );
                    },
                  );
                },
          ),
    );
  }
}

// ─── Sync Status Icon Widget ───

class _SyncStatusIcon extends StatelessWidget {
  const _SyncStatusIcon({
    required this.connectivity,
    required this.syncStatus,
    required this.pendingCount,
  });

  final ConnectivityState connectivity;
  final SyncEngineStatus syncStatus;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String tooltip;

    if (connectivity == ConnectivityState.offline) {
      color = Colors.red;
      icon = Icons.cloud_off;
      tooltip = 'Offline ($pendingCount pending)';
    } else if (syncStatus == SyncEngineStatus.syncing) {
      color = Colors.amber;
      icon = Icons.cloud_sync;
      tooltip = 'Syncing...';
    } else if (pendingCount > 0) {
      color = Colors.orange;
      icon = Icons.cloud_upload;
      tooltip = '$pendingCount pending uploads';
    } else {
      color = Colors.green;
      icon = Icons.cloud_done;
      tooltip = 'Synced';
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(icon, color: color),
      ),
    );
  }
}

// ─── Lesson Card Widget ───

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.progressPercent,
    required this.syncStatus,
    required this.onUpdateOffline,
    required this.onSimulateConflict,
  });

  final Lesson lesson;
  final int progressPercent;
  final String syncStatus;
  final VoidCallback? onUpdateOffline;
  final VoidCallback? onSimulateConflict;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    if (syncStatus == SyncStatus.pending.name) {
      statusColor = Colors.orange;
    } else if (syncStatus == SyncStatus.failed.name) {
      statusColor = Colors.red;
    } else if (syncStatus == SyncStatus.synced.name) {
      statusColor = Colors.green;
    } else {
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  syncStatus,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lesson.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${lesson.durationMinutes} min',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: LinearProgressIndicator(
                    value: progressPercent / 100.0,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$progressPercent%',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: progressPercent >= 100 ? null : onUpdateOffline,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Update Progress Offline'),
                ),
                OutlinedButton(
                  onPressed: onSimulateConflict,
                  child: const Text('Simulate Remote Conflict'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
