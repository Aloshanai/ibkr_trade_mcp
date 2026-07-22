import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ibkr_trade_mcp/ibkr_trade_mcp.dart';
import 'package:test/test.dart';

void main() {
  group('McpProtocolConstants & ResponseBuilder', () {
    test('buildInitializeResult returns valid MCP capability map', () {
      final result = McpResponseBuilder.buildInitializeResult();
      expect(result['protocolVersion'], equals('2024-11-05'));
      expect(result['serverInfo']['name'], equals('ibkr_trade_mcp'));
      expect(result['capabilities'], contains('tools'));
    });

    test('buildToolSuccessResponse formats text content payload', () {
      final res = McpResponseBuilder.buildToolSuccessResponse('Hello World');
      expect(res['isError'], isFalse);
      expect(res['content'], isList);
      expect(res['content'].first['text'], equals('Hello World'));
    });

    test('buildToolErrorResponse formats error content payload', () {
      final res = McpResponseBuilder.buildToolErrorResponse('Failed request');
      expect(res['isError'], isTrue);
      expect(res['content'].first['text'], equals('Failed request'));
    });
  });

  group('McpToolRegistry', () {
    late CookieClient client;
    late GatewayConfig config;
    late McpToolRegistry registry;

    setUp(() {
      final httpClient = HttpClient(bypassSslVerification: true);
      client = CookieClient(httpClient);
      config = const GatewayConfig();
      registry = McpToolRegistry(client: client, config: config);
    });

    tearDown(() {
      client.close();
    });

    test('listTools announces required set of thin adapter tools', () {
      final tools = registry.listTools();
      final toolNames = tools.map((t) => t['name'] as String).toList();

      expect(toolNames, contains('get_session_status'));
      expect(toolNames, contains('list_accounts'));
      expect(toolNames, contains('get_positions'));
      expect(toolNames, contains('place_order'));
      expect(toolNames, contains('reply_to_challenge'));
      expect(toolNames, contains('search_contracts'));
      expect(toolNames, contains('get_market_data'));
      expect(toolNames, contains('get_historical_prices'));
      expect(toolNames, contains('list_working_orders'));
      expect(toolNames, contains('cancel_order'));
      expect(toolNames, contains('modify_order'));
      expect(toolNames, contains('get_account_summary'));
      expect(toolNames, contains('get_cash_ledger'));
      expect(toolNames, contains('ibkr_login'));
      expect(toolNames, contains('ibkr_logout'));
    });

    test('callTool returns error for unknown tool names', () async {
      final res = await registry.callTool('non_existent_tool', {});
      expect(res['isError'], isTrue);
      expect(res['content'].first['text'], contains('Unknown tool name'));
    });

    test('callTool get_positions returns error if missing accountId argument', () async {
      final res = await registry.callTool('get_positions', {});
      expect(res['isError'], isTrue);
      expect(res['content'].first['text'], contains('Missing required argument: accountId'));
    });

    test('callTool search_contracts returns error if missing query argument', () async {
      final res = await registry.callTool('search_contracts', {});
      expect(res['isError'], isTrue);
      expect(res['content'].first['text'], contains('Missing required argument: query'));
    });

    test('callTool get_historical_prices returns error if missing conid argument', () async {
      final res = await registry.callTool('get_historical_prices', {});
      expect(res['isError'], isTrue);
      expect(res['content'].first['text'], contains('Missing required argument: conid'));
    });

    test('callTool cancel_order returns error if missing accountId or orderId', () async {
      final res = await registry.callTool('cancel_order', {});
      expect(res['isError'], isTrue);
      expect(res['content'].first['text'], contains('Missing required arguments'));
    });

    test('callTool get_account_summary returns error if missing accountId', () async {
      final res = await registry.callTool('get_account_summary', {});
      expect(res['isError'], isTrue);
      expect(res['content'].first['text'], contains('Missing required argument: accountId'));
    });

    test('callTool ibkr_login returns success message and triggers browser path', () async {
      final res = await registry.callTool('ibkr_login', {});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('Successfully opened browser'));
    });
  });
}
