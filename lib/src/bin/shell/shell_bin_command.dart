// ignore_for_file: avoid_unused_constructor_parameters
import 'dart:io';

// ignore: import_of_legacy_library_into_null_safe
import 'package:args/args.dart';
import 'package:meta/meta.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

import '/src/bin/shell/shell.dart';
import '/src/common/import.dart';

class ShellBinCommand {
  // Optional parent
  ShellBinCommand? parent;
  String name;

  ArgParser get parser => _parser ??= ArgParser(allowTrailingOptions: false);
  FutureOr<bool> Function()? _onRun;
  ArgParser? _parser;
  late ArgResults results;
  bool? _verbose;

  // Set before run
  bool? get verbose => _verbose ??= parent?.verbose;

  String? _description;

  String? get description => _description;
  Version? _version;

  Version? get version => _version ??= parent?.version;

  // name
  //   description
  void printNameDescription() {
    stdout.writeln('$name${parent != null ? '' : ' ${version.toString()}'}');
    if (description != null) {
      stdout.writeln('  $description');
    }
  }

  void printUsage() {
    printNameDescription();
    stdout.writeln();
    stdout.writeln(parser.usage);
    if (_commands.isNotEmpty) {
      printCommands();
    }
  }

  /// Prepend an em
  void printCommands() {
    _commands.forEach((String name, ShellBinCommand value) {
      value.printNameDescription();
    });
    stdout.writeln();
  }

  void printBaseUsage() {
    printNameDescription();
    if (_commands.isNotEmpty) {
      stdout.writeln();
      printCommands();
    } else {
      stdout.writeln();
      stdout.writeln(parser.usage);
    }
  }

  ArgResults parse(List<String> arguments) {
    // Add missing common commands
    parser.addFlag(flagVersion,
        help: 'Print the command version', negatable: false,);
    parser.addFlag(flagVerbose,
        abbr: 'v', help: 'Verbose mode', negatable: false,);
    return results = parser.parse(arguments);
  }

  @nonVirtual
  FutureOr<bool> parseAndRun(List<String> arguments) {
    parse(arguments);
    return run();
  }

  final Map<String, ShellBinCommand> _commands = <String, ShellBinCommand>{};

  ShellBinCommand(
      {required this.name,
      Version? version,
      ArgParser? parser,
      ShellBinCommand? parent,
      @Deprecated('Do no user') FutureOr<bool> Function()? onRun,
      String? description,}) {
    _onRun = onRun;
    _parser = parser;
    _description = description;
    _version = version;
    // read or create
    parser = this.parser;
    parser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
  }

  void addCommand(ShellBinCommand command) {
    parser.addCommand(command.name, command.parser);
    _commands[command.name] = command;
    command.parent = this;
  }

  /// To override
  ///
  /// return true if handled.
  @visibleForOverriding
  FutureOr<bool> onRun() {
    if (_onRun != null) {
      return _onRun!();
    }
    return false;
  }

  /// Get a flag
  bool? getFlag(String name) => results[name] as bool?;

  @nonVirtual
  FutureOr<bool> run() async {
    // Handle version first
    if (parent == null) {
      // Handle verbose
      _verbose = getFlag(flagVerbose);

      final bool hasVersion = getFlag(flagVersion)!;
      if (hasVersion) {
        stdout.writeln(version);
        return true;
      }
    }
    // Handle help
    final bool help = results[flagHelp] as bool;

    if (help) {
      printUsage();
      return true;
    }

    // Find the command if any
    final ArgResults? command = results.command;

    final ShellBinCommand? shellCommand = _commands[command?.name];
    if (shellCommand != null) {
      // Set the result in the the shell command
      shellCommand.results = command!;
      return shellCommand.run();
    }

    final bool ran = await onRun();
    if (!ran) {
      stderr.writeln('No command ran');
      printBaseUsage();
      exit(1);
    }
    return ran;
  }

  @override
  String toString() => 'ShellCommand($name)';
}
