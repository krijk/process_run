// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

import '/shell.dart';
import '/src/bin/shell/run.dart';
import 'env.dart';
import 'import.dart';

Version shellBinVersion = Version(0, 2, 0);

const String flagHelp = 'help';
const String flagInfo = 'info';
const String flagLocal = 'local';
const String flagUser = 'user';
// Force an action
const String flagForce = 'force';
const String flagDelete = 'delete';
const String flagVerbose = 'verbose';
const String flagVersion = 'version';

const String commandEdit = 'edit-env';
const String commandRun = 'run';
const String commandEnv = 'env';

const String commandEnvEdit = 'edit';
const String commandEnvVar = 'var';
const String commandEnvVarDump = 'dump';
const String commandEnvPath = 'path';
const String commandEnvAliases = 'alias';

String get script => 'ds';

class MainShellCommand extends ShellBinCommand {
  MainShellCommand() : super(name: 'ds', version: shellBinVersion) {
    addCommand(ShellEnvCommand());
    addCommand(ShellRunCommand());
  }

  @override
  void printUsage() {
    stdout.writeln('*** ubuntu/windows only for now ***');
    stdout.writeln('Process run shell configuration utility');
    stdout.writeln();
    stdout.writeln('Usage: $script <command> [<arguments>]');
    stdout.writeln('Usage: pub run process_run:shell <command> [<arguments>]');
    stdout.writeln();
    stdout.writeln('Examples:');
    stdout.writeln();
    stdout.writeln('''
# Set a local env variable
ds env var set MY_VAR my_value
# Get a local env variable
ds env var get USER
# Prepend a path
ds env path prepend ~/.my_path
# Add an alias
ds env alias set hello_world echo Hello World
# Run a command in the overriden envionement
ds run hello_world
ds run echo MY_VAR
# Edit the local environment file
ds env edit
''',);
    super.printUsage();
  }

  @override
  void printBaseUsage() {
    stdout.writeln('Process run shell configuration utility');
    stdout.writeln(' -h, --help       Usage help');
    // super.printBaseUsage();
  }

  @override
  FutureOr<bool> onRun() {
    return false;
  }
}

final MainShellCommand mainCommand = MainShellCommand();

///
/// write rest arguments as lines
///
Future<dynamic> main(List<String> arguments) async {
  await mainCommand.parseAndRun(arguments);
  await promptTerminate();
}
