#!/usr/bin/env bash
# Packages a Flutter Linux release bundle as an x86_64 AppImage.
#
# Usage: build_appimage.sh <bundle dir> <output .AppImage>
#
# One file that runs on most distros without installing anything: make it
# executable and run it. Like the tarball it uses the system's GTK 3, and EGL and
# OpenGL ES (libEGL.so.1, libGLESv2.so.2), which Flutter loads at startup. Those
# have to come from the system to match its GPU driver; desktop installs have
# them. Its runtime is static, so it doesn't need libfuse2 either. Downloads a pinned appimagetool
# unless APPIMAGETOOL points at one, and always the pinned runtime.
set -euo pipefail

bundle=$1
output=$2

app_id=com.trisonics4003.pathplanner
repo_root=$(cd "$(dirname "$0")/../.." && pwd)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# The bundle (pathplanner, lib/, data/) goes at the root of the AppDir, since
# the binary finds lib/ and data/ next to itself
appdir=$work/PathPlanner-4003.AppDir
mkdir -p "$appdir"
cp -r "$bundle"/. "$appdir"
install -m 644 "$repo_root/images/icon.png" "$appdir/$app_id.png"
ln -s "$app_id.png" "$appdir/.DirIcon"

cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
here=$(dirname "$(readlink -f "$0")")
exec "$here/pathplanner" "$@"
EOF
chmod 755 "$appdir/AppRun"

# Named after the GTK application ID like the deb's, so docks match the window
cat > "$appdir/$app_id.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=PathPlanner 4003
Comment=Motion profile generator for FRC robots
Exec=pathplanner
Icon=$app_id
Terminal=false
Categories=Development;Engineering;
StartupWMClass=pathplanner
EOF

# Pinned appimagetool and AppImage runtime, checked against their release
# digests. Without --runtime-file, appimagetool downloads the newest runtime.
appimagetool_url=https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage
appimagetool_sha256=ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
runtime_url=https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64
runtime_sha256=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d

download() {
  curl -fsSL -o "$3" "$1"
  echo "$2  $3" | sha256sum --check --quiet
}

tool=${APPIMAGETOOL:-}
if [[ -z $tool ]]; then
  tool=$work/appimagetool
  download "$appimagetool_url" "$appimagetool_sha256" "$tool"
  chmod +x "$tool"
fi
download "$runtime_url" "$runtime_sha256" "$work/runtime"

# Extract and run, since CI runners and containers don't have FUSE
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$tool" --no-appstream \
  --runtime-file "$work/runtime" "$appdir" "$output"
