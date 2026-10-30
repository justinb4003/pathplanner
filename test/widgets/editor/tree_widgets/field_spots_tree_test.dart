import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/path/pathplanner_path.dart';
import 'package:pathplanner/path/waypoint.dart';
import 'package:pathplanner/util/wpimath/geometry.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/field_spots_tree.dart';

void main() {
  late PathPlannerPath path;
  late PathPlannerPath other;
  late List<PathPlannerPath> paths;

  setUp(() {
    final fs = MemoryFileSystem();
    fs.directory('/paths').createSync();
    Waypoint.linked.clear();
    path = PathPlannerPath.defaultPath(pathDir: '/paths', fs: fs, name: 'A');
    other = PathPlannerPath.defaultPath(pathDir: '/paths', fs: fs, name: 'B');
    path.waypoints.last.linkedName = 'Shoot';
    other.waypoints.first.linkedName = 'Shoot';
    path.updateLinkedWaypoints();
    paths = [path, other];
  });

  Future<void> pumpTree(WidgetTester widgetTester) async {
    path.fieldSpotsExpanded = true;
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: FieldSpotsTree(
              path: path,
              allPaths: paths,
              // Like the project page, then rebuild like the editor does
              onPathChanged: () =>
                  setState(() => PathPlannerPath.syncLinked(paths, path)),
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('lists spots', (widgetTester) async {
    await pumpTree(widgetTester);

    expect(find.text('Shoot (2 waypoints)'), findsOneWidget);
  });

  testWidgets('editing a spot moves every waypoint on it',
      (widgetTester) async {
    await pumpTree(widgetTester);

    await widgetTester.enterText(
        find.widgetWithText(TextField, 'X Position (M)'), '1.5');
    await widgetTester.testTextInput.receiveAction(TextInputAction.done);
    await widgetTester.pump();
    await widgetTester.enterText(
        find.widgetWithText(TextField, 'Rotation (Deg)'), '90');
    await widgetTester.testTextInput.receiveAction(TextInputAction.done);
    await widgetTester.pump();

    expect(path.waypoints.last.anchor.x, closeTo(1.5, 1e-9));
    expect(other.waypoints.first.anchor.x, closeTo(1.5, 1e-9));
    expect(path.goalEndState.rotation.degrees, closeTo(90, 1e-9));
    expect(other.idealStartingState.rotation.degrees, closeTo(90, 1e-9));
  });

  testWidgets('rename a spot', (widgetTester) async {
    await pumpTree(widgetTester);

    await widgetTester.tap(find.byTooltip('Rename Field Spot'));
    await widgetTester.pumpAndSettle();
    await widgetTester.enterText(find.widgetWithText(TextField, 'Name'), 'Hub');
    await widgetTester.tap(find.text('RENAME'));
    await widgetTester.pumpAndSettle();

    expect(Waypoint.linked.keys, ['Hub']);
    expect(other.waypoints.first.linkedName, 'Hub');
    expect(find.text('Hub (2 waypoints)'), findsOneWidget);
  });

  testWidgets('rename refuses a name already in use', (widgetTester) async {
    Waypoint.linked['Hub'] = const Pose2d(Translation2d(), Rotation2d());
    await pumpTree(widgetTester);

    await widgetTester.tap(find.byTooltip('Rename Field Spot').last);
    await widgetTester.pumpAndSettle();
    await widgetTester.enterText(find.widgetWithText(TextField, 'Name'), 'Hub');
    await widgetTester.pump();

    expect(find.text('A field spot with that name exists'), findsOneWidget);
    expect(
        widgetTester
            .widget<TextButton>(find.widgetWithText(TextButton, 'RENAME'))
            .onPressed,
        isNull);
  });

  testWidgets('delete a spot', (widgetTester) async {
    await pumpTree(widgetTester);

    await widgetTester.tap(find.byTooltip('Delete Field Spot'));
    await widgetTester.pumpAndSettle();
    await widgetTester.tap(find.text('DELETE'));
    await widgetTester.pumpAndSettle();

    expect(Waypoint.linked, isEmpty);
    expect(path.waypoints.last.linkedName, isNull);
    expect(other.waypoints.first.linkedName, isNull);
    expect(find.text('Link a waypoint to create a field spot'), findsOneWidget);
  });
}
