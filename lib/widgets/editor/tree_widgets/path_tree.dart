import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pathplanner/path/path_constraints.dart';
import 'package:pathplanner/path/pathplanner_path.dart';
import 'package:pathplanner/path/waypoint.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/constraint_zones_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/editor_settings_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/event_markers_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/global_constraints_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/goal_end_state_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/ideal_starting_state_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/path_optimization_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/point_towards_zones_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/rotation_targets_tree.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/waypoints_tree.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undo/undo.dart';

class PathTree extends StatefulWidget {
  final PathPlannerPath path;
  final ValueChanged<int?>? onWaypointHovered;
  final ValueChanged<int?>? onWaypointSelected;
  final ValueChanged<int?>? onZoneHovered;
  final ValueChanged<int?>? onZoneSelected;
  final ValueChanged<int?>? onPointZoneHovered;
  final ValueChanged<int?>? onPointZoneSelected;
  final ValueChanged<int?>? onRotTargetHovered;
  final ValueChanged<int?>? onRotTargetSelected;
  final ValueChanged<int?>? onMarkerHovered;
  final ValueChanged<int?>? onMarkerSelected;
  final ValueChanged<int>? onWaypointDeleted;
  final ValueChanged<PathPlannerPath?>? onOptimizationUpdate;
  final VoidCallback? onSideSwapped;
  final VoidCallback? onPathChanged;
  final VoidCallback? onPathChangedNoSim;
  final WaypointsTreeController? waypointsTreeController;
  final (int, int)? waypointRange;
  final ValueChanged<(int, int)?>? onWaypointRangeChanged;
  final int? initiallySelectedWaypoint;
  final int? initiallySelectedZone;
  final int? initiallySelectedPointZone;
  final int? initiallySelectedRotTarget;
  final int? initiallySelectedMarker;
  final ChangeStack undoStack;
  final num? pathRuntime;
  final bool holonomicMode;
  final PathConstraints defaultConstraints;
  final SharedPreferences prefs;
  final Widget? runtimeDisplay;
  final Size fieldSizeMeters;
  final VoidCallback? onRenderPath;
  final List<PathPlannerPath> allPaths;
  final ValueChanged<PathPlannerPath>? onOpenPath;

  const PathTree({
    super.key,
    required this.path,
    this.onWaypointHovered,
    this.onSideSwapped,
    this.onPathChanged,
    this.onWaypointSelected,
    this.waypointsTreeController,
    this.waypointRange,
    this.onWaypointRangeChanged,
    this.initiallySelectedWaypoint,
    this.onWaypointDeleted,
    this.onOptimizationUpdate,
    this.onZoneHovered,
    this.onZoneSelected,
    this.initiallySelectedZone,
    this.onPointZoneHovered,
    this.onPointZoneSelected,
    this.initiallySelectedPointZone,
    this.onRotTargetHovered,
    this.onRotTargetSelected,
    this.initiallySelectedRotTarget,
    this.onMarkerHovered,
    this.onMarkerSelected,
    this.initiallySelectedMarker,
    required this.undoStack,
    this.runtimeDisplay,
    this.pathRuntime,
    this.onPathChangedNoSim,
    required this.holonomicMode,
    required this.defaultConstraints,
    required this.prefs,
    required this.fieldSizeMeters,
    this.onRenderPath,
    this.allPaths = const [],
    this.onOpenPath,
  });

  @override
  State<PathTree> createState() => _PathTreeState();
}

class _PathTreeState extends State<PathTree> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 4.0),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (widget.path.waypoints.length > 2)
                  _buildWaypointRangeSlider(),
                _buildWaypointsTree(),
                _buildEventMarkersTree(),
                if (widget.holonomicMode) ...[
                  _buildRotationTargetsTree(),
                  _buildPointZonesTree(),
                ],
                const Divider(),
                if (widget.allPaths.isNotEmpty) _buildPreviousSegmentCard(),
                _buildIdealStartingStateTree(),
                _buildGoalEndStateTree(),
                const Divider(),
                _buildGlobalConstraintsTree(),
                _buildConstraintZonesTree(),
                if (!widget.holonomicMode) _buildReversedCheckbox(),
                _buildAutoSmoothCard(),
                const Divider(),
                _buildPathOptimizationTree(),
                const EditorSettingsTree(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!widget.holonomicMode) ...[
                _buildReversedButton(),
                const SizedBox(width: 8),
                Tooltip(
                  message:
                      'Moving ${widget.path.reversed ? 'Reversed' : 'Forward'}',
                  child: _buildInfoCard(
                    value: widget.path.reversed ? 'RVD' : 'FWD',
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (widget.runtimeDisplay != null) widget.runtimeDisplay!,
            ],
          ),
          Row(
            children: [
              Tooltip(
                message: 'Export Path to Image',
                waitDuration: const Duration(milliseconds: 500),
                child: IconButton(
                  onPressed: widget.onRenderPath,
                  icon: const Icon(Icons.ios_share),
                ),
              ),
              Tooltip(
                message: 'Move to Other Side',
                waitDuration: const Duration(milliseconds: 500),
                child: IconButton(
                  onPressed: widget.onSideSwapped,
                  icon: const Icon(Icons.swap_horiz),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(36, 0, 0, 0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.normal,
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildWaypointsTree() {
    return WaypointsTree(
      key: ValueKey('waypoints${widget.path.waypoints.length}'),
      onWaypointDeleted: widget.onWaypointDeleted,
      initialSelectedWaypoint: widget.initiallySelectedWaypoint,
      controller: widget.waypointsTreeController,
      path: widget.path,
      waypointRange: widget.waypointRange,
      onWaypointHovered: widget.onWaypointHovered,
      onWaypointSelected: widget.onWaypointSelected,
      onPathChanged: widget.onPathChanged,
      undoStack: widget.undoStack,
      holonomicMode: widget.holonomicMode,
    );
  }

  Widget _buildWaypointRangeSlider() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    int last = widget.path.waypoints.length - 1;
    var (first, end) = widget.waypointRange ?? (0, last);

    // The label and button sit above the slider so the slider's width never
    // changes while it's being dragged
    return Card(
      elevation: 1.0,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 2.0, 4.0, 2.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message:
                        'Only show these waypoints in the list and on the field, e.g. to work on one part of a path that overlaps itself',
                    waitDuration: const Duration(seconds: 1),
                    child: Text(
                      'Show waypoints $first-$end',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Show all waypoints',
                  icon: const Icon(Icons.visibility),
                  onPressed: widget.waypointRange == null
                      ? null
                      : () => widget.onWaypointRangeChanged?.call(null),
                ),
              ],
            ),
            RangeSlider(
              values: RangeValues(first.toDouble(), end.toDouble()),
              max: last.toDouble(),
              divisions: last,
              labels: RangeLabels('$first', '$end'),
              onChanged: (values) {
                int newFirst = values.start.round();
                int newEnd = values.end.round();
                // Always show at least one segment
                if (newEnd <= newFirst) return;
                widget.onWaypointRangeChanged?.call(
                    newFirst == 0 && newEnd == last
                        ? null
                        : (newFirst, newEnd));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalConstraintsTree() {
    return GlobalConstraintsTree(
      path: widget.path,
      onPathChanged: widget.onPathChanged,
      undoStack: widget.undoStack,
      defaultConstraints: widget.defaultConstraints,
    );
  }

  Widget _buildIdealStartingStateTree() {
    return IdealStartingStateTree(
      path: widget.path,
      undoStack: widget.undoStack,
      holonomicMode: widget.holonomicMode,
      onPathChanged: widget.onPathChanged,
    );
  }

  Widget _buildGoalEndStateTree() {
    return GoalEndStateTree(
      path: widget.path,
      onPathChanged: widget.onPathChanged,
      undoStack: widget.undoStack,
      holonomicMode: widget.holonomicMode,
    );
  }

  Widget _buildRotationTargetsTree() {
    return RotationTargetsTree(
      key: ValueKey('rotations${widget.path.rotationTargets.length}'),
      path: widget.path,
      onPathChanged: widget.onPathChanged,
      onPathChangedNoSim: widget.onPathChangedNoSim,
      onTargetHovered: widget.onRotTargetHovered,
      onTargetSelected: widget.onRotTargetSelected,
      initiallySelectedTarget: widget.initiallySelectedRotTarget,
      undoStack: widget.undoStack,
    );
  }

  Widget _buildPointZonesTree() {
    return PointTowardsZonesTree(
      key: ValueKey('pointZones${widget.path.pointTowardsZones.length}'),
      path: widget.path,
      onPathChanged: widget.onPathChanged,
      onPathChangedNoSim: widget.onPathChangedNoSim,
      onZoneHovered: widget.onPointZoneHovered,
      onZoneSelected: widget.onPointZoneSelected,
      initiallySelectedZone: widget.initiallySelectedPointZone,
      undoStack: widget.undoStack,
    );
  }

  Widget _buildEventMarkersTree() {
    return EventMarkersTree(
      key: ValueKey('markers${widget.path.eventMarkers.length}'),
      path: widget.path,
      onPathChangedNoSim: widget.onPathChangedNoSim,
      onMarkerHovered: widget.onMarkerHovered,
      onMarkerSelected: widget.onMarkerSelected,
      initiallySelectedMarker: widget.initiallySelectedMarker,
      undoStack: widget.undoStack,
    );
  }

  Widget _buildConstraintZonesTree() {
    return ConstraintZonesTree(
      key: ValueKey('zones${widget.path.constraintZones.length}'),
      path: widget.path,
      onPathChanged: widget.onPathChanged,
      onPathChangedNoSim: widget.onPathChangedNoSim,
      onZoneHovered: widget.onZoneHovered,
      onZoneSelected: widget.onZoneSelected,
      initiallySelectedZone: widget.initiallySelectedZone,
      undoStack: widget.undoStack,
    );
  }

  Widget _buildReversedButton() {
    return Tooltip(
      message: widget.path.reversed ? 'Unreverse Path' : 'Reverse Path',
      child: GestureDetector(
        onTap: () {
          bool newReversed = !widget.path.reversed;

          widget.undoStack.add(Change(
            widget.path.reversed,
            () {
              widget.path.reversed = newReversed;
              widget.onPathChanged?.call();
            },
            (oldValue) {
              widget.path.reversed = oldValue;
              widget.onPathChanged?.call();
            },
          ));
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(36, 0, 0, 0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.path.reversed
                ? Icons.arrow_forward_rounded
                : Icons.arrow_back_rounded,
            color: Colors.white,
            size: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildReversedCheckbox() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1.0,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        child: Row(
          children: [
            Checkbox(
              value: widget.path.reversed,
              onChanged: (value) {
                bool reversed = value ?? false;

                widget.undoStack.add(Change(
                  widget.path.reversed,
                  () {
                    widget.path.reversed = reversed;
                    widget.onPathChanged?.call();
                  },
                  (oldValue) {
                    widget.path.reversed = oldValue;
                    widget.onPathChanged?.call();
                  },
                ));
              },
            ),
            const SizedBox(width: 4),
            const Text(
              'Reversed',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Links this path after another one, e.g. the pieces of a split Choreo
  /// trajectory. The end of the previous segment and the start of this one
  /// become a linked waypoint, so dragging either one moves both.
  Widget _buildPreviousSegmentCard() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    final path = widget.path;
    final startLink = path.waypoints.first.linkedName;
    final previous = startLink == null
        ? null
        : widget.allPaths.firstWhereOrNull(
            (p) => p != path && p.waypoints.last.linkedName == startLink);
    final endLink = path.waypoints.last.linkedName;
    final next = endLink == null
        ? null
        : widget.allPaths.firstWhereOrNull(
            (p) => p != path && p.waypoints.first.linkedName == endLink);

    // A path is in a group if either end is linked. Two groups can't be
    // joined, so a grouped path can only link after an ungrouped one.
    bool grouped(PathPlannerPath p) =>
        p.waypoints.first.linkedName != null ||
        p.waypoints.last.linkedName != null;
    final options = previous != null
        ? [previous]
        : [
            if (startLink == null)
              for (final p in widget.allPaths)
                if (p != path &&
                    p.waypoints.last.linkedName == null &&
                    !(grouped(path) && grouped(p)))
                  p,
          ].sortedBy((p) => p.name);

    return Card(
      elevation: 1.0,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 12.0, 4.0, 8.0),
        child: Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Previous Segment',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PathPlannerPath?>(
                    value: previous,
                    isExpanded: true,
                    onChanged: (value) =>
                        _confirmPreviousSegment(value, previous),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      for (final p in options)
                        DropdownMenuItem(
                          value: p,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'Open Previous Segment',
              child: IconButton(
                onPressed: previous == null
                    ? null
                    : () => widget.onOpenPath?.call(previous),
                icon: const Icon(Icons.skip_previous_rounded),
              ),
            ),
            Tooltip(
              message: 'Open Next Segment',
              child: IconButton(
                onPressed:
                    next == null ? null : () => widget.onOpenPath?.call(next),
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Linking moves this path's start onto the previous segment's end, so ask
  /// first when they don't already match. A wrong pick in the dropdown
  /// shouldn't quietly mess up a good path.
  void _confirmPreviousSegment(
      PathPlannerPath? previous, PathPlannerPath? oldPrevious) {
    final path = widget.path;
    if (previous == null) {
      _setPreviousSegment(previous, oldPrevious);
      return;
    }

    final distance =
        path.waypoints.first.anchor.getDistance(previous.waypoints.last.anchor);
    final rotationDiff =
        (previous.goalEndState.rotation - path.idealStartingState.rotation)
            .degrees
            .abs();
    if (distance < 0.01 && rotationDiff < 0.01) {
      _setPreviousSegment(previous, oldPrevious);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        ColorScheme colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          title: const Text('Link Segments'),
          content: Text(
              'The start of ${path.name} doesn\'t match the end of ${previous.name}. Linking them will move the start of ${path.name} and its starting rotation to match.\n\nAre you sure you want to link them?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setPreviousSegment(previous, oldPrevious);
              },
              child: const Text('LINK'),
            ),
          ],
        );
      },
    );
  }

  void _setPreviousSegment(
      PathPlannerPath? previous, PathPlannerPath? oldPrevious) {
    final start = widget.path.waypoints.first;

    if (oldPrevious != null) {
      Waypoint.linked.remove(start.linkedName);
      oldPrevious.waypoints.last.linkedName = null;
      oldPrevious.saveFile();
    }
    start.linkedName = null;

    if (previous != null) {
      final end = previous.waypoints.last;
      final name = '${previous.name} -> ${widget.path.name}';
      end.linkedName = name;
      start.linkedName = name;
      start.move(end.anchor.x, end.anchor.y);
      widget.path.idealStartingState.rotation = previous.goalEndState.rotation;
      previous.saveFile();
    }

    // Saves this path and updates Waypoint.linked from its start
    widget.onPathChanged?.call();
  }

  /// Changes auto-smooth settings as one undoable step. The old waypoints are
  /// kept so undo restores hand-placed control points exactly.
  void _changeAutoSmooth({bool? smooth, bool? lockEnds}) {
    final newSmooth = smooth ?? widget.path.autoSmooth;
    final newLock = lockEnds ?? widget.path.autoSmoothLockEnds;

    widget.undoStack.add(Change(
      (
        widget.path.autoSmooth,
        widget.path.autoSmoothLockEnds,
        PathPlannerPath.cloneWaypoints(widget.path.waypoints)
      ),
      () {
        widget.path.autoSmooth = newSmooth;
        widget.path.autoSmoothLockEnds = newLock;
        widget.onPathChanged?.call();
      },
      (oldValue) {
        widget.path.autoSmooth = oldValue.$1;
        widget.path.autoSmoothLockEnds = oldValue.$2;
        widget.path.waypoints = PathPlannerPath.cloneWaypoints(oldValue.$3);
        widget.onPathChanged?.call();
      },
    ));
  }

  Widget _buildAutoSmoothCard() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1.0,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              message:
                  'Compute all control points automatically as a C2-continuous minimum-acceleration spline through the waypoints',
              waitDuration: const Duration(seconds: 1),
              child: Row(
                children: [
                  Checkbox(
                    value: widget.path.autoSmooth,
                    onChanged: (value) => _changeAutoSmooth(smooth: value),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Auto-smooth (min accel)',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            if (widget.path.autoSmooth)
              Tooltip(
                message:
                    'Use the direction of the first/last control handles for the start/end of the path. Otherwise the ends are natural.',
                waitDuration: const Duration(seconds: 1),
                child: Padding(
                  padding: const EdgeInsets.only(left: 24.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: widget.path.autoSmoothLockEnds,
                        onChanged: (value) =>
                            _changeAutoSmooth(lockEnds: value),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Lock end directions',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathOptimizationTree() {
    return PathOptimizationTree(
      path: widget.path,
      onPathChanged: widget.onPathChanged,
      onUpdate: widget.onOptimizationUpdate,
      undoStack: widget.undoStack,
      prefs: widget.prefs,
      fieldSizeMeters: widget.fieldSizeMeters,
    );
  }
}
