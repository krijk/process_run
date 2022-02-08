import 'dart:io';

import '/src/shell_context_common.dart';
import '/src/shell_context_io.dart';

bool get platformIoIsWindows => Platform.isWindows;

/// Global shell context
ShellContext shellContext = ShellContextIo();
