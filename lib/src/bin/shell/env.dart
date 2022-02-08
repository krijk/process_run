import 'dart:convert';

// ignore: import_of_legacy_library_into_null_safe
import 'package:args/args.dart';
import 'package:path/path.dart';
import '/cmd_run.dart' as prefix0;
import '/shell_run.dart';
import '/src/bin/shell/env_edit.dart';
import '/src/user_config.dart';

import 'env_alias.dart';
import 'env_delete.dart';
import 'env_file_content.dart';
import 'env_path.dart';
import 'env_var.dart';
import 'import.dart';

class ShellEnvCommandBase extends ShellBinCommand {
  ShellEnvCommandBase({required String name, String? description})
      : super(name: name, description: description) {
    parser.addFlag(flagLocal,
        abbr: 'l', help: 'Use local env', negatable: false, defaultsTo: true,);
    parser.addFlag(flagUser,
        abbr: 'u', help: 'Use user env instead of local env', negatable: false,);
  }

  bool get local {
    final bool user = results[flagUser] as bool;
    final bool local = !user;
    return local;
  }

  String get label => local ? 'local' : 'user';

  Future<EnvFileContent> envFileReadOrCreate({bool write = false}) async {
    final EnvFileContent fileContent = EnvFileContent(_envFilePath!);
    if (!await fileContent.read()) {
      fileContent.lines = sampleFileContent;
    }
    if (write) {
      await fileContent.write();
    }
    return fileContent;
  }

  String? get envFilePath => _envFilePath;

  String? get _envFilePath => local
      ? getLocalEnvFilePath(userEnvironment)
      : getUserEnvFilePath(userEnvironment);

  List<String>? _sampleFileContent;

  List<String> get sampleFileContent => _sampleFileContent ??= () {
        final String content = local
            ? '''
# Local Environment path and variable for `Shell.run` calls.
#
# `path(s)` is a list of path, `var(s)` is a key/value map.
#
# Content example. See <https://github.com/tekartik/process_run.dart/blob/master/doc/user_config.md> for more information
#
# path:
#   - ./local
#   - bin/
# var:
#   MY_PWD: my_password
#   MY_USER: my user
# alias:
#   qr: /path/to/my_qr_app
  '''
            : '''
# Environment path and variable for `Shell.run` calls.
#
# `path` is a list of path, `var` is a key/value map.
#
# Content example. See <https://github.com/tekartik/process_run.dart/blob/master/doc/user_config.md> for more information
#
# path:
#   - ~/Android/Sdk/tools/bin
#   - ~/Android/Sdk/platform-tools
#   - ~/.gem/bin/
#   - ~/.pub-cache/bin
# var:
#   ANDROID_TOP: ~/.android
#   FLUTTER_BIN: ~/.flutter/bin
# alias:
#   qr: /path/to/my_qr_app

''';

        return LineSplitter.split(content).toList();
      }();
}

class ShellEnvCommand extends ShellEnvCommandBase {
  ShellEnvCommand()
      : super(
            name: 'env',
            description:
                'Manipulate local and global env vars, paths and aliases',) {
    addCommand(ShellEnvVarCommand());
    addCommand(ShellEnvEditCommand());
    addCommand(ShellEnvDeleteCommand());

    addCommand(ShellEnvAliasCommand());
    addCommand(ShellEnvPathCommand());
    parser.addFlag(flagInfo, abbr: 'i', help: 'display info', negatable: false);
  }

  @override
  FutureOr<bool> onRun() async {
    final bool displayInfo = results[flagInfo] as bool;
    if (displayInfo) {
      void displayInfo(String title, String path) {
        final EnvFileConfig config = loadFromPath(path);
        stdout.writeln('# $title');
        stdout.writeln('file: ${relative(path, from: Directory.current.path)}');
        //stdout.writeln('${config.fileContent}');
        // stdout.writeln();
        // if (config.yaml != null) {
        //  stdout.writeln('yaml: ${config.yaml}');
        // }
        if (config.vars.isNotEmpty) {
          stdout.writeln('  var: ${config.vars}');
        }
        if (config.paths.isNotEmpty) {
          stdout.writeln(' path: ${config.paths}');
        }
        if (config.aliases.isNotEmpty) {
          stdout.writeln('alias: ${config.paths}');
        }
        if (config.isEmpty) {
          stdout.writeln('empty');
        }
      }

      displayInfo('env ($label)', envFilePath!);
      return true;
    }
    return false;
  }
}

/// Direct shell env Alias dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvCommand().parseAndRun(arguments);
}

/// pub run process_run:shell edit-env
Future<void> shellEnv(ArgParser parser, ArgResults results) async {
  final bool help = results[flagHelp] as bool;

  void _printUsage() {
    stdout.writeln('Manipulate local and global env vars');
    stdout.writeln();
    stdout.writeln('Usage: ds env var <command>');
    stdout.writeln();
    stdout.writeln('Options:');
    stdout.writeln(parser.usage);
    stdout.writeln();
  }

  if (help) {
    _printUsage();
    return;
  }

  late String command;
  final List<String> commands = results.rest;
  if (commands.isEmpty) {
    stderr.writeln('missing command');
  } else if (commands.length == 1) {
    command = commands.first;
  } else {
    command = prefix0.argumentsToString(commands);
  }

  final bool displayInfo = results[flagInfo] as bool;
  if (displayInfo) {
    void displayInfo(String title, String path) {
      final EnvFileConfig config = loadFromPath(path);
      stdout.writeln('# $title');
      stdout.writeln('file: ${relative(path, from: Directory.current.path)}');
      stdout.writeln('vars: ${config.vars}');
      stdout.writeln('paths: ${config.paths}');
    }

    stdout.writeln('command: $command');
    displayInfo('user_env', getUserEnvFilePath()!);
    displayInfo('local_env', getLocalEnvFilePath());

    return;
  }

  await run(command);
}
