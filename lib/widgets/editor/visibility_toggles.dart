import 'package:flutter/material.dart';
import 'package:pathplanner/util/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quick toggles over the field for what the editor shows. These are the same
/// settings as the checkboxes in Editor Settings.
class VisibilityToggles extends StatelessWidget {
  /// Bumped whenever one of these settings changes, so the field, these
  /// toggles and the Editor Settings checkboxes all stay in sync.
  static final ValueNotifier<int> changed = ValueNotifier(0);

  static const List<(String, bool, IconData, String)> _toggles = [
    (
      PrefsKeys.showRobotOutlines,
      Defaults.showRobotOutlines,
      Icons.crop_din_rounded,
      'Robot Outlines'
    ),
    (
      PrefsKeys.showEventMarkers,
      Defaults.showEventMarkers,
      Icons.pin_drop_rounded,
      'Event Markers'
    ),
    (
      PrefsKeys.showControlPoints,
      Defaults.showControlPoints,
      Icons.linear_scale_rounded,
      'Control Points'
    ),
    (
      PrefsKeys.showRotationTargets,
      Defaults.showRotationTargets,
      Icons.rotate_90_degrees_cw_rounded,
      'Rotation Targets'
    ),
    (
      PrefsKeys.showPointZones,
      Defaults.showPointZones,
      Icons.rotate_left_rounded,
      'Point Towards Zones'
    ),
  ];

  final SharedPreferences prefs;

  const VisibilityToggles({
    super.key,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Card(
          color: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListenableBuilder(
            listenable: changed,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (key, fallback, icon, label) in _toggles)
                  _buildToggle(key, prefs.getBool(key) ?? fallback, icon, label,
                      colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String key, bool value, IconData icon, String label,
      ColorScheme colorScheme) {
    return Tooltip(
      message: '${value ? 'Hide' : 'Show'} $label',
      child: IconButton(
        onPressed: () {
          prefs.setBool(key, !value);
          changed.value++;
        },
        icon: Icon(
          icon,
          color: value ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
