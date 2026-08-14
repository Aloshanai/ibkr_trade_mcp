import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ibkr_trade_mcp/ibkr_trade_mcp.dart';

void main() async {
  // Configure Interactive Brokers Client Portal Gateway connection
  final config = GatewayConfig(
    host: 'localhost',
    port: 5000,
    useSsl: true,
    bypassSslVerification: true,
    tickleIntervalSeconds: 45,
  );

  // Initialize the MCP server with Gateway configuration
  final server = McpServer(config: config);

  McpLogger.info('Starting IBKR Trade MCP server...');

  // Start the server using stdio transport for MCP host communication
  await server.start();
}
