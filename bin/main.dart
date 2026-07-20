import 'dart:io';
import 'package:args/args.dart';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ibkr_trade_mcp/ibkr_trade_mcp.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('host', abbr: 'h', defaultsTo: 'localhost', help: 'IBKR Gateway host')
    ..addOption('port', abbr: 'p', defaultsTo: '5000', help: 'IBKR Gateway port')
    ..addFlag('use-ssl', defaultsTo: true, help: 'Use HTTPS/SSL')
    ..addFlag('bypass-ssl', abbr: 'k', defaultsTo: false, help: 'Bypass self-signed SSL verification')
    ..addOption('tickle-interval', defaultsTo: '45', help: 'Tickle interval in seconds')
    ..addFlag('help', abbr: '?', negatable: false, help: 'Show usage information');

  final ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    stderr.writeln('Error parsing CLI arguments: $e');
    stderr.writeln(parser.usage);
    exit(1);
  }

  if (argResults['help'] == true) {
    stdout.writeln('IBKR Trade MCP Server');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final host = argResults['host'] as String;
  final port = int.tryParse(argResults['port'] as String) ?? 5000;
  final useSsl = argResults['use-ssl'] as bool;
  final bypassSsl = argResults['bypass-ssl'] as bool;
  final tickleInterval = int.tryParse(argResults['tickle-interval'] as String) ?? 45;

  final config = GatewayConfig(
    host: host,
    port: port,
    useSsl: useSsl,
    bypassSslVerification: bypassSsl,
    tickleIntervalSeconds: tickleInterval,
  );

  final server = McpServer(config: config);

  ProcessSignal.sigint.watch().listen((_) async {
    McpLogger.info('SIGINT received, shutting down...');
    await server.stop();
    exit(0);
  });

  await server.start();
}
