import 'package:flutter/foundation.dart';

enum LogCategory {
  db('🗄️', 'DB'),
  apkg('📦', 'APKG'),
  audio('🎵', 'AUDIO'),
  study('📚', 'STUDY'),
  fsrs('🧠', 'FSRS'),
  general('📝', 'APP');

  final String emoji;
  final String name;
  const LogCategory(this.emoji, this.name);
}

enum LogStatus {
  info('ℹ️'),
  success('✅'),
  warning('⚠️'),
  error('❌');

  final String emoji;
  const LogStatus(this.emoji);
}

class AppLogger {
  static void i(LogCategory category, String message) {
    _log(category, LogStatus.info, message);
  }

  static void s(LogCategory category, String message) {
    _log(category, LogStatus.success, message);
  }

  static void w(LogCategory category, String message) {
    _log(category, LogStatus.warning, message);
  }

  static void e(LogCategory category, String message, [dynamic error, StackTrace? stackTrace]) {
    final errorMessage = error != null ? '$message | Error: $error' : message;
    _log(category, LogStatus.error, errorMessage);
    if (stackTrace != null && kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void _log(LogCategory category, LogStatus status, String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
      debugPrint('[${category.emoji} ${category.name}] ${status.emoji} [$timestamp] $message');
    }
  }
}
