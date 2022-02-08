// ignore_for_file: always_specify_types
@TestOn('vm')
library process_run.process_run_in_test;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/process_run.dart';
import 'package:test/test.dart';

import 'process_run_test_common.dart';

void main() {
  test('connect_stdin', () async {
    debugPrint("Please enter 'hi'");
    ProcessResult result = await runExecutableArguments(
        dartExecutable!, [echoScriptPath, '--stdin'],
        stdin: testStdin,);
    expect(result.stdout, 'hi');
    debugPrint("Please enter 'ho'");
    result = await runExecutableArguments(
        dartExecutable!, [echoScriptPath, '--stdin'],
        stdin: testStdin,);
    expect(result.stdout, 'ho');
  });
}
