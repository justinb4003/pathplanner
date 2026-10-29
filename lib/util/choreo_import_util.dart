import 'dart:math';

import 'package:file/file.dart';
import 'package:pathplanner/path/constraints_zone.dart';
import 'package:pathplanner/path/event_marker.dart';
import 'package:pathplanner/path/goal_end_state.dart';
import 'package:pathplanner/path/ideal_starting_state.dart';
import 'package:pathplanner/path/path_constraints.dart';
import 'package:pathplanner/path/pathplanner_path.dart';
import 'package:pathplanner/path/point_towards_zone.dart';
import 'package:pathplanner/path/rotation_target.dart';
import 'package:pathplanner/path/waypoint.dart';
import 'package:pathplanner/util/wpimath/geometry.dart';

/// Turns a Choreo trajectory (.traj, version 3) into an editable PathPlanner
/// path, keeping as much of the original as PathPlanner can express:
///   - one waypoint per Choreo waypoint, with control handles pointing along
///     the direction Choreo's solution was traveling there
///   - Choreo's solved heading at every interior waypoint as a rotation target,
///     plus its start/end heading and speed as the ideal start and goal end
///   - MaxVelocity / MaxAcceleration / MaxAngularVelocity as constraint zones
///     (or the global constraints when they cover the whole path)
///   - PointAt over a range of waypoints as a point towards zone
///   - event markers at the same spot in time along the path
/// Everything else (stop points in the middle, keep-in/keep-out regions) has
/// no PathPlanner equivalent and is reported back as skipped.
class ChoreoImportUtil {
  /// Width (in waypoint relative position) given to a Choreo constraint that
  /// applies at a single waypoint, since PathPlanner zones need a range.
  static const num singleWaypointZoneWidth = 0.1;

  /// Build a path from decoded .traj JSON. [split] picks one segment of a
  /// split trajectory (Choreo's "Name.0", "Name.1", ...), or null for all of it.
  ///
  /// Returns the new path (not yet saved) and a description of each Choreo
  /// constraint that couldn't be converted.
  static ({PathPlannerPath path, List<String> skipped}) pathFromTraj(
    Map<String, dynamic> json, {
    required String name,
    required String pathDir,
    required FileSystem fs,
    required PathConstraints defaultConstraints,
    int? split,
    String? folder,
  }) {
    List<dynamic> allWaypoints = json['params']['waypoints'];
    List<num> allTimes = [
      for (dynamic t in json['trajectory']['waypoints']) t as num
    ];
    List<Map<String, dynamic>> samples = [
      for (dynamic s in json['trajectory']['samples']) s as Map<String, dynamic>
    ];

    // Split segments run between waypoints flagged as split points
    int lastIdx = allWaypoints.length - 1;
    List<int> bounds = [
      0,
      for (int i = 1; i < lastIdx; i++)
        if (allWaypoints[i]['split'] == true) i,
      lastIdx,
    ];
    int start = split == null ? 0 : bounds[split];
    int end = split == null ? lastIdx : bounds[split + 1];
    int segments = end - start;

    List<Translation2d> anchors = [
      for (int i = start; i <= end; i++)
        Translation2d(_val(allWaypoints[i]['x']), _val(allWaypoints[i]['y'])),
    ];
    List<num> times = allTimes.sublist(start, end + 1);
    List<Map<String, dynamic>> atWaypoint = [
      for (num t in times) _sampleAt(samples, t)
    ];

    // Handles point along Choreo's direction of travel at each waypoint, a
    // third of the way to the neighbouring waypoint
    List<Waypoint> waypoints = [];
    for (int i = 0; i <= segments; i++) {
      Translation2d dir = _travelDirection(anchors, atWaypoint, i);
      waypoints.add(Waypoint(
        anchor: anchors[i],
        prevControl: i > 0
            ? anchors[i] - dir * (anchors[i].getDistance(anchors[i - 1]) / 3)
            : null,
        nextControl: i < segments
            ? anchors[i] + dir * (anchors[i].getDistance(anchors[i + 1]) / 3)
            : null,
      ));
    }

    PathConstraints globalConstraints = defaultConstraints.clone();
    bool globalFromChoreo = false;
    Map<(num, num), ConstraintsZone> zones = {};
    List<PointTowardsZone> pointZones = [];
    List<String> skipped = [];

    // Whole-path limits go first so zones copy them into the limits they
    // don't override
    List<Map<String, dynamic>> constraints = [
      for (Map<String, dynamic> c in json['params']['constraints'])
        if (c['enabled'] != false) c
    ];
    bool coversSegment(Map<String, dynamic> c) =>
        _index(c['from'], lastIdx) <= start &&
        (c['to'] == null
                ? _index(c['from'], lastIdx)
                : _index(c['to'], lastIdx)) >=
            end;
    constraints.sort((x, y) =>
        (coversSegment(y) ? 1 : 0).compareTo(coversSegment(x) ? 1 : 0));

    for (Map<String, dynamic> c in constraints) {
      String type = c['data']['type'];
      Map<String, dynamic> props = c['data']['props'] ?? {};
      int from = _index(c['from'], lastIdx);
      int to = c['to'] == null ? from : _index(c['to'], lastIdx);
      // Shift to this segment, dropping constraints that are entirely outside
      // it, or a range that only touches it at the split waypoint
      if (to < start || from > end) continue;
      if (from != to && (to == start || from == end)) continue;
      num lo = max(from, start) - start;
      num hi = min(to, end) - start;
      bool wholePath = lo == 0 && hi == segments;
      String where = from == to ? 'waypoint $from' : 'waypoints $from-$to';

      switch (type) {
        case 'MaxVelocity':
        case 'MaxAcceleration':
        case 'MaxAngularVelocity':
          num limit = _val(props['max']);
          if (type == 'MaxAngularVelocity') {
            if (limit <= 0) {
              // Choreo uses 0 to hold the heading; the rotation targets
              // below already keep its solved heading
              skipped.add('MaxAngularVelocity 0 ($where)');
              continue;
            }
            limit = limit * 180 / pi;
          }
          PathConstraints target;
          if (wholePath) {
            target = globalConstraints;
            globalFromChoreo = true;
          } else {
            if (lo == hi) {
              lo = max(0, lo - singleWaypointZoneWidth / 2);
              hi = min(segments, hi + singleWaypointZoneWidth / 2);
            }
            ConstraintsZone zone = zones.putIfAbsent(
                (lo, hi),
                () => ConstraintsZone(
                      minWaypointRelativePos: lo,
                      maxWaypointRelativePos: hi,
                      constraints: globalConstraints.clone(),
                      name: 'Choreo $where',
                    ));
            target = zone.constraints;
          }
          if (type == 'MaxVelocity') {
            target.maxVelocityMPS = limit;
          } else if (type == 'MaxAcceleration') {
            target.maxAccelerationMPSSq = limit;
          } else {
            target.maxAngularVelocityDeg = limit;
          }
        case 'PointAt':
          // At a single waypoint, the solved heading (a rotation target) is
          // already pointing at it
          if (lo == hi) continue;
          pointZones.add(PointTowardsZone(
            fieldPosition: Translation2d(_val(props['x']), _val(props['y'])),
            rotationOffset: props['flip'] == true
                ? Rotation2d.fromDegrees(180)
                : const Rotation2d(),
            minWaypointRelativePos: lo,
            maxWaypointRelativePos: hi,
            name: 'Choreo PointAt $where',
          ));
        case 'StopPoint':
          // Stops at the ends come through as the start/end velocities
          if (from > start && from < end) skipped.add('StopPoint ($where)');
        default:
          skipped.add('$type ($where)');
      }
    }

    // Choreo's solved heading at each interior waypoint, unless a point
    // towards zone is controlling the rotation there
    List<RotationTarget> rotationTargets = [
      for (int i = 1; i < segments; i++)
        if (!pointZones.any((z) =>
            i >= z.minWaypointRelativePos && i <= z.maxWaypointRelativePos))
          RotationTarget(i, _heading(atWaypoint[i])),
    ];

    List<EventMarker> eventMarkers = [];
    for (Map<String, dynamic> e in json['events'] ?? []) {
      num t = (e['from']['targetTimestamp'] ?? 0) + _val(e['from']['offset']);
      num? pos = _relativePos(times, t, includeEnd: end == lastIdx);
      if (pos != null) {
        eventMarkers
            .add(EventMarker(name: e['name'], waypointRelativePos: pos));
      }
    }

    PathPlannerPath path = PathPlannerPath(
      name: name,
      waypoints: waypoints,
      globalConstraints: globalConstraints,
      goalEndState:
          GoalEndState(_speed(atWaypoint.last), _heading(atWaypoint.last)),
      constraintZones: zones.values.toList(),
      pointTowardsZones: pointZones,
      rotationTargets: rotationTargets,
      eventMarkers: eventMarkers,
      pathDir: pathDir,
      fs: fs,
      reversed: false,
      folder: folder,
      idealStartingState: IdealStartingState(
          _speed(atWaypoint.first), _heading(atWaypoint.first)),
      useDefaultConstraints: !globalFromChoreo,
    );
    return (path: path, skipped: skipped);
  }

  /// Choreo stores most numbers as {"exp": "2 m / s", "val": 2.0}.
  static num _val(dynamic v) => v is Map ? v['val'] as num : (v ?? 0) as num;

  /// Choreo constraint endpoints are waypoint indices, "first" or "last".
  static int _index(dynamic v, int lastIdx) {
    if (v == 'first') return 0;
    if (v == 'last') return lastIdx;
    return (v as num).toInt();
  }

  /// The trajectory sample closest in time to [t].
  static Map<String, dynamic> _sampleAt(
      List<Map<String, dynamic>> samples, num t) {
    Map<String, dynamic> best = samples.first;
    for (Map<String, dynamic> s in samples) {
      if ((s['t'] - t).abs() < (best['t'] - t).abs()) best = s;
    }
    return best;
  }

  static num _speed(Map<String, dynamic> s) =>
      Translation2d(s['vx'], s['vy']).norm;

  static Rotation2d _heading(Map<String, dynamic> s) =>
      Rotation2d.fromRadians(s['heading']);

  /// Unit direction of travel at waypoint [i]: Choreo's velocity there, or the
  /// direction between its neighbours if the robot is (nearly) stopped.
  static Translation2d _travelDirection(List<Translation2d> anchors,
      List<Map<String, dynamic>> atWaypoint, int i) {
    Translation2d v = Translation2d(atWaypoint[i]['vx'], atWaypoint[i]['vy']);
    if (v.norm < 1e-3) {
      v = anchors[min(i + 1, anchors.length - 1)] - anchors[max(i - 1, 0)];
    }
    return v.norm < 1e-9 ? const Translation2d() : v / v.norm;
  }

  /// Waypoint relative position (segment index + fraction) for time [t], or
  /// null if [t] isn't within these waypoint times. An event exactly on a split
  /// belongs to the segment that starts there, so only the last segment of the
  /// trajectory includes its end time.
  static num? _relativePos(List<num> times, num t, {required bool includeEnd}) {
    for (int i = 0; i < times.length - 1; i++) {
      bool last = i == times.length - 2;
      if (t >= times[i] &&
          (t < times[i + 1] || (last && includeEnd && t == times[i + 1]))) {
        num span = times[i + 1] - times[i];
        return i + (span > 0 ? (t - times[i]) / span : 0);
      }
    }
    return null;
  }
}
