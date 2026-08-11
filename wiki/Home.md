# Home

Welcome to the **ibkr_trade_mcp** Wiki!

`ibkr_trade_mcp` is a Model Context Protocol (MCP) server for **Interactive Brokers (IBKR)**, built using the `ib_trade_core` Dart SDK.

It provides a standardized JSON-RPC 2.0 interface for AI assistants (such as Claude Desktop, Cursor, or custom LLM agents) to execute trades, manage open orders, inspect portfolio PnL, preview margin impact, and explore option chains via the local IBKR Client Portal Gateway REST API.

---

## 📚 Wiki Contents

* **[SDK Setup Guide](SDK-Setup-Guide)**: Complete step-by-step instructions for installing Dart, setting up IBKR Client Portal Gateway, configuring repositories, and embedding the MCP server.
* **[Quick Set Up](set-up)**: Quick configuration steps, environment variables guide, and verification checklist.

---

## 🛠 Features Overview

* **20 Standardized MCP Tools**: Account management, order placement (LMT, MKT, STP, TRAIL, TRAIL LIMIT), 3-legged bracket orders, portfolio PnL, pre-trade margin preview, market data, and options chain discovery.
* **Claude Desktop & Cursor Ready**: Easy JSON-RPC transport configuration for seamless integration into AI assistant workflows.
* **Docker Support**: Containerized deployment option for zero-dependency execution.
