@TestOn('vm')
library process_run.process_run_in_test2_;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/process_run.dart';
import 'package:test/test.dart';

import 'process_run_test_common.dart';

Future<void> main() async {
  debugPrint("Please enter 'hi'");
  ProcessResult result = await runExecutableArguments(
    dartExecutable!, <String>[echoScriptPath, '--stdin'],
    //stdin: testStdin);
  );
  debugPrint('out: ${result.stdout}');
  debugPrint("Please enter 'ho'");
  result = await runExecutableArguments(
    dartExecutable!, <String>[echoScriptPath, '--stdin'],
    //stdin: testStdin);
  );
  debugPrint('out: ${result.stdout}');

  // unfortunately using testStdin hangs...
}
