#!/usr/bin/env bash
# Beyond-stock packages for omarchy-pve. Three have dedicated omarchy commands
# (do more than a bare install: set default, start a service, add a bar widget).

omarchy install browser firefox
omarchy default browser firefox

omarchy install terminal ghostty

# Also enables the omarchy.tailscale bar widget (step 7's shell.json already
# includes it, so no separate action needed there).
omarchy install service tailscale

omarchy pkg add freecad just keepassxc kicad syncthing uv speedcrunch
omarchy pkg aur add winbox
