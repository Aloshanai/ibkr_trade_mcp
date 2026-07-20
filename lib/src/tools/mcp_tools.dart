import 'dart:convert';
import 'package:ib_trade_core/ib_trade_core.dart';
import '../protocol/mcp_protocol.dart';
import '../utils/logger.dart';

/// Class managing declaration and execution of MCP tools using `ib_trade_core`.
class McpToolRegistry {
  final CookieClient _client;
  final GatewayConfig _config;

  McpToolRegistry({
    required CookieClient client,
    required GatewayConfig config,
  })  : _client = client,
        _config = config;

  /// Returns the array of tool definitions announced during `tools/list`.
  List<Map<String, dynamic>> listTools() {
    return [
      {
        'name': 'get_session_status',
        'description':
            'Retrieve the current Interactive Brokers (IBKR) connection status, authentication state, and logged-in username.',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'list_accounts',
        'description':
            'Fetch all trading accounts associated with the active IBKR session.',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'get_positions',
        'description':
            'Fetch current portfolio positions (stocks, options, cash) for a specified trading account.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'accountId': {
              'type': 'string',
              'description': 'The target IBKR trading account ID (e.g. DU123456)',
            },
          },
          'required': ['accountId'],
        },
      },
      {
        'name': 'place_order',
        'description':
            'Submit a trade order (buy/sell equities or options) to the IBKR Gateway.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'accountId': {
              'type': 'string',
              'description': 'Trading account ID',
            },
            'conid': {
              'type': 'integer',
              'description': 'Contract ID of the security (e.g. 265598 for AAPL)',
            },
            'side': {
              'type': 'string',
              'enum': ['BUY', 'SELL'],
              'description': 'Order side (BUY or SELL)',
            },
            'orderType': {
              'type': 'string',
              'enum': ['LMT', 'MKT', 'STP'],
              'description': 'Type of order',
            },
            'price': {
              'type': 'number',
              'description': 'Limit price (required for LMT and STP orders)',
            },
            'quantity': {
              'type': 'number',
              'description': 'Number of shares/contracts',
            },
          },
          'required': ['accountId', 'conid', 'side', 'orderType', 'quantity'],
        },
      },
      {
        'name': 'reply_to_challenge',
        'description':
            'Submit a confirmation reply (accept or decline) to an execution warning challenge prompt returned by IBKR.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'replyId': {
              'type': 'string',
              'description': 'Unique challenge ID (e.g. c_12345)',
            },
            'confirmed': {
              'type': 'boolean',
              'description': 'Set to true to confirm risk disclosure, or false to cancel',
            },
          },
          'required': ['replyId', 'confirmed'],
        },
      },
      {
        'name': 'search_contracts',
        'description':
            'Search for IBKR securities (stocks, ETFs, options) by ticker symbol or company name to obtain contract IDs (conid).',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'Ticker symbol or company name (e.g. AAPL, Tesla)',
            },
          },
          'required': ['query'],
        },
      },
      {
        'name': 'get_market_data',
        'description':
            'Retrieve real-time market data snapshot (last price, bid, ask, volume, daily range) for a specified contract ID (conid).',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'conid': {
              'type': 'integer',
              'description': 'Contract ID of the security (e.g. 265598 for AAPL)',
            },
          },
          'required': ['conid'],
        },
      },
      {
        'name': 'get_historical_prices',
        'description':
            'Retrieve historical price candlestick bars (1min, 5min, 1hour, 1day) for technical analysis on a security.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'conid': {
              'type': 'integer',
              'description': 'Contract ID of the security (e.g. 265598 for AAPL)',
            },
            'period': {
              'type': 'string',
              'description': 'Historical time duration (e.g. 1d, 1w, 1m, 1y). Default is 1d.',
            },
            'bar': {
              'type': 'string',
              'description': 'Candlestick bar size (e.g. 1min, 5min, 1h, 1d). Default is 1h.',
            },
          },
          'required': ['conid'],
        },
      },
      {
        'name': 'list_working_orders',
        'description':
            'Fetch all live open, pending, or working orders across accounts.',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'cancel_order',
        'description':
            'Cancel an active pending order by account ID and order ID.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'accountId': {
              'type': 'string',
              'description': 'Trading account ID',
            },
            'orderId': {
              'type': 'string',
              'description': 'Order ID to cancel',
            },
          },
          'required': ['accountId', 'orderId'],
        },
      },
      {
        'name': 'modify_order',
        'description':
            'Modify limit price or quantity of an active pending working order.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'accountId': {
              'type': 'string',
              'description': 'Trading account ID',
            },
            'orderId': {
              'type': 'string',
              'description': 'Order ID to modify',
            },
            'price': {
              'type': 'number',
              'description': 'Updated limit price',
            },
            'quantity': {
              'type': 'number',
              'description': 'Updated order quantity',
            },
          },
          'required': ['accountId', 'orderId'],
        },
      },
    ];
  }

  /// Executes a requested tool by name with arguments.
  Future<Map<String, dynamic>> callTool(
      String name, Map<String, dynamic> args) async {
    McpLogger.info('Executing tool: $name with args: $args');

    try {
      switch (name) {
        case 'get_session_status':
          return await _executeGetSessionStatus();
        case 'list_accounts':
          return await _executeListAccounts();
        case 'get_positions':
          return await _executeGetPositions(args);
        case 'place_order':
          return await _executePlaceOrder(args);
        case 'reply_to_challenge':
          return await _executeReplyToChallenge(args);
        case 'search_contracts':
          return await _executeSearchContracts(args);
        case 'get_market_data':
          return await _executeGetMarketData(args);
        case 'get_historical_prices':
          return await _executeGetHistoricalPrices(args);
        case 'list_working_orders':
          return await _executeListWorkingOrders();
        case 'cancel_order':
          return await _executeCancelOrder(args);
        case 'modify_order':
          return await _executeModifyOrder(args);
        default:
          return McpResponseBuilder.buildToolErrorResponse(
              'Unknown tool name: $name');
      }
    } catch (e, st) {
      McpLogger.error('Unhandled exception executing tool $name', e, st);
      return McpResponseBuilder.buildToolErrorResponse('Tool error: $e');
    }
  }

  Future<Map<String, dynamic>> _executeGetSessionStatus() async {
    final uri = _config.baseHttpUri.resolve('iserver/auth/status');
    final res = await _client.get(uri);

    if (res.statusCode == 200) {
      final parsed = _safeJsonDecode(res.body);
      if (parsed is Map<String, dynamic>) {
        final status = AuthStatus.fromJson(parsed);
        return McpResponseBuilder.buildToolSuccessResponse(status.toString());
      }
      return McpResponseBuilder.buildToolSuccessResponse(res.body);
    } else {
      return _buildErrorFromResponse(res);
    }
  }

  Future<Map<String, dynamic>> _executeListAccounts() async {
    final uri = _config.baseHttpUri.resolve('iserver/accounts');
    final res = await _client.get(uri);

    if (res.statusCode == 200) {
      return McpResponseBuilder.buildToolSuccessResponse(res.body);
    } else {
      return _buildErrorFromResponse(res);
    }
  }

  Future<Map<String, dynamic>> _executeGetPositions(
      Map<String, dynamic> args) async {
    final acctId = args['accountId']?.toString();
    if (acctId == null || acctId.isEmpty) {
      return McpResponseBuilder.buildToolErrorResponse(
          'Missing required argument: accountId');
    }

    final uri = _config.baseHttpUri.resolve('portfolio/$acctId/positions/0');
    final res = await _client.get(uri);

    if (res.statusCode == 200) {
      return McpResponseBuilder.buildToolSuccessResponse(res.body);
    } else {
      return _buildErrorFromResponse(res);
    }
  }

  Future<Map<String, dynamic>> _executePlaceOrder(
      Map<String, dynamic> args) async {
    final acctId = args['accountId']?.toString();
    final conid = args['conid'];
    final side = args['side']?.toString();
    final orderType = args['orderType']?.toString();
    final quantity = args['quantity'];
    final price = args['price'];

    if (acctId == null || conid == null || side == null || orderType == null || quantity == null) {
      return McpResponseBuilder.buildToolErrorResponse(
          'Invalid or missing order parameters');
    }

    final orderPayload = {
      'orders': [
        {
          'conid': conid,
          'orderType': orderType,
          'price': price,
          'side': side,
          'quantity': quantity,
          'tif': 'DAY',
        }
      ]
    };

    final uri = _config.baseHttpUri.resolve('iserver/account/$acctId/orders');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderPayload),
    );

    if (res.statusCode == 200) {
      return McpResponseBuilder.buildToolSuccessResponse(res.body);
    } else {
      return _buildErrorFromResponse(res);
    }
  }

  Future<Map<String, dynamic>> _executeReplyToChallenge(
      Map<String, dynamic> args) async {
    final replyId = args['replyId']?.toString();
    final confirmed = args['confirmed'] == true;

    if (replyId == null || replyId.isEmpty) {
      return McpResponseBuilder.buildToolErrorResponse(
          'Missing required argument: replyId');
    }

    final handler = ChallengeHandler(_client, _config.baseHttpUri);
    final success = await handler.submitReply(replyId, confirmed);

    if (success) {
      return McpResponseBuilder.buildToolSuccessResponse(
          'Challenge $replyId successfully submitted with confirmed=$confirmed.');
    } else {
      return McpResponseBuilder.buildToolErrorResponse(
          'Failed to submit reply to challenge $replyId');
    }
  }

  Future<Map<String, dynamic>> _executeSearchContracts(
      Map<String, dynamic> args) async {
    final query = args['query']?.toString();
    if (query == null || query.isEmpty) {
      return McpResponseBuilder.buildToolErrorResponse(
          'Missing required argument: query');
    }

    final uri = _config.baseHttpUri.resolve('iserver/secdef/search');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'symbol': query, 'name': true}),
    );

    if (res.statusCode == 200) {
      return McpResponseBuilder.buildToolSuccessResponse(res.body);
    } else {
      return _buildErrorFromResponse(res);
    }
  }

  Future<Map<String, dynamic>> _executeGetMarketData(
      Map<String, dynamic> args) async {
    final conid = args['conid'];
    if (conid == null) {
      return McpResponseBuilder.buildToolErrorResponse(
          'Missing required argument: conid');
    }

    final uri = _config.baseHttpUri
        .resolve('iserver/marketdata/snapshot?conids=$conid&fields=31,84,86,88,85');
    final res = await _client.get(uri);

    if (res.statusCode == 200) {
      return McpResponseBuilder.buildToolSuccessResponse(res.body);
    } else {
      return _buildErrorFromResponse(res);
    }
  }

  Future<Map<String, dynamic>> _executeGetHistoricalPrices(
      Map<String, dynamic> args) async {
    final conid = args['conid'];
    if (conid == null) {
      return McpResponseBuilder.buildToolErrorResponse(
          'Missing required argument: conid');
    }

    final period = args['period']?.toString() ?? '1d';
    final bar = args['bar']?.toString() ?? '1h';

    final uri = _config.baseHttpUri
        .resolve('iserver/marketdata/history?conid=$conid&period=$period&bar=$bar');
    final res = await _client.get(uri);

    if (res.statusCode == 200) {
      return McpResponseBuilder.buildToolSuccessResponse(res.body);
    } else {
      return _buildErrorFromResponse(res);
    }
  }

  Future<Map<String, dynamic>> _executeListWorkingOrders() async {
    final uri = _config.baseHttpUri.resolve('iserver/account/orders');
    final res = await _client.get(uri);

    if (res.statusCode == 200) {
      return McpResponseBuilder.buildToolSuccessResponse(res.body);
    } else {
      return _buildErrorFromResponse(res);
    }
  }

  Future<Map<String, dynamic>> _executeCancelOrder(
      Map<String, dynamic> args) async {
    final acctId = args['accountId']?.toString();
    final orderId = args['orderId']?.toString();

    if (acctId == null || acctId.isEmpty || orderId == null || orderId.isEmpty) {
      return McpResponseBuilder.buildToolErrorResponse(
          'Missing required arguments: accountId and orderId');
    }

    final uri = _config.baseHttpUri.resolve('iserver/account/$acctId/order/$orderId');
    final res = await _client.delete(uri);

    if (res.statusCode == 200) {
      return McpResponseBuilder.buildToolSuccessResponse(res.body);
    } else {
      return _buildErrorFromResponse(res);
    }
  }

  Future<Map<String, dynamic>> _executeModifyOrder(
      Map<String, dynamic> args) async {
    final acctId = args['accountId']?.toString();
    final orderId = args['orderId']?.toString();
    final price = args['price'];
    final quantity = args['quantity'];

    if (acctId == null || acctId.isEmpty || orderId == null || orderId.isEmpty) {
      return McpResponseBuilder.buildToolErrorResponse(
          'Missing required arguments: accountId and orderId');
    }

    final modifyPayload = {
      'price': price,
      'quantity': quantity,
    };

    final uri = _config.baseHttpUri.resolve('iserver/account/$acctId/order/$orderId');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(modifyPayload),
    );

    if (res.statusCode == 200) {
      return McpResponseBuilder.buildToolSuccessResponse(res.body);
    } else {
      return _buildErrorFromResponse(res);
    }
  }

  dynamic _safeJsonDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  Map<String, dynamic> _buildErrorFromResponse(dynamic res) {
    final body = res.body as String;
    final statusCode = res.statusCode as int;
    final json = _safeJsonDecode(body);
    final exc = IbException.fromJson(json, statusCode);
    return McpResponseBuilder.buildToolErrorResponse(exc.toString());
  }
}
