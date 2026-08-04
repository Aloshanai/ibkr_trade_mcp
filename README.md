# ibkr_trade_mcp

[![pub package](https://img.shields.io/pub/v/ibkr_trade_mcp.svg)](https://pub.dev/packages/ibkr_trade_mcp)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Model Context Protocol (MCP) server for Interactive Brokers (IBKR), built using the `ib_trade_core` Dart SDK.

This MCP server provides a standardized JSON-RPC 2.0 interface for AI assistants (such as Claude Desktop, Cursor, or custom LLM agents) to execute trades, manage working orders, inspect portfolio PnL, preview margin impact, and explore option chains via the local IBKR Client Portal Gateway REST API.

---

## 🚀 Key Features & Supported MCP Tools

`ibkr_trade_mcp` exposes 20 dedicated MCP tools designed for automated trading agents:

### 👤 Account & Session Management
* **`get_session_status`**: Retrieve active IBKR connection status, authentication state, and logged-in username.
* **`list_accounts`**: Fetch all trading accounts associated with the active IBKR session.
* **`get_positions`**: Fetch current portfolio positions (stocks, options, cash balances) for an account.
* **`get_account_summary`**: Retrieve Net Liquidation Value, buying power, available funds, and total equity.
* **`get_cash_ledger`**: Fetch multi-currency cash balances (USD, EUR, GBP, JPY, etc.).
* **`ibkr_login`**: Automatically launch browser for local IBKR Client Portal 2FA authentication.
* **`ibkr_logout`**: Terminate the active IBKR Client Portal Gateway session.

### 📈 Order Placement & Execution
* **`place_order`**: Submit trade orders (`BUY`/`SELL`) for equities or options with support for `LMT`, `MKT`, `STP`, **`TRAIL` (trailing stop dollar amount)**, and **`TRAIL LIMIT` (trailing stop percentage)** order types.
* **`place_bracket_order`**: Orchestrate linked 3-legged bracket orders (Market/Limit Buy entry + Take-Profit + Stop-Loss protective legs).
* **`reply_to_challenge`**: Submit confirmation replies (accept/decline) for execution warning challenge prompts returned by IBKR.
* **`list_working_orders`**: Fetch open, pending, or working orders across accounts.
* **`modify_order`**: Modify price or quantity of active working orders.
* **`cancel_order`**: Cancel pending active working orders.

### 📊 Portfolio PnL & Pre-Trade Preview
* **`get_portfolio_pnl`**: Retrieve aggregated daily PnL, unrealized PnL, realized PnL, Net Liquidation Value, and position breakdown with automatic position-level reconciliation.
* **`preview_order`**: Pre-trade order what-if preview returning estimated margin impact, fee bounds, and risk warnings before submitting live orders.

### 🔍 Market Data & Derivatives Discovery
* **`search_contracts`**: Search IBKR securities (stocks, ETFs, options) by symbol or name to discover contract IDs (`conid`).
* **`get_market_data`**: Retrieve real-time market data snapshots (last price, bid, ask, daily volume).
* **`get_historical_prices`**: Retrieve historical candlestick price bars (1min, 5min, 1h, 1d) for technical analysis.
* **`get_option_chains`**: Fetch available option expiration dates and strike price matrices for an underlying security.
* **`resolve_option_contract`**: Resolve exact option contract IDs (`conid`) given underlying conid, strike, expiration date, and right (`CALL`/`PUT`).

---

## 💻 Quick Start Guide

### 1. Prerequisites
* **Dart SDK**: `^3.0.0`
* **IBKR Client Portal Gateway**: Download and run the local IBKR Client Portal Gateway on `https://localhost:5000`. Authenticate via browser 2FA.

### 2. Installation

Install via Dart Pub:
```bash
dart pub add ibkr_trade_mcp
```

Or activate globally as a CLI executable:
```bash
dart pub global activate ibkr_trade_mcp
```

---

## 🤖 Configuration for Claude Desktop

Connect this MCP server to **Claude Desktop** by updating your `claude_desktop_config.json`:

### Configuration Path
* **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
* **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

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

## 🔧 Programmatic Embedding in Dart

```dart
import 'dart:io';
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

  print('Starting IBKR Trade MCP Server...');
  await server.start();
}
```

---

## 📄 License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.
