import 'dart:convert';
import 'dart:io';

import 'package:process_run/src/bin/shell/env_file_content.dart';

import '/shell.dart';
import '/src/bin/shell/env.dart';
import '/src/common/import.dart';

class ShellEnvAliasDeleteCommand extends ShellEnvCommandBase {
  ShellEnvAliasDeleteCommand()
      : super(
          name: 'delete',
          description: 'Delete an alias from a user/local config file',
        );

  @override
  void printUsage() {
    stdout.writeln('ds env alias delete <name> [<name2>...]');
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    final List<String> rest = results.rest;
    if (rest.isEmpty) {
      stderr.writeln('At least 1 arguments expected');
      exit(1);
    } else {
      if (verbose!) {
        stdout.writeln('file $label: $envFilePath');
        stdout.writeln('before: ${jsonEncode(ShellEnvironment().aliases)}');
      }

      final EnvFileContent fileContent = await envFileReadOrCreate();
      bool modified = false;
      for (final String name in rest) {
        modified = fileContent.deleteAlias(name) || modified;
      }
      if (modified) {
        if (verbose!) {
          stdout.writeln('writing file');
        }
        await fileContent.write();
      }

      // Force reload
      shellEnvironment = null;
      if (verbose!) {
        stdout.writeln('After: ${jsonEncode(ShellEnvironment().vars)}');
      }
      return true;
    }
  }
}

/// Direct shell env Var Set run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvAliasDeleteCommand().parseAndRun(arguments);
}
