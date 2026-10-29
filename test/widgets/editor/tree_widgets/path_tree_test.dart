import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/path/path_constraints.dart';
import 'package:pathplanner/path/pathplanner_path.dart';
import 'package:pathplanner/path/waypoint.dart';
import 'package:pathplanner/util/prefs.dart';
import 'package:pathplanner/util/wpimath/geometry.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/constraint_zones_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/event_markers_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/global_constraints_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/goal_end_state_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/path_optimization_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/path_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/point_towards_zones_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/rotation_targets_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/waypoints_tree.dart';
import 'package:pathplanner/widgets/editor/runtime_display.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undo/undo.dart';

void main() {
  late PathPlannerPath path;
  bool sideSwapped = false;
  late SharedPreferences prefs;

  setUp(() async {
    path = PathPlannerPath.defaultPath(
      pathDir: '/paths',
      fs: MemoryFileSystem(),
    );
    path.reversed = false;
    sideSwapped = false;
    SharedPreferences.setMockInitialValues({
      PrefsKeys.holonomicMode: true,
      PrefsKeys.treeOnRight: true,
    });
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('has runtime display', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          runtimeDisplay: const RuntimeDisplay(
            currentRuntime: 5.0,
            previousRuntime: null,
          ),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(RuntimeDisplay), findsOneWidget);
  });

  testWidgets('swap side button', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          onSideSwapped: () => sideSwapped = true,
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    var btn = find.byTooltip('Move to Other Side');

    expect(btn, findsOneWidget);

    await widgetTester.tap(btn);
    await widgetTester.pump();
    expect(sideSwapped, true);
  });

  testWidgets('has waypoints tree', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(WaypointsTree), findsOneWidget);
  });

  testWidgets('has constraint zones tree', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(ConstraintZonesTree), findsOneWidget);
  });

  testWidgets('has event markers tree', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(EventMarkersTree), findsOneWidget);
  });

  testWidgets('has global constraints tree', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(GlobalConstraintsTree), findsOneWidget);
  });

  testWidgets('has goal end state tree', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(GoalEndStateTree), findsOneWidget);
  });

  testWidgets('has rotation targets tree', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(RotationTargetsTree), findsOneWidget);
  });

  testWidgets('has point zones tree', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(PointTowardsZonesTree), findsOneWidget);
  });

  testWidgets('has optimizer tree', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(PathOptimizationTree), findsOneWidget);
  });

  testWidgets('has optimizer tree', (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(PathOptimizationTree), findsOneWidget);
  });

  testWidgets('Reversed button', (widgetTester) async {
    final ChangeStack undoStack = ChangeStack();

    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: undoStack,
          holonomicMode: false,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    final reversedButton = find.byTooltip('Reverse Path');

    expect(reversedButton, findsOneWidget);

    await widgetTester.tap(reversedButton);
    await widgetTester.pump();
    expect(path.reversed, true);

    undoStack.undo();

    await widgetTester.pump();
    expect(path.reversed, false);

    undoStack.redo();

    await widgetTester.pump();
    expect(path.reversed, true);
  });

  testWidgets('no waypoint range slider with two waypoints',
      (widgetTester) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    expect(find.byType(RangeSlider), findsNothing);
  });

  testWidgets('waypoint range slider', (widgetTester) async {
    path.addWaypoint(const Translation2d(7.0, 4.0));
    path.addWaypoint(const Translation2d(8.0, 5.0));
    (int, int)? range = (1, 2);
    bool changed = false;

    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
          waypointRange: range,
          onWaypointRangeChanged: (value) {
            range = value;
            changed = true;
          },
        ),
      ),
    ));

    expect(find.text('Show waypoints 1-2'), findsOneWidget);
    RangeSlider slider = widgetTester.widget(find.byType(RangeSlider));
    expect(slider.max, 3);

    slider.onChanged!(const RangeValues(1, 3));
    expect(range, (1, 3));

    // The full range means "show everything"
    slider.onChanged!(const RangeValues(0, 3));
    expect(range, isNull);

    // Thumbs on top of each other would hide every segment, so it's ignored
    changed = false;
    slider.onChanged!(const RangeValues(2, 2));
    expect(changed, false);

    range = (1, 2);
    await widgetTester.tap(find.byTooltip('Show all waypoints'));
    expect(range, isNull);
  });

  testWidgets('waypoint range slider keeps its width', (widgetTester) async {
    path.addWaypoint(const Translation2d(7.0, 4.0));
    path.addWaypoint(const Translation2d(8.0, 5.0));

    Widget tree((int, int)? range) => MaterialApp(
          home: Scaffold(
            body: PathTree(
              path: path,
              undoStack: ChangeStack(),
              holonomicMode: true,
              defaultConstraints: PathConstraints(),
              prefs: prefs,
              fieldSizeMeters: const Size(16.54, 8.21),
              waypointRange: range,
            ),
          ),
        );

    // Showing everything: the show all button is there but disabled
    await widgetTester.pumpWidget(tree(null));
    Size fullWidth = widgetTester.getSize(find.byType(RangeSlider));
    IconButton showAll = widgetTester.widget(find.ancestor(
        of: find.byIcon(Icons.visibility), matching: find.byType(IconButton)));
    expect(showAll.onPressed, isNull);

    // Hiding some waypoints mid-drag must not resize the slider under the
    // pointer
    await widgetTester.pumpWidget(tree((1, 2)));
    expect(widgetTester.getSize(find.byType(RangeSlider)), fullWidth);
  });

  testWidgets('previous segment links and unlinks', (widgetTester) async {
    final fs = MemoryFileSystem();
    fs.directory('/paths').createSync();
    final previous =
        PathPlannerPath.defaultPath(pathDir: '/paths', fs: fs, name: 'A');
    previous.goalEndState.rotation = Rotation2d.fromDegrees(90);
    path.waypoints.first.move(1.0, 1.0);
    int changes = 0;

    Widget tree() => MaterialApp(
          home: Scaffold(
            body: PathTree(
              path: path,
              allPaths: [previous, path],
              undoStack: ChangeStack(),
              onPathChanged: () => changes++,
              holonomicMode: true,
              defaultConstraints: PathConstraints(),
              prefs: prefs,
              fieldSizeMeters: const Size(16.54, 8.21),
            ),
          ),
        );

    await widgetTester.pumpWidget(tree());
    final dropdown = find.byType(DropdownButton<PathPlannerPath?>);
    await widgetTester.ensureVisible(dropdown);
    await widgetTester.pumpAndSettle();

    // This path can't be its own previous segment
    await widgetTester.tap(dropdown);
    await widgetTester.pumpAndSettle();
    expect(find.text('New Path'), findsNothing);
    await widgetTester.tap(find.text('A').last);
    await widgetTester.pumpAndSettle();

    // The ends don't match, so it asks first. Cancel leaves it alone.
    expect(find.text('Link Segments'), findsOneWidget);
    await widgetTester.tap(find.text('CANCEL'));
    await widgetTester.pumpAndSettle();
    expect(changes, 0);
    expect(path.waypoints.first.linkedName, isNull);
    expect(path.waypoints.first.anchor, const Translation2d(1.0, 1.0));

    await widgetTester.tap(dropdown);
    await widgetTester.pumpAndSettle();
    await widgetTester.tap(find.text('A').last);
    await widgetTester.pumpAndSettle();
    await widgetTester.tap(find.text('LINK'));
    await widgetTester.pumpAndSettle();

    final start = path.waypoints.first;
    final end = previous.waypoints.last;
    expect(changes, 1);
    expect(start.linkedName, isNotNull);
    expect(end.linkedName, start.linkedName);
    expect(start.anchor, end.anchor);
    expect(path.idealStartingState.rotation.degrees, closeTo(90, 1e-9));

    final linkName = start.linkedName;
    Waypoint.linked[linkName!] = Pose2d(start.anchor, const Rotation2d());

    await widgetTester.pumpWidget(tree());
    await widgetTester.tap(dropdown);
    await widgetTester.pumpAndSettle();
    await widgetTester.tap(find.text('None').last);
    await widgetTester.pumpAndSettle();

    expect(changes, 2);
    expect(start.linkedName, isNull);
    expect(end.linkedName, isNull);
    expect(Waypoint.linked.containsKey(linkName), false);
  });

  testWidgets('previous and next segment buttons', (widgetTester) async {
    final fs = MemoryFileSystem();
    final previous =
        PathPlannerPath.defaultPath(pathDir: '/paths', fs: fs, name: 'A');
    final next =
        PathPlannerPath.defaultPath(pathDir: '/paths', fs: fs, name: 'C');
    previous.waypoints.last.linkedName = 'A -> B';
    path.waypoints.first.linkedName = 'A -> B';
    PathPlannerPath? opened;

    Widget tree() => MaterialApp(
          home: Scaffold(
            body: PathTree(
              path: path,
              allPaths: [previous, path, next],
              onOpenPath: (p) => opened = p,
              undoStack: ChangeStack(),
              holonomicMode: true,
              defaultConstraints: PathConstraints(),
              prefs: prefs,
              fieldSizeMeters: const Size(16.54, 8.21),
            ),
          ),
        );

    await widgetTester.pumpWidget(tree());
    final prevBtn = find.byTooltip('Open Previous Segment');
    final nextBtn = find.byTooltip('Open Next Segment');
    await widgetTester.ensureVisible(prevBtn);
    await widgetTester.pumpAndSettle();

    // No next segment yet
    await widgetTester.tap(nextBtn);
    expect(opened, isNull);

    await widgetTester.tap(prevBtn);
    expect(opened, previous);

    path.waypoints.last.linkedName = 'B -> C';
    next.waypoints.first.linkedName = 'B -> C';
    await widgetTester.pumpWidget(tree());
    await widgetTester.tap(nextBtn);
    expect(opened, next);
  });

  testWidgets('previous segment links matching ends without asking',
      (widgetTester) async {
    final fs = MemoryFileSystem();
    fs.directory('/paths').createSync();
    final previous =
        PathPlannerPath.defaultPath(pathDir: '/paths', fs: fs, name: 'A');
    final end = previous.waypoints.last;
    path.waypoints.first.move(end.anchor.x, end.anchor.y);

    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PathTree(
          path: path,
          allPaths: [previous, path],
          undoStack: ChangeStack(),
          holonomicMode: true,
          defaultConstraints: PathConstraints(),
          prefs: prefs,
          fieldSizeMeters: const Size(16.54, 8.21),
        ),
      ),
    ));

    final dropdown = find.byType(DropdownButton<PathPlannerPath?>);
    await widgetTester.ensureVisible(dropdown);
    await widgetTester.pumpAndSettle();
    await widgetTester.tap(dropdown);
    await widgetTester.pumpAndSettle();
    await widgetTester.tap(find.text('A').last);
    await widgetTester.pumpAndSettle();

    expect(find.text('Link Segments'), findsNothing);
    expect(path.waypoints.first.linkedName, end.linkedName);
    expect(end.linkedName, isNotNull);
  });
}
