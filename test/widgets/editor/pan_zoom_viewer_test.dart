import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/widgets/editor/pan_zoom_viewer.dart';

void main() {
  setUp(PanZoomViewer.resetView);

  testWidgets('right drag pans', (widgetTester) async {
    await widgetTester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PanZoomViewer(
          child: SizedBox(width: 400, height: 300),
        ),
      ),
    ));

    Matrix4 transform() => widgetTester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value;

    final gesture = await widgetTester.startGesture(
        widgetTester.getCenter(find.byType(SizedBox)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton);
    await gesture.moveBy(const Offset(30, -20));
    await gesture.up();
    await widgetTester.pump();

    expect(transform().getTranslation().x, closeTo(30, 0.01));
    expect(transform().getTranslation().y, closeTo(-20, 0.01));
  });

  testWidgets('right drag pans from outside the field', (widgetTester) async {
    await widgetTester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PanZoomViewer(
          child: SizedBox(width: 400, height: 300),
        ),
      ),
    ));

    // The field is centered, so the top left corner is empty space
    final gesture = await widgetTester.startGesture(const Offset(10, 10),
        kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
    await gesture.moveBy(const Offset(30, -20));
    await gesture.up();
    await widgetTester.pump();

    final transform = widgetTester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value;
    expect(transform.getTranslation().x, closeTo(30, 0.01));
    expect(transform.getTranslation().y, closeTo(-20, 0.01));
  });

  testWidgets('zooms out smaller than the field', (widgetTester) async {
    await widgetTester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PanZoomViewer(
          child: SizedBox(width: 400, height: 300),
        ),
      ),
    ));

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await widgetTester.sendEventToBinding(
        pointer.hover(widgetTester.getCenter(find.byType(SizedBox))));
    for (int i = 0; i < 20; i++) {
      await widgetTester
          .sendEventToBinding(pointer.scroll(const Offset(0, 200)));
    }
    await widgetTester.pump();

    final transform = widgetTester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value;
    expect(transform.getMaxScaleOnAxis(), closeTo(0.2, 0.001));
  });

  testWidgets('the next viewer keeps the view', (widgetTester) async {
    Widget viewer(Key key) => MaterialApp(
          home: Scaffold(
            body: PanZoomViewer(
              key: key,
              child: const SizedBox(width: 400, height: 300),
            ),
          ),
        );

    await widgetTester.pumpWidget(viewer(const Key('first')));
    final gesture = await widgetTester.startGesture(const Offset(10, 10),
        kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
    await gesture.moveBy(const Offset(30, -20));
    await gesture.up();
    await widgetTester.pump();

    // A new editor page builds a new viewer
    await widgetTester.pumpWidget(viewer(const Key('second')));

    final transform = widgetTester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value;
    expect(transform.getTranslation().x, closeTo(30, 0.01));
    expect(transform.getTranslation().y, closeTo(-20, 0.01));
  });
}
