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

## After applying

```bash
hyprctl reload && hyprctl configerrors   # hypr/*.lua changes
omarchy restart shell                    # shell.json / plugin changes — editing an
                                          # already-mounted widget's .qml won't
                                          # hot-reload on its own, this always works
```
