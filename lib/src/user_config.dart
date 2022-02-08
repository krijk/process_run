// ignore_for_file: always_specify_types
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import '/shell.dart';
import '/src/common/constant.dart';
import '/src/dartbin_impl.dart';
import '/src/script_filename.dart';
import '/src/shell_utils.dart';
import 'common/import.dart';

/// Supported path keys
List<String> userConfigPathKeys = <String>['path', 'paths'];

/// Supported var keys
List<String> userConfigVarKeys = <String>['var', 'vars'];

/// Supported alias keys
List<String> userConfigAliasKeys = <String>['alias', 'aliases'];

class UserConfig {
  /// never null
  final Map<String, String> vars;

  /// never null
  final List<String> paths;

  /// never null
  final Map<String, String> aliases;

  UserConfig(
      {Map<String, String>? vars,
      List<String>? paths,
      Map<String, String>? aliases,})
      : vars = vars ?? <String, String>{},
        paths = paths ?? <String>[],
        aliases = aliases ?? <String, String>{};

  @override
  String toString() =>
      '${vars.length} vars ${paths.length} paths ${aliases.length} aliases';
}

UserConfig? _userConfig;

UserConfig get userConfig =>
    _userConfig ??
    () {
      return getUserConfig(null);
    }();

/// Dev only
@protected
set userConfig(UserConfig userConfig) => _userConfig = userConfig;

///
/// Get the list of user paths used to resolve binaries location.
///
/// It includes items from the PATH environment variable.
///
/// It can be overriden to include user defined paths loaded from
/// ~/.config/tekartik/process_run/env.yam
///
/// See [https://github.com/tekartik/process_run.dart/blob/master/doc/user_config.md]
/// in the documentation for more information.
///
List<String> get userPaths => userConfig.paths;

/// Get the user environment
///
/// It includes current system user environment.
///
/// It can be overriden to include user defined variables loaded from
/// ~/.config/tekartik/process_run/env.yam
///
/// [userEnvironment] must be explicitly used as it could contain sensitive
/// information.
///
Map<String, String> get userEnvironment => ShellEnvironment.empty()
  ..vars.addAll(userConfig.vars)
  ..aliases.addAll(userConfig.aliases)
  ..paths.addAll(userConfig.paths);

// Test only
@protected
void resetUserConfig() {
  shellEnvironment = null;
  _userConfig = null;
}

class EnvFileConfig {
  final List<String> paths;
  final Map<String, String> vars;
  final Map<String, String> aliases;

  EnvFileConfig(List<String>? paths, Map<String, String>? vars,
      Map<String, String>? aliases,)
      : paths = paths ?? <String>[],
        vars = vars ?? <String, String>{},
        aliases = aliases ?? <String, String>{};

  /// Has no vars, paths nor aliases.
  bool get isEmpty => paths.isEmpty && vars.isEmpty && aliases.isEmpty;

  /// Has vars, paths or aliases.
  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toDebugMap() =>
      <String, dynamic>{'paths': paths, 'vars': vars, 'aliases': aliases};

  Future<EnvFileConfig> loadFromPath(String path) async {
    return _loadFromPath(path);
  }

  @override
  String toString() => toDebugMap().toString();
}

/// Never null, all members can be null
EnvFileConfig loadFromMap(Map<dynamic, dynamic> map) {
  final List<String> paths = <String>[];
  final Map<String, String> fileVars = <String, String>{};
  final Map<String, String> fileAliases = <String, String>{};

  try {
    // Handle added path
    // can be
    //
    // path:~/bin
    //
    // or
    //
    // path:
    //   - ~/bin
    //   - ~/Android/Sdk/tools/bin
    //

    // Add current dart path

    Object? mapKeysValue(Map map, List<String> keys) {
      for (final String key in keys) {
        final value = map[key];
        if (value != null) {
          return value;
        }
      }
      return null;
    }

    final Object? path = mapKeysValue(map, userConfigPathKeys);
    if (path is List) {
      paths.addAll(path.map((path) => expandPath(path.toString())));
    } else if (path is String) {
      paths.add(expandPath(path));
    }

    // Handle variable like
    //
    // var:
    //   ANDROID_TOP: /home/user/Android
    //   FIREBASE_TOP: /home/user/.firebase
    void _addVar(String key, String value) {
      // devPrint('$key: $value');
      fileVars[key] = value;
    }

    final Object? vars = mapKeysValue(map, userConfigVarKeys);

    if (vars is List) {
      for (final item in vars) {
        if (item is Map) {
          if (item.isNotEmpty) {
            final MapEntry entry = item.entries.first;
            final String key = entry.key.toString();
            final String value = entry.value.toString();
            _addVar(key, value);
          }
        } else {
          // devPrint(item.runtimeType);
        }
        // devPrint(item);
      }
    }
    if (vars is Map) {
      vars.forEach((key, value) {
        _addVar(key.toString(), value.toString());
      });
    }

    // Handle variable like
    //
    // alias:
    //   ll: ls -l
    //
    //  or
    //
    // alias:
    //   - ll: ls -l
    void _addAlias(String key, String value) {
      // devPrint('$key: $value');
      if (value.isNotEmpty) {
        fileAliases[key] = value;
      }
    }

    // Copy alias
    final Object? alias = mapKeysValue(map, userConfigAliasKeys);
    if (alias is List) {
      for (final item in alias) {
        if (item is Map) {
          if (item.isNotEmpty) {
            final MapEntry entry = item.entries.first;
            final String key = entry.key.toString();
            final String value = entry.value.toString();
            _addAlias(key, value);
          }
        } else {
          // devPrint(item.runtimeType);
        }
        // devPrint(item);
      }
    }
    if (alias is Map) {
      alias.forEach((key, value) {
        _addAlias(key.toString(), value.toString());
      });
    }
  } catch (e) {
    stderr.writeln('error reading yaml $e');
  }
  return EnvFileConfig(paths, fileVars, fileAliases);
}

/// Never null, all members can be null
EnvFileConfig loadFromPath(String path) => _loadFromPath(path);

EnvFileConfig _loadFromPath(String path) {
  String? fileContent;
  Map<String, String>? vars;
  Map<String, String>? aliases;
  List<String>? paths;
  try {
    // Look for any config file in ~/tekartik/process_run/env.yaml
    try {
      fileContent = File(path).readAsStringSync();
    } catch (e) {
      //  stderr.writeln('error reading env file $path $e');
    }
    if (fileContent != null) {
      final yaml = loadYaml(fileContent);
      // devPrint('yaml: $yaml');
      if (yaml is Map) {
        final EnvFileConfig config = loadFromMap(yaml);
        vars = config.vars;
        paths = config.paths;
        aliases = config.aliases;
      }
    }
  } catch (e) {
    stderr.writeln('error reading yaml $e');
  }
  return EnvFileConfig(paths, vars, aliases);
}

/// Update userPaths and userEnvironment
void userLoadEnvFile(String path) {
  userLoadEnvFileConfig(loadFromPath(path));
}

// private
void userLoadConfigMap(Map map) {
  userLoadEnvFileConfig(loadFromMap(map));
}

/// Only specify the vars to override and the paths to add
void userLoadEnv(
    {Map<String, String>? vars,
    List<String>? paths,
    Map<String, String>? aliases,}) {
  userLoadEnvFileConfig(EnvFileConfig(paths, vars, aliases));
}

// private
void userLoadEnvFileConfig(EnvFileConfig envFileConfig) {
  final UserConfig config = userConfig;
  final List<String> paths = List<String>.from(config.paths);
  final Map<String, String> vars = Map<String, String>.from(config.vars);
  final EnvFileConfig added = envFileConfig;
  // devPrint('adding config: $config');
  if (const ListEquality().equals(
      paths.sublist(0, min(added.paths.length, paths.length)), added.paths,)) {
    // don't add if already in same order at the beginning
  } else {
    paths.insertAll(0, added.paths);
  }

  added.vars.forEach((String key, String value) {
    vars[key] = value;
  });
  // Set env PATH from path
  vars[envPathKey] = paths.join(envPathSeparator);
  userConfig = UserConfig(vars: vars, paths: paths);
}

/// Returns the matching flutter ancestor if any
String? getFlutterAncestorPath(String dartSdkBinDirPath) {
  try {
    String parent = dartSdkBinDirPath;
    if (basename(parent) == 'bin') {
      parent = dirname(parent);
      if (basename(parent) == 'dart-sdk') {
        parent = dirname(parent);
        if (basename(parent) == 'cache') {
          parent = dirname(parent);
          if (basename(parent) == 'bin') {
            return parent;
          }
        }
      }
    }
  } catch (_) {}

  // Second test, check if flutter is at path in this case
  // dart sdk comes from flutter dart path
  try {
    if (File(join(dartSdkBinDirPath, getBashOrBatExecutableFilename('flutter')))
        .existsSync()) {
      return dartSdkBinDirPath;
    }
  } catch (_) {}
  return null;
}

/// Get config map
UserConfig getUserConfig(Map<String, String>? environment) {
  /// Init a platform environment
  final ShellEnvironment shEnv = ShellEnvironment(environment: environment ?? platformEnvironment);

  // Copy to environment used to resolve progressively
  void addConfig(String path) {
    final EnvFileConfig config = loadFromPath(path);
    final ShellEnvironment configShEnv = ShellEnvironment.empty();
    if (config.isNotEmpty) {
      configShEnv
        ..vars.addAll(config.vars)
        ..paths.addAll(config.paths)
        ..aliases.addAll(config.aliases);
      shEnv.merge(configShEnv);
    }
  }

  // Add user config first (it will be eventually overwritten by local config)
  addConfig(getUserEnvFilePath(shEnv)!);

  // Prepend local dart environment
  // Always prepend dart executable so that dart runner context is used first

  // Don't use global dartExecutable since it will trigger a call to userConfig
  final String? dartExecutable =
      platformResolvedExecutable ?? resolveDartExecutable(environment: shEnv);
  if (dartExecutable != null) {
    final String dartBinPath = dirname(dartExecutable);

    // Add dart path so that dart commands always work!
    shEnv.paths.prepend(dartBinPath);

    // Flutter path must be before any other dart directoy as it'd better matches
    // Add flutter path if path matches:
    // /flutter/bin/cache/dart-sdk/bin
    final String? flutterBinPath = getFlutterAncestorPath(dartBinPath);
    if (flutterBinPath != null) {
      shEnv.paths.prepend(flutterBinPath);
    }
  }

  // Add local config using our environment that might have been updated
  addConfig(getLocalEnvFilePath(shEnv));

  return UserConfig(
      paths: shEnv.paths, vars: shEnv.vars, aliases: shEnv.aliases,);
}

// Fix environment with global settings and current dart sdk
List<String> getUserPaths(Map<String, String> environment) =>
    getUserConfig(environment).paths;

/// Get the user env file path
String? getUserEnvFilePath([Map<String, String>? environment]) {
  environment ??= platformEnvironment;
  // devPrint((Map<String, String>.from(environment)..removeWhere((key, value) => !key.toLowerCase().contains('teka'))).keys);
  return environment[userEnvFilePathEnvKey] ??
      join(userAppDataPath, 'tekartik', 'process_run', 'env.yaml');
}

/// Get the local env file path
///
/// Must be called after loading the env vars
String getLocalEnvFilePath([Map<String, String>? environment]) {
  environment ??= platformEnvironment;

  final String subDir = environment[localEnvFilePathEnvKey] ?? localEnvFilePathDefault;
  return join(Directory.current.path, subDir);
}

final String localEnvFilePathDefault = joinAll(<String>['.local', 'ds_env.yaml']);
final String localEnvFilePathDefaultOld =
    joinAll(<String>['.dart_tool', 'process_run', 'env.yaml']);
