# Omarchy machine setup — recreate customizations

Diffed against a fresh Omarchy clone (commit `47de6329`, 2026-09-14) to
isolate hand-customizations on `omarchy-pve` from stock. Additive only —
nothing here touches `/usr/share/omarchy/`. Files referenced below live in
[`omarchy-setup/`](omarchy-setup/).

Not customizations (verified stock or auto-generated — skip on a new machine):
`~/.config/omarchy/branding/{about.txt,screensaver.txt}`,
`~/.config/omarchy/hooks/post-update.d/{install-voxtype,setup-agent,setup-fingerprint}.hook`,
comment-only diffs in `omarchy-menu.jsonc`, `*.bak.<timestamp>` files.

## 0. Packages

```bash
bash omarchy-setup/packages.sh
```

## 1. Auto night light schedule

```bash
cat omarchy-setup/autostart-append.lua >> ~/.config/hypr/autostart.lua
```

Append `omarchy-setup/hyprsunset-profile.conf` to `~/.config/hypr/hyprsunset.conf`.

## 2. SSH agent socket (KeePassXC-backed)

```bash
cat omarchy-setup/hyprland-env-append.lua >> ~/.config/hypr/hyprland.lua
systemctl --user enable --now ssh-agent.socket
bash omarchy-setup/keepassxc-hidpi.sh
```

Enable in KeePassXC: Tools → Settings → SSH Agent → Enable (vault under `~/sync/by_letter/P/`).
Verify: `ssh-add -l` → `The agent has no identities.` (not a connection error).
Key setup: [KeePassXC/ssh-agent writeup](https://blog.burakcankus.com/keepassxc-and-ssh-agent-setup/).

## 3. Firewall: allow Syncthing

```bash
sudo ufw allow 22000/tcp
sudo ufw allow 22000/udp
```

## 4. Keybindings

```bash
cat omarchy-setup/bindings-append.lua >> ~/.config/hypr/bindings.lua
```

Check `omarchy menu keybindings --print` first — rebind SUPER+R / SUPER+SHIFT+R /
SUPER+SHIFT+P if already taken.

## 5. Bar/shell UI font size

```bash
mkdir -p ~/.config/omarchy
cp omarchy-setup/shell.toml ~/.config/omarchy/shell.toml
```

## 6. Custom workspace bar widget

Clone of `omarchy.workspaces` with per-workspace app icons (grayscale,
color when focused), workspace 11 pinned to "Z", fixed slots 1–5, 11.

```bash
cp -r omarchy-setup/roman.workspaces ~/.config/omarchy/plugins/
```

## 7. Bar layout

```bash
cp omarchy-setup/shell.json ~/.config/omarchy/shell.json
```

Merges: `roman.workspaces` replaces `omarchy.workspaces` (left); adds
`omarchy.tailscale` (right, skip if step 0's `omarchy install service tailscale`
already added it); clock format `"ddd d MMM HH:mm"` + life-calendar mode
(`birthYear`/`lifeExpectancy` — personal, adjust or drop); idle doubled
(`screensaver` 300s, `lock` 600s — keep the 1:2 ratio or the screensaver
never shows before lock fires).

## 8. Power menu: remove Suspend and Hibernate (Proxmox VM — no working ACPI S3/S4)

```bash
omarchy toggle suspend
```

Append `omarchy-setup/menu-hibernate-override.jsonc` into
`~/.config/omarchy/extensions/omarchy-menu.jsonc` before the closing `}`.
Both hot-reload, no restart. Reversible: toggle suspend again; delete the
hibernate line.

## 9. Zed settings

```bash
cp settings.json keymap.json ~/.config/zed/
```

## 10. Workspace app launcher

Opens Firefox/terminal/SpeedCrunch+Obsidian/KeePassXC/Zed onto fixed
workspaces (silent, no focus stealing) on `SUPER SHIFT + U`. See
[`hypr-workspace-launcher/README.md`](hypr-workspace-launcher/README.md).

```bash
cat hypr-workspace-launcher/bindings.lua >> ~/.config/hypr/bindings.lua
```

---

## 11. Natural (inverted) trackpad scroll

Hyprland has no per-axis scroll invert — this flips both horizontal and
vertical scroll together.

```bash
cat omarchy-setup/input-append.lua >> ~/.config/hypr/input.lua
```

## 12. SuperSlicer desktop launcher

AppImage downloaded to `~/Downloads`, no bundled desktop integration.

```bash
mv ~/Downloads/SuperSlicer-*.AppImage ~/.local/bin/superslicer.AppImage
chmod +x ~/.local/bin/superslicer.AppImage
cd /tmp && ~/.local/bin/superslicer.AppImage --appimage-extract SuperSlicer.png
cp squashfs-root/SuperSlicer.png ~/.local/share/icons/superslicer.png
rm -rf squashfs-root
```

Create `~/.local/share/applications/superslicer.desktop`:

```ini
[Desktop Entry]
Name=SuperSlicer
Comment=3D printing slicer
Exec=/home/roman/.local/bin/superslicer.AppImage %F
Icon=superslicer
Type=Application
Categories=Graphics;3DGraphics;
MimeType=model/stl;application/vnd.ms-3mfdocument;application/prs.wavefront-obj;application/x-amf;
Terminal=false
```

```bash
update-desktop-database ~/.local/share/applications/
```

## 13. Firefox video doesn't inhibit screensaver

Firefox uses the portal `Inhibit` interface first; the GTK backend fakes
success under Hyprland, so Firefox never falls back to native Wayland
`idle-inhibit-v1` (which Omarchy's idle service respects). Disable that
backend for `Inhibit` (needs xdg-desktop-portal >= 1.18.4; keep
`xdg-desktop-portal-gtk` installed).

```bash
mkdir -p ~/.config/xdg-desktop-portal
cp omarchy-setup/hyprland-portals.conf ~/.config/xdg-desktop-portal/
systemctl --user restart xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
```

Then fully restart Firefox. Verify: `about:support` → Window Protocol = `wayland`;
video playing past the screensaver timeout doesn't trigger it.

## 14. Brightness synced across both external monitors

Apply as is only if the machine has two identical external (DDC) monitors
connected; otherwise adapt to the local setup (the script skips laptop panels
and applies the same step to every other monitor).

Keys and the menu slider adjust all DDC monitors together. `roman.monitor` is a
clone of `omarchy.monitor` with `setBrightness` calling the sync script; it
replaces `omarchy.monitor` in `shell.json` (already in step 7's file).

```bash
cp omarchy-setup/omarchy-brightness-display-sync ~/.local/bin/
cat omarchy-setup/brightness-bindings-append.lua >> ~/.config/hypr/bindings.lua
cp -r omarchy-setup/roman.monitor ~/.config/omarchy/plugins/
```

## 15. Ghostty as default terminal

```bash
omarchy default terminal ghostty
```

## 16. WinBox HiDPI

XWayland is unscaled under Omarchy; force Qt scale 2 (drop the Qt platform override).

```bash
cp omarchy-setup/winbox.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
```

## 17. Screensaver: dismiss on any key or mouse move

Patches a package file — an Omarchy update overwrites it, reapply after updates.
Skip if the patch no longer applies (upstream may have fixed it).

```bash
sudo patch /usr/bin/omarchy-screensaver < omarchy-setup/omarchy-screensaver.patch
```

## 18. Slimmer Hyprland group headers

```bash
cat omarchy-setup/looknfeel-append.lua >> ~/.config/hypr/looknfeel.lua
```

## 19. Thinner top bar

Only apply on computers with a small physical screen size (e.g. GPD-class
handhelds); skip on normal-size monitors/laptops, where the default bar
height reads fine. Shrinks the bar token from the default 26px down to 20px.

```bash
cat omarchy-setup/shell-bar-thin-append.toml >> ~/.config/omarchy/shell.toml
```

## 20. Lock screen: Escape suspends

Skip on virtualized machines (e.g. the Proxmox VM `omarchy-pve`) — no working
ACPI suspend there, same reason as step 8.

At the password prompt, Escape now clears the field and suspends
(`systemctl suspend`) instead of just clearing it — for when the screen woke
accidentally and you just want it back asleep. Ctrl+U still clears without
suspending. No-op while a password is mid-check (won't fire during PAM
verify). Clone of `omarchy.lock`.

```bash
cp -r omarchy-setup/roman.lock ~/.config/omarchy/plugins/
```

Merges into `~/.config/omarchy/shell.json` (already in step 7's file): adds
`"roman.lock"` to `plugins`, `"omarchy.lock"` to `disabledPlugins`, and
`"roman.lock"` to `cloneSourceRestores`.

```bash
omarchy restart shell
```

A hot-reload after copying the plugin files in-place (without a restart)
leaves two lock-service instances alive at once (duplicate `WlSessionLock`,
IPC handler collision) — always restart the shell after touching this one.

## After applying

```bash
hyprctl reload && hyprctl configerrors   # hypr/*.lua changes
omarchy restart shell                    # shell.json / plugin changes — editing an
                                          # already-mounted widget's .qml won't
                                          # hot-reload on its own, this always works
```
