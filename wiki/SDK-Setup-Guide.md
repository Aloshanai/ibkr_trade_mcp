# SDK Setup Guide

Welcome to the **Interactive Brokers Trading MCP Server (`ibkr_trade_mcp`) Setup Guide**! This guide is designed to help you set up your development environment, configure the IBKR Client Portal Gateway, and get the MCP server running from scratch.

---

## 1. Prerequisites

Before starting, ensure the following tools are installed on your system:

### A. Dart SDK
`ibkr_trade_mcp` is written in Dart. You need **Dart version 3.0.0 or higher**.
* Download and install Dart from [dart.dev/get-dart](https://dart.dev/get-dart).
* Verify installation:
  ```bash
  dart --version
  ```

### B. Java Runtime Environment (JRE)
The IBKR Client Portal Gateway requires Java to run.
* Verify Java installation:
  ```bash
  java -version
  ```

---

## 2. Setting Up the Repositories

### Target Directory Structure
Recommended directory layout when working with the SDK and MCP server locally:
```text
development/
├── ib_trade_core/
└── ibkr_trade_mcp/
```

### Setup Steps
1. Clone the core SDK and MCP server repositories:
   ```bash
   git clone https://github.com/Aloshanai/ib_trade_core.git
   git clone https://github.com/Aloshanai/ibkr_trade_mcp.git
   ```
2. Navigate to the MCP server directory:
   ```bash
   cd ibkr_trade_mcp
   ```

---

## 3. Fetching Dependencies

Fetch the Dart pub packages:
```bash
dart pub get
```

---

## 4. Setting Up the IBKR Client Portal Gateway

The MCP server connects to Interactive Brokers via the **IBKR Client Portal Gateway** REST API running on your local machine.

### A. Download the Gateway
Download the latest Client Portal Gateway zip file from [Interactive Brokers API Downloads](https://www.interactivebrokers.com/en/trading/ibgateway-downloads.php).

### B. Configure and Run the Gateway
1. Extract the downloaded zip file into a local folder.
2. Start the gateway using the provided startup script:
   * **Windows**: `bin\run.bat root\conf.yaml`
   * **macOS / Linux**: `./bin/run.sh root/conf.yaml`
3. By default, the gateway runs on `https://localhost:5000`.

### C. Authenticate via Browser
Open your browser and navigate to `https://localhost:5000`. Log in with your Interactive Brokers paper or live account credentials and complete 2FA.

---

## 5. Running the MCP Server

### Option A: Standard Dart Run
```bash
dart run bin/ibkr_trade_mcp.dart
```

### Option B: Docker Container
Build and run using Docker:
```bash
docker build -t ibkr_trade_mcp .
docker run -it --net=host ibkr_trade_mcp
```

---

## 6. Configuring for Claude Desktop / Cursor

To use `ibkr_trade_mcp` with **Claude Desktop**, add the following entry to your `claude_desktop_config.json`:

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
