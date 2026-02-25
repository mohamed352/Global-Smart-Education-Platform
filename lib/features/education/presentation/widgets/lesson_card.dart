import 'package:flutter/material.dart';
import 'package:global_smart_education_platform/core/constants/sync_constants.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.progressPercent,
    required this.syncStatus,
    required this.onTap,
    required this.onUpdateOffline,
    required this.onSimulateConflict,
  });

  final Lesson lesson;
  final int progressPercent;
  final String syncStatus;
  final VoidCallback? onTap;
  final VoidCallback? onUpdateOffline;
  final VoidCallback? onSimulateConflict;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String displayStatus;
    if (syncStatus == SyncStatus.pending.name) {
      statusColor = Colors.orange;
      displayStatus = 'قيد الانتظار';
    } else if (syncStatus == SyncStatus.failed.name) {
      statusColor = Colors.red;
      displayStatus = 'فشل المزامنة';
    } else if (syncStatus == SyncStatus.synced.name) {
      statusColor = Colors.green;
      displayStatus = 'تمت المزامنة';
    } else {
      statusColor = Colors.grey;
      displayStatus = 'غير معروف';
    }

    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                    displayStatus,
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
                'مدة الدرس: ${lesson.durationMinutes} دقيقة',
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
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
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
                    label: const Text('تحديث التقدم'),
                  ),
                  OutlinedButton(
                    onPressed: onSimulateConflict,
                    child: const Text('محاكاة تعارض'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
