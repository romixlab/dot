# Omarchy machine setup — recreate customizations

Diffed against a fresh Omarchy clone (commit `47de6329`, 2026-09-14) to
isolate hand-customizations on `omarchy-pve` from stock. Additive only —
nothing here touches `/usr/share/omarchy/`. Files referenced below live in
[`omarchy-setup/`](omarchy-setup/).

Not customizations (verified stock or auto-generated — skip on a new machine):
`~/.config/omarchy/branding/about.txt`,
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
```

**Do not run `keepassxc-hidpi.sh`** (removed 2026-09-28). It forced
`QT_SCALE_FACTOR=2` on KeePassXC's desktop entry to fix tiny rendering under
XWayland, back when `qt5-wayland` wasn't installed. `qt5-wayland` is now
installed, so KeePassXC renders natively on Wayland and already picks up
Hyprland's compositor scale — the forced override double-scales the UI on
top of that, desyncing click/focus coordinates from what's rendered, which
broke keyboard input when launched from the app launcher (worked fine run
directly from a terminal, which bypasses the desktop entry). If a future
machine still lacks `qt5-wayland` and KeePassXC renders tiny again, redo the
override then — don't apply it pre-emptively.

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

Two variants of the same `[bar] size-horizontal` token, stock default 26px.
Applying both is pointless — the second append would just win; pick one.

- **Moderate — all machines.** A bit smaller than stock but still reads fine
  on normal monitors/laptops. Applies everywhere, not screen-size-gated.

  ```bash
  cat omarchy-setup/shell-bar-thin-moderate-append.toml >> ~/.config/omarchy/shell.toml
  ```

- **Aggressive — small physical screens only** (e.g. GPD-class handhelds).
  26px down to 20px; too cramped on normal-size monitors/laptops, skip there.

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

## 21. Screensaver branding art fits a narrower terminal

Only apply on non-standard displays — rotated/portrait panels or unusual
scale factors (e.g. this GPD-class handheld: `transform=3`, `scale=2`,
forced `GDK_SCALE=2`). There, Ghostty's screensaver terminal (forced
`--font-size=18`) renders far fewer columns than usual (~75 here), so the
stock 81-column Omarchy wordmark overflows both edges. Skip on normal
monitors — the stock art fits fine there.

```bash
cp omarchy-setup/screensaver-narrow.txt ~/.config/omarchy/branding/screensaver.txt
```

Regenerate instead of reusing this file if the wordmark ever changes
upstream, or the available columns differ on another such machine:

```bash
omarchy transcode ascii /usr/share/omarchy/logo.svg ~/.config/omarchy/branding/screensaver.txt --width 70 --mode block
```

## 22. Personal bash aliases

Deliberately doesn't shadow `grep` with `rg` — `rg` skips hidden/gitignored/binary
files by default, which would silently hide matches vs. real grep. Use `rg`
directly instead.

Check the "Add your own exports, aliases, and functions here" section of
`~/.bashrc` first — if it already has content (e.g. hand-added on the machine,
or this step re-run), merge by hand instead of blindly appending, to avoid
duplicate/conflicting aliases.

```bash
cat omarchy-setup/bashrc-append.sh >> ~/.bashrc   # only if that section is empty/stock
```

## 23. Verify `~/.bashrc` is Omarchy's own, not the plain Arch skeleton

Seen on a fresh install: `~/.bashrc` ends up as `/etc/skel/.bashrc` instead of
Omarchy's template (`/usr/share/omarchy/etc-overrides/dot.bashrc`) — missing the
`OMARCHY_PATH` bootstrap and all of Omarchy's default aliases/functions. Run this
check before step 22:

```bash
grep -q 'OMARCHY_PATH/default/bash/rc' ~/.bashrc || echo "NOT Omarchy's bashrc — needs replacing"
```

If it prints that, replace it, then reapply step 22's append on top:

```bash
cp ~/.bashrc ~/.bashrc.bak.$(date +%Y%m%d%H%M%S)
cp /usr/share/omarchy/etc-overrides/dot.bashrc ~/.bashrc
cat omarchy-setup/bashrc-append.sh >> ~/.bashrc
```

## 24. VLC video doesn't inhibit sleep

Same underlying issue as step 13, different mechanism: VLC's Arch build has
no Wayland idle-inhibit plugin at all (only `dbus_screensaver` and `xdg`,
checked via `vlc --list`), and it prefers the D-Bus one, calling
`org.freedesktop.ScreenSaver` at object path `/ScreenSaver` (not
`/org/freedesktop/ScreenSaver` — checked via `strings` on
`libdbus_screensaver_plugin.so`). Nothing on Hyprland/omarchy owns that name,
so VLC's own service probe (`cannot find service org.freedesktop.ScreenSaver`
in `vlc -vv` logs) fails and it falls back to the `xdg` module, which no-ops
under Hyprland too (no X screensaver, no gnome/mate session D-Bus service).

Fix: a small D-Bus service that owns that name at that path and bridges
Inhibit/UnInhibit to `omarchy-toggle-idle` (the same stay-awake override the
idle service already respects), refcounted and cleaned up if the caller
disconnects without calling UnInhibit. VLC only *probes* for an
already-running owner — it never triggers on-demand D-Bus activation — so
this has to run as a persistent service, not a D-Bus-activated one. Needs
`python-dbus` and `python-gobject` (already present on a stock Omarchy
install).

```bash
cp omarchy-setup/screensaver-inhibit-bridge.py ~/.local/bin/omarchy-screensaver-inhibit-bridge
chmod +x ~/.local/bin/omarchy-screensaver-inhibit-bridge
mkdir -p ~/.config/systemd/user
cp omarchy-setup/omarchy-screensaver-inhibit-bridge.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now omarchy-screensaver-inhibit-bridge.service
```

Verify: play a video in VLC past the screensaver timeout, screen stays awake;
`omarchy-shell idle status` shows `"stayAwake":true` while playing (also
visible as `~/.local/state/omarchy/indicators/stay-awake` existing), reverts
within a second of stopping/closing VLC.

## 25. Limit battery charge to 80%

Only on machines with the `macsmc-battery` driver (Apple Silicon/Asahi, e.g.
this M1 laptop) — check `ls /sys/class/power_supply/ | grep macsmc-battery`
first. Sysfs threshold resets to 100 on reboot and can reset across
suspend/resume too, so a boot-time oneshot unit plus a system-sleep hook both
reapply it.

```bash
sudo cp omarchy-setup/battery-charge-threshold.service /etc/systemd/system/
sudo systemctl enable --now battery-charge-threshold.service

sudo install -m 755 -o root -g root omarchy-setup/battery-charge-threshold-sleep.sh \
  /etc/systemd/system-sleep/battery-charge-threshold.sh
```

Verify:

```bash
cat /sys/class/power_supply/macsmc-battery/charge_control_end_threshold   # -> 80
```

## After applying

```bash
hyprctl reload && hyprctl configerrors   # hypr/*.lua changes
omarchy restart shell                    # shell.json / plugin changes — editing an
                                          # already-mounted widget's .qml won't
                                          # hot-reload on its own, this always works
```
