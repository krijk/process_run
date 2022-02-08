// ignore_for_file: always_specify_types
@TestOn('vm')
library process_run.which_test;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

import 'dartbin_test.dart';

void main() {
  group('which', () {
    test('dart', () async {
      final env = {'PATH': dartSdkBinDirPath};
      final dartExecutable = whichSync('dart', environment: env);
      expect(dartExecutable, isNotNull);
      debugPrint(dartExecutable);
      final cmd = ProcessCmd(dartExecutable, ['--version']);
      final result = await runCmd(cmd);
      testDartVersionOutput(result);
    });

    test('no_env', () {
      final empty = <String, String>{};

      // We can always find dart and pub
      try {
        expect(whichSync('dart', environment: empty), dartExecutable);
      } on TestFailure catch (_) {
        /*
        if (!isFlutterSupportedSync) {
          rethrow;
        }
        // In case flutter in in the path first
        expect(
            whichSync('dart', environment: empty),
            join(dirname(whichSync('flutter')),
                getBashOrBatExecutableFilename('dart')));*/
      }
      expect(whichSync('pub', environment: empty), isNotNull);
      expect(whichSync('current_dir', environment: empty), isNull);

      expect(
          basename(whichSync('current_dir',
              environment: <String, String>{'PATH': join('test', 'src')},)!,),
          Platform.isWindows ? 'current_dir.bat' : 'current_dir',);
    });

    test('dart_env', () async {
      final empty = <String, String>{};

      String? foundDart;
      // We can always find dart and pub
      try {
        // Normal
        foundDart = whichSync('dart', environment: empty);
        expect(foundDart, dartExecutable);
      } on TestFailure catch (_) {
        // In case flutter in in the path first
        // var foundFlutter = whichSync('flutter', environment: empty);
        // if (foundFlutter != null) {
        //  expect(foundDart, startsWith(dirname(foundFlutter)));
        // }
      }
    });

    test('echo', () async {
      if (Platform.isWindows) {
        // Not true on github actions...
        // expect(whichSync('echo'), isNull);
      }
    });
  });
}
