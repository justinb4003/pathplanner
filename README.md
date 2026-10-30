This is an experimental fork of PathPlanner. I'm must tinkering around with it and not sure if our own team would use this.

## Alterations

### Path editing
- **Auto-smooth (min accel):** a per-path option that places every control point for you, as a minimum-acceleration spline through the waypoints. The end directions can be locked.
- **Linked path segments:** chain paths so the end of one and the start of the next always stay together. ⏮ / ⏭ buttons jump between them.
- **Field spots:** named spots shared by every path, e.g. the spot you always shoot from. Move the spot and every path using it follows.
- **Waypoint range slider:** shows only part of a path's waypoints, for working on paths that overlap themselves.
- **Switch Path menu:** a ▾ next to the path name opens any other path.

### Field view
- **Visibility toggles** for robot outlines, event markers, control points, rotation targets and point towards zones.
- **Right-drag to pan** and zoom out to 0.2×. The zoom and pan carry over when you open another path.
- The editor sidebar can shrink further, giving the field more room.

### Choreo import
- **Import as Path** turns a Choreo trajectory, or one of its splits, into a regular, editable PathPlanner path. The Choreo files are left alone.
- **Import All as Paths** brings in every trajectory, with split trajectories as linked pieces.
- The Choreo Paths folder is sorted by name.

### Builds and releases
- Installs as **PathPlanner 4003** next to stock PathPlanner, with its own settings.
- Windows, macOS and Linux builds are published as GitHub releases, and the in-app update check follows this fork.

### Accessibility
- An **OpenDyslexic** font option in Settings.

## About
![PathPlanner](https://github.com/user-attachments/assets/5b87c1a4-8fdb-4eb9-bf29-71f79a826a82)


PathPlanner is a motion profile generator for FRC robots created by team 3015. The main features of PathPlanner include:
* Each path is made with Bézier curves, allowing fine tuning of the exact path shape.
* Holonomic mode supports decoupling the robot's rotation from its direction of travel.
* Real-time path preview
* Allows placing "event markers" along the path which can be used to trigger other code while path following.
* Build modular autonomous routines using other paths.
* Automatic saving and file management
* Robot-side vendor library for path generation and custom path following commands/controllers
* Full autonomous command generation with PathPlannerLib auto builder
* Real time path following telemetry
* Hot reload (paths and autos can be updated and regenerated on the robot without redeploying code)
* Automatic pathfinding in PathPlannerLib with AD*

## Usage and Documentation
### [pathplanner.dev](https://pathplanner.dev)

<br/>

Make sure you [install PathPlannerLib](https://pathplanner.dev/pplib-getting-started.html) to generate your paths.
```
https://3015rangerrobotics.github.io/pathplannerlib/PathplannerLib.json
```

[Java API Docs](https://pathplanner.dev/api/java/)

[C++ API Docs](https://pathplanner.dev/api/cpp/)

[Python API Docs](https://pathplanner.dev/api/python/)

## How to build manually:
* [Install Flutter](https://flutter.dev/docs/get-started/install)
* Open the project in a terminal and run the following command: `flutter build <PLATFORM>`
   * Valid platforms are:
      * windows
      * macos
      * linux
* The built app will be located here:
    * Windows: `<PROJECT DIR>/build/windows/runner/Release`
    * macOS: `<PROJECT DIR>/build/macos/Build/Products/Release`
    * Linux: `<PROJECT DIR>/build/linux/x64/release/bundle`
* OR `flutter run` to run in debug mode
