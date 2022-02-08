// ignore_for_file: avoid_positional_boolean_parameters
import 'package:flutter/material.dart';

/// Development helpers to generate warning in code

void _devPrint(Object object) {
  if (_devPrintEnabled) {
    debugPrint(object.toString());
  }
}

bool _devPrintEnabled = true;

@Deprecated('Dev only')
set devPrintEnabled(bool enabled) => _devPrintEnabled = enabled;

@Deprecated('Dev only')
void devPrint(Object object) {
  if (_devPrintEnabled) {
    debugPrint(object.toString());
  }
}

@Deprecated('Dev only')
T devWarning<T>(T t) => t;

void _devError([Object? msg]) {
  // one day remove the print however sometimes the error thrown is hidden
  try {
    throw UnsupportedError('$msg');
  } catch (e, st) {
    if (_devPrintEnabled) {
      debugPrint('# ERROR $msg');
      debugPrint(st.toString());
    }
    rethrow;
  }
}

@Deprecated('Dev only')
void devError([String? msg]) => _devError(msg);

// exported for testing
void debugDevPrint(Object object) => _devPrint(object);

void debugDevError(Object object) => _devError(object);

set debugDevPrintEnabled(bool enabled) => _devPrintEnabled = enabled;
