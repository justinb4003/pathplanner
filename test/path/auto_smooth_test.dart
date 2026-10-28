import 'dart:math';

import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/path/auto_smooth.dart';
import 'package:pathplanner/path/pathplanner_path.dart';
import 'package:pathplanner/path/waypoint.dart';
import 'package:pathplanner/util/wpimath/geometry.dart';

const double eps = 1e-9;

/// Recover tangents D_i from the control points.
List<(double, double)> tangents(List<(double, double)> a, AutoSmoothResult r) {
  final n = a.length - 1;
  double h(int i) =>
      sqrt(pow(a[i + 1].$1 - a[i].$1, 2) + pow(a[i + 1].$2 - a[i].$2, 2));
  return [
    for (int i = 0; i <= n; i++)
      if (i < n)
        (
          3 * (r.next[i]!.$1 - a[i].$1) / h(i),
          3 * (r.next[i]!.$2 - a[i].$2) / h(i),
        )
      else
        (
          3 * (a[i].$1 - r.prev[i]!.$1) / h(i - 1),
          3 * (a[i].$2 - r.prev[i]!.$2) / h(i - 1),
        ),
  ];
}

double cross((double, double) u, (double, double) v) =>
    u.$1 * v.$2 - u.$2 * v.$1;

void main() {
  group('solveAutoSmooth', () {
    test('two anchors give a straight line with handles at 1/3 and 2/3', () {
      final r = solveAutoSmooth([(0.0, 0.0), (3.0, 6.0)]);
      expect(r.prev[0], isNull);
      expect(r.next[1], isNull);
      expect(r.next[0]!.$1, closeTo(1.0, eps));
      expect(r.next[0]!.$2, closeTo(2.0, eps));
      expect(r.prev[1]!.$1, closeTo(2.0, eps));
      expect(r.prev[1]!.$2, closeTo(4.0, eps));
    });

    test('collinear anchors give collinear control points', () {
      final a = [(0.0, 0.0), (1.0, 1.0), (3.0, 3.0), (3.5, 3.5), (7.0, 7.0)];
      final r = solveAutoSmooth(a);
      for (int i = 0; i < a.length; i++) {
        for (final c in [r.prev[i], r.next[i]]) {
          if (c == null) continue;
          expect(c.$1, closeTo(c.$2, 1e-9));
        }
      }
    });

    test(
      'uniform spacing satisfies D[i-1] + 4D[i] + D[i+1] = 3(P[i+1]-P[i-1])',
      () {
        // Unit spacing between all anchors (zig-zag so it is not collinear)
        final a = [
          (0.0, 0.0),
          (1.0, 0.0),
          (1.0, 1.0),
          (2.0, 1.0),
          (2.0, 2.0),
          (3.0, 2.0),
        ];
        final r = solveAutoSmooth(a);
        final d = tangents(a, r);
        for (int i = 1; i < a.length - 1; i++) {
          expect(
            d[i - 1].$1 + 4 * d[i].$1 + d[i + 1].$1,
            closeTo(3 * (a[i + 1].$1 - a[i - 1].$1), 1e-9),
          );
          expect(
            d[i - 1].$2 + 4 * d[i].$2 + d[i + 1].$2,
            closeTo(3 * (a[i + 1].$2 - a[i - 1].$2), 1e-9),
          );
        }
        // Natural ends
        expect(2 * d[0].$1 + d[1].$1, closeTo(3 * (a[1].$1 - a[0].$1), 1e-9));
        expect(2 * d[0].$2 + d[1].$2, closeTo(3 * (a[1].$2 - a[0].$2), 1e-9));
        final n = a.length - 1;
        expect(
          d[n - 1].$1 + 2 * d[n].$1,
          closeTo(3 * (a[n].$1 - a[n - 1].$1), 1e-9),
        );
        expect(
          d[n - 1].$2 + 2 * d[n].$2,
          closeTo(3 * (a[n].$2 - a[n - 1].$2), 1e-9),
        );
      },
    );

    test('non-uniform spacing satisfies the general interior equation', () {
      final a = [(0.0, 0.0), (2.0, 1.0), (2.5, 4.0), (6.0, 3.0), (7.0, -1.0)];
      final r = solveAutoSmooth(a);
      final d = tangents(a, r);
      double h(int i) =>
          sqrt(pow(a[i + 1].$1 - a[i].$1, 2) + pow(a[i + 1].$2 - a[i].$2, 2));
      for (int i = 1; i < a.length - 1; i++) {
        for (final axis in [0, 1]) {
          double c(List<(double, double)> l, int k) =>
              axis == 0 ? l[k].$1 : l[k].$2;
          final lhs = h(i) * c(d, i - 1) +
              2 * (h(i - 1) + h(i)) * c(d, i) +
              h(i - 1) * c(d, i + 1);
          final rhs = 3 *
              (h(i) * (c(a, i) - c(a, i - 1)) / h(i - 1) +
                  h(i - 1) * (c(a, i + 1) - c(a, i)) / h(i));
          expect(lhs, closeTo(rhs, 1e-9));
        }
      }
    });

    test('locked ends keep the requested direction', () {
      final a = [(0.0, 0.0), (2.0, 1.0), (3.0, 4.0), (6.0, 3.0)];
      final r = solveAutoSmooth(a, startDir: (0.0, 5.0), endDir: (-3.0, -4.0));
      // Start handle points along +y, end handle arrives along (-3,-4)/5
      expect(r.next[0]!.$1, closeTo(0.0, eps));
      expect(r.next[0]!.$2, greaterThan(0.0));
      final d = tangents(a, r);
      expect(d.first.$1, closeTo(0.0, eps));
      expect(d.first.$2, closeTo(1.0, eps));
      expect(d.last.$1, closeTo(-0.6, eps));
      expect(d.last.$2, closeTo(-0.8, eps));
    });

    test(
      'joints are C1: prev/next handles are collinear through the anchor',
      () {
        final a = [(0.0, 0.0), (2.0, 1.0), (2.5, 4.0), (6.0, 3.0), (7.0, -1.0)];
        for (final locked in [false, true]) {
          final r = solveAutoSmooth(
            a,
            startDir: locked ? (1.0, 1.0) : null,
            endDir: locked ? (1.0, -2.0) : null,
          );
          for (int i = 1; i < a.length - 1; i++) {
            final inV = (a[i].$1 - r.prev[i]!.$1, a[i].$2 - r.prev[i]!.$2);
            final outV = (r.next[i]!.$1 - a[i].$1, r.next[i]!.$2 - a[i].$2);
            expect(cross(inV, outV), closeTo(0.0, 1e-9));
            expect(inV.$1 * outV.$1 + inV.$2 * outV.$2, greaterThan(0.0));
          }
        }
      },
    );

    test('zero-length segments do not produce NaN', () {
      final r = solveAutoSmooth([(0.0, 0.0), (0.0, 0.0), (1.0, 1.0)]);
      for (final c in [...r.prev, ...r.next]) {
        if (c == null) continue;
        expect(c.$1.isFinite && c.$2.isFinite, true);
      }
    });
  });

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
