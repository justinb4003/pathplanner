import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/util/auto_smooth_util.dart';
import 'package:pathplanner/util/wpimath/geometry.dart';

const double eps = 1e-9;

/// Recover the tangent D at every anchor from the control points.
List<Translation2d> tangents(
    List<Translation2d> a, List<(Translation2d?, Translation2d?)> c) {
  int n = a.length - 1;
  return [
    for (int i = 0; i <= n; i++)
      i < n
          ? (c[i].$2! - a[i]) * (3 / a[i].getDistance(a[i + 1]))
          : (a[i] - c[i].$1!) * (3 / a[i - 1].getDistance(a[i])),
  ];
}

num cross(Translation2d u, Translation2d v) => u.x * v.y - u.y * v.x;

void expectTranslation(Translation2d actual, Translation2d expected) {
  expect(actual.x, closeTo(expected.x, eps));
  expect(actual.y, closeTo(expected.y, eps));
}

void main() {
  group('AutoSmoothUtil.controlPoints', () {
    test('two anchors give a straight line with handles at 1/3 and 2/3', () {
      var c = AutoSmoothUtil.controlPoints(
          [const Translation2d(0, 0), const Translation2d(3, 6)]);
      expect(c[0].$1, isNull);
      expect(c[1].$2, isNull);
      expectTranslation(c[0].$2!, const Translation2d(1, 2));
      expectTranslation(c[1].$1!, const Translation2d(2, 4));
    });

    test('collinear anchors give collinear control points', () {
      var a = const [
        Translation2d(0, 0),
        Translation2d(1, 1),
        Translation2d(3, 3),
        Translation2d(3.5, 3.5),
        Translation2d(7, 7),
      ];
      for (var (prev, next) in AutoSmoothUtil.controlPoints(a)) {
        for (Translation2d? control in [prev, next]) {
          if (control == null) continue;
          expect(control.x, closeTo(control.y, eps));
        }
      }
    });

    test('uniform spacing satisfies D[i-1] + 4D[i] + D[i+1] = 3(P[i+1]-P[i-1])',
        () {
      // Unit spacing between all anchors (zig-zag so it is not collinear)
      var a = const [
        Translation2d(0, 0),
        Translation2d(1, 0),
        Translation2d(1, 1),
        Translation2d(2, 1),
        Translation2d(2, 2),
        Translation2d(3, 2),
      ];
      var d = tangents(a, AutoSmoothUtil.controlPoints(a));
      for (int i = 1; i < a.length - 1; i++) {
        expectTranslation(
            d[i - 1] + d[i] * 4 + d[i + 1], (a[i + 1] - a[i - 1]) * 3);
      }
      // Natural ends
      int n = a.length - 1;
      expectTranslation(d[0] * 2 + d[1], (a[1] - a[0]) * 3);
      expectTranslation(d[n - 1] + d[n] * 2, (a[n] - a[n - 1]) * 3);
    });

    test('non-uniform spacing satisfies the general interior equation', () {
      var a = const [
        Translation2d(0, 0),
        Translation2d(2, 1),
        Translation2d(2.5, 4),
        Translation2d(6, 3),
        Translation2d(7, -1),
      ];
      var d = tangents(a, AutoSmoothUtil.controlPoints(a));
      num h(int i) => a[i].getDistance(a[i + 1]);
      for (int i = 1; i < a.length - 1; i++) {
        Translation2d lhs = d[i - 1] * h(i) +
            d[i] * (2 * (h(i - 1) + h(i))) +
            d[i + 1] * h(i - 1);
        Translation2d rhs = ((a[i] - a[i - 1]) * (h(i) / h(i - 1)) +
                (a[i + 1] - a[i]) * (h(i - 1) / h(i))) *
            3;
        expectTranslation(lhs, rhs);
      }
    });

    test('locked ends keep the requested direction', () {
      var a = const [
        Translation2d(0, 0),
        Translation2d(2, 1),
        Translation2d(3, 4),
        Translation2d(6, 3),
      ];
      var c = AutoSmoothUtil.controlPoints(a,
          startDir: const Translation2d(0, 5),
          endDir: const Translation2d(-3, -4));
      // Start handle points along +y, end handle arrives along (-3,-4)/5
      var d = tangents(a, c);
      expectTranslation(d.first, const Translation2d(0, 1));
      expectTranslation(d.last, const Translation2d(-0.6, -0.8));
    });

    test('zero-length end directions are treated as natural ends', () {
      var a = const [
        Translation2d(0, 0),
        Translation2d(1, 1),
        Translation2d(2, 0),
      ];
      var natural = AutoSmoothUtil.controlPoints(a);
      var zero = AutoSmoothUtil.controlPoints(a,
          startDir: const Translation2d(), endDir: const Translation2d());
      for (int i = 0; i < a.length; i++) {
        expect(zero[i], natural[i]);
      }
    });

    test('joints are C1: prev/next handles are collinear through the anchor',
        () {
      var a = const [
        Translation2d(0, 0),
        Translation2d(2, 1),
        Translation2d(2.5, 4),
        Translation2d(6, 3),
        Translation2d(7, -1),
      ];
      for (bool locked in [false, true]) {
        var c = AutoSmoothUtil.controlPoints(a,
            startDir: locked ? const Translation2d(1, 1) : null,
            endDir: locked ? const Translation2d(1, -2) : null);
        for (int i = 1; i < a.length - 1; i++) {
          Translation2d inV = a[i] - c[i].$1!;
          Translation2d outV = c[i].$2! - a[i];
          expect(cross(inV, outV), closeTo(0, eps));
          expect(inV.x * outV.x + inV.y * outV.y, greaterThan(0));
        }
      }
    });

    test('zero-length segments do not produce NaN', () {
      var c = AutoSmoothUtil.controlPoints(const [
        Translation2d(0, 0),
        Translation2d(0, 0),
        Translation2d(1, 1),
      ]);
      for (var (prev, next) in c) {
        for (Translation2d? control in [prev, next]) {
          if (control == null) continue;
          expect(control.x.isFinite && control.y.isFinite, true);
        }
      }
    });

    test('fewer than two anchors gives no control points', () {
      expect(AutoSmoothUtil.controlPoints([]), isEmpty);
      expect(AutoSmoothUtil.controlPoints([const Translation2d(1, 1)]),
          [(null, null)]);
    });
  });
}
