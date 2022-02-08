// ignore_for_file: join_return_with_assignment
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

import '/cmd_run.dart';
import '/src/utils.dart';
import 'common/import.dart';

String dartBinFileName = 'dart${Platform.isWindows ? '.exe' : ''}';

@Deprecated('Use DartCmd instead')
ProcessCmd dartCmd(List<String> arguments) => DartCmd(arguments);

@Deprecated('Use DartFmtCmd instead')
ProcessCmd dartfmtCmd(List<String> args) => DartFmtCmd(args);

@Deprecated('Use DartAnalyzerCmd instead')
ProcessCmd dartanalyzerCmd(List<String> args) => DartAnalyzerCmd(args);

@Deprecated('Use Dart2JsCmd instead')
ProcessCmd dart2jsCmd(List<String> args) => Dart2JsCmd(args);

@Deprecated('Use DartDocCmd instead')
ProcessCmd dartdocCmd(List<String> args) => DartDocCmd(args);

@Deprecated('Use DartDevcCmd instead')
ProcessCmd dartdevcCmd(List<String> args) => DartDevcCmd(args);

@Deprecated('Use PubCmd instead')
ProcessCmd pubCmd(List<String> args) => PubCmd(args);

/// Call dart executable
///
/// To prevent 'Observatory server failed to start after 1 tries' when
/// running from an idea use: includeParentEnvironment = false
class DartCmd extends _DartBinCmd {
  DartCmd(List<String> arguments) : super(dartBinFileName, arguments);
}

/// dartfmt command

class DartFmtCmd extends DartCmd {
  @Deprecated('dartfmt is deprecated itself')
  DartFmtCmd(List<String> arguments) : super(<String>['format', ...arguments]);
}

/// dartanalyzer
class DartAnalyzerCmd extends _DartBinCmd {
  DartAnalyzerCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dartanalyzer'), arguments);
}

/// dart2js
class Dart2JsCmd extends _DartBinCmd {
  Dart2JsCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dart2js'), arguments);
}

/// dartdoc
class DartDocCmd extends _DartBinCmd {
  DartDocCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dartdoc'), arguments);
}

/// dartdevc
class DartDevcCmd extends _DartBinCmd {
  DartDevcCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dartdevc'), arguments);
}

/// pub
class PubCmd extends DartCmd {
  PubCmd(List<String> arguments) : super(<String>['pub', ...arguments]);
}


class DartDevkCmd extends _DartBinCmd {
  @Deprecated('Not supported anymore')
  DartDevkCmd(List<String> arguments)
      : super(getShellCmdBinFileName('dartdevk'), arguments);
}

class _DartBinCmd extends ProcessCmd {
  final String binName;

  _DartBinCmd(this.binName, List<String> arguments)
      : super(join(dartSdkBinDirPath, binName), arguments);

  @override
  String toString() => executableArgumentsToString(binName, arguments);
}

class PubRunCmd extends PubCmd {
  final String _command;
  final List<String> _arguments;

  PubRunCmd(this._command, this._arguments)
      : super(<String>['run', _command, ..._arguments]);

  @override
  String toString() => executableArgumentsToString(_command, _arguments);
}

class PubGlobalRunCmd extends PubCmd {
  final String _command;
  final List<String> _arguments;

  PubGlobalRunCmd(this._command, this._arguments)
      : super(<String>['global', 'run', _command, ..._arguments]);

  @override
  String toString() => executableArgumentsToString(_command, _arguments);
}

Version parsePlatformVersion(String text) {
  return Version.parse(text.split(' ').first);
}

/// Parse the text from Platform.version
String parsePlatformChannel(String text) {
  //  // 2.8.0-dev.18.0.flutter-eea9717938 (be) (Wed Apr 1 08:55:31 2020 +0000) on "linux_x64"
  final List<String> parts = text.split(' ');
  if (parts.length > 1) {
    final String channelText = parts[1];
    if (channelText.toLowerCase().contains('dev')) {
      return dartChannelDev;
    } else if (channelText.toLowerCase().contains('beta')) {
      return dartChannelBeta;
    }
  }
  return dartChannelStable;
}

/// Parse flutter version
Future<Version?> getDartBinVersion() async {
  // $ dart --version
  // Linux: Dart VM version: 2.7.0 (Unknown timestamp) on "linux_x64"
  final DartCmd cmd = DartCmd(<String>['--version']);
  final ProcessResult result = await runCmd(cmd);

  // Take from stderr first
  Version? version = parseDartBinVersionOutput(result.stderr.toString().trim());
  // Take stdout in case it changes
  version ??= parseDartBinVersionOutput(result.stdout.toString().trim());
  return version;
}

/// Parse version from 'dart --version' output.
Version? parseDartBinVersionOutput(String text) {
  final Iterable<String> output = LineSplitter.split(text)
      .join(' ')
      .split(' ')
      .map((String word) => word.trim())
      .where((String word) => word.isNotEmpty);
  bool foundDart = false;
  try {
    for (final String word in output) {
      if (foundDart) {
        try {
          final Version version = Version.parse(word);
          return version;
        } catch (_) {}
      }
      if (word.toLowerCase().contains('dart')) {
        foundDart = true;
      }
    }
  } catch (_) {}
  return null;
}
