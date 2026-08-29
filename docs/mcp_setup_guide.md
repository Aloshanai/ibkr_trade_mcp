# IBKR MCP Client Setup Guide

This guide details how to integrate and configure the **Interactive Brokers (IBKR) Model Context Protocol (MCP) Server** with various AI coding assistants and desktop environments, including **Claude Desktop**, **Cursor IDE**, **Windsurf Editor**, and **Antigravity IDE**.

---

## 1. Prerequisites

1. **Dart SDK**: Version `^3.0.0` installed and available in your system `PATH`.
   ```bash
   dart --version
   ```
2. **IBKR Client Portal Gateway**: Downloaded and running locally (or on a networked machine).
   - Default address: `https://localhost:5000`
   - Ensure the Gateway API is running and accessible before connecting LLM clients.

---

## 2. Compilation and Packaging

You can run the MCP server directly via `dart run` or compile it into a standalone native binary for faster startup times.

### Option A: Standalone Native Binary (Recommended)
```bash
# In the ib_trade_mcp project root
dart pub get
dart compile exe bin/ibkr_trade_mcp.dart -o build/ibkr_trade_mcp
```
*(On Windows, this produces `build/ibkr_trade_mcp.exe`)*

### Option B: Run via Dart CLI
```bash
dart run ibkr_trade_mcp:ibkr_trade_mcp
```

---

## 3. Client Integration Configurations

### A. Claude Desktop

Locate your Claude Desktop configuration file:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

Add the `ibkr_trade` server configuration to `mcpServers`:

#### Using Compiled Binary:
```json
{
  "mcpServers": {
    "ibkr_trade": {
      "command": "/path/to/ib_trade_mcp/build/ibkr_trade_mcp",
      "args": [
        "--port=5000",
        "--host=localhost",
        "--bypass-ssl=true"
      ]
    }
  }
}
```

#### Using Dart CLI:
```json
{
  "mcpServers": {
    "ibkr_trade": {
      "command": "dart",
      "args": [
        "run",
        "/path/to/ib_trade_mcp/bin/ibkr_trade_mcp.dart",
        "--port=5000",
        "--host=localhost",
        "--bypass-ssl=true"
      ]
    }
  }
}
```

---

### B. Cursor IDE

In Cursor, navigate to **Settings** > **Cursor Settings** > **MCP Servers** (or edit `.cursor/mcp.json` in your workspace):

```json
{
  "mcpServers": {
    "ibkr_trade": {
      "command": "dart",
      "args": [
        "run",
        "/path/to/ib_trade_mcp/bin/ibkr_trade_mcp.dart",
        "--port=5000",
        "--host=localhost",
        "--bypass-ssl=true"
      ]
    }
  }
}
```

---

### C. Windsurf Editor

Open `~/.codeium/windsurf/mcp_config.json` and configure:

```json
{
  "mcpServers": {
    "ibkr_trade": {
      "command": "/path/to/ib_trade_mcp/build/ibkr_trade_mcp",
      "args": [
        "--port=5000",
        "--host=localhost",
        "--bypass-ssl=true"
      ]
    }
  }
}
```

---

### D. Antigravity IDE / Config

In Antigravity IDE configuration (`~/.gemini/antigravity-ide/mcp_config.json` or `.agents/mcp_config.json`):

```json
{
  "mcpServers": {
    "ibkr_trade": {
      "command": "dart",
      "args": [
        "run",
        "/path/to/ib_trade_mcp/bin/ibkr_trade_mcp.dart",
        "--port=5000",
        "--host=localhost",
        "--bypass-ssl=true"
      ]
    }
  }
}
```

---

## 4. Command-Line Arguments & Options

| Option | Default | Description |
|---|---|---|
| `--host` | `localhost` | Hostname or IP address of the IBKR Client Portal Gateway |
| `--port` | `5000` | Port number of the IBKR Client Portal Gateway |
| `--bypass-ssl` | `true` | Bypass self-signed SSL certificate verification for local Gateway |
| `--tickle-interval` | `60` | Interval in seconds for session keep-alive background ping |
| `--help` | - | Show help and usage information |

---

## 5. Verifying Connection

Once configured and your AI client is running:

1. **Check Status**:
   Ask the assistant: *"What is my IBKR Gateway session status?"*
   - The assistant will call `get_session_status`.
2. **Login**:
   If not authenticated, ask the assistant: *"Log in to IBKR"*
   - The assistant will call `ibkr_login`, automatically opening your browser to `https://localhost:5000` to complete 2FA authentication.
3. **Query Portfolio**:
   Ask: *"Show my open positions and account summary."*
   - The assistant will call `get_positions` and `get_account_summary`.
