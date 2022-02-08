import '/src/shell_context_common.dart';

/// Only true for IO windows
bool get platformIoIsWindows => false;

ShellContext? _shellContext;

/// Must be set before use
ShellContext get shellContext {
  if (_shellContext == null) {
    throw StateError('shellContext must be set before use');
  }
  return _shellContext!;
}

/// Set shell context before use
set shellContext(ShellContext shellContext) => _shellContext = shellContext;
