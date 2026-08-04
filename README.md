# ibkr_trade_mcp

[![pub package](https://img.shields.io/pub/v/ibkr_trade_mcp.svg)](https://pub.dev/packages/ibkr_trade_mcp)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Model Context Protocol (MCP) server for Interactive Brokers (IBKR), built using the `ib_trade_core` Dart SDK.

This MCP server provides a standardized JSON-RPC 2.0 interface for AI assistants (such as Claude Desktop, Cursor, or custom LLM agents) to execute trades, manage working orders, inspect portfolio PnL, preview margin impact, and explore option chains via the local IBKR Client Portal Gateway REST API.

---

## Features & Supported MCP Tools

| MCP Tool Name | Description |
| :--- | :--- |
| `get_session_status` | Retrieve connection status, authentication state, and logged-in username. |
| `list_accounts` | Fetch all trading accounts associated with the active IBKR session. |
| `get_positions` | Fetch current portfolio positions (stocks, options, cash balances). |
| `get_portfolio_pnl` | Aggregate daily, unrealized, and realized PnL with Net Liquidation Value. |
| `get_account_summary` | Retrieve Net Liquidation Value, buying power, and available liquidity. |
| `get_cash_ledger` | Fetch multi-currency cash balances (USD, EUR, GBP, JPY, etc.). |
| `place_order` | Submit market, limit, stop, or **trailing stop (`TRAIL` / `TRAIL LIMIT`)** trade orders. |
| `place_bracket_order` | Orchestrate 3-legged bracket orders (Market Buy + Take-Profit + Stop-Loss). |
| `preview_order` | Preview pre-trade margin impact, estimated fees, and risk warnings before execution. |
| `reply_to_challenge` | Confirm execution warning risk disclosure challenge prompts from IBKR. |
| `list_working_orders` | Fetch open, pending, or working orders across accounts. |
| `modify_order` | Modify price or quantity of an active pending working order. |
| `cancel_order` | Cancel an active pending working order. |
| `search_contracts` | Search for IBKR securities (stocks, ETFs, options) to obtain contract IDs (`conid`). |
| `get_market_data` | Retrieve real-time market data snapshot (last price, bid, ask, volume). |
| `get_historical_prices` | Retrieve historical candlestick price bars (1min, 5min, 1h, 1d). |
| `get_option_chains` | Fetch available option expiration dates and strike price matrices. |
| `resolve_option_contract` | Resolve the exact contract ID (`conid`) for an option given strike, expiry, and right (CALL/PUT). |
| `ibkr_login` | Open browser automatically for local IBKR Client Portal 2FA authentication. |
| `ibkr_logout` | Terminate the active IBKR Client Portal Gateway session. |

---

## Quick Start

### 1. Prerequisites
- **Dart SDK**: `^3.0.0`
- **IBKR Client Portal Gateway**: Download and run the local IBKR Client Portal Gateway on `https://localhost:5000`. Log in and complete 2FA in your browser.

### 2. Installation

Install via Dart Pub:
```bash
dart pub add ibkr_trade_mcp
```

Or run globally as a CLI tool:
```bash
dart pub global activate ibkr_trade_mcp
```

---

## Configuration for Claude Desktop

To connect this MCP server to **Claude Desktop**, add the following configuration to your `claude_desktop_config.json`:

### macOS
`~/Library/Application Support/Claude/claude_desktop_config.json`

### Windows
`%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "ibkr-trade": {
      "command": "dart",
      "args": [
        "run",
        "ibkr_trade_mcp"
      ],
      "env": {
        "IBKR_GATEWAY_HOST": "localhost",
        "IBKR_GATEWAY_PORT": "5000",
        "IBKR_GATEWAY_SCHEME": "https"
      }
    }
  }
}
```

---

## Running Programmatically in Dart

```dart
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ibkr_trade_mcp/ibkr_trade_mcp.dart';

void main() async {
  final config = GatewayConfig(
    host: 'localhost',
    port: 5000,
    scheme: 'https',
  );

  final client = CookieClient(HttpClient(bypassSslVerification: true));
  final registry = McpToolRegistry(client: client, config: config);
  final server = McpServer(registry);

  await server.start();
}
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
