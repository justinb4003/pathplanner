import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/path/pathplanner_path.dart';
import 'package:pathplanner/path/waypoint.dart';
import 'package:pathplanner/util/wpimath/geometry.dart';

void main() {
  late MemoryFileSystem fs;

  PathPlannerPath named(String name) =>
      PathPlannerPath.defaultPath(pathDir: '/paths', fs: fs, name: name);

  setUp(() {
    fs = MemoryFileSystem();
    fs.directory('/paths').createSync();
    Waypoint.linked.clear();
  });

  test('previousSegment is saved only when set', () {
    final path = named('B');
    expect(path.toJson().containsKey('previousSegment'), false);

    path.previousSegment = 'A';
    final json = path.toJson();
    expect(json['previousSegment'], 'A');
    expect(
        PathPlannerPath.fromJson(json, 'B', '/paths', fs).previousSegment, 'A');

    // A copy would be a second segment after A
    expect(path.duplicate('C').previousSegment, isNull);
  });

  test('segments stay joined', () {
    final a = named('A');
    final b = named('B')..previousSegment = 'A';
    final paths = [a, b];

    // Editing the previous segment moves the start of the next one
    a.waypoints.last.move(5.0, 5.0);
    a.goalEndState.rotation = Rotation2d.fromDegrees(45);
    expect(PathPlannerPath.syncLinked(paths, a), {b});
    expect(b.waypoints.first.anchor, const Translation2d(5.0, 5.0));
    expect(b.idealStartingState.rotation.degrees, closeTo(45, 1e-9));

    // And editing the next one moves the end of the previous one
    b.waypoints.first.move(6.0, 4.0);
    expect(PathPlannerPath.syncLinked(paths, b), {a});
    expect(a.waypoints.last.anchor, const Translation2d(6.0, 4.0));

    expect(PathPlannerPath.syncLinked(paths, b), isEmpty);
  });

  test('field spots move every waypoint on them', () {
    final a = named('A')..addWaypoint(const Translation2d(6.0, 5.0));
    final b = named('B');
    a.waypoints[1].linkedName = 'Shoot';
    b.waypoints.first.linkedName = 'Shoot';
    final paths = [a, b];

    // Moving the start of B and its rotation moves the spot
    b.waypoints.first.move(3.0, 3.0);
    b.idealStartingState.rotation = Rotation2d.fromDegrees(30);
    expect(PathPlannerPath.syncLinked(paths, b), {a});

    // A uses the spot in the middle of the path, so it gets a rotation target
    expect(a.waypoints[1].anchor, const Translation2d(3.0, 3.0));
    final target =
        a.rotationTargets.singleWhere((t) => t.waypointRelativePos == 1);
    expect(target.rotation.degrees, closeTo(30, 1e-9));

    // Turning that rotation target turns the spot
    target.rotation = Rotation2d.fromDegrees(-90);
    expect(PathPlannerPath.syncLinked(paths, a), {b});
    expect(b.idealStartingState.rotation.degrees, closeTo(-90, 1e-9));
  });

  test('a segment joint on a field spot stays on it', () {
    final a = named('A');
    final b = named('B')..previousSegment = 'A';
    final c = named('C');
    a.waypoints.last.linkedName = 'Shoot';
    c.waypoints.first.linkedName = 'Shoot';
    final paths = [a, b, c];

    // B's start joins the spot too
    PathPlannerPath.syncLinked(paths, a);
    expect(b.waypoints.first.linkedName, 'Shoot');

    // So moving the spot from C moves both ends of the joint
    c.waypoints.first.move(7.0, 2.0);
    expect(PathPlannerPath.syncLinked(paths, c), {a, b});
    expect(a.waypoints.last.anchor, const Translation2d(7.0, 2.0));
    expect(b.waypoints.first.anchor, const Translation2d(7.0, 2.0));
  });

  test('old "A -> B" segment links are migrated', () {
    final a = named('A');
    final b = named('B');
    a.waypoints.last.linkedName = 'A -> B';
    b.waypoints.first.linkedName = 'A -> B';
    Waypoint.linked['A -> B'] = const Pose2d(Translation2d(), Rotation2d());

    PathPlannerPath.migrateSegmentLinks([a, b]);

    expect(b.previousSegment, 'A');
    expect(a.waypoints.last.linkedName, isNull);
    expect(b.waypoints.first.linkedName, isNull);
    expect(Waypoint.linked, isEmpty);
  });

  test('rename and delete field spots', () {
    final a = named('A');
    final b = named('B');
    a.waypoints.last.linkedName = 'Shoot';
    b.waypoints.first.linkedName = 'Shoot';
    a.updateLinkedWaypoints();

    PathPlannerPath.renameLinkedWaypoint([a, b], 'Shoot', 'Hub');
    expect(Waypoint.linked.keys, ['Hub']);
    expect(a.waypoints.last.linkedName, 'Hub');
    expect(b.waypoints.first.linkedName, 'Hub');

    PathPlannerPath.deleteLinkedWaypoint([a, b], 'Hub');
    expect(Waypoint.linked, isEmpty);
    expect(a.waypoints.last.linkedName, isNull);
    expect(b.waypoints.first.linkedName, isNull);
  });
}
