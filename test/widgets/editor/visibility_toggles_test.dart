import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/util/prefs.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/editor_settings_tree.dart';
import 'package:pathplanner/widgets/editor/visibility_toggles.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('toggles settings and stays in sync with Editor Settings',
      (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(height: 60, child: VisibilityToggles(prefs: prefs)),
            const Expanded(
              child: SingleChildScrollView(
                child: EditorSettingsTree(initiallyExpanded: true),
              ),
            ),
          ],
        ),
      ),
    ));
    await widgetTester.pump();

    final toggles = [
      ('Robot Outlines', PrefsKeys.showRobotOutlines),
      ('Event Markers', PrefsKeys.showEventMarkers),
      ('Control Points', PrefsKeys.showControlPoints),
      ('Rotation Targets', PrefsKeys.showRotationTargets),
      ('Point Towards Zones', PrefsKeys.showPointZones),
    ];

    for (final (label, key) in toggles) {
      final check = find.descendant(
        of: find
            .ancestor(of: find.text('Show $label'), matching: find.byType(Row))
            .first,
        matching: find.byType(Checkbox),
      );

      await widgetTester.tap(find.byTooltip('Hide $label'));
      await widgetTester.pump();

      expect(prefs.getBool(key), false);
      expect(find.byTooltip('Show $label'), findsOneWidget);
      expect(widgetTester.widget<Checkbox>(check).value, false);

      // And back again from the Editor Settings checkbox
      await widgetTester.ensureVisible(check);
      await widgetTester.tap(check);
      await widgetTester.pump();

      expect(prefs.getBool(key), true);
      expect(find.byTooltip('Hide $label'), findsOneWidget);
    }
  });
}
