# Workspace app launcher

Opens the daily-driver apps on fixed workspaces, without stealing focus, on
demand via `SUPER SHIFT + U`. Idempotent — skips any app that's already
running instead of spawning a duplicate.

| App | Workspace | Window class |
|---|---|---|
| Firefox | 1 | `firefox` |
| Terminal (ghostty) | 2 | `com.mitchellh.ghostty` |
| SpeedCrunch | 3 | `org.speedcrunch.speedcrunch` |
| Obsidian | 3 | `md.obsidian.Obsidian` |
| KeePassXC | 10 | `org.keepassxc.KeePassXC` |
| Zed | 11 (the "Z" workspace from step 4) | `dev.zed.Zed` |

## Apply

```bash
cat hypr-workspace-launcher/bindings.lua >> ~/.config/hypr/bindings.lua
hyprctl reload && hyprctl configerrors
```

[`bindings.lua`](bindings.lua) defines `omarchy_launch_workspace_session()`
(the per-app launch + one-shot workspace rule) and binds it to
`SUPER SHIFT + U`. No autostart hook — it only runs when triggered.

Check `omarchy menu keybindings --print` first — if `SUPER SHIFT + U` is
already bound on the target machine, pick a different free key and update it
in `bindings.lua` before appending.

## Why not a plain window-class rule

The obvious alternative — `o.window({ class = "..." }, { workspace = "N" })`
— assigns *every* window of that class to workspace N forever. That breaks
normal usage: e.g. every ad-hoc terminal opened later via `SUPER + RETURN`
would get yanked to workspace 2 instead of opening where you are. Using
`hl.exec_cmd(cmd, { workspace = "N silent" })` instead attaches the workspace
rule only to the window spawned by that specific launch, so it's a one-shot
placement, not a standing rule.

## Why the "already running" check matters

Ghostty and Zed are effectively single-instance: relaunching the binary just
asks the already-running process to open a new window rather than starting a
fresh process. Hyprland's one-shot exec rule is tracked by the PID it
spawned, so if that PID just forwards the request and exits, the rule never
attaches to the right window and can bleed onto whatever opens next. Guarding
each launch with `hl.get_windows({ class = ... })` avoids the whole class of
bug by never re-launching an app that's already open (which is also just the
more useful behavior for the `SUPER SHIFT + U` replay case).

## Rederiving window classes on a new machine

If an app version changes its class, or you're adapting this for other apps,
open it and check `hyprctl clients -j`, e.g.:

```bash
uwsm-app -- speedcrunch &
sleep 1
hyprctl clients -j | python3 -c "import json,sys; [print(c['class']) for c in json.load(sys.stdin)]"
```
