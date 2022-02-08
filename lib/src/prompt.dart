// ignore_for_file: always_specify_types
import 'dart:convert';
import 'dart:io';

import '/shell.dart';
import 'shell_utils.dart';

/// Get text
Future<String> prompt(String? text, {Stream<List<int>>? stdin}) async {
  stdout.write('${(text?.isNotEmpty ?? false) ? '$text' : 'Enter text'}: ');
  await stdout.safeFlush();
  return _promptGetText(stdin: stdin);
}

/// Get text
Future<String> _promptGetText({Stream<List<int>>? stdin}) async {
  stdin ??= sharedStdIn;
  final String input =
      await stdin.transform(utf8.decoder).transform(const LineSplitter()).first;
  // devPrint('input: $input');
  return input;
}

/// Confirm action
Future<bool> promptConfirm(String? text, {Stream<List<int>>? stdin}) async {
  stdout.write('${(text?.isNotEmpty ?? false) ? '$text. ' : ''}Continue Y/N? ');
  await stdout.safeFlush();
  final String input = await _promptGetText(stdin: stdin);
  if (input.toLowerCase() != 'y') {
    return false;
  }
  return true;
}

/// Terminate a prompt session.
Future promptTerminate() async {
  await sharedStdIn.terminate();
}
