// ignore_for_file: always_specify_types
// ignore_for_file: parameter_assignments
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '/shell.dart';
import '/src/shell.dart';
import '/src/shell_utils.dart' as utils;
import '/src/shell_utils.dart';

import 'common/import.dart';

///
/// if [commmandVerbose] or [verbose] is true, display the command.
/// if [verbose] is true, stream stdout & stdin
///
/// Optional [onProcess(process)] is called to allow killing the process.
///
/// Don't mess-up with the input and output for now here. only use it for kill.
Future<ProcessResult> runExecutableArguments(
    String executable, List<String> arguments,
    {String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool? runInShell,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
    Stream<List<int>>? stdin,
    StreamSink<List<int>>? stdout,
    StreamSink<List<int>>? stderr,
    bool? verbose,
    bool? commandVerbose,
    void Function(Process process)? onProcess,}) async {
  if (verbose == true) {
    commandVerbose = true;
    stdout ??= io.stdout;
    stderr ??= io.stderr;
  }

  if (commandVerbose == true) {
    utils.streamSinkWriteln(stdout ?? io.stdout,
        '\$ ${executableArgumentsToString(executable, arguments)}',
        encoding: stdoutEncoding,);
  }

  // Build our environment
  final ShellEnvironment shellEnvironment = ShellEnvironment.full(
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,);

  // Default is the full command
  final String executableShortName = executable;

  // Find executable if needed, i.e. if it is only a name
  if (basename(executable) == executable) {
    // Try to find it in path or use it as is
    executable = utils.findExecutableSync(executable, shellEnvironment.paths) ??
        executable;
  }

  // Fix runInShell on windows (force run in shell for non-.exe)
  runInShell = utils.fixRunInShell(runInShell, executable);

  Process process;
  try {
    process = await Process.start(executable, arguments,
        workingDirectory: workingDirectory,
        environment: shellEnvironment,
        includeParentEnvironment: false,
        runInShell: runInShell,);
    if (shellDebug) {
      debugPrint('process: ${process.pid}');
    }
    if (onProcess != null) {
      onProcess(process);
    }
    if (shellDebug) {
      // ignore: unawaited_futures
      () async {
        try {
          final int exitCode = await process.exitCode;
          debugPrint('process: ${process.pid} exitCode $exitCode');
        } catch (e) {
          debugPrint('process: ${process.pid} Error $e waiting exit code');
        }
      }();
    }
  } catch (e) {
    if (verbose == true) {
      io.stderr.writeln(e);
      io.stderr.writeln(
          '\$ ${executableArgumentsToString(executableShortName, arguments)}',);
      io.stderr.writeln(
          'workingDirectory: ${workingDirectory ?? Directory.current.path}',);
    }
    rethrow;
  }

  final StreamController<List<int>> outCtlr = StreamController<List<int>>(sync: true);
  final StreamController<List<int>> errCtlr = StreamController<List<int>>(sync: true);

  // Connected stdin
  // Buggy!
  StreamSubscription? stdinSubscription;
  if (stdin != null) {
    //stdin.pipe(process.stdin); // this closes the stream...
    stdinSubscription = stdin.listen((List<int> data) {
      process.stdin.add(data);
    })
      ..onDone(() {
        process.stdin.close();
      });
    // OLD 2: process.stdin.addStream(stdin);
  } else {
    // Close the input sync, we want this not interractive
    //process.stdin.close();
  }

  Future<dynamic> streamToResult(
      Stream<List<int>> stream, Encoding? encoding,) async {
    final List<int> list = <int>[];
    await for (final List<int> data in stream) {
      //devPrint('s: ${data}');
      list.addAll(data);
    }
    if (encoding != null) {
      return encoding.decode(list);
    }
    return list;
  }

  final Future out = streamToResult(outCtlr.stream, stdoutEncoding);
  final Future err = streamToResult(errCtlr.stream, stderrEncoding);

  process.stdout.listen((List<int> d) {
    if (stdout != null) {
      stdout.add(d);
    }
    outCtlr.add(d);
  }, onDone: () {
    outCtlr.close();
  },);

  process.stderr.listen((List<int> d) async {
    if (stderr != null) {
      stderr.add(d);
    }
    errCtlr.add(d);
  }, onDone: () {
    errCtlr.close();
  },);

  final int exitCode = await process.exitCode;

  /// Cancel input sink
  if (stdinSubscription != null) {
    await stdinSubscription.cancel();
  }

  // Notice that exitCode can complete before all of the lines of output have been
  // processed. Also note that we do not explicitly close the process. In order
  // to not leak resources we have to drain both the stderr and the stdout streams.
  // To do that we set a listener (using await for) to drain the stderr stream.
  //await process.stdout.drain();
  //await process.stderr.drain();

  final io.ProcessResult result = ProcessResult(process.pid, exitCode, await out, await err);

  if (stdin != null) {
    //process.stdin.close();
  }

  // flush for consistency
  if (stdout == io.stdout) {
    await io.stdout.safeFlush();
  }
  if (stderr == io.stderr) {
    await io.stderr.safeFlush();
  }

  return result;
}

/// Convenient way to display a command
String executableArgumentsToString(
    String? executable, List<String>? arguments,) {
  final StringBuffer sb = StringBuffer();
  if (Platform.isWindows && (basename(executable!) == executable)) {
    final String ext = extension(executable);
    switch (ext) {
      case '.exe':
      case '.bat':
      case '.cmd':
      case '.com':
        executable = executable.substring(0, executable.length - 4);
    }
  }
  sb.write(executable);
  if (arguments is List && arguments!.isNotEmpty) {
    sb.write(' ${argumentsToString(arguments)}');
  }
  return sb.toString();
}

/// Command runner. not exported

/// Execute a predefined ProcessCmd command
///
/// if [commandVerbose] is true, it writes the command line executed preceeded by $ to stdout. It streams
/// stdout/error if [verbose] is true.
/// [verbose] implies [commandVerbose]
///
Future<ProcessResult> processCmdRun(ProcessCmd cmd,
    {bool? verbose,
    bool? commandVerbose,
    Stream<List<int>>? stdin,
    StreamSink<List<int>>? stdout,
    StreamSink<List<int>>? stderr,
    void Function(Process process)? onProcess,}) async {
  if (verbose == true) {
    stdout ??= io.stdout;
    stderr ??= io.stderr;
    commandVerbose ??= true;
  }

  if (commandVerbose == true) {
    streamSinkWriteln(stdout ?? io.stdout, '\$ $cmd',
        encoding: cmd.stdoutEncoding,);
  }

  try {
    return await runExecutableArguments(cmd.executable!, cmd.arguments,
        workingDirectory: cmd.workingDirectory,
        environment: cmd.environment,
        includeParentEnvironment: cmd.includeParentEnvironment,
        runInShell: cmd.runInShell,
        stdoutEncoding: cmd.stdoutEncoding,
        stderrEncoding: cmd.stderrEncoding,
        //verbose: verbose,
        //commandVerbose: commandVerbose,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        onProcess: onProcess,);
  } catch (e) {
    if (verbose == true) {
      io.stderr.writeln(e);
      io.stderr.writeln('\$ $cmd');
      io.stderr.writeln(
          'workingDirectory: ${cmd.workingDirectory ?? Directory.current.path}',);
    }
    rethrow;
  }
}
