import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A centered [InteractiveViewer] for the field that can also be panned by
/// dragging with the right mouse button. Left drags belong to the editor for
/// moving waypoints, so they never reach the viewer's own panning.
///
/// It fills the whole editor area so a right drag works from anywhere, not
/// just on top of the field.
class PanZoomViewer extends StatefulWidget {
  final Widget child;
  final double maxScale;

  const PanZoomViewer({
    super.key,
    required this.child,
    this.maxScale = 2.5,
  });

  @override
  State<PanZoomViewer> createState() => _PanZoomViewerState();
}

class _PanZoomViewerState extends State<PanZoomViewer> {
  final TransformationController _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerMove: (event) {
        if (event.buttons & kSecondaryMouseButton != 0) {
          _transform.value =
              Matrix4.translationValues(event.delta.dx, event.delta.dy, 0)
                ..multiply(_transform.value);
        }
      },
      child: Center(
        child: InteractiveViewer(
          transformationController: _transform,
          // A quarter of InteractiveViewer's default minimum of 0.8. Without a
          // boundary margin it won't zoom out past the size of the field.
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.2,
          maxScale: widget.maxScale,
          child: widget.child,
        ),
      ),
    );
  }
}
