#!/usr/bin/env bash
# KeePassXC runs via XWayland (no qt5-wayland installed) and renders
# tiny/unscaled on HiDPI. Force scale on its desktop entry only.
mkdir -p ~/.local/share/applications
cp /usr/share/applications/org.keepassxc.KeePassXC.desktop ~/.local/share/applications/
sed -i 's/^Exec=keepassxc %f/Exec=env QT_SCALE_FACTOR=2 keepassxc %f/' \
  ~/.local/share/applications/org.keepassxc.KeePassXC.desktop
