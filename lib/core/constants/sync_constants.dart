class SyncConstants {
  SyncConstants._();

  static const int maxRetryCount = 5;
  static const int networkDelayMs = 800;
  static const int failureProbabilityPercent = 15;
}

enum SyncStatus {
  synced,
  pending,
  failed,
}

enum OperationType {
  createProgress,
  updateProgress,
}
