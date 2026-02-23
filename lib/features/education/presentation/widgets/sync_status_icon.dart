import 'package:flutter/material.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';

class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({
    super.key,
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
