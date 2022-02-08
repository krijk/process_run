import 'dart:io';

void dumpStringMap(Map<String, String> map) {
  final List<String> keys = map.keys.toList()
    ..sort((String t1, String t2) => t1.toLowerCase().compareTo(t2.toLowerCase()));
  for (final String key in keys) {
    final String? value = map[key];
    stdout.writeln('$key: $value');
  }
}

void dumpStringList(List<String?> list) {
  for (final String? item in list) {
    stdout.writeln('$item');
  }
}
