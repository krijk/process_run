import 'dart:convert';
import 'dart:io';

String getShellCmdBinFileName(String command) =>
    '$command${Platform.isWindows ? '.bat' : ''}';

//
// [data] can be map a list
// if it is a string, it will try to parse it first
//
String? jsonPretty(dynamic data) {
  if (data is String) {
    final dynamic parsed = jsonDecode(data);
    if (parsed != null) {
      try {
        return const JsonEncoder.withIndent('  ').convert(parsed);
      } catch (e) {
        return 'Err: $e decoding $parsed';
      }
    }
  }
  return null;
}
