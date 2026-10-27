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

An override made earlier stays behind when `qt5-wayland` arrives later (it is
pulled in as a dependency, e.g. by `qt5-declarative`): on omarchy-m1 the
18 Oct 2026 update installed it while
`~/.local/share/applications/org.keepassxc.KeePassXC.desktop` still had
`Exec=env QT_SCALE_FACTOR=2 keepassxc`, and KeePassXC came up at 4x. Whenever
`pacman -Q qt5-wayland` succeeds, check `ls ~/.local/share/applications | rg -i keepass`
and trash any such override (`gio trash ...`), then quit KeePassXC fully
(tray too) and start it again. `hyprctl clients` shows `xwayland: 0` for
KeePassXC when it runs natively.

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

## 26. USB device access without root

Grants the logged-in user rw on raw USB (libusb), USB hidraw (WebHID/VIA/security
keys) and USB serial (`ttyUSB*`/`ttyACM*`) via systemd `uaccess` — no groups, no relogin.

```bash
sudo install -m 644 omarchy-setup/70-usb-uaccess.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --subsystem-match=hidraw --subsystem-match=tty
```

Verify: `getfacl /dev/bus/usb/*/* | grep "user:$USER"`.

## 27. Rust toolchain (rustup, cargo-binstall, probe-rs, flip-link, cargo tools)

Each line skips what's already installed.

```bash
command -v rustup >/dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"
command -v cargo-binstall >/dev/null || curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
command -v probe-rs >/dev/null || cargo binstall -y probe-rs-tools
command -v cargo-nextest >/dev/null || cargo binstall -y cargo-nextest
command -v cargo-bloat >/dev/null || cargo binstall -y cargo-bloat
command -v cargo-semver-checks >/dev/null || cargo binstall -y cargo-semver-checks
command -v cargo-sort >/dev/null || cargo binstall -y cargo-sort
command -v cargo-upgrades >/dev/null || cargo binstall -y cargo-upgrades
command -v sqlx >/dev/null || cargo binstall -y sqlx-cli
command -v typos >/dev/null || cargo binstall -y typos-cli
command -v flip-link >/dev/null || cargo install flip-link
```

## 28. Show hostname in bash prompt

Prompt is Starship (`~/.config/starship.toml`). Prepend `$hostname` to `format`
and show it locally too, not only over SSH:

```bash
sed -i 's/^format = "\[\$directory/format = "[$hostname$directory/' ~/.config/starship.toml
cat >> ~/.config/starship.toml <<'EOF'

[hostname]
ssh_only = false
format = "[$hostname]($style) "
style = "bold cyan"
EOF
```

## 29. btop as background on empty workspaces

Removed (reverted). Skip.

## 30. sccache: dropped (27 Oct 2026)

Removed. Skip. Compiled Rust dependencies are shared by tpm's deps pool instead (reflinks inside the cargo build-dir root, tpm_cli ops#27oct-1317): sccache can't cache incrementally built crates, so it only ever held dependencies, and every hit was a full copy rather than a reflink. On a PC set up earlier: delete `rustc-wrapper = "sccache"` from `~/.cargo/config.toml`, `sccache --stop-server`, and trash its cache dir and `~/.config/sccache`.

## 31. Public DNS instead of the home router

The home router (192.168.0.1, Compal) answers IPv6 (AAAA) lookups with NOTIMP; static Rust binaries
(Codex) then fail every connection. Each home connection (wired and wifi) uses Quad9 + Cloudflare;
Tailscale MagicDNS stays.

```bash
for c in $(nmcli -g NAME,TYPE con show | grep -E "ethernet|wireless" | cut -d: -f1); do
  sudo nmcli con mod "$c" ipv4.ignore-auto-dns yes ipv4.dns "9.9.9.9 1.1.1.1" ipv6.ignore-auto-dns yes
done
for d in $(nmcli -g DEVICE,TYPE dev | grep -E "ethernet|wifi" | cut -d: -f1); do sudo nmcli dev reapply "$d"; done
python3 -c "import socket; print(socket.getaddrinfo(\"chatgpt.com\", 443, socket.AF_INET6)[0][4])"
```

## 32. Russian layout: XKB us,ru switched by keyd (MacBook keyboard + Ergodox)

Russian is a real XKB layout (no compose sequences); keyd tracks the mode and picks the XKB group.
Alt+Space toggles en/ru, Esc (Mac: Caps Lock) in ru → en. Files in [`keyd_mac/`](keyd_mac/).
`mac.conf` matches the built-in Apple keyboard by full id (trackpad shares `05ac:0343`) —
check with `keyd monitor` on a new machine.

```bash
cat keyd_mac/hypr-input.lua >> ~/.config/hypr/input.lua
hyprctl reload && hyprctl configerrors
sudo rm -f /etc/keyd/default.conf /etc/keyd/ru_std
sudo cp keyd_mac/mac.conf keyd_mac/ergodox.conf keyd_mac/ru /etc/keyd/
sudo keyd reload
```

Coming from the old compose-based version: drop the `ru.compose` include from `~/.XCompose`,
remove `~/.config/keyd/ru.compose`, `omarchy-restart-xcompose`.

## 33. Extra fonts (docs, Typst, Russian/GOST documents)

Text fonts for reports and datasheets, Office metric twins so Word exports keep their layout, PT and
GOST 2.304-81 type A/B for Russian engineering documents, Audiowide for logos and headings. Ghostscript comes with Omarchy.
Astra Serif/Sans (AUR) are skipped: their source, webfonts.ru, was down (6 Oct 2026). Candidates and licences:
vhrd_brand `logo/fonts.md`.

```bash
yay -S --needed ttf-dejavu ttf-carlito ttf-caladea ttf-croscore tex-gyre-fonts ttf-ibm-plex inter-font \
  ttf-roboto ttf-roboto-mono ttf-opensans ttf-fira-sans ttf-fira-code ttf-lato otf-montserrat \
  adobe-source-sans-fonts adobe-source-serif-fonts adobe-source-code-pro-fonts otf-libertinus \
  otf-crimson-pro ttf-ubuntu-font-family otf-atkinson-hyperlegible ttf-gentium-plus \
  ttf-gost ttf-paratype ttf-ms-fonts audiowide-font
```

## 34. Bluetooth survives suspend (Apple Silicon)

Only on machines with the `hci_bcm4377` driver (Asahi, e.g. this M1 laptop) — check
`lsmod | grep hci_bcm4377` first. Without it Bluetooth is dead after resume
(`hci0: command 0x0c01 tx timeout` in `journalctl -k`). The sleep hook unloads the
driver before suspend and loads it again on wake.

```bash
sudo install -m 755 -o root -g root omarchy-setup/bluetooth-bcm4377-sleep.sh \
  /etc/systemd/system-sleep/bluetooth-bcm4377.sh
```

Manual fix without the hook: `sudo modprobe -r hci_bcm4377 && sudo modprobe hci_bcm4377`.
Verify: suspend, wake, `bluetoothctl show` → `Powered: yes`, no tx timeouts in `journalctl -k -b`.

## 35. USB hub doesn't miss replugged devices

Only if a Terminus FE1.1 (`1a40:0101`) or Genesys USB 3.2 (`05e3:0625`/`0610`) hub is used —
`lsusb | grep -E '1a40:0101|05e3:06(25|10)'`.
Autosuspended with nothing plugged in, they miss new connections (replugged device
stays dead until the hub is power-cycled). Keep them awake; add other bad hubs' ids to the rule.

```bash
sudo install -m 644 omarchy-setup/80-usb-hub-no-autosuspend.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --action=add
```

Verify: `cat /sys/bus/usb/devices/*/power/control` of each hub → `on` (paths: `lsusb -t`);
unplug and replug the keyboard, it comes back.

## 36. Quiet fan curve (GPD)

Only on GPD devices with the `gpd_fan` driver — `grep -l gpdfan /sys/class/hwmon/*/name`. The EC never stops
the fan (≈2400 rpm at 36 °C idle); `gpd-fan-curve` runs it in manual mode: off below 48 °C, ramps 55→85 °C,
gives control back to the EC when stopped.

```bash
cargo build --release --manifest-path gpd-fan-curve/Cargo.toml
sudo install -m 755 gpd-fan-curve/target/release/gpd-fan-curve /usr/local/bin/
sudo install -m 644 gpd-fan-curve/gpd-fan-curve.service /etc/systemd/system/
sudo install -Dm 755 gpd-fan-curve/gpd-fan-curve-sleep.sh /etc/systemd/system-sleep/gpd-fan-curve.sh
sudo systemctl daemon-reload && sudo systemctl enable --now gpd-fan-curve.service
```

Verify: `gpd-fan-curve status` → `mode manual`, fan 0 rpm when idle and cool. Tune with `--curve` / `--off-below`
in the unit's `ExecStart`. Undo: `sudo systemctl disable --now gpd-fan-curve` (EC auto again).

## 37. Cargo tools on PATH for ssh commands

`ssh host 'cargo ...'` (also `tpm`, `tpm_mesh_dash`, remote `tpm work spawn --on`) reads no `~/.bashrc` on
Arch; the PATH comes from the `PATH DEFAULT=` line Omarchy adds to `/etc/security/pam_env.conf`
(`install/config/ssh-command-path.sh`, only if missing, so the edit stays). Add `~/.cargo/bin` to it:

```bash
sudo sed -i '/^PATH DEFAULT=/{/cargo\/bin/b;s|$|:@{HOME}/.cargo/bin|}' /etc/security/pam_env.conf
```

Verify from another PC: `ssh <host> 'command -v cargo'`. A pam update may leave a `.pacnew`; keep ours.

## 38. Keep running: lid close doesn't sleep

Laptops only. A bar indicator next to Stay Awake (󰒲, revealed on hover like the others) holds a logind
`handle-lid-switch` inhibitor while on, so closing the lid locks but doesn't suspend. Idle stays as is:
screensaver → lock with password → screen off (idle never suspends). Explicit suspend (power menu,
Escape on the lock screen) still works. State persists in `~/.local/state/omarchy/indicators/keep-running`.
Clones of `omarchy.idle` (holds the inhibitor) and `omarchy.indicators` (adds `KeepRunning`).

```bash
cp -r omarchy-setup/roman.idle omarchy-setup/roman.indicators ~/.config/omarchy/plugins/
```

Merges into `~/.config/omarchy/shell.json` (already in step 7's file): `"roman.idle"` in `plugins` and
`cloneSourceRestores`, `"omarchy.idle"` in `disabledPlugins`, `omarchy.indicators` → `roman.indicators`
in the bar layout. Then `omarchy restart shell` (services don't hot-reload).

Verify: click 󰒲, `systemd-inhibit --list` shows "Omarchy keep running"; `omarchy-shell idle status`
→ `"keepRunning":true,"lidInhibited":true`.

## 39. Cargo build-dir on disk, not in /tmp

Session worktrees live in `/tmp/wt` (RAM tmpfs); two mx3 builds filled 16 GB there (9 Oct 2026). Cargo's
intermediates go to a disk path per workspace, final binaries stay in `./target`; `tpm work done` and `tpm land`
remove a worktree's build-dir (HK-6). Pick the disk with the most room (GPD: `/mnt/data/omarchy/cargo-build`).

```bash
DIR=~/.cache/cargo-build   # adjust
grep -q '^build-dir' ~/.cargo/config.toml 2>/dev/null || {
  grep -q '^\[build\]' ~/.cargo/config.toml 2>/dev/null \
    && sed -i "/^\[build\]/a build-dir = \"$DIR/{workspace-path-hash}\"" ~/.cargo/config.toml \
    || printf '[build]\nbuild-dir = "%s/{workspace-path-hash}"\n' "$DIR" >> ~/.cargo/config.toml; }
```

Verify: `cargo build` in a worktree under `/tmp/wt` leaves only the binaries in its `target/`.

## 40. Prompt colour per machine

Every machine gets a distinct prompt colour plus an icon for its kind, so shells are never mixed up. Each kind
has its own palette: a new machine takes the first free entry of its kind and gets a row in the assignments.
A retired machine's entry becomes free again. Work PCs colour the text; every other kind gets a coloured block
around the host name.

Kinds, icons and palettes (block entries are SGR codes: `fg;bg`, 256-colour where needed):

- **work** 💻 (Starship, text colour): `cyan` · `purple` · `green` · `blue` · `208` (orange) · `205` (pink)
- **prod** 🔥 (warm block): `97;41` white on red · `30;48;5;208` black on orange · `97;48;5;125` white on wine ·
  `97;48;5;161` white on raspberry
- **lab** 🧪 (servers, VMs, Proxmox; blue block): `97;44` white on blue · `97;48;5;31` white on teal ·
  `97;48;5;61` white on slate · `97;48;5;24` white on navy
- **sbc** 🍓 (Raspberry Pi and other boards; green block): `97;42` white on green · `30;48;5;114` black on mint ·
  `97;48;5;29` white on sea green · `30;48;5;148` black on lime
- **printer** 🧵 (3D printer hosts, Klipper; yellow block): `30;43` black on yellow · `30;48;5;222` black on sand ·
  `97;48;5;130` white on brown · `30;48;5;178` black on gold

Icons are single-codepoint emoji (no `U+FE0F` variation selector), so bash counts their width right.

Assignments:

| Machine          | Kind    | Entry                    |
|------------------|---------|--------------------------|
| omarchy-m1       | work    | `cyan`                   |
| gpd-omarchy      | work    | `purple`                 |
| mail.vhrd.tech   | prod    | `97;41` white on red     |
| vhrd.tech (web)  | prod    | `30;48;5;208` on orange  |
| omarchy-pve      | lab     | `97;44` (not applied)    |
| mx3 (VM)         | lab     | `97;48;5;31` (not appl.) |

Work PCs (Starship, step 28 first): recolour the whole prompt and put the icon before the host name.

```bash
C=purple   # Starship names: black red green blue yellow purple cyan white, or a 256-colour number
sed -i "s/cyan/$C/g; /^\[directory\]/a style = \"bold $C\"" ~/.config/starship.toml
sed -i '/^\[hostname\]/,/^format/s/^format = "\[/format = "💻 [/' ~/.config/starship.toml
```

Other kinds (bash): append a PS1 to `~/.bashrc` (overrides the distro default above it).

```bash
grep -q 'dot step 40' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
# prompt colour per machine (dot step 40)
PS1='\[\e[1;97;41m\] 🔥 \H \[\e[0m\] \u:\[\e[1;34m\]\w\[\e[0m\]\$ '
EOF
```

Swap in the entry's SGR code (after `1;`) and the kind's icon. Already applied without an icon: add it with
`sed -i '/dot step 40/{n;s/m\\] \\H/m\\] 🔥 \\H/}' ~/.bashrc`.

## 41. Screensaver: random art per round

Each effect picks a random file: the stock `screensaver.txt` plus any `screensaver-*.txt` (tech logos and words:
Linux, Arch, Asahi, Apple, VhrdTech, Rust, RISC-V, KiCad, Open HW, Hyprland, Wayland, Neovim, Embassy,
wire_weaver, 0xDEADBEEF, 0xC0FFEE, `while(1);`/`loop {}`, sudo sandwich, PCB "Ship it!").
Patches a package file like step 17 (both patches apply in either order); reapply after Omarchy updates.

```bash
cp omarchy-setup/screensaver/screensaver-*.txt ~/.config/omarchy/branding/
sudo patch /usr/bin/omarchy-screensaver < omarchy-setup/omarchy-screensaver-random-art.patch
```

Sources are the SVGs next to the art (fonts: Audiowide from step 33, JetBrainsMono Nerd Font). After editing one:

```bash
omarchy transcode ascii omarchy-setup/screensaver/arch.svg omarchy-setup/screensaver/screensaver-arch.txt --width 84 --height 30 --mode block
```

On a narrow-terminal machine (step 21) lower `--width` to fit.

## 42. Big download caches on the data disk

Machines with a small root and a roomy data disk only (GPD: `/mnt/data/omarchy/cache`). The whole `~/.cache` is a
symlink to the data disk, so every tool, shell, unit and ssh command follows it (`XDG_CACHE_HOME` would miss ssh
commands, and the systemd user manager sets it to `~/.cache` anyway). uv also gets its config file. uv then copies
into venvs instead of hard-linking (other filesystem).

```bash
C=/mnt/data/omarchy/cache   # adjust
mkdir -p $C ~/.config/uv
printf 'cache-dir = "%s/uv"\n' $C > ~/.config/uv/uv.toml
rsync -a ~/.cache/ $C/
mv ~/.cache ~/.cache.old && ln -s $C ~/.cache
rsync -a --update ~/.cache.old/ $C/   # what running programs wrote meanwhile
```

Then delete `~/.cache.old` (programs with files still open there keep them until they restart).

Verify: `ls -ld ~/.cache` shows the link; `uv cache dir` prints `$C/uv`.

## 43. Shell colours under Qt 6.12

Qt 6.12's QtQuick ships a `Color` singleton that shadows the shell's `qs.Commons` `Color`, so every theme colour
reads as undefined (black bar, invisible text). Upstream fixed it in Omarchy 4.0.5 (PR #14553, issue #15545) by
qualifying every use as `Commons.Color` (`import qs.Commons as Commons`); the patch backports that to older
builds (the Asahi bundle was still on b8ed395 in Oct 2026). Our plugins (`roman.lock`, `roman.monitor`) use
`Commons.Color` too, so they work with and without the patch. Skip once Omarchy is 4.0.5 or newer, or if the
patch no longer applies.

```bash
sudo patch -p1 -d /usr/share/omarchy/shell < omarchy-setup/omarchy-shell-qt612-color.patch
omarchy-restart-shell
```

Verify: `journalctl --user -t omarchy-shell --since -1min | grep -c TypeError` is 0 or close to it.

## 44. Bash: Tab cycles through completions

Tab steps through the candidates one by one (Shift+Tab goes back) instead of listing them, e.g. the documents
`tpm d g0 errata<TAB>` offers. `~/.inputrc` replaces `/etc/inputrc`, so it includes it first to keep the defaults.

```bash
cat > ~/.inputrc <<'EOF'
$include /etc/inputrc
TAB: menu-complete
"\e[Z": menu-complete-backward
EOF
```

Verify in a new terminal: `bind -q menu-complete` names `\C-i`.

## 45. Alt+D opens the library picker (tpm d)

Alt+D at the prompt opens `tpm d`'s list of the library (tpm_cli LIB-11): on an empty line the pick becomes
`tpm d PICK`, inside a command it goes in at the cursor (Ctrl-Y: the full path). Replaces bash's Alt+D kill-word.
The switch goes just above the `# >>> tpm completion` block of `~/.bashrc`: that block belongs to `tpm provision`,
which rewrites it, so a line inside it is lost.

```bash
grep -q '^export TPM_ALT_D=1' ~/.bashrc || sed -i 's|^# >>> tpm completion (managed by tpm provision|export TPM_ALT_D=1  # Alt+D opens the tpm d library picker (dot step 45)\n&|' ~/.bashrc
```

Verify in a new terminal (tpm 0.205.36 or newer): `bind -X | grep ed` shows `"\ed" "_tpm_pick_tpm"`.

## 46. Keyboard pointer grid (wl-kbptr)

SUPER+M shows a labelled grid over the screen: type a label to zoom into that cell, then bisect; `g`/`h`/`b`
click left/right/middle, Backspace steps back. Check SUPER+M is still free (`omarchy menu keybindings --print`).
AUR 0.4.1 doesn't build against OpenCV 5, so the PKGBUILD is pinned to upstream main; switch to `yay -S wl-kbptr` once
the AUR package is past 0.4.1.

```bash
(cd omarchy-setup/wl-kbptr && BUILDDIR=/tmp/wl-kbptr SRCDEST=/tmp/wl-kbptr PKGDEST=/tmp/wl-kbptr makepkg -si)
cat omarchy-setup/kbptr-bindings-append.lua >> ~/.config/hypr/bindings.lua
mkdir -p ~/.config/wl-kbptr && cp omarchy-setup/wl-kbptr/config ~/.config/wl-kbptr/config   # Tokyo Night colours
```

Verify: SUPER+M shows the grid.

## After applying

```bash
hyprctl reload && hyprctl configerrors   # hypr/*.lua changes
omarchy restart shell                    # shell.json / plugin changes — editing an
                                          # already-mounted widget's .qml won't
                                          # hot-reload on its own, this always works
```
