@TestOn('vm')
library process_run.process_cmd_test;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

import 'dartbin_test.dart';
import 'process_run_test_common.dart';

void main() {
  group('process_cmd', () {
    test('simple', () {
      final ProcessCmd cmd = ProcessCmd('a', <String>[]);
      expect(cmd.executable, 'a');
    });
    test('equals', () {
      final ProcessCmd cmd1 = ProcessCmd('a', <String>[]);
      final ProcessCmd cmd2 = ProcessCmd('a', <String>[]);
      expect(cmd1, cmd2);
      cmd1.executable = 'b';
      expect(cmd1, isNot(cmd2));
      cmd2
        ..executable = 'b'
        ..arguments = <String>['1'];
      expect(cmd1, isNot(cmd2));
    });
    test('clone', () {
      final ProcessCmd cmd1 = ProcessCmd('a', <String>[]);
      final ProcessCmd cmd2 = cmd1.clone();
      expect(cmd1, cmd2);
      cmd1.executable = 'b';
      expect(cmd1, isNot(cmd2));
    });
    test('dart_cmd', () async {
      final ProcessResult result = await runCmd(ProcessCmd(dartExecutable, <String>['--version']));
      testDartVersionOutput(result);
      // 'Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on 'linux_x64'\n'
    });
    // only duplicate this one
    test('system_command', () async {
      // read pubspec.yaml
      final Iterable<String> lines = LineSplitter.split(
          await File(join(projectTop, 'pubspec.yaml')).readAsString(),);

      // use 'cat' on mac and linux
      // use 'type' on windows
      ProcessCmd cmd;
      if (Platform.isWindows) {
        cmd = ProcessCmd('type', <String>['pubspec.yaml'],
            workingDirectory: projectTop, runInShell: true,);
      } else {
        cmd = ProcessCmd('cat', <String>['pubspec.yaml'], workingDirectory: projectTop);
      }

      final ProcessResult result = await runCmd(cmd);
      expect(LineSplitter.split(result.stdout.toString()), lines);
      expect(result.stderr, '');
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);
    });

    test('processResultToDebugString', () {
      expect(
          LineSplitter.split(
              processResultToDebugString(ProcessResult(1, 0, 'out', 'err')),),
          <String>['exitCode: 0', 'out: out', 'err: err'],);
      expect(
          LineSplitter.split(processResultToDebugString(
              ProcessResult(2, 1, 'testout', 'testerr'),),),
          <String>['exitCode: 1', 'out: testout', 'err: testerr'],);
    });

    test('processCmdToDebugString', () {
      expect(
          LineSplitter.split(
              processCmdToDebugString(ProcessCmd('cmd', <String>['arg'])),),
          <String>['cmd: cmd arg'],);

      expect(
          LineSplitter.split(processCmdToDebugString(
              ProcessCmd('cmd', <String>['arg'])..workingDirectory = 'dir',),),
          <String>['dir: dir', 'cmd: cmd arg'],);
    });
  });
}
