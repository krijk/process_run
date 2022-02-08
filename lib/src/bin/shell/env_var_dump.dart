import '/shell.dart';

import 'import.dart';

class ShellEnvVarDumpCommand extends ShellBinCommand {
  ShellEnvVarDumpCommand()
      : super(name: 'dump', description: 'Dump environment variable');

  @override
  FutureOr<bool> onRun() async {
    final ShellEnvironmentVars vars = ShellEnvironment().vars;
    final List<String> keys = vars.keys.toList()
      ..sort((String t1, String t2) => t1.toLowerCase().compareTo(t2.toLowerCase()));
    for (final String key in keys) {
      final String? value = vars[key];
      stdout.writeln('$key: $value');
    }
    return true;
  }
}

/// Direct shell env var dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvVarDumpCommand().parseAndRun(arguments);
}
