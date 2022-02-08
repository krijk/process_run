import 'dart:io';

import 'package:flutter/material.dart';

import '/shell.dart';
import '/src/common/import.dart';

import 'env.dart';

class ShellEnvEditCommand extends ShellEnvCommandBase {
  ShellEnvEditCommand()
      : super(name: 'edit', description: 'Edit the environment file');

  @override
  FutureOr<bool> onRun() async {
    if (verbose!) {
      debugPrint('envFilePath: $envFilePath');
    }
    await envFileReadOrCreate(write: true);

    Future<dynamic> _run(String command) async {
      await run(command, commandVerbose: verbose);
    }

    if (Platform.isLinux) {
      if (await which('gedit') != null) {
        await _run('gedit ${shellArgument(envFilePath!)}');
        return true;
      }
    } else if (Platform.isWindows) {
      if (await which('notepad') != null) {
        await _run('notepad ${shellArgument(envFilePath!)}');
        return true;
      }
    } else if (Platform.isMacOS) {
      if (await which('open') != null) {
        await _run('open -a TextEdit ${shellArgument(envFilePath!)}');
        return true;
      }
    }
    if (await which('vi') != null) {
      await _run('vi ${shellArgument(envFilePath!)}');
      return true;
    }
    debugPrint('no editor found');
    return false;
  }
}

/// Direct shell env Edit dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvEditCommand().parseAndRun(arguments);
}
