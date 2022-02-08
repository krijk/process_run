import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import '/shell.dart' as ds;
import '/src/shell.dart' as io;
import '/src/shell_common.dart';
import '/src/shell_common_io.dart';
import '/src/shell_context_common.dart';
import '/src/shell_environment.dart' as io;
import '/src/shell_environment_common.dart';

class ShellContextIo implements ShellContext {
  @override
  ShellEnvironment get shellEnvironment =>
      io.ShellEnvironment(environment: ds.shellEnvironment);

  @override
  p.Context get path => p.context;

  @override
  Future<String?> which(String command,
          {ShellEnvironment? environment,
          bool includeParentEnvironment = true,}) =>
      ds.which(command,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment,);

  @override
  Encoding get encoding => systemEncoding;

  @override
  ShellEnvironment newShellEnvironment({Map<String, String>? environment}) {
    return io.ShellEnvironment(environment: environment);
  }

  @override
  Shell newShell(
      {ShellOptions? options,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,}) {
    final ds.Shell ioShell = io.Shell(
        options: options,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,);
    return ShellIo(impl: ioShell);
  }
}
