# Changelog

## 0.1.2

### Added
- **High-level Trading Tools**:
  - `place_bracket_order`: Orchestrates atomic multi-leg bracket orders (parent entry + take-profit limit + stop-loss exit) linked via `cOID` and `parentId`.
  - `get_portfolio_pnl`: Synthesizes portfolio unrealized, realized, and daily PnL alongside Net Liquidation Value, with automatic reconciliation across individual positions.
  - `preview_order`: Pre-trade what-if simulation (`POST /iserver/account/{acctId}/orders/whatif`) for margin requirements, fee estimates, equity impact, and risk warnings.
- **Order Features**:
  - Trailing stop support (`TRAIL`, `TRAIL LIMIT`) in `place_order` with `auxPrice` (dollar gap) and `trailingPercent` (% gap).
  - Configurable Time in Force (`tif`: `DAY`, `GTC`, `IOC`) and Regular Trading Hours execution (`outsideRth`).
  - Parameterized `modify_order` tool supporting `price`, `quantity`, `conid`, `side`, `orderType`, `tif`, and automatic `conid` resolution from active working orders.
- **Session Management**:
  - `keep_alive` / `tickle` MCP tool invoking `POST /iserver/tickle` to prevent gateway authentication timeouts during long LLM conversations.
- **Infrastructure & Testing**:
  - GitHub Actions CI workflow (`.github/workflows/ci.yml`) running static analysis, formatting verification, and unit tests across Windows, Ubuntu, and macOS runners.
  - Comprehensive unit test coverage for `StdioServerTransport` and MCP JSON-RPC protocol handling.
- **Documentation**:
  - Comprehensive client setup guide (`docs/mcp_setup_guide.md`) for Cursor, Windsurf, Claude Desktop, and Antigravity IDE.

### Fixed
- Prevented runtime `UnsupportedError` in `ibkr_logout` by safely clearing session cookies via `_client.clearCookies()`.

## 0.1.0

- Initial release of Model Context Protocol (MCP) server for Interactive Brokers.
- Added package example directory and usage example (`example/example.dart`).
- Completed dartdoc documentation for `McpLogger` and `LogLevel`.
- Expanded `json_rpc_2` dependency constraint range (`>=3.0.2 <5.0.0`).
