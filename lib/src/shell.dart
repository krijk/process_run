// ignore_for_file: avoid_unused_constructor_parameters
// ignore_for_file: parameter_assignments
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:synchronized/synchronized.dart';

import '/cmd_run.dart';
import '/shell.dart';
import '/src/process_run.dart';
import '/src/shell_common.dart'
    show ShellOptions, shellDebug;
import '/src/shell_utils.dart';
import 'common/import.dart';

export 'shell_common.dart' show shellDebug;

///
/// Run one or multiple plain text command(s).
///
/// Commands can be splitted by line.
///
/// Commands can be on multiple line if ending with ' ^' or ' \'.
///
/// Returns a list of executed command line results. Verbose by default.
///
///
/// ```dart
/// await run('flutter build');
/// await run('dart --version');
/// await run('''
///  dart --version
///  git status
/// ''');
/// ```
Future<List<ProcessResult>> run(
  String script, {
  bool throwOnError = true,
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool? runInShell,
  Encoding stdoutEncoding = systemEncoding,
  Encoding stderrEncoding = systemEncoding,
  Stream<List<int>>? stdin,
  StreamSink<List<int>>? stdout,
  StreamSink<List<int>>? stderr,
  bool verbose = true,

  // Default to true
  bool? commandVerbose,
  // Default to true if verbose is true
  bool? commentVerbose,
  void Function(Process process)? onProcess,
}) {
  return Shell(
          throwOnError: throwOnError,
          workingDirectory: workingDirectory,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment,
          runInShell: runInShell,
          stdoutEncoding: stdoutEncoding,
          stderrEncoding: stderrEncoding,
          stdin: stdin,
          stdout: stdout,
          stderr: stderr,
          verbose: verbose,
          commandVerbose: commandVerbose,
          commentVerbose: commentVerbose,)
      .run(script, onProcess: onProcess);
}

/// Multiplatform Shell utility to run a script with multiple commands.
///
/// Extra path/env can be loaded using ~/.config/tekartik/process_run/env.yaml
///
/// ```
/// path: ~/bin
/// ```
///
/// or
///
/// ```
/// path:
///   - ~/bin
///   - ~/Android/Sdk/tools/bin
/// env:
///   ANDROID_TOP: ~/Android
///   FIREBASE_TOP: ~/.firebase
/// ```
///
/// A list of ProcessResult is returned
///
class Shell {
  final bool _throwOnError;
  final String? _workingDirectory;
  ShellEnvironment? _environment;
  final bool? _runInShell;
  final Encoding _stdoutEncoding;
  final Encoding _stderrEncoding;
  final Stream<List<int>>? _stdin;
  final StreamSink<List<int>>? _stdout;
  final StreamSink<List<int>>? _stderr;
  final bool _verbose;
  final bool _commandVerbose;
  final bool _commentVerbose;

  /// Incremental internal runId
  int _runId = 0;

  /// Killed runId. would kill any process with a lower run id
  int _killedRunId = 0;

  /// Current kill process signal
  late ProcessSignal _killedProcessSignal;

  /// Current child process running.
  Process? _currentProcess;

  ProcessCmd? _currentProcessCmd;
  int? _currentProcessRunId;

  /// Parent shell for pushd/popd
  Shell? _parentShell;

  /// Get it only once
  List<String>? _userPathsCache;

  /// Resolve environment
  List<String> get _userPaths =>
      _userPathsCache ??= List<String>.from(_environment!.paths);

  /// [throwOnError] means that if an exit code is not 0, it will throw an error
  ///
  /// Unless specified [runInShell] will be false. However on windows, it will
  /// default to true for non .exe files
  ///
  /// if [verbose] is not false or [commentVerbose] is true, it will display the
  /// comments as well
  Shell(
      {bool throwOnError = true,
      String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool? runInShell,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding,
      Stream<List<int>>? stdin,
      StreamSink<List<int>>? stdout,
      StreamSink<List<int>>? stderr,
      bool verbose = true,
      // Default to true
      bool? commandVerbose,
      // Default to false
      bool? commentVerbose,
      ShellOptions? options,})
      : _throwOnError = throwOnError,
        _workingDirectory = workingDirectory,
        _runInShell = runInShell,
        _stdoutEncoding = stdoutEncoding,
        _stderrEncoding = stderrEncoding,
        _stdin = stdin,
        _stdout = stdout,
        _stderr = stderr,
        _verbose = verbose,
        _commandVerbose = commandVerbose ?? verbose,
        _commentVerbose = commentVerbose ?? false {
    // Fix environment right away
    _environment = ShellEnvironment.full(
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,);
  }

  /// Create a new shell
  Shell clone(
      {bool? throwOnError,
      String? workingDirectory,
      // Don't change environment
      @Deprecated("Don't change map")
          Map<String, String>? environment,
      @Deprecated("Don't change includeParentEnvironment")
          // Don't change includeParentEnvironment
          bool? includeParentEnvironment,
      bool? runInShell,
      Encoding? stdoutEncoding,
      Encoding? stderrEncoding,
      Stream<List<int>>? stdin,
      StreamSink<List<int>>? stdout,
      StreamSink<List<int>>? stderr,
      bool? verbose,
      bool? commandVerbose,
      bool? commentVerbose,}) {
    return Shell(
        verbose: verbose ?? _verbose,
        environment: _environment,
        runInShell: runInShell ?? _runInShell,
        commandVerbose: commandVerbose ?? _commandVerbose,
        commentVerbose: commentVerbose ?? _commentVerbose,
        includeParentEnvironment: false,
        stderr: stderr ?? _stderr,
        stderrEncoding: stderrEncoding ?? _stderrEncoding,
        stdin: stdin ?? _stdin,
        stdout: stdout ?? _stdout,
        stdoutEncoding: stdoutEncoding ?? _stdoutEncoding,
        throwOnError: throwOnError ?? _throwOnError,
        workingDirectory: workingDirectory ?? _workingDirectory,);
  }

  /// non null
  String get _workingDirectoryPath =>
      _workingDirectory ?? Directory.current.path;

  /// Create new shell at the given path
  Shell cd(String path) {
    if (isRelative(path)) {
      path = join(_workingDirectoryPath, path);
    }
    if (_commandVerbose) {
      streamSinkWriteln(_stdout ?? stdout, '\$ cd $path',
          encoding: _stdoutEncoding,);
    }
    return clone(workingDirectory: path);
  }

  /// Get the shell path, using workingDirectory or current directory if null.
  String get path => _workingDirectoryPath;

  /// Create a new shell at the given path, allowing popd on it
  Shell pushd(String path) => cd(path).._parentShell = this;

  /// Pop the current directory to get the previous shell
  /// throw State error if nothing in the stack
  Shell popd() {
    if (_parentShell == null) {
      throw StateError('no previous shell');
    }
    if (_commandVerbose) {
      stdout.writeln('\$ cd ${_parentShell!._workingDirectoryPath}');
    }
    return _parentShell!;
  }

  /// Kills the current running process.
  ///
  /// Returns `true` if the signal is successfully delivered to the process.
  /// Otherwise the signal could not be sent, usually meaning,
  /// that the process is already dead.
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    // Picked the current 'timestamp' of the run killed
    _killedRunId = _runId;
    _killedProcessSignal = signal;
    return _kill();
  }

  bool _kill() {
    if (_currentProcess != null) {
      io.stderr.writeln('killing $_killedRunId, ${_currentProcessToString()}');
      final bool result = _currentProcess!.kill(_killedProcessSignal);
      _clearPreviousContext();
      return result;
    } else if (_currentProcessResultCompleter != null) {
      _clearPreviousContext();
      return false;
    } else {
      io.stderr.writeln('Killing $_killedRunId');
      return false;
    }
  }

  ///
  /// Run one or multiple plain text command(s).
  ///
  /// Commands can be splitted by line.
  ///
  /// Commands can be on multiple line if ending with ' ^' or ' \'. (note that \
  /// must be escaped too so you might have to enter \\).
  ///
  /// Returns a list of executed command line results.
  ///
  /// [onProcess] is called for each started process.
  ///
  Future<List<ProcessResult>> run(String script,
      {void Function(Process process)? onProcess,}) {
    // devPrint('Running $script');
    return _runLocked((int runId) async {
      final List<String?> commands = scriptToCommands(script);

      final List<ProcessResult> processResults = <ProcessResult>[];
      for (final String? command in commands) {
        if (_killedRunId >= runId) {
          throw ShellException('Script was killed', null);
        }
        // Display the comments
        if (isLineComment(command!)) {
          if (_commentVerbose) {
            stdout.writeln(command);
          }
          continue;
        }
        List<String> parts = shellSplit(command);
        String executable = parts[0];
        List<String> arguments = parts.sublist(1);

        // Find alias
        final String? alias = _environment!.aliases[executable];
        if (alias != null) {
          // The alias itself should be split
          parts = shellSplit(alias);
          executable = parts[0];
          arguments = <String>[...parts.sublist(1), ...arguments];
        }
        final ProcessResult processResult = await _lockedRunExecutableArguments(
            runId, executable, arguments,
            onProcess: onProcess,);
        processResults.add(processResult);
      }

      return processResults;
    });
  }

  final Lock _runLock = Lock();

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Returns a process result (or throw if specified in the shell).
  ///
  /// [onProcess] is called for each started process.
  Future<ProcessResult> runExecutableArguments(
      String executable, List<String> arguments,
      {void Function(Process process)? onProcess,}) async {
    return _runLocked((int runId) async {
      return _lockedRunExecutableArguments(runId, executable, arguments,
          onProcess: onProcess,);
    });
  }

  Future<T> _runLocked<T>(FutureOr<T> Function(int runId) action) {
    // devPrint('Previous: ${_currentProcessToString()}');
    final int runId = ++_runId;
    return _runLock.synchronized(() async {
      // devPrint('Running $runId');
      return action(runId);
    });
  }

  String _currentProcessToString() {
    return 'runId:$_currentProcessRunId${_currentProcess == null ? '' : ', process: ${_currentProcess?.pid}: $_currentProcessRunId $_currentProcessCmd'}';
  }

  Completer<ProcessResult>? _currentProcessResultCompleter;

  void _clearPreviousContext() {
    if (shellDebug) {
      debugPrint(
          'Clear previous context ${_currentProcessResultCompleter?.isCompleted}',);
    }
    if (!(_currentProcessResultCompleter?.isCompleted ?? true)) {
      _currentProcessResultCompleter!
          .completeError(ShellException('Killed by framework', null));
    }
    _currentProcessResultCompleter = null;
  }

  /// Run a single [executable] with [arguments], resolving the [executable] if needed.
  ///
  /// Call onProcess upon process startup
  ///
  /// Returns a process result (or throw if specified in the shell).
  Future<ProcessResult> _lockedRunExecutableArguments(
      int runId, String executable, List<String> arguments,
      {void Function(Process process)? onProcess,}) {
    try {
      _clearPreviousContext();
      final Completer<ProcessResult> completer =
          _currentProcessResultCompleter = Completer<ProcessResult>();

      Future<ProcessResult?> run() async {
        ProcessResult? processResult;

        final String executableFullPath =
            findExecutableSync(executable, _userPaths) ?? executable;

        final _ProcessCmd processCmd = _ProcessCmd(executableFullPath, arguments,
            executableShortName: executable,)
          ..runInShell = _runInShell
          ..environment = _environment
          ..includeParentEnvironment = false
          ..stderrEncoding = _stderrEncoding
          ..stdoutEncoding = _stdoutEncoding
          ..workingDirectory = _workingDirectory;
        try {
          if (shellDebug) {
            debugPrint('$_runId: Before $processCmd');
          }
          try {
            processResult = await processCmdRun(processCmd,
                verbose: _verbose,
                commandVerbose: _commandVerbose,
                stderr: _stderr,
                stdin: _stdin,
                stdout: _stdout, onProcess: (Process process) {
              _currentProcess = process;
              _currentProcessCmd = processCmd;
              _currentProcessRunId = runId;
              if (shellDebug) {
                debugPrint('onProcess ${_currentProcessToString()}');
              }
              if (onProcess != null) {
                onProcess(process);
              }
              if (_killedRunId >= _runId) {
                if (shellDebug) {
                  debugPrint('shell was killed');
                }
                _kill();
                return;
              }
            },);
          } finally {
            if (shellDebug) {
              debugPrint(
                  '$_runId: After $processCmd exitCode ${processResult?.exitCode}',);
            }
          }
          // devPrint('After $processCmd');
          if (_throwOnError && processResult.exitCode != 0) {
            throw ShellException(
                '$processCmd, exitCode ${processResult.exitCode}, workingDirectory: $_workingDirectoryPath',
                processResult,);
          }
        } on ProcessException catch (e) {
          final StreamSink<List<int>> stderr = _stderr ?? io.stderr;
          void _writeln([String? msg]) {
            stderr.add(utf8.encode(msg ?? ''));
            stderr.add(utf8.encode('\n'));
          }

          final String workingDirectory =
              processCmd.workingDirectory ?? Directory.current.path;

          _writeln();
          if (!Directory(workingDirectory).existsSync()) {
            _writeln('Missing working directory $workingDirectory');
          } else {
            _writeln('''
  Check that $executableFullPath exists
    command: $processCmd''',);
          }
          _writeln();

          throw ShellException(
              '$processCmd, error: $e, workingDirectory: $_workingDirectoryPath',
              null,);
        }

        return processResult;
      }

      run().then((ProcessResult? value) {
        if (shellDebug) {
          debugPrint('$runId: done');
        }
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      }).catchError((dynamic e) {
        if (shellDebug) {
          debugPrint('$runId: error $e');
        }
        if (!completer.isCompleted) {
          completer.completeError(e as Object);
        }
      });
      return completer.future;
    } finally {
      _currentProcess = null;
    }
  }
}

// Simplify toString to avoid the full path got with which
class _ProcessCmd extends ProcessCmd {
  final String executableShortName;

  _ProcessCmd(String executable, List<String> arguments,
      {required this.executableShortName,})
      : super(executable, arguments);

  @override
  String toString() =>
      executableArgumentsToString(executableShortName, arguments);
}

/// Exception thrown in exitCode != 0 and throwOnError is true
class ShellException implements Exception {
  final ProcessResult? result;
  final String message;

  ShellException(this.message, this.result);

  @override
  String toString() => 'ShellException($message)';
}
