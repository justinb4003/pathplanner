import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pathplanner/path/pathplanner_path.dart';
import 'package:pathplanner/path/waypoint.dart';
import 'package:pathplanner/util/wpimath/geometry.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/tree_card_node.dart';
import 'package:pathplanner/widgets/number_text_field.dart';

/// The linked waypoints in the project, shown as named spots on the field.
/// Each spot has a position and the way the robot faces there. Changing a
/// spot moves every waypoint on it, in every path.
class FieldSpotsTree extends StatelessWidget {
  final PathPlannerPath path;
  final List<PathPlannerPath> allPaths;
  final VoidCallback? onPathChanged;

  const FieldSpotsTree({
    super.key,
    required this.path,
    required this.allPaths,
    this.onPathChanged,
  });

  @override
  Widget build(BuildContext context) {
    final names = Waypoint.linked.keys.sorted();

    return TreeCardNode(
      title: const Text('Field Spots'),
      leading: const Icon(Icons.push_pin_rounded),
      initiallyExpanded: path.fieldSpotsExpanded,
      onExpansionChanged: (value) {
        if (value != null) {
          path.fieldSpotsExpanded = value;
        }
      },
      elevation: 1.0,
      children: [
        if (names.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Link a waypoint to create a field spot'),
          ),
        for (final name in names) _buildSpot(context, name),
      ],
    );
  }

  Widget _buildSpot(BuildContext context, String name) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final pose = Waypoint.linked[name]!;
    final uses = allPaths
        .expand((p) => p.waypoints)
        .where((w) => w.linkedName == name)
        .length;

    return Padding(
      key: ValueKey(name),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  uses == 1 ? '$name (1 waypoint)' : '$name ($uses waypoints)',
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Tooltip(
                message: 'Rename Field Spot',
                waitDuration: const Duration(seconds: 1),
                child: IconButton(
                  onPressed: () => _showRenameDialog(context, name),
                  icon: const Icon(Icons.edit_rounded, size: 20),
                ),
              ),
              Tooltip(
                message: 'Delete Field Spot',
                waitDuration: const Duration(seconds: 1),
                child: IconButton(
                  onPressed: () => _showDeleteDialog(context, name),
                  icon: const Icon(Icons.delete_forever, size: 20),
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: NumberTextField(
                  initialValue: pose.translation.x,
                  label: 'X Position (M)',
                  onSubmitted: (value) {
                    if (value != null) {
                      _updateSpot(name,
                          Pose2d(Translation2d(value, pose.y), pose.rotation));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NumberTextField(
                  initialValue: pose.translation.y,
                  label: 'Y Position (M)',
                  onSubmitted: (value) {
                    if (value != null) {
                      _updateSpot(name,
                          Pose2d(Translation2d(pose.x, value), pose.rotation));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NumberTextField(
                  initialValue: pose.rotation.degrees,
                  label: 'Rotation (Deg)',
                  arrowKeyIncrement: 1.0,
                  onSubmitted: (value) {
                    if (value != null) {
                      _updateSpot(
                          name,
                          Pose2d(
                              pose.translation, Rotation2d.fromDegrees(value)));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateSpot(String name, Pose2d pose) {
    Waypoint.linked[name] = pose;
    // This path first, then onPathChanged updates all the others
    path.applyLinkedWaypoints();
    onPathChanged?.call();
  }

  void _showRenameDialog(BuildContext context, String name) {
    final controller = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (context) {
        ColorScheme colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(builder: (context, setState) {
          final newName = controller.text.trim();
          final taken = newName != name && Waypoint.linked.containsKey(newName);

          return AlertDialog(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            title: const Text('Rename Field Spot'),
            content: SizedBox(
              width: 400,
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText:
                      taken ? 'A field spot with that name exists' : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: newName.isEmpty || taken
                    ? null
                    : () {
                        final renamed = controller.text.trim();
                        if (renamed.isEmpty ||
                            (renamed != name &&
                                Waypoint.linked.containsKey(renamed))) {
                          return;
                        }

                        Navigator.of(context).pop();
                        if (renamed == name) return;
                        PathPlannerPath.renameLinkedWaypoint(
                            allPaths, name, renamed);
                        onPathChanged?.call();
                      },
                child: const Text('RENAME'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) {
        ColorScheme colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          title: const Text('Delete Field Spot'),
          content: Text(
              'Are you sure you want to delete the field spot "$name"? The waypoints on it will stay where they are, but will no longer move with it.'),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                PathPlannerPath.deleteLinkedWaypoint(allPaths, name);
                onPathChanged?.call();
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }
}
