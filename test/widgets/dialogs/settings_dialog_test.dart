import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/widgets/dialogs/settings_dialog.dart';
import 'package:pathplanner/widgets/field_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUpAll(() async {
    await loadOpenDyslexicFont();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('settings dialog', (widgetTester) async {
    FlutterError.onError = ignoreOverflowErrors;
    await widgetTester.binding.setSurfaceSize(const Size(1280, 800));

    await widgetTester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'OpenDyslexic'),
      home: Scaffold(
        body: SettingsDialog(
          onSettingsChanged: () {},
          onFieldSelected: (_) {},
          fieldImages: FieldImage.offialFields(),
          selectedField: FieldImage.defaultField,
          prefs: prefs,
          onTeamColorChanged: (_) {},
          onDyslexicFontChanged: (_) {},
        ),
      ),
    ));
  });
}
