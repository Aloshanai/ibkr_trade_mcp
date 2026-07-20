/// Constant parameters defining the MCP server protocol capabilities.
class McpProtocolConstants {
  static const String protocolVersion = '2024-11-05';
  static const String serverName = 'ibkr_trade_mcp';
  static const String serverVersion = '0.1.0';
}

/// Helper payload builders conforming to the Model Context Protocol specification.
class McpResponseBuilder {
  /// Builds standard MCP initialization handshake payload.
  static Map<String, dynamic> buildInitializeResult() {
    return {
      'protocolVersion': McpProtocolConstants.protocolVersion,
      'capabilities': {
        'tools': {
          'listChanged': false,
        },
      },
      'serverInfo': {
        'name': McpProtocolConstants.serverName,
        'version': McpProtocolConstants.serverVersion,
      },
    };
  }

  /// Wraps successful tool text output as an MCP content response object.
  static Map<String, dynamic> buildToolSuccessResponse(String textContent) {
    return {
      'content': [
        {
          'type': 'text',
          'text': textContent,
        }
      ],
      'isError': false,
    };
  }

  /// Wraps tool error output as an MCP error response object.
  static Map<String, dynamic> buildToolErrorResponse(String errorMessage) {
    return {
      'content': [
        {
          'type': 'text',
          'text': errorMessage,
        }
      ],
      'isError': true,
    };
  }
}
