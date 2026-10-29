import 'dart:math';

import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/path/path_constraints.dart';
import 'package:pathplanner/path/pathplanner_path.dart';
import 'package:pathplanner/util/choreo_import_util.dart';
import 'package:pathplanner/util/wpimath/geometry.dart';

const double eps = 1e-9;

Map<String, dynamic> v(num val) => {'exp': '$val', 'val': val};

Map<String, dynamic> waypoint(num x, num y, {bool split = false}) =>
    {'x': v(x), 'y': v(y), 'heading': v(0), 'split': split};

Map<String, dynamic> sample(num t, num x, num y, num heading, num vx, num vy) =>
    {'t': t, 'x': x, 'y': y, 'heading': heading, 'vx': vx, 'vy': vy};

Map<String, dynamic> constraint(dynamic from, dynamic to, String type,
        [Map<String, dynamic> props = const {}, bool enabled = true]) =>
    {
      'from': from,
      'to': to,
      'enabled': enabled,
      'data': {'type': type, 'props': props},
    };

/// Five waypoints one second apart, split at waypoint 2:
///   (0,0) -> (2,0) -> (2,2) | (4,2) -> (4,4)
Map<String, dynamic> trajJson() => {
      'version': 3,
      'params': {
        'waypoints': [
          waypoint(0, 0),
          waypoint(2, 0),
          waypoint(2, 2, split: true),
          waypoint(4, 2),
          waypoint(4, 4),
        ],
        'constraints': [
          constraint('first', null, 'StopPoint'),
          constraint('last', null, 'StopPoint'),
          constraint(2, null, 'StopPoint'),
          constraint('first', 'last', 'MaxVelocity', {'max': v(2.5)}),
          constraint(1, 2, 'MaxVelocity', {'max': v(1.0)}),
          constraint(1, 2, 'MaxAcceleration', {'max': v(2.0)}),
          constraint('first', null, 'MaxAngularVelocity', {'max': v(0)}),
          constraint(0, 1, 'KeepInLane', {'tolerance': v(0.01)}),
          constraint(3, 4, 'PointAt', {'x': v(5), 'y': v(5), 'flip': false}),
          constraint('first', 'last', 'MaxVelocity', {'max': v(0.1)}, false),
        ],
      },
      'trajectory': {
        'waypoints': [0.0, 1.0, 2.0, 3.0, 4.0],
        'splits': [0, 2],
        'samples': [
          sample(0.0, 0, 0, 0, 0, 0),
          sample(1.0, 2, 0, pi / 4, 1, 1),
          sample(2.0, 2, 2, pi / 2, 0, 1.5),
          sample(3.0, 4, 2, pi / 2, 1, 0),
          sample(4.0, 4, 4, pi, 0, 0),
        ],
      },
      'events': [
        {
          'name': 'A',
          'from': {'target': 1, 'targetTimestamp': 1.0, 'offset': v(0.5)},
        },
        {
          'name': 'B',
          'from': {'target': 2, 'targetTimestamp': 2.0, 'offset': v(0)},
        },
      ],
    };

({PathPlannerPath path, List<String> skipped}) convert({int? split}) =>
    ChoreoImportUtil.pathFromTraj(
      trajJson(),
      name: 'Test',
      pathDir: '/paths',
      fs: MemoryFileSystem(),
      defaultConstraints: PathConstraints(),
      split: split,
    );

void main() {
  group('ChoreoImportUtil.pathFromTraj', () {
    test('waypoints keep the anchors, with handles along the travel direction',
        () {
      var (:path, skipped: _) = convert();
      expect([
        for (var w in path.waypoints) w.anchor
      ], const [
        Translation2d(0, 0),
        Translation2d(2, 0),
        Translation2d(2, 2),
        Translation2d(4, 2),
        Translation2d(4, 4),
      ]);
      expect(path.waypoints.first.prevControl, isNull);
      expect(path.waypoints.last.nextControl, isNull);

      // Stopped at the start: aim at the next waypoint, a third of the way
      expect(path.waypoints[0].nextControl!.x, closeTo(2 / 3, eps));
      expect(path.waypoints[0].nextControl!.y, closeTo(0, eps));

      // Moving along (1, 1) at waypoint 1
      Translation2d out =
          path.waypoints[1].nextControl! - const Translation2d(2, 0);
      expect(out.x, closeTo(out.y, eps));
      expect(out.norm, closeTo(2 / 3, eps));
    });

    test('whole-path limits become global, ranges become merged zones', () {
      var (:path, skipped: _) = convert();
      expect(path.useDefaultConstraints, false);
      expect(path.globalConstraints.maxVelocityMPS, 2.5);

      expect(path.constraintZones.length, 1);
      var zone = path.constraintZones.first;
      expect(zone.minWaypointRelativePos, 1);
      expect(zone.maxWaypointRelativePos, 2);
      expect(zone.constraints.maxVelocityMPS, 1.0);
      expect(zone.constraints.maxAccelerationMPSSq, 2.0);
    });

    test('PointAt over a range becomes a point towards zone', () {
      var (:path, skipped: _) = convert();
      expect(path.pointTowardsZones.length, 1);
      var zone = path.pointTowardsZones.first;
      expect(zone.fieldPosition, const Translation2d(5, 5));
      expect(zone.minWaypointRelativePos, 3);
      expect(zone.maxWaypointRelativePos, 4);
    });

    test('solved headings become rotation targets outside point towards zones',
        () {
      var (:path, skipped: _) = convert();
      expect(
          [for (var t in path.rotationTargets) t.waypointRelativePos], [1, 2]);
      expect(path.rotationTargets[0].rotation.degrees, closeTo(45, eps));
      expect(path.rotationTargets[1].rotation.degrees, closeTo(90, eps));
      expect(path.idealStartingState.rotation.degrees, closeTo(0, eps));
      expect(path.goalEndState.rotation.degrees, closeTo(180, eps));
      expect(path.idealStartingState.velocityMPS, 0);
      expect(path.goalEndState.velocityMPS, 0);
    });

    test('unsupported constraints are reported; disabled ones are ignored', () {
      var (path: _, :skipped) = convert();
      expect(skipped, [
        'StopPoint (waypoint 2)',
        'MaxAngularVelocity 0 (waypoint 0)',
        'KeepInLane (waypoints 0-1)',
      ]);
    });

    test('event markers land at the same time along the path', () {
      var (:path, skipped: _) = convert();
      expect([for (var e in path.eventMarkers) e.name], ['A', 'B']);
      expect(path.eventMarkers[0].waypointRelativePos, closeTo(1.5, eps));
      expect(path.eventMarkers[1].waypointRelativePos, closeTo(2.0, eps));
    });

    test('a split only gets its own waypoints, constraints and events', () {
      var first = convert(split: 0).path;
      expect(first.waypoints.length, 3);
      expect(first.waypoints.last.anchor, const Translation2d(2, 2));
      expect(first.goalEndState.velocityMPS, closeTo(1.5, eps));
      expect(first.pointTowardsZones, isEmpty);
      // B sits exactly on the split, so it belongs to the second half
      expect([for (var e in first.eventMarkers) e.name], ['A']);

      var (path: second, :skipped) = convert(split: 1);
      expect(second.waypoints.length, 3);
      expect(second.waypoints.first.anchor, const Translation2d(2, 2));
      expect(second.idealStartingState.velocityMPS, closeTo(1.5, eps));
      expect(second.globalConstraints.maxVelocityMPS, 2.5);
      // The 1-2 zone only touches this half at the split waypoint
      expect(second.constraintZones, isEmpty);
      expect(second.pointTowardsZones.single.minWaypointRelativePos, 1);
      expect(second.pointTowardsZones.single.maxWaypointRelativePos, 2);
      expect([for (var e in second.eventMarkers) e.name], ['B']);
      expect(second.eventMarkers.single.waypointRelativePos, closeTo(0, eps));
      expect(skipped, isEmpty);
    });

    test('the converted path generates and saves', () {
      var (:path, skipped: _) = convert();
      path.fs.directory('/paths').createSync(recursive: true);
      path.generateAndSavePath();
      expect(path.pathPoints, isNotEmpty);
      expect(path.fs.file('/paths/Test.path').existsSync(), true);
    });
  });
}
