import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ibkr_trade_mcp/src/protocol/mcp_protocol.dart';
import 'package:ibkr_trade_mcp/src/protocol/stdio_transport.dart';
import 'package:ibkr_trade_mcp/src/tools/mcp_tools.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  group('StdioServerTransport Unit Tests', () {
    test('creates transport with valid channel and closes cleanly', () async {
      final transport = StdioServerTransport();
      expect(transport.channel, isNotNull);
      expect(transport.channel.stream, isNotNull);
      expect(transport.channel.sink, isNotNull);

      // Verify close does not throw
      await expectLater(transport.close(), completes);
    });
  });

  group('McpServer JSON-RPC Protocol & Dispatcher Tests', () {
    late StreamChannelController<String> channelController;
    late rpc.Server server;
    late rpc.Client client;
    late CookieClient cookieClient;
    late GatewayConfig config;
    late McpToolRegistry tools;

    setUp(() {
      channelController =
          StreamChannelController<String>(allowForeignErrors: true);
      server = rpc.Server(channelController.foreign);
      client = rpc.Client(channelController.local);

      final httpClient = HttpClient(bypassSslVerification: true);
      cookieClient = CookieClient(httpClient);
      config = const GatewayConfig();
      tools = McpToolRegistry(client: cookieClient, config: config);

      // Register MCP Handlers as done in McpServer
      server.registerMethod('initialize', (rpc.Parameters params) {
        return McpResponseBuilder.buildInitializeResult();
      });

      server.registerMethod('notifications/initialized',
          (rpc.Parameters params) {
        return null;
      });

      server.registerMethod('tools/list', (rpc.Parameters params) {
        final toolList = tools.listTools();
        return {'tools': toolList};
      });

      server.registerMethod('tools/call', (rpc.Parameters params) async {
        final name = params['name'].asString;
        final args = params['arguments'].asMap.cast<String, dynamic>();
        return await tools.callTool(name, args);
      });

      server.listen();
      client.listen();
    });

    tearDown(() async {
      cookieClient.close();
      await client.close();
      await server.close();
    });

    test('handles initialize handshake with protocol capability response',
        () async {
      final res = await client.sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {'name': 'test-client', 'version': '1.0.0'},
      }) as Map;

      expect(res, isA<Map>());
      expect(res['protocolVersion'], equals('2024-11-05'));
      expect(res['serverInfo']['name'], equals('ibkr_trade_mcp'));
      expect(res['capabilities'], contains('tools'));
    });

    test('handles notifications/initialized without errors', () async {
      // Notifications do not wait for return value
      expect(() => client.sendNotification('notifications/initialized', {}),
          returnsNormally);
    });

    test('handles tools/list returning complete schema list', () async {
      final res = await client.sendRequest('tools/list', {}) as Map;
      expect(res, isA<Map>());
      final toolList = res['tools'] as List;
      expect(toolList, isNotEmpty);

      final names = toolList.map((t) => t['name'] as String).toSet();
      expect(names, contains('get_session_status'));
      expect(names, contains('list_accounts'));
      expect(names, contains('get_positions'));
      expect(names, contains('place_order'));
      expect(names, contains('search_contracts'));
      expect(names, contains('ibkr_login'));
      expect(names, contains('ibkr_logout'));
    });

    test(
        'handles tools/call executing known tool with error payload on invalid params',
        () async {
      final res = await client.sendRequest('tools/call', {
        'name': 'place_order',
        'arguments': {},
      }) as Map;

      expect(res, isA<Map>());
      expect(res['isError'], isTrue);
      expect(res['content'], isList);
      expect(res['content'].first['text'],
          contains('Invalid or missing order parameters'));
    });

    test('handles tools/call for unrecognized tool with error payload',
        () async {
      final res = await client.sendRequest('tools/call', {
        'name': 'invalid_tool_action',
        'arguments': {},
      }) as Map;

      expect(res, isA<Map>());
      expect(res['isError'], isTrue);
      expect(res['content'].first['text'], contains('Unknown tool name'));
    });

    test('rejects unregistered JSON-RPC methods with MethodNotFound error',
        () async {
      expect(
        () => client.sendRequest('unsupported/custom_rpc_method', {}),
        throwsA(isA<rpc.RpcException>()
            .having((e) => e.code, 'code', equals(-32601))),
      );
    });
  });
}
