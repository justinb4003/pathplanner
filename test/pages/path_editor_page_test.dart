import 'package:file/memory.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/pages/path_editor_page.dart';
import 'package:pathplanner/path/pathplanner_path.dart';
import 'package:pathplanner/widgets/editor/split_path_editor.dart';
import 'package:pathplanner/widgets/field_image.dart';
import 'package:pathplanner/widgets/renamable_title.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undo/undo.dart';

void main() {
  late PathPlannerPath path;
  late ChangeStack undoStack;
  late SharedPreferences prefs;
  String? name;

  setUp(() async {
    final fs = MemoryFileSystem();
    path = PathPlannerPath.defaultPath(
        pathDir: '/paths', fs: fs, name: 'testPath');
    undoStack = ChangeStack();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    name = null;
  });

  testWidgets('shows editor', (widgetTester) async {
    await widgetTester.binding.setSurfaceSize(const Size(1280, 720));

    await widgetTester.pumpWidget(MaterialApp(
      home: PathEditorPage(
        prefs: prefs,
        path: path,
        fieldImage: FieldImage.defaultField,
        onRenamed: (value) => name = value,
        undoStack: undoStack,
        shortcuts: false,
      ),
    ));

    expect(find.byType(SplitPathEditor), findsOneWidget);
  });

  testWidgets('rename', (widgetTester) async {
    await widgetTester.binding.setSurfaceSize(const Size(1280, 720));

    await widgetTester.pumpWidget(MaterialApp(
      home: PathEditorPage(
        prefs: prefs,
        path: path,
        fieldImage: FieldImage.defaultField,
        onRenamed: (value) => name = value,
        undoStack: undoStack,
        shortcuts: false,
      ),
    ));

    final nameField = find.byType(RenamableTitle);

    expect(nameField, findsOneWidget);

    await widgetTester.enterText(nameField, 'renamed');
    await widgetTester.testTextInput.receiveAction(TextInputAction.done);
    await widgetTester.pump();

    expect(name, 'renamed');
  });

  testWidgets('back button', (widgetTester) async {
    await widgetTester.binding.setSurfaceSize(const Size(1280, 720));

    await widgetTester.pumpWidget(MaterialApp(
      home: PathEditorPage(
        prefs: prefs,
        path: path,
        fieldImage: FieldImage.defaultField,
        onRenamed: (value) => name = value,
        undoStack: undoStack,
        shortcuts: false,
      ),
    ));

    final backButton = find.byType(BackButton);

    expect(backButton, findsOneWidget);

    undoStack.add(Change(null, () => null, (oldValue) => null));

    await widgetTester.tap(backButton);
    await widgetTester.pump();

    // undo history should be cleared
    expect(undoStack.canUndo, false);
  });

  testWidgets('switch path menu', (widgetTester) async {
    await widgetTester.binding.setSurfaceSize(const Size(1280, 720));
    final fs = MemoryFileSystem();
    final b = PathPlannerPath.defaultPath(pathDir: '/paths', fs: fs, name: 'b');
    final a = PathPlannerPath.defaultPath(pathDir: '/paths', fs: fs, name: 'a');
    PathPlannerPath? opened;

    await widgetTester.pumpWidget(MaterialApp(
      home: PathEditorPage(
        prefs: prefs,
        path: path,
        fieldImage: FieldImage.defaultField,
        onRenamed: (value) => name = value,
        undoStack: undoStack,
        shortcuts: false,
        allPaths: [path, b, a],
        onOpenPath: (p) => opened = p,
      ),
    ));

    // The app bar waits to see if a click is a double click
    await widgetTester.tap(find.byTooltip('Switch Path'));
    await widgetTester.pump(kDoubleTapTimeout);
    await widgetTester.pumpAndSettle();

    // Sorted by name, with this path shown but not selectable
    final items = widgetTester
        .widgetList<PopupMenuItem<PathPlannerPath>>(
            find.byWidgetPredicate((w) => w is PopupMenuItem<PathPlannerPath>))
        .toList();
    expect(items.map((i) => i.value!.name), ['a', 'b', 'testPath']);
    expect(items.last.enabled, false);

    await widgetTester.tap(find.text('b').last);
    await widgetTester.pumpAndSettle();
    expect(opened, b);
  });
}
