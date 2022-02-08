// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: always_specify_types
@TestOn('vm')
library process_run.test.shell_environment_test;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:test/test.dart';

import 'echo_test.dart';

void main() {
  final ShellEnvironment emptyEnv = ShellEnvironment.empty();
  final ShellEnvironment basicEnv = ShellEnvironment.empty();
  basicEnv.vars['VAR1'] = 'var1';
  basicEnv.paths.add('path1');
  basicEnv.aliases['alias1'] = 'command1';

  group('ShellEnvironment', () {
    test('empty', () {
      final Map<String, String> _prev = shellEnvironment;
      expect(shellEnvironment, isNotEmpty);
      final ShellEnvironment env = ShellEnvironment.empty();
      try {
        shellEnvironment = env;
        expect(shellEnvironment, isEmpty);
        shellEnvironment = null;
        expect(shellEnvironment, _prev);
      } finally {
        shellEnvironment = _prev;
        expect(shellEnvironment, isNotEmpty);
      }
    });
    test('vars and paths name', () {
      final ShellEnvironment env = ShellEnvironment.empty();
      env.paths.addAll(['path1', 'path2']);
      env.vars['VAR1'] = 'var1';
      env.vars['PATH'] = 'dummy';

      expect(env, {
        'VAR1': 'var1',
        'PATH': Platform.isWindows ? 'path1;path2' : 'path1:path2'
      });
    });

    test('vars', () {
      final ShellEnvironment env = ShellEnvironment.empty();
      env.vars['VAR1'] = 'var1';
      env.paths.add('path1');

      expect(env, {'VAR1': 'var1', 'PATH': 'path1'});
      env.vars.clear();
      env.vars.remove('PATH');
      expect(env, {'PATH': 'path1'});

      env.vars.addAll({'VAR2': 'var2', 'PATH': 'path2', 'VAR3': 'var3'});
      expect(env, {'PATH': 'path1', 'VAR2': 'var2', 'VAR3': 'var3'});
      env.vars.remove('VAR2');
      env.vars.remove('VAR4');
      expect(env, {
        'PATH': 'path1',
        'VAR3': 'var3',
      });
      env.paths.remove('path1');
      env.paths.remove('path2');
      expect(env, {
        'VAR3': 'var3',
      });
    });
    test('prepend', () {
      final ShellEnvironment env = ShellEnvironment.empty();
      env.paths.addAll(['path2', 'path3']);
      env.paths.prepend('path1');
      env.paths.remove('path3');

      expect(env, {
        envPathKey: ['path1', 'path2'].join(envPathSeparator)
      });
    });

    test('non empty paths', () {
      final ShellEnvironment env = ShellEnvironment(environment: {'PATH': 'test'});
      env.paths.addAll(['path2']);

      env.paths.prepend('path1');
      env.paths.addAll(['path3']);
      env.paths.remove('path3');

      expect(env, {
        envPathKey: ['path1', 'test', 'path2'].join(envPathSeparator)
      });
    });

    test('global vars ', () async {
      final Map<String, String> _prev = shellEnvironment;
      expect(shellEnvironment, isNotEmpty);
      final Shell shell = Shell(verbose: false);
      final ShellEnvironment env = ShellEnvironment()
        ..vars['TEST_PROCESS_RUN_VAR1'] = 'test_process_run_value1';

      final ShellEnvironment result = await getEchoEnv(shell);

      // expect(result, {});
      expect(result.vars['TEST_PROCESS_RUN_VAR1'], isNull);

      try {
        // Set globally
        shellEnvironment = env;

        // print(shellEnvironment);

        // Create the shell after
        final Shell shell = Shell(verbose: false);
        final ShellEnvironment result = await getEchoEnv(shell);

        // expect(result, {});
        expect(result.vars['TEST_PROCESS_RUN_VAR1'], 'test_process_run_value1');
      } finally {
        shellEnvironment = _prev;
      }
    }); // not working

    test('local vars', () async {
      final ShellEnvironment env = ShellEnvironment()
        ..vars['TEST_PROCESS_RUN_VAR1'] = 'test_process_run_value1';
      Shell localShell = Shell(environment: env, verbose: false);
      final Shell shell = Shell(verbose: false);

      final ShellEnvironment result = await getEchoEnv(shell);
      expect(result.vars['TEST_PROCESS_RUN_VAR1'], isNull);

      final ShellEnvironment resultWithParent = await getEchoEnv(localShell);
      expect(resultWithParent.vars['TEST_PROCESS_RUN_VAR1'],
          'test_process_run_value1',);

      localShell = Shell(environment: env, includeParentEnvironment: false);
      final ShellEnvironment resultWithoutParent = await getEchoEnv(localShell);
      expect(resultWithoutParent.vars['TEST_PROCESS_RUN_VAR1'],
          'test_process_run_value1',);
    });

    test('local one var', () async {
      try {
        final ShellEnvironment env = ShellEnvironment.empty()
          ..vars['TEST_PROCESS_RUN_VAR1'] = 'test_process_run_value1';
        Shell shell = Shell(environment: env, verbose: false);

        debugPrint(getEchoEnv(shell).toString());

        shell = Shell(
            environment: env,
            includeParentEnvironment: false,
            verbose: true,); // This should be small
        final ShellEnvironment resultWithoutParent = await getEchoEnv(shell);
        debugPrint(resultWithoutParent.toString());

        final ShellEnvironment result = await getEchoEnv(shell);

        // expect(result, {});
        expect(result.vars['TEST_PROCESS_RUN_VAR1'], 'test_process_run_value1');

        await shell.run('dart --version');
      } catch (e) {
        stderr.writeln('empty environment test error $e');
        stderr.writeln('could fail on CI');
      }
    });

    // ignore: non_constant_identifier_names
    const String current_dir = 'current_dir';
    test('which', () async {
      const String dart = 'dart';
      ShellEnvironment env = ShellEnvironment.empty();
      expect(await env.which(dart), isNull);
      expect(await env.which(current_dir), isNull);
      env.paths.add('test/src');
      expect(await env.which(current_dir), isNotNull);

      env = ShellEnvironment();
      expect(await env.which(dart), isNotNull);
    });

    test('global path', () async {
      // Don't test if there is a global current_id
      if (whichSync(current_dir) != null) {
        stderr.writeln('Global current_dir found, skipping');
      }
      final Map<String, String> _prev = shellEnvironment;
      expect(shellEnvironment, isNotEmpty);

      final Shell shell = Shell();
      try {
        await shell.run(current_dir);
        fail('should fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }

      final ShellEnvironment newEnvironment = ShellEnvironment.empty()..paths.add('test/src');

      try {
        // Set globally
        shellEnvironment = newEnvironment;

        final Shell shell = Shell();
        await shell.run(current_dir);
      } finally {
        shellEnvironment = _prev;
      }
    });
    test('local empty include parent', () async {
      const String git = 'git';
      if (await which(git) != null) {
        final ShellEnvironment env = ShellEnvironment.empty();
        expect(await env.which(git), isNull);
        Shell shell = Shell(
            environment: env,
            includeParentEnvironment:
                false,); // Shell(environment: env, includeParentEnvironment: false);

        try {
          await shell.run('git --version');
          fail('Should fail');
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }

        shell = Shell(environment: env, includeParentEnvironment: true);

        await shell.run('git --version');
      }
    },
        skip:
            true,); // It does not seem to prevent calling git although not in the path
    test('equals', () async {
      expect(ShellEnvironment.empty(), ShellEnvironment.empty());
    });
    test('toJson', () async {
      expect(ShellEnvironment.empty().toJson(),
          <String,dynamic>{'paths': <dynamic>[], 'vars': <dynamic>{}, 'aliases': <dynamic>{}},);
      expect(basicEnv.toJson(), <String,dynamic>{
        'paths': <String>['path1'],
        'vars': {'VAR1': 'var1'},
        'aliases': {'alias1': 'command1'}
      });
    });
    test('fromJson', () async {
      expect(
          ShellEnvironment.fromJson({
            'paths': ['path1'],
            'vars': {'VAR1': 'var1'},
            'aliases': {'alias1': 'command1'}
          }),
          basicEnv,);
      expect(ShellEnvironment.fromJson({}), emptyEnv);
    });
    test('merge', () {
      final ShellEnvironment env = ShellEnvironment.empty();

      env.vars.addAll({'VAR1': 'var1', 'VAR2': 'value2'});
      env.paths.addAll(['path_fourth', 'path_second']);

      final ShellEnvironment envOther = ShellEnvironment.empty();

      envOther.vars.addAll({'VAR2': 'new_value2', 'VAR3': 'var3'});
      envOther.paths.addAll([
        'path_first',
        'path_second',
        'path_third',
      ]);
      env.merge(envOther);
      expect(env, {
        'VAR1': 'var1',
        'VAR2': 'new_value2',
        'PATH': ['path_first', 'path_second', 'path_third', 'path_fourth']
            .join(envPathSeparator),
        'VAR3': 'var3'
      });
    });
    test('path merge', () {
      ShellEnvironmentPaths paths = ShellEnvironment().paths;
      paths.merge(paths);
      ShellEnvironment env = ShellEnvironment.full(
          environment: shellEnvironment, includeParentEnvironment: true,);
      paths = env.paths;
      paths.merge(paths);

      env = ShellEnvironment();
      paths = env.paths;
      paths.merge(paths);

      paths = ShellEnvironment.empty().paths;
      paths.add('1');
      paths.prepend('0');
      paths.add('2');
      paths.addAll(['3', '4']);
      expect(paths, ['0', '1', '2', '3', '4']);
      paths.insertAll(0, ['1', '4']);
      paths.addAll(paths);
      // Shoud be ignored
      paths.addAll(['3', '4']);
      expect(paths, ['1', '4', '0', '2', '3']);
      paths.merge(paths);
      expect(paths, ['1', '4', '0', '2', '3']);
    });
  });

  test('overriding', () async {
    final Map<String, String> _prev = shellEnvironment;
    try {
      final ShellEnvironment env = ShellEnvironment()..paths.prepend('T1');
      shellEnvironment = env;
      expect(ShellEnvironment().paths.first, 'T1');
    } finally {
      shellEnvironment = _prev;
    }
  });
}

/// Better with non verbose shell.
Future<ShellEnvironment> getEchoEnv(Shell shell) async {
  return ShellEnvironment.fromJson(
      jsonDecode((await shell.run('$echo --all-env')).outLines.join()) as Map?,);
}
