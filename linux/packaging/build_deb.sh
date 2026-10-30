#!/usr/bin/env bash
# Packages a Flutter Linux release bundle as an amd64 .deb.
#
# Usage: build_deb.sh <bundle dir> <version> <output .deb>
#
# Installs to /opt/pathplanner-4003 with a pathplanner-4003 command and a desktop
# entry, so it sits next to stock PathPlanner. Dependencies use the pre-t64 package
# names, which newer Debian/Ubuntu releases still provide, and the deb is xz
# compressed so older dpkg can read it.
set -euo pipefail

bundle=$1
version=$2
output=$3

package=pathplanner-4003
app_id=com.trisonics4003.pathplanner
install_dir=/opt/$package
repo_root=$(cd "$(dirname "$0")/../.." && pwd)

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

mkdir -p "$stage$install_dir" "$stage/usr/bin" "$stage/usr/share/applications" \
  "$stage/usr/share/icons/hicolor/512x512/apps" "$stage/DEBIAN"
cp -r "$bundle"/. "$stage$install_dir"
ln -s "$install_dir/pathplanner" "$stage/usr/bin/$package"
install -m 644 "$repo_root/images/icon.png" \
  "$stage/usr/share/icons/hicolor/512x512/apps/$app_id.png"

# Named after the GTK application ID so Wayland docks match the window to it
cat > "$stage/usr/share/applications/$app_id.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=PathPlanner 4003
Comment=Motion profile generator for FRC robots
Exec=$install_dir/pathplanner
Icon=$app_id
Terminal=false
Categories=Development;Engineering;
StartupWMClass=pathplanner
EOF

# The oldest glibc any of the bundle's binaries need
glibc=$(find "$stage$install_dir" -type f \( -name pathplanner -o -name '*.so' \) \
  -exec objdump -T {} + | grep -o 'GLIBC_[0-9.]*' | sed 's/GLIBC_//' | sort -uV | tail -1)

cat > "$stage/DEBIAN/control" <<EOF
Package: $package
Version: $version
Architecture: amd64
Maintainer: FRC Team 4003
Installed-Size: $(du -sk --exclude=DEBIAN "$stage" | cut -f1)
Depends: libc6 (>= $glibc), libgtk-3-0, libglib2.0-0, libstdc++6, libgcc-s1, libblkid1, liblzma5
Section: devel
Priority: optional
Homepage: https://github.com/justinb4003/pathplanner
Description: PathPlanner 4003, a motion profile generator for FRC robots
 FRC Team 4003's fork of PathPlanner. Installs and runs next to stock
 PathPlanner with its own settings.
EOF

# 755 for directories and executables, 644 for the rest, whatever the umask
chmod -R u=rwX,go=rX "$stage"

dpkg-deb --root-owner-group -Zxz --build "$stage" "$output"
