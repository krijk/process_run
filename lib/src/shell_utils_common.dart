// ignore_for_file: parameter_assignments
import 'dart:async';
import 'dart:convert';

import '/src/platform/platform.dart';

import 'characters.dart';

const List<String> windowsDefaultPathExt = <String>['.exe', '.bat', '.cmd', '.com'];

const String windowsEnvPathSeparator = ';';
const String posixEnvPathSeparator = ':';
const String envPathKey = 'PATH';

String get envPathSeparator =>
    platformIoIsWindows ? windowsEnvPathSeparator : posixEnvPathSeparator;

/// Write a string line to the ouput
void streamSinkWriteln(StreamSink<List<int>> sink, String message,
    {Encoding? encoding,}) {
  encoding ??= shellContext.encoding;
  streamSinkWrite(sink, '$message\n', encoding: encoding);
}

/// Write a string to a to sink
void streamSinkWrite(StreamSink<List<int>> sink, String message,
    {Encoding? encoding,}) {
  encoding ??= shellContext.encoding;
  sink.add(encoding.encode(message));
}

/// Helper to run a process and connect the input/output for verbosity
///

/// Helper to run a process and connect the input/output for verbosity
///

/// Use to safely enclose an argument if needed
///
/// argument must not be null
String argumentToString(String argument) {
  bool hasWhitespace = false;
  int singleQuoteCount = 0;
  int doubleQuoteCount = 0;
  if (argument.isEmpty) {
    return '""';
  }
  for (final int rune in argument.runes) {
    if ((!hasWhitespace) && (isWhitespace(rune))) {
      hasWhitespace = true;
    } else if (rune == 0x0027) {
      // '
      singleQuoteCount++;
    } else if (rune == 0x0022) {
      // "
      doubleQuoteCount++;
    }
  }
  if (singleQuoteCount > 0) {
    if (doubleQuoteCount > 0) {
      // simply escape all double quotes
      argument = '"${argument.replaceAll('"', '\\"')}"';
    } else {
      argument = '"$argument"';
    }
  } else if (doubleQuoteCount > 0) {
    argument = "'$argument'";
  } else if (hasWhitespace) {
    argument = '"$argument"';
  }
  return argument;
}

/// Convert multiple arguments to string than can be used in a terminal
String argumentsToString(List<String> arguments) {
  final List<String> argumentStrings = <String>[];
  for (final String argument in arguments) {
    argumentStrings.add(argumentToString(argument));
  }
  return argumentStrings.join(' ');
}

/// Use to safely enclose an argument if needed
String shellArgument(String argument) => argumentToString(argument);

/// Convert multiple arguments to string than can be used in a terminal
String shellArguments(List<String> argument) => argumentsToString(argument);
