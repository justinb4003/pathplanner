import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void ignoreOverflowErrors(
  FlutterErrorDetails details, {
  bool forceReport = false,
}) {
  bool ifIsOverflowError = false;
  bool isUnableToLoadAsset = false;

  // Detect overflow error.
  var exception = details.exception;
  if (exception is FlutterError) {
    ifIsOverflowError = !exception.diagnostics.any(
      (e) => e.value.toString().startsWith('A RenderFlex overflowed by'),
    );
    isUnableToLoadAsset = !exception.diagnostics.any(
      (e) => e.value.toString().startsWith('Unable to load asset'),
    );
  }

  // Ignore if is overflow error.
  if (ifIsOverflowError || isUnableToLoadAsset) {
    return;
  } else {
    FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
    exit(1);
  }
}

/// Load the bundled OpenDyslexic font so a test can render with it, verify
/// it actually loads and the packaging isn't broken
Future<void> loadOpenDyslexicFont() async {
  FontLoader loader = FontLoader('OpenDyslexic')
    ..addFont(rootBundle.load('fonts/OpenDyslexic-Regular.otf'))
    ..addFont(rootBundle.load('fonts/OpenDyslexic-Bold.otf'));
  await loader.load();
}
