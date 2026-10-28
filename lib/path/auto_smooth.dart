import 'dart:math';

/// Minimum segment length used to avoid dividing by zero.
const double autoSmoothMinSegmentLength = 1e-6;

/// Result of [solveAutoSmooth]. For anchor i, [next] is its nextControl (null
/// for the last anchor) and [prev] is its prevControl (null for the first).
class AutoSmoothResult {
  final List<(double, double)?> prev;
  final List<(double, double)?> next;

  const AutoSmoothResult(this.prev, this.next);
}

/// Computes all Bezier control points for a C2-continuous, chord-length
/// parameterized cubic spline through [anchors] (the minimum integral of
/// |p''|^2 interpolant).
///
/// With [startDir] / [endDir] null the corresponding end is natural. If given,
/// the end tangent D is the unit vector of that direction. A direction with
/// (near) zero length is treated as null.
///
/// Pure math, no Flutter dependency. Mirrors the robot-side Python version.
AutoSmoothResult solveAutoSmooth(
  List<(double, double)> anchors, {
  (double, double)? startDir,
  (double, double)? endDir,
}) {
  final int count = anchors.length;
  if (count < 2) {
    return AutoSmoothResult(List.filled(count, null), List.filled(count, null));
  }
  final int n = count - 1;

  final List<double> h = [
    for (int i = 0; i < n; i++)
      max(
        sqrt(
          pow(anchors[i + 1].$1 - anchors[i].$1, 2) +
              pow(anchors[i + 1].$2 - anchors[i].$2, 2),
        ),
        autoSmoothMinSegmentLength,
      ),
  ];

  (double, double)? unit((double, double)? v) {
    if (v == null) return null;
    final len = sqrt(v.$1 * v.$1 + v.$2 * v.$2);
    if (len < 1e-9 || !len.isFinite) return null;
    return (v.$1 / len, v.$2 / len);
  }

  final sDir = unit(startDir);
  final eDir = unit(endDir);

  // Tridiagonal system: lower[i]*D[i-1] + diag[i]*D[i] + upper[i]*D[i+1] = rhs
  final lower = List<double>.filled(count, 0);
  final diag = List<double>.filled(count, 0);
  final upper = List<double>.filled(count, 0);
  final rx = List<double>.filled(count, 0);
  final ry = List<double>.filled(count, 0);

  // Start row
  if (sDir != null) {
    diag[0] = 1;
    rx[0] = sDir.$1;
    ry[0] = sDir.$2;
  } else {
    diag[0] = 2;
    upper[0] = 1;
    rx[0] = 3 * (anchors[1].$1 - anchors[0].$1) / h[0];
    ry[0] = 3 * (anchors[1].$2 - anchors[0].$2) / h[0];
  }

  // Interior rows
  for (int i = 1; i < n; i++) {
    lower[i] = h[i];
    diag[i] = 2 * (h[i - 1] + h[i]);
    upper[i] = h[i - 1];
    rx[i] = 3 *
        (h[i] * (anchors[i].$1 - anchors[i - 1].$1) / h[i - 1] +
            h[i - 1] * (anchors[i + 1].$1 - anchors[i].$1) / h[i]);
    ry[i] = 3 *
        (h[i] * (anchors[i].$2 - anchors[i - 1].$2) / h[i - 1] +
            h[i - 1] * (anchors[i + 1].$2 - anchors[i].$2) / h[i]);
  }

  // End row
  if (eDir != null) {
    diag[n] = 1;
    rx[n] = eDir.$1;
    ry[n] = eDir.$2;
  } else {
    lower[n] = 1;
    diag[n] = 2;
    rx[n] = 3 * (anchors[n].$1 - anchors[n - 1].$1) / h[n - 1];
    ry[n] = 3 * (anchors[n].$2 - anchors[n - 1].$2) / h[n - 1];
  }

  // Thomas algorithm (shared matrix, x and y right-hand sides)
  final cp = List<double>.filled(count, 0);
  final dx = List<double>.filled(count, 0);
  final dy = List<double>.filled(count, 0);
  cp[0] = upper[0] / diag[0];
  dx[0] = rx[0] / diag[0];
  dy[0] = ry[0] / diag[0];
  for (int i = 1; i < count; i++) {
    final m = diag[i] - lower[i] * cp[i - 1];
    cp[i] = upper[i] / m;
    dx[i] = (rx[i] - lower[i] * dx[i - 1]) / m;
    dy[i] = (ry[i] - lower[i] * dy[i - 1]) / m;
  }
  final tx = List<double>.filled(count, 0);
  final ty = List<double>.filled(count, 0);
  tx[n] = dx[n];
  ty[n] = dy[n];
  for (int i = n - 1; i >= 0; i--) {
    tx[i] = dx[i] - cp[i] * tx[i + 1];
    ty[i] = dy[i] - cp[i] * ty[i + 1];
  }

  final prev = List<(double, double)?>.filled(count, null);
  final next = List<(double, double)?>.filled(count, null);
  for (int i = 0; i < n; i++) {
    final k = h[i] / 3.0;
    next[i] = (anchors[i].$1 + k * tx[i], anchors[i].$2 + k * ty[i]);
    prev[i + 1] = (
      anchors[i + 1].$1 - k * tx[i + 1],
      anchors[i + 1].$2 - k * ty[i + 1],
    );
  }
  return AutoSmoothResult(prev, next);
}
