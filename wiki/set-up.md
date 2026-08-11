# set up

Quick reference guide for environment variables, connection verification, and troubleshooting the **`ibkr_trade_mcp`** server.

---

## Environment Variables

The MCP server accepts environment variables to configure the gateway connection:

| Environment Variable | Default Value | Description |
|---|---|---|
| `IBKR_GATEWAY_HOST` | `localhost` | Hostname or IP address of the local IBKR Client Portal Gateway |
| `IBKR_GATEWAY_PORT` | `5000` | Port number of the gateway REST API |
| `IBKR_GATEWAY_SCHEME` | `https` | Protocol scheme (`https` or `http`) |

---

## Step-by-Step Environment Verification

1. **Verify IBKR Gateway is Active**:
   Open a terminal and run:
   ```bash
   curl -k https://localhost:5000/v1/api/iserver/auth/status
   ```
   A successful response should return JSON showing `authenticated: true`.

2. **Verify MCP Server Output**:
   Run the MCP server manually to check for clean JSON-RPC startup:
   ```bash
   dart run bin/ibkr_trade_mcp.dart
   ```

3. **Check Stderr Logs**:
   All diagnostic logs from `McpLogger` are sent to `stderr` to avoid interfering with stdout JSON-RPC messaging. Check for `[INFO]` messages confirming gateway target configuration.

---

## Common Issues & Troubleshooting

* **SSL Certificate Warnings**: The local IBKR gateway uses a self-signed SSL certificate. `ibkr_trade_mcp` automatically bypasses SSL verification for local connections.
* **Session Expiration**: IBKR Client Portal Gateway sessions periodically expire or require re-authentication. Re-open `https://localhost:5000` in your browser if `get_session_status` returns unauthenticated.
