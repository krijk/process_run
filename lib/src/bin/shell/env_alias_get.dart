import 'dart:io';

import '/shell.dart';
import '/src/bin/shell/env.dart';
import '/src/common/import.dart';

import 'dump.dart';

class ShellEnvAliasGetCommand extends ShellEnvCommandBase {
  ShellEnvAliasGetCommand()
      : super(
          name: 'get',
          description: 'Get an alias from the config file',
        );

  @override
  void printUsage() {
    stdout.writeln('ds env alias get <name1> [<name2> ...]');
    stdout.writeln();
    stdout.writeln('Output if defined:');
    stdout.writeln('  <name>: <value>');
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    final List<String> rest = results.rest;
    if (rest.isEmpty) {
      stderr.writeln('At least 1 arguments expected');
      exit(1);
    } else {
      Map<String, String> map = ShellEnvironment().aliases;
      map = Map<String, String>.from(map)
        ..removeWhere((String key, String value) => !rest.contains(key));
      if (map.isEmpty) {
        stdout.writeln('not found');
      } else {
        dumpStringMap(map);
      }
      return true;
    }
  }
}

/// Direct shell env Var Set run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvAliasGetCommand().parseAndRun(arguments);
}
