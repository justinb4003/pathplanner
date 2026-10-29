import 'dart:math';

import 'package:pathplanner/util/wpimath/geometry.dart';

/// Picks every Bezier control point of a path from its anchors alone, so the
/// path is as smooth as possible: a natural cubic spline, the curve through
/// the anchors with the least total (squared) acceleration.
///
/// Segments are weighted by their length (chord-length parameterization), so
/// unevenly spaced waypoints don't bulge or overshoot. The same math lives on
/// the robot side in Rebuilt2026's utilities/path_smoothing.py.
class AutoSmoothUtil {
  /// Segments shorter than this are treated as this long, so two anchors on
  /// top of each other don't divide by zero.
  static const num minSegmentLength = 1e-6;

  /// Control points for a smooth path through [anchors].
  ///
  /// Returns one (prevControl, nextControl) pair per anchor. Like PathPlanner's
  /// own waypoints, the first anchor's prevControl and the last anchor's
  /// nextControl are null.
  ///
  /// [startDir] and [endDir] pin the direction of travel at the ends; only the
  /// direction matters. Leave them null (or zero length) for a "natural" end
  /// with no bend.
  static List<(Translation2d?, Translation2d?)> controlPoints(
      List<Translation2d> anchors,
      {Translation2d? startDir,
      Translation2d? endDir}) {
    int count = anchors.length;
    if (count < 2) {
      return List.filled(count, (null, null));
    }
    int n = count - 1;

    // Length of each segment, used as its "duration" along the spline
    List<num> h = [
      for (int i = 0; i < n; i++)
        max(anchors[i].getDistance(anchors[i + 1]), minSegmentLength),
    ];

    List<Translation2d> tangents =
        _solveTangents(anchors, h, _unit(startDir), _unit(endDir));

    // A cubic Bezier's handles sit a third of the segment out along the
    // tangent at each end
    List<(Translation2d?, Translation2d?)> controls =
        List.filled(count, (null, null));
    for (int i = 0; i < count; i++) {
      Translation2d? prev =
          i > 0 ? anchors[i] - tangents[i] * (h[i - 1] / 3) : null;
      Translation2d? next =
          i < n ? anchors[i] + tangents[i] * (h[i] / 3) : null;
      controls[i] = (prev, next);
    }
    return controls;
  }

  /// Tangent (direction of travel, about 1 per meter) at every anchor.
  ///
  /// Making the curve's second derivative match on both sides of each interior
  /// anchor gives one equation per anchor:
  ///   h[i] * D[i-1] + 2 * (h[i-1] + h[i]) * D[i] + h[i-1] * D[i+1]
  ///     = 3 * (h[i] * (P[i] - P[i-1]) / h[i-1] + h[i-1] * (P[i+1] - P[i]) / h[i])
  /// Each end either pins its tangent, or uses the "no bend" (natural) rule
  ///   2 * D[0] + D[1] = 3 * (P[1] - P[0]) / h[0]
  /// The result is tridiagonal, so it is solved directly in one pass each way
  /// (the Thomas algorithm).
  static List<Translation2d> _solveTangents(List<Translation2d> p, List<num> h,
      Translation2d? startDir, Translation2d? endDir) {
    int count = p.length;
    int n = count - 1;

    // Row i is: lower[i] * D[i-1] + diag[i] * D[i] + upper[i] * D[i+1] = rhs[i]
    List<num> lower = List.filled(count, 0);
    List<num> diag = List.filled(count, 0);
    List<num> upper = List.filled(count, 0);
    List<Translation2d> rhs = List.filled(count, const Translation2d());

    if (startDir != null) {
      diag[0] = 1;
      rhs[0] = startDir;
    } else {
      diag[0] = 2;
      upper[0] = 1;
      rhs[0] = (p[1] - p[0]) * (3 / h[0]);
    }

    for (int i = 1; i < n; i++) {
      lower[i] = h[i];
      diag[i] = 2 * (h[i - 1] + h[i]);
      upper[i] = h[i - 1];
      rhs[i] = ((p[i] - p[i - 1]) * (h[i] / h[i - 1]) +
              (p[i + 1] - p[i]) * (h[i - 1] / h[i])) *
          3;
    }

    if (endDir != null) {
      diag[n] = 1;
      rhs[n] = endDir;
    } else {
      lower[n] = 1;
      diag[n] = 2;
      rhs[n] = (p[n] - p[n - 1]) * (3 / h[n - 1]);
    }

    // Forward pass: eliminate the lower diagonal
    List<num> upperPrime = List.filled(count, 0);
    List<Translation2d> rhsPrime = List.filled(count, const Translation2d());
    upperPrime[0] = upper[0] / diag[0];
    rhsPrime[0] = rhs[0] / diag[0];
    for (int i = 1; i < count; i++) {
      num m = diag[i] - lower[i] * upperPrime[i - 1];
      upperPrime[i] = upper[i] / m;
      rhsPrime[i] = (rhs[i] - rhsPrime[i - 1] * lower[i]) / m;
    }

    // Back substitution
    List<Translation2d> tangents = List.filled(count, const Translation2d());
    tangents[n] = rhsPrime[n];
    for (int i = n - 1; i >= 0; i--) {
      tangents[i] = rhsPrime[i] - tangents[i + 1] * upperPrime[i];
    }
    return tangents;
  }

  /// [v] scaled to length 1, or null if it is null or (nearly) zero length.
  static Translation2d? _unit(Translation2d? v) {
    if (v == null) return null;
    num len = v.norm;
    if (len < 1e-9 || !len.isFinite) return null;
    return v / len;
  }
}
