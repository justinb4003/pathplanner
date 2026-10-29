import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:pathplanner/main.dart';
import 'package:pathplanner/services/pplib_telemetry.dart';
import 'package:pathplanner/services/update_checker.dart';
import 'package:pathplanner/util/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undo/undo.dart';
import 'package:mockito/annotations.dart';

import 'main_test.mocks.dart';

@GenerateNiceMocks([MockSpec<PPLibTelemetry>(), MockSpec<UpdateChecker>()])
void main() {
  testWidgets('Full app test', (widgetTester) async {
    var fs = MemoryFileSystem();
    var undoStack = ChangeStack();
    var telemetry = MockPPLibTelemetry();
    var updateChecker = MockUpdateChecker();

    SharedPreferences.setMockInitialValues({});
    var prefs = await SharedPreferences.getInstance();

    when(telemetry.isConnected).thenReturn(true);
    when(telemetry.connectionStatusStream())
        .thenAnswer((_) => Stream.value(true));

    when(updateChecker.isGuiUpdateAvailable(any))
        .thenAnswer((_) => Future.value(false));
    when(updateChecker.isPPLibUpdateAvailable(
            projectDir: anyNamed('projectDir'), fs: anyNamed('fs')))
        .thenAnswer((_) => Future.value(false));

    await widgetTester.pumpWidget(PathPlanner(
      appVersion: '2077.1.0',
      fs: fs,
      prefs: prefs,
      undoStack: undoStack,
      telemetry: telemetry,
      updateChecker: updateChecker,
    ));
    await widgetTester.pumpAndSettle();
  });

  testWidgets('dyslexia-friendly font setting', (widgetTester) async {
    var telemetry = MockPPLibTelemetry();
    var updateChecker = MockUpdateChecker();
    when(telemetry.connectionStatusStream())
        .thenAnswer((_) => Stream.value(false));
    when(updateChecker.isGuiUpdateAvailable(any))
        .thenAnswer((_) => Future.value(false));

    for (bool enabled in [false, true]) {
      SharedPreferences.setMockInitialValues({PrefsKeys.dyslexicFont: enabled});
      var prefs = await SharedPreferences.getInstance();

      await widgetTester.pumpWidget(PathPlanner(
        key: UniqueKey(),
        appVersion: '2077.1.0',
        fs: MemoryFileSystem(),
        prefs: prefs,
        undoStack: ChangeStack(),
        telemetry: telemetry,
        updateChecker: updateChecker,
      ));
      await widgetTester.pumpAndSettle();

      MaterialApp app = widgetTester.widget(find.byType(MaterialApp));
      expect(app.theme!.textTheme.bodyMedium!.fontFamily == 'OpenDyslexic',
          enabled);
    }
  });
}
