import 'dart:io';

/// Logging level for the MCP server.
enum LogLevel { debug, info, warning, error }

/// Utility logger that routes all messages strictly to `stderr` to prevent
/// corrupting the `stdout` stream used by standard JSON-RPC transport.
class McpLogger {
  static LogLevel currentLevel = LogLevel.info;

  static void debug(String message) {
    _log(LogLevel.debug, message);
  }

  static void info(String message) {
    _log(LogLevel.info, message);
  }

  static void warning(String message) {
    _log(LogLevel.warning, message);
  }

  static void error(String message, [Object? exception, StackTrace? stackTrace]) {
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
