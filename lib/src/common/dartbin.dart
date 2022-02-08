import 'dart:io';

import 'package:path/path.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

import '/src/dartbin_cmd.dart';
import '/src/dartbin_impl.dart';

///
/// Get dart vm either from executable or using the which command
///
String? get dartExecutable => resolvedDartExecutable;

String get dartSdkBinDirPath => dirname(dartExecutable!);

String get dartSdkDirPath => dirname(dartSdkBinDirPath);

Version? _dartVersion;

/// Current dart platform version
Version get dartVersion =>
    _dartVersion ??= parsePlatformVersion(Platform.version);

String? _dartChannel;

/// Current dart platform channel
String get dartChannel =>
    _dartChannel ??= parsePlatformChannel(Platform.version);

/// Stable channel.
const String dartChannelStable = 'stable';

/// Beta channel.
const String dartChannelBeta = 'beta';

/// Dev channel.
const String dartChannelDev = 'dev';

/// Master channel.
const String dartChannelMaster = 'master';
