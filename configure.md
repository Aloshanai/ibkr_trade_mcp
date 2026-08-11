# IBKR Trade MCP Configuration Guide

Welcome to the configuration guide for `ibkr_trade_mcp`. This document explains how to configure the Model Context Protocol (MCP) server, connect it to the Interactive Brokers (IBKR) Client Portal Gateway, and integrate it with LLM clients such as **Claude Desktop**, **Cursor IDE**, and custom agent implementations.

---

## 📋 Prerequisites

Before configuring `ibkr_trade_mcp`, ensure you have:
1. **Dart SDK**: Version `^3.0.0` or higher installed.
2. **IBKR Client Portal Gateway**: Installed and running locally on port `5000` (or your custom port) and authenticated via browser 2FA.

---

## ⚙️ Environment Variables

`ibkr_trade_mcp` uses environment variables to configure its connection to the local IBKR Client Portal Gateway REST API.

| Environment Variable | Default Value | Description |
|---|---|---|
| `IBKR_GATEWAY_HOST` | `localhost` | Hostname or IP address of the IBKR Client Portal Gateway. |
| `IBKR_GATEWAY_PORT` | `5000` | Port number on which the Gateway REST service is listening. |
| `IBKR_GATEWAY_SCHEME` | `https` | Protocol scheme (`https` or `http`). IBKR Gateway uses `https` by default. |

---

## 🤖 1. Configuring Claude Desktop

To use `ibkr_trade_mcp` inside **Claude Desktop**, add the server definition to your `claude_desktop_config.json`.

### Configuration File Locations
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

### Option A: Running via Dart CLI (Recommended for development)

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

### Option B: Running via Globally Activated Pub Executable

First activate the package globally:
```bash
dart pub global activate ibkr_trade_mcp
```

Then configure Claude Desktop:
```json
{
  "mcpServers": {
    "ibkr-trade": {
      "command": "ibkr_trade_mcp",
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

## 💻 2. Configuring Cursor IDE

To connect `ibkr_trade_mcp` to **Cursor IDE**:

1. Open **Cursor Settings** -> **Features** -> **MCP Servers**.
2. Click **+ Add New MCP Server**.
3. Fill in the details:
   - **Name**: `ibkr-trade`
   - **Type**: `command` (stdio)
   - **Command**: `dart run ibkr_trade_mcp` (or path to dart executable)
4. Save and verify that the 20 trading tools populate under the MCP server status indicator.

---

## 🐳 3. Configuring Docker Container

If you prefer running `ibkr_trade_mcp` inside a Docker container:

### Build the Docker Image
```bash
docker build -t ibkr_trade_mcp .
```

### Run the Docker Container
When running in Docker, set `host.docker.internal` (or host IP) so the container can connect to the IBKR Client Portal Gateway running on the host machine:

```bash
docker run -i --rm \
  -e IBKR_GATEWAY_HOST=host.docker.internal \
  -e IBKR_GATEWAY_PORT=5000 \
  -e IBKR_GATEWAY_SCHEME=https \
  ibkr_trade_mcp
```

---

## 🔒 4. IBKR Gateway Authentication & Session Lifecycle

The IBKR Client Portal Gateway requires an active authenticated session to execute API calls:

1. **Start Gateway**: Execute `run.bat` (Windows) or `run.sh` (macOS/Linux) in your Client Portal Gateway root directory.
2. **Browser Authentication**: Navigate to `https://localhost:5000` in your browser and complete 2FA login.
3. **Session Verification**: Use the `get_session_status` tool to check connection health or `ibkr_login` to re-trigger login if your session expires.

---

## ❓ Troubleshooting

### SSL Certificate Errors
The IBKR Client Portal Gateway uses a self-signed SSL certificate by default. `ibkr_trade_mcp` automatically bypasses SSL verification for local HTTPS gateway connections.

### Stdio Transport Protocol Integrity
The Model Context Protocol relies strictly on standard output (`stdout`) for JSON-RPC 2.0 message exchange. All log outputs in `ibkr_trade_mcp` are routed exclusively to standard error (`stderr`) via `McpLogger` to prevent protocol corruption.
