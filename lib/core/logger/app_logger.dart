import 'dart:developer' as developer;

class LogTags {
  LogTags._();

  static const String bloc = 'BLOC';
  static const String cache = 'CACHE';
  static const String network = 'NETWORK';
  static const String sync = 'SYNC';
  static const String db = 'DB';
  static const String error = 'ERROR';
  static const String app = 'APP';
}

class AppLogger {
  const AppLogger._();

  static const AppLogger instance = AppLogger._();

  void d(String message, {String tag = LogTags.app}) {
    developer.log('[DEBUG] $message', name: tag);
  }

  void i(String message, {String tag = LogTags.app}) {
    developer.log('[INFO] $message', name: tag);
  }

  void w(String message, {String tag = LogTags.app}) {
    developer.log('[WARN] $message', name: tag);
  }

  void e(
    String message, {
    String tag = LogTags.error,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '[ERROR] $message',
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

const AppLogger log = AppLogger.instance;
