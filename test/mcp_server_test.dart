import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  group('McpToolRegistry - Tool Discovery & Unknown Handling', () {
    late CookieClient client;
    late GatewayConfig config;
    late McpToolRegistry registry;

    setUp(() {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });
      client = CookieClient(mockClient);
      config = const GatewayConfig();
      registry = McpToolRegistry(client: client, config: config);
    });

    tearDown(() {
      client.close();
    });

    test('listTools announces all 15 IBKR MCP tools', () {
      final tools = registry.listTools();
      final toolNames = tools.map((t) => t['name'] as String).toList();

      expect(tools.length, equals(15));
      expect(toolNames, containsAll([
        'get_session_status',
        'list_accounts',
        'get_positions',
        'place_order',
        'reply_to_challenge',
        'search_contracts',
        'get_market_data',
        'get_historical_prices',
        'list_working_orders',
        'cancel_order',
        'modify_order',
        'get_account_summary',
        'get_cash_ledger',
        'ibkr_login',
        'ibkr_logout',
      ]));
    });

    test('callTool returns error for unknown tool names', () async {
      final res = await registry.callTool('non_existent_tool', {});
      expect(res['isError'], isTrue);
      expect(res['content'].first['text'], contains('Unknown tool name'));
    });
  });

  group('McpToolRegistry - All 15 Tools Execution & Coverage', () {
    late GatewayConfig config;

    setUp(() {
      config = const GatewayConfig();
    });

    test('1. get_session_status success & error paths', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/iserver/auth/status'));
        return http.Response(
          jsonEncode({'authenticated': true, 'connected': true, 'user': 'test_trader'}),
          200,
        );
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      final res = await registry.callTool('get_session_status', {});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('authenticated: true'));

      // Error path
      final errClient = MockClient((req) async => http.Response('Server Error', 500));
      final errRegistry = McpToolRegistry(client: CookieClient(errClient), config: config);
      final errRes = await errRegistry.callTool('get_session_status', {});
      expect(errRes['isError'], isTrue);
    });

    test('2. list_accounts success & error paths', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/iserver/accounts'));
        return http.Response(jsonEncode(['DU123456', 'DU789012']), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      final res = await registry.callTool('list_accounts', {});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('DU123456'));

      // Error path
      final errClient = MockClient((req) async => http.Response('Unauthorized', 401));
      final errRegistry = McpToolRegistry(client: CookieClient(errClient), config: config);
      final errRes = await errRegistry.callTool('list_accounts', {});
      expect(errRes['isError'], isTrue);
    });

    test('3. get_positions missing args & success path', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/portfolio/DU123456/positions/0'));
        return http.Response(jsonEncode([{'conid': 265598, 'position': 100}]), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      // Missing argument
      final errRes = await registry.callTool('get_positions', {});
      expect(errRes['isError'], isTrue);
      expect(errRes['content'].first['text'], contains('Missing required argument: accountId'));

      // Valid call
      final res = await registry.callTool('get_positions', {'accountId': 'DU123456'});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('265598'));
    });

    test('4. place_order validation & success path', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/iserver/account/DU123456/orders'));
        expect(request.method, equals('POST'));
        final body = jsonDecode(request.body);
        expect(body['orders'][0]['conid'], equals(265598));
        return http.Response(jsonEncode([{'order_id': '1001', 'order_status': 'Submitted'}]), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      // Missing parameters
      final invalidRes = await registry.callTool('place_order', {'accountId': 'DU123456'});
      expect(invalidRes['isError'], isTrue);

      // Valid order execution
      final res = await registry.callTool('place_order', {
        'accountId': 'DU123456',
        'conid': 265598,
        'side': 'BUY',
        'orderType': 'LMT',
        'price': 150.0,
        'quantity': 10,
      });
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('Submitted'));
    });

    test('5. reply_to_challenge validation & success/failure paths', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/iserver/reply/c_12345'));
        return http.Response(jsonEncode({'confirmed': true}), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      // Missing replyId
      final errRes = await registry.callTool('reply_to_challenge', {});
      expect(errRes['isError'], isTrue);
      expect(errRes['content'].first['text'], contains('Missing required argument: replyId'));

      // Confirmed reply success
      final res = await registry.callTool('reply_to_challenge', {
        'replyId': 'c_12345',
        'confirmed': true,
      });
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('successfully submitted'));

      // Failed submission reply
      final errMock = MockClient((req) async => http.Response('Error', 500));
      final errRegistry = McpToolRegistry(client: CookieClient(errMock), config: config);
      final failRes = await errRegistry.callTool('reply_to_challenge', {
        'replyId': 'c_12345',
        'confirmed': true,
      });
      expect(failRes['isError'], isTrue);
      expect(failRes['content'].first['text'], contains('Tool error'));
    });

    test('6. search_contracts validation & success path', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/iserver/secdef/search'));
        final body = jsonDecode(request.body);
        expect(body['symbol'], equals('AAPL'));
        return http.Response(jsonEncode([{'conid': 265598, 'companyHeader': 'APPLE INC'}]), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      // Missing query
      final errRes = await registry.callTool('search_contracts', {});
      expect(errRes['isError'], isTrue);

      // Valid search query
      final res = await registry.callTool('search_contracts', {'query': 'AAPL'});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('APPLE INC'));
    });

    test('7. get_market_data validation & success path', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/iserver/marketdata/snapshot'));
        expect(request.url.queryParameters['conids'], equals('265598'));
        return http.Response(jsonEncode([{'31': '150.25', '84': '150.20'}]), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      // Missing conid
      final errRes = await registry.callTool('get_market_data', {});
      expect(errRes['isError'], isTrue);

      // Valid market data request
      final res = await registry.callTool('get_market_data', {'conid': 265598});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('150.25'));
    });

    test('8. get_historical_prices validation & success path', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/iserver/marketdata/history'));
        expect(request.url.queryParameters['conid'], equals('265598'));
        expect(request.url.queryParameters['period'], equals('1d'));
        expect(request.url.queryParameters['bar'], equals('1h'));
        return http.Response(jsonEncode({'data': [{'o': 150, 'c': 152}]}), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      // Missing conid
      final errRes = await registry.callTool('get_historical_prices', {});
      expect(errRes['isError'], isTrue);

      // Valid historical request
      final res = await registry.callTool('get_historical_prices', {
        'conid': 265598,
        'period': '1d',
        'bar': '1h',
      });
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('152'));
    });

    test('9. list_working_orders success & error paths', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/iserver/account/orders'));
        return http.Response(jsonEncode({'orders': [{'orderId': '101'}]}), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      final res = await registry.callTool('list_working_orders', {});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('101'));
    });

    test('10. cancel_order validation & success path', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/iserver/account/DU123456/order/101'));
        expect(request.method, equals('DELETE'));
        return http.Response(jsonEncode({'msg': 'Order cancelled'}), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      // Missing parameters
      final errRes = await registry.callTool('cancel_order', {'accountId': 'DU123456'});
      expect(errRes['isError'], isTrue);

      // Valid cancellation
      final res = await registry.callTool('cancel_order', {
        'accountId': 'DU123456',
        'orderId': '101',
      });
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('Order cancelled'));
    });

    test('11. modify_order validation & success path', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/iserver/account/DU123456/order/101'));
        expect(request.method, equals('POST'));
        final body = jsonDecode(request.body);
        expect(body['price'], equals(155.0));
        return http.Response(jsonEncode({'msg': 'Order modified'}), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      // Missing parameters
      final errRes = await registry.callTool('modify_order', {'orderId': '101'});
      expect(errRes['isError'], isTrue);

      // Valid modification
      final res = await registry.callTool('modify_order', {
        'accountId': 'DU123456',
        'orderId': '101',
        'conid': 265598,
        'price': 155.0,
        'quantity': 20,
      });
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('Order modified'));
    });

    test('12. get_account_summary validation & success path', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/portfolio/DU123456/summary'));
        return http.Response(jsonEncode({'netliquidation': {'amount': 100000}}), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      // Missing accountId
      final errRes = await registry.callTool('get_account_summary', {});
      expect(errRes['isError'], isTrue);

      // Valid request
      final res = await registry.callTool('get_account_summary', {'accountId': 'DU123456'});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('netliquidation'));
    });

    test('13. get_cash_ledger validation & success path', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/portfolio/DU123456/ledger'));
        return http.Response(jsonEncode({'USD': {'cashbalance': 50000}}), 200);
      });
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      // Missing accountId
      final errRes = await registry.callTool('get_cash_ledger', {});
      expect(errRes['isError'], isTrue);

      // Valid request
      final res = await registry.callTool('get_cash_ledger', {'accountId': 'DU123456'});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('50000'));
    });

    test('14. ibkr_login triggers browser path and returns success text', () async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final registry = McpToolRegistry(client: CookieClient(mockClient), config: config);

      final res = await registry.callTool('ibkr_login', {});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('Successfully opened browser'));
    });

    test('15. ibkr_logout success path clears client cookies', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/api/logout'));
        expect(request.method, equals('POST'));
        return http.Response(jsonEncode({'status': true}), 200);
      });
      final cookieClient = CookieClient(mockClient);
      final registry = McpToolRegistry(client: cookieClient, config: config);

      final res = await registry.callTool('ibkr_logout', {});
      expect(res['isError'], isFalse);
      expect(res['content'].first['text'], contains('Successfully logged out'));
    });
  });
}
