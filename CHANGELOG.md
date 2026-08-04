# Changelog

## 0.1.0

- Initial release of `ibkr_trade_mcp` Model Context Protocol (MCP) server.
- Standardized MCP server implementation for Interactive Brokers (IBKR) Client Portal REST API.
- Implemented core session and account tools: `get_session_status`, `list_accounts`, `get_positions`, `get_account_summary`, `get_cash_ledger`, `ibkr_login`, `ibkr_logout`.
- Implemented trading tools: `place_order` (including `TRAIL` and `TRAIL LIMIT` trailing stop support), `place_bracket_order`, `reply_to_challenge`, `list_working_orders`, `modify_order`, `cancel_order`.
- Implemented pre-trade preview tool: `preview_order` for margin impact, fee estimation, and risk warning validation.
- Implemented portfolio management tools: `get_portfolio_pnl` with position-level auto-reconciliation.
- Implemented market data & options tools: `search_contracts`, `get_market_data`, `get_historical_prices`, `get_option_chains`, `resolve_option_contract`.
