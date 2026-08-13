import 'dart:io';

/// Logging level for the MCP server.
enum LogLevel {
  /// Detailed debugging messages.
  debug,

  /// Informational messages highlighting server operations.
  info,

  /// Warnings regarding potential non-fatal issues.
  warning,

  /// Severe errors indicating failed operations or exceptions.
  error,
}

/// Utility logger that routes all messages strictly to `stderr` to prevent
/// corrupting the `stdout` stream used by standard JSON-RPC transport.
class McpLogger {
  /// Creates a new [McpLogger] instance.
  McpLogger();

  /// The active minimum [LogLevel] for filtering log messages.
  static LogLevel currentLevel = LogLevel.info;

  /// Logs a [LogLevel.debug] message to `stderr`.
  static void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// Logs a [LogLevel.info] message to `stderr`.
  static void info(String message) {
    _log(LogLevel.info, message);
  }

  /// Logs a [LogLevel.warning] message to `stderr`.
  static void warning(String message) {
    _log(LogLevel.warning, message);
  }

  /// Logs a [LogLevel.error] message and optional [exception] and [stackTrace] to `stderr`.
  static void error(String message,
      [Object? exception, StackTrace? stackTrace]) {
    final buffer = StringBuffer(message);
    if (exception != null) buffer.write(' | Exception: $exception');
    _log(LogLevel.error, buffer.toString());
    if (stackTrace != null) {
      stderr.writeln(stackTrace);
    }
  }

  static void _log(LogLevel level, String message) {
    if (level.index < currentLevel.index) return;
    final timestamp = DateTime.now().toIso8601String();
    final tag = level.name.toUpperCase().padRight(7);
    stderr.writeln('[$timestamp] [$tag] $message');
  }
}
