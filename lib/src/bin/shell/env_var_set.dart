import 'dart:convert';
import 'dart:io';

import 'package:process_run/src/bin/shell/env_file_content.dart';

import '/shell.dart';
import '/src/bin/shell/env.dart';
import '/src/common/constant.dart';
import '/src/common/import.dart';

class ShellEnvVarSetCommand extends ShellEnvCommandBase {
  ShellEnvVarSetCommand()
      : super(
          name: 'set',
          description: 'Set environment variable in a user/local config file',
        );

  @override
  void printUsage() {
    stdout.writeln('ds env var set <name> <command with space>');
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    final List<String> rest = results.rest;
    if (rest.length < 2) {
      stderr.writeln('At least 2 arguments expected');
      exit(1);
    } else {
      if (verbose!) {
        stdout.writeln('file $label: $envFilePath');
        stdout.writeln('before: ${jsonEncode(ShellEnvironment().vars)}');
      }
      final String name = rest[0];
      final String value = rest.sublist(1).join(' ');
      final EnvFileContent fileContent = await envFileReadOrCreate();
      if (fileContent.addVar(name, value)) {
        if (verbose!) {
          stdout.writeln('writing file');
        }
        await fileContent.write();
      }
      if (local && name == localEnvFilePathEnvKey) {
        stderr.writeln('$name cannot be set in local file');
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
  await ShellEnvVarSetCommand().parseAndRun(arguments);
}
