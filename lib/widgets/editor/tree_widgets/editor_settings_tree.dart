import 'package:flutter/material.dart';
import 'package:pathplanner/util/prefs.dart';
import 'package:pathplanner/widgets/editor/visibility_toggles.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/tree_card_node.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditorSettingsTree extends StatefulWidget {
  final bool initiallyExpanded;

  const EditorSettingsTree({
    super.key,
    this.initiallyExpanded = false,
  });

  @override
  State<EditorSettingsTree> createState() => _EditorSettingsTreeState();
}

class _EditorSettingsTreeState extends State<EditorSettingsTree> {
  late SharedPreferences _prefs;
  bool _snapToGuidelines = Defaults.snapToGuidelines;
  bool _hidePathsOnHover = Defaults.hidePathsOnHover;
  bool _showStates = Defaults.showStates;
  bool _showRobotDetails = Defaults.showRobotDetails;
  bool _showGrid = Defaults.showGrid;
  bool _showRobotOutlines = Defaults.showRobotOutlines;
  bool _showEventMarkers = Defaults.showEventMarkers;
  bool _showControlPoints = Defaults.showControlPoints;
  bool _showRotationTargets = Defaults.showRotationTargets;
  bool _showPointZones = Defaults.showPointZones;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((value) {
      setState(() {
        _prefs = value;
        _snapToGuidelines = _prefs.getBool(PrefsKeys.snapToGuidelines) ??
            Defaults.snapToGuidelines;
        _hidePathsOnHover = _prefs.getBool(PrefsKeys.hidePathsOnHover) ??
            Defaults.hidePathsOnHover;
        _showStates =
            _prefs.getBool(PrefsKeys.showStates) ?? Defaults.showStates;
        _showRobotDetails = _prefs.getBool(PrefsKeys.showRobotDetails) ??
            Defaults.showRobotDetails;
        _showGrid = _prefs.getBool(PrefsKeys.showGrid) ?? Defaults.showGrid;
      });
      _loadVisibility();
      VisibilityToggles.changed.addListener(_loadVisibility);
    });
  }

  @override
  void dispose() {
    VisibilityToggles.changed.removeListener(_loadVisibility);
    super.dispose();
  }

  /// Reads the settings that the quick toggles over the field also change
  void _loadVisibility() {
    setState(() {
      _showRobotOutlines = _prefs.getBool(PrefsKeys.showRobotOutlines) ??
          Defaults.showRobotOutlines;
      _showEventMarkers = _prefs.getBool(PrefsKeys.showEventMarkers) ??
          Defaults.showEventMarkers;
      _showControlPoints = _prefs.getBool(PrefsKeys.showControlPoints) ??
          Defaults.showControlPoints;
      _showRotationTargets = _prefs.getBool(PrefsKeys.showRotationTargets) ??
          Defaults.showRotationTargets;
      _showPointZones =
          _prefs.getBool(PrefsKeys.showPointZones) ?? Defaults.showPointZones;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TreeCardNode(
      initiallyExpanded: widget.initiallyExpanded,
      title: const Text('Editor Settings'),
      leading: const Icon(Icons.settings),
      elevation: 1.0,
      children: [
        _buildCheckboxRow(
          'Snap To Guidelines',
          _snapToGuidelines,
          _updateSnapToGuidelines,
          'Enable or disable snapping to guidelines.',
        ),
        _buildCheckboxRow(
          'Hide Other Paths on Hover',
          _hidePathsOnHover,
          _updateHidePathsOnHover,
          'Hide other paths when hovering over a specific path.',
        ),
        _buildCheckboxRow(
          'Show Trajectory States',
          _showStates,
          _updateShowStates,
          'Display trajectory states.',
        ),
        _buildCheckboxRow(
          'Show Robot Details',
          _showRobotDetails,
          _updateShowRobotDetails,
          'Display additional details about the robot\'s current rotation and position.',
        ),
        _buildCheckboxRow(
          'Show Grid',
          _showGrid,
          _updateShowGrid,
          'Toggle the visibility of the grid on the field. Each cell is 0.5M x 0.5M.',
        ),
        _buildCheckboxRow(
          'Show Robot Outlines',
          _showRobotOutlines,
          _updateShowRobotOutlines,
          'Display the robot at the start and end of the path and the preview robot.',
        ),
        _buildCheckboxRow(
          'Show Event Markers',
          _showEventMarkers,
          _updateShowEventMarkers,
          'Display event markers on the path.',
        ),
        _buildCheckboxRow(
          'Show Control Points',
          _showControlPoints,
          _updateShowControlPoints,
          'Display the control points of the waypoints. Hidden control points can\'t be dragged.',
        ),
        _buildCheckboxRow(
          'Show Rotation Targets',
          _showRotationTargets,
          _updateShowRotationTargets,
          'Display the robot at each rotation target.',
        ),
        _buildCheckboxRow(
          'Show Point Towards Zones',
          _showPointZones,
          _updateShowPointZones,
          'Display the positions that point towards zones face.',
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(
      String label, bool value, Function(bool) onChanged, String tooltip) {
    return Row(
      children: [
        Tooltip(
          message: tooltip,
          child: Checkbox(
            value: value,
            onChanged: (val) => onChanged(val!),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            bottom: 3.0,
            left: 4.0,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  void _updateSnapToGuidelines(bool value) {
    setState(() {
      _snapToGuidelines = value;
    });
    _prefs.setBool(PrefsKeys.snapToGuidelines, _snapToGuidelines);
  }

  void _updateHidePathsOnHover(bool value) {
    setState(() {
      _hidePathsOnHover = value;
    });
    _prefs.setBool(PrefsKeys.hidePathsOnHover, _hidePathsOnHover);
  }

  void _updateShowStates(bool value) {
    setState(() {
      _showStates = value;
    });
    _prefs.setBool(PrefsKeys.showStates, _showStates);
  }

  void _updateShowRobotDetails(bool value) {
    setState(() {
      _showRobotDetails = value;
    });
    _prefs.setBool(PrefsKeys.showRobotDetails, _showRobotDetails);
  }

  void _updateShowGrid(bool value) {
    setState(() {
      _showGrid = value;
    });
    _prefs.setBool(PrefsKeys.showGrid, _showGrid);
  }

  void _updateShowRobotOutlines(bool value) {
    setState(() {
      _showRobotOutlines = value;
    });
    _prefs.setBool(PrefsKeys.showRobotOutlines, _showRobotOutlines);
    VisibilityToggles.changed.value++;
  }

  void _updateShowEventMarkers(bool value) {
    setState(() {
      _showEventMarkers = value;
    });
    _prefs.setBool(PrefsKeys.showEventMarkers, _showEventMarkers);
    VisibilityToggles.changed.value++;
  }

  void _updateShowControlPoints(bool value) {
    setState(() {
      _showControlPoints = value;
    });
    _prefs.setBool(PrefsKeys.showControlPoints, _showControlPoints);
    VisibilityToggles.changed.value++;
  }

  void _updateShowRotationTargets(bool value) {
    setState(() {
      _showRotationTargets = value;
    });
    _prefs.setBool(PrefsKeys.showRotationTargets, _showRotationTargets);
    VisibilityToggles.changed.value++;
  }

  void _updateShowPointZones(bool value) {
    setState(() {
      _showPointZones = value;
    });
    _prefs.setBool(PrefsKeys.showPointZones, _showPointZones);
    VisibilityToggles.changed.value++;
  }
}
