import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:stream_channel/stream_channel.dart';
import '../utils/logger.dart';

/// Stdio StreamChannel implementation for JSON-RPC over stdin/stdout.
class StdioServerTransport {
  final StreamController<String> _readController = StreamController<String>();
  final StreamController<String> _writeController = StreamController<String>();
  StreamSubscription? _stdinSubscription;
  StreamSubscription? _writeSubscription;

  /// Underlying StreamChannel interfacing with json_rpc_2 Server.
  late final StreamChannel<String> channel;

  StdioServerTransport() {
    channel = StreamChannel<String>(
      _readController.stream,
      _writeController.sink,
    );

    _writeSubscription = _writeController.stream.listen(
      (data) {
        // Send JSON-RPC response frame to stdout followed by newline
        stdout.writeln(data);
      },
      onError: (err) {
        McpLogger.error('Error in stdout channel output', err);
      },
    );
  }

  /// Begins reading incoming lines from [stdin].
  void listen() {
    _stdinSubscription = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          McpLogger.debug('Received line from stdin: $trimmed');
          _readController.add(trimmed);
        }
      },
      onError: (err) {
        McpLogger.error('Error reading from stdin', err);
        _readController.addError(err);
      },
      onDone: () {
        McpLogger.info('stdin closed');
        _readController.close();
      },
    );
  }

  /// Closes subscriptions and controllers.
  Future<void> close() async {
    await _stdinSubscription?.cancel();
    await _writeSubscription?.cancel();
    await _readController.close();
    await _writeController.close();
  }
}
