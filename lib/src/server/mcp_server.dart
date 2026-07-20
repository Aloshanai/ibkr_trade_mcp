import 'dart:async';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import '../protocol/mcp_protocol.dart';
import '../protocol/stdio_transport.dart';
import '../tools/mcp_tools.dart';
import '../utils/logger.dart';

/// Main MCP Server instance orchestrating Gateway configuration, core session tickling,
/// tool declarations, and JSON-RPC over stdio.
class McpServer {
  final GatewayConfig _config;
  late final HttpClient _httpClient;
  late final CookieClient _cookieClient;
  late final SessionTickler _tickler;
  late final McpToolRegistry _tools;
  late final StdioServerTransport _transport;
  late final rpc.Server _rpcServer;

  /// Creates an [McpServer] with optional custom [GatewayConfig].
  McpServer({GatewayConfig? config}) : _config = config ?? const GatewayConfig() {
    _httpClient = HttpClient(bypassSslVerification: _config.bypassSslVerification);
    _cookieClient = CookieClient(_httpClient);
    _tickler = SessionTickler(
      _cookieClient,
      _config.baseHttpUri,
      interval: Duration(seconds: _config.tickleIntervalSeconds),
    );
    _tools = McpToolRegistry(client: _cookieClient, config: _config);
  }

  /// Starts the server, session keep-alive loop, and stdin/stdout JSON-RPC protocol.
  Future<void> start() async {
    McpLogger.info('Starting MCP Server targeting IBKR Gateway: ${_config.baseHttpUri}');

    // 1. Start background tickler loop
    _tickler.start();

    // 2. Setup stdio transport channel
    _transport = StdioServerTransport();
    _rpcServer = rpc.Server(_transport.channel);

    // 3. Register MCP Methods
    _registerRpcHandlers();

    // 4. Start listening on stdio
    _transport.listen();
    _rpcServer.listen();

    McpLogger.info('MCP Server initialized and listening on stdin/stdout.');
  }

  void _registerRpcHandlers() {
    // Standard MCP handshake: initialize
    _rpcServer.registerMethod('initialize', (rpc.Parameters params) {
      McpLogger.info('Received initialize handshake from client.');
      return McpResponseBuilder.buildInitializeResult();
    });

    // Client notification: initialized
    _rpcServer.registerMethod('notifications/initialized', (rpc.Parameters params) {
      McpLogger.info('Client confirmed initialization.');
      return null;
    });

    // List tools handler
    _rpcServer.registerMethod('tools/list', (rpc.Parameters params) {
      McpLogger.info('Client requested tools/list.');
      final tools = _tools.listTools();
      return {'tools': tools};
    });

    // Call tool handler
    _rpcServer.registerMethod('tools/call', (rpc.Parameters params) async {
      final name = params['name'].asString;
      final args = params['arguments'].asMap.cast<String, dynamic>();
      return await _tools.callTool(name, args);
    });
  }

  /// Stops session keep-alives and closes HTTP clients and stdio streams.
  Future<void> stop() async {
    McpLogger.info('Stopping MCP Server...');
    _tickler.stop();
    await _transport.close();
    _httpClient.close();
    McpLogger.info('MCP Server stopped.');
  }
}
