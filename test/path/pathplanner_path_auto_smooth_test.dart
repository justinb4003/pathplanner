import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/path/pathplanner_path.dart';
import 'package:pathplanner/path/waypoint.dart';
import 'package:pathplanner/util/wpimath/geometry.dart';

void main() {
  group('PathPlannerPath auto-smooth', () {
    PathPlannerPath make({bool smooth = false, bool lock = false}) {
      return PathPlannerPath(
        name: 't',
        pathDir: '/paths',
        fs: MemoryFileSystem(),
        waypoints: [
          Waypoint(
            anchor: const Translation2d(1, 1),
            nextControl: const Translation2d(1, 2),
          ),
          Waypoint(
            anchor: const Translation2d(3, 2),
            prevControl: const Translation2d(2, 2),
            nextControl: const Translation2d(4, 2),
          ),
          Waypoint(
            anchor: const Translation2d(5, 1),
            prevControl: const Translation2d(5, 2),
          ),
        ],
        globalConstraints: PathPlannerPath.defaultPath(
          pathDir: '/paths',
          fs: MemoryFileSystem(),
        ).globalConstraints,
        goalEndState: PathPlannerPath.defaultPath(
          pathDir: '/paths',
          fs: MemoryFileSystem(),
        ).goalEndState,
        constraintZones: [],
        pointTowardsZones: [],
        rotationTargets: [],
        eventMarkers: [],
        reversed: false,
        folder: null,
        idealStartingState: PathPlannerPath.defaultPath(
          pathDir: '/paths',
          fs: MemoryFileSystem(),
        ).idealStartingState,
        useDefaultConstraints: false,
        autoSmooth: smooth,
        autoSmoothLockEnds: lock,
      );
    }

    test('old json without the keys loads as off and does not write them', () {
      final json = make().toJson();
      expect(json.containsKey('autoSmooth'), false);
      expect(json['version'], '2025.0');
      final p = PathPlannerPath.fromJson(
        json,
        't',
        '/paths',
        MemoryFileSystem(),
      );
      expect(p.autoSmooth, false);
      expect(p.autoSmoothLockEnds, false);
    });

    test('flags round trip through json', () {
      final p = make(smooth: true, lock: true);
      final json = p.toJson();
      expect(json['autoSmooth'], true);
      expect(json['autoSmoothLockEnds'], true);
      final p2 = PathPlannerPath.fromJson(
        json,
        't',
        '/paths',
        MemoryFileSystem(),
      );
      expect(p2.autoSmooth, true);
      expect(p2.autoSmoothLockEnds, true);
    });

    test('off leaves hand-placed controls alone', () {
      final p = make();
      p.generatePathPoints();
      expect(p.waypoints[1].prevControl, const Translation2d(2, 2));
    });

    test('on recomputes controls when anchors change, ends stay null', () {
      final p = make(smooth: true);
      expect(p.waypoints.first.prevControl, isNull);
      expect(p.waypoints.last.nextControl, isNull);
      final before = p.waypoints[1].nextControl;
      p.waypoints[1].move(3, 4);
      p.generatePathPoints();
      expect(p.waypoints[1].nextControl, isNot(before));

      p.addWaypoint(const Translation2d(8, 3));
      p.generatePathPoints();
      expect(p.waypoints.length, 4);
      expect(p.waypoints.last.nextControl, isNull);
      expect(p.waypoints[2].nextControl, isNotNull);

      p.insertWaypointAfter(0);
      p.generatePathPoints();
      expect(p.waypoints.length, 5);
      for (int i = 1; i < 4; i++) {
        final w = p.waypoints[i];
        final a = w.anchor - w.prevControl!;
        final b = w.nextControl! - w.anchor;
        expect(a.x * b.y - a.y * b.x, closeTo(0.0, 1e-9));
      }
    });

    test('lock ends keeps the end handle directions', () {
      final p = make(smooth: true, lock: true);
      p.waypoints.first.nextControl = const Translation2d(1, 3); // +y
      p.generatePathPoints();
      p.waypoints.first.move(1.5, 1);
      p.generatePathPoints();
      final d = p.waypoints.first.nextControl! - p.waypoints.first.anchor;
      expect(d.x, closeTo(0.0, 1e-9));
      expect(d.y, greaterThan(0.0));
    });

    test('handles are interactive only for locked ends', () {
      expect(make().isControlInteractive(1, next: true), true);
      expect(make(smooth: true).isControlInteractive(0, next: true), false);
      final l = make(smooth: true, lock: true);
      expect(l.isControlInteractive(0, next: true), true);
      expect(l.isControlInteractive(2, next: false), true);
      expect(l.isControlInteractive(1, next: true), false);
    });
  });
}
