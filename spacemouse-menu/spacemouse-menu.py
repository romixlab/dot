#!/usr/bin/env python3
"""Pie menu in KiCad on the SpaceMouse buttons: hold a button, move the mouse, release."""
import argparse
import json
import socket
import struct
import subprocess
import sys
import time
import tomllib
from pathlib import Path

HERE = Path(__file__).resolve().parent
SHELL = HERE / "shell.qml"
MENUS = HERE / "menu.json"
BUTTONS = Path.home() / ".config/spacemouse-menu/buttons.json"
THEME = Path.home() / ".local/state/omarchy/current/theme/colors.toml"
EVENT = struct.Struct("8i")
MOTION, PRESS, RELEASE = 0, 1, 2


def version():
    def git(*args):
        return subprocess.run(["git", "-C", str(HERE), *args], capture_output=True, text=True).stdout.strip()

    sha = git("rev-parse", "--short", "HEAD") or "unknown"
    dirty = "-dirty" if git("status", "--porcelain", ".") else ""
    return f"spacemouse-menu ({sha}{dirty}, commit {git('log', '-1', '--format=%cd', '--date=format:%-d %b %Y %H:%M')})"


def events(path):
    """Yield (type, button) for every event, reconnecting when spacenavd restarts."""
    while True:
        try:
            with socket.socket(socket.AF_UNIX) as sock:
                sock.connect(path)
                stream = sock.makefile("rb")
                while len(data := stream.read(EVENT.size)) == EVENT.size:
                    kind, button, *_ = EVENT.unpack(data)
                    yield kind, button
        except OSError as e:
            print(f"{path}: {e}", file=sys.stderr)
        time.sleep(2)


def hyprctl(*args):
    return json.loads(subprocess.run(["hyprctl", "-j", *args], capture_output=True, text=True, check=True).stdout)


def menu_for(menus, window):
    if window.get("class") != "kicad":
        return None
    return next((m for m in menus if m["title"] in window.get("title", "")), None)


def ipc(*args):
    done = subprocess.run(["qs", "ipc", "-p", str(SHELL), "call", "pie", *args], capture_output=True, text=True)
    if done.returncode:
        print(f"qs ipc {args[0]}: {done.stderr.strip()}", file=sys.stderr)
    return done.stdout.strip()


def dispatch(lua):
    subprocess.run(["hyprctl", "dispatch", lua], capture_output=True)


def send_key(key):
    """Send a keyd macro like "x", "S-grave" or "C-S-z", the same as pressing the physical keys."""
    subprocess.run(["keyd", "do", key])


def fire(key, x, y):
    # KiCad's hotkeys act where the cursor is: put it back first, then let KiCad see it.
    dispatch(f"hl.dsp.cursor.move({{ x = {x}, y = {y} }})")
    if key:
        time.sleep(0.03)
        send_key(key)


def load_buttons():
    if BUTTONS.exists():
        return json.loads(BUTTONS.read_text())
    return {"left": 0, "right": 1}


def load_colors():
    colors = {"accent": "#7aa2f7", "background": "#1a1b26", "foreground": "#a9b1d6"}
    if THEME.exists():
        theme = tomllib.loads(THEME.read_text())
        colors |= {k: theme[k] for k in colors if k in theme}
    return colors


def run(args):
    menus = json.loads(MENUS.read_text())
    sides = {number: side for side, number in load_buttons().items()}
    shell = subprocess.Popen(["quickshell", "-n", "-p", str(SHELL)])
    held = set()
    for kind, button in events(args.socket):
        if shell.poll() is not None:
            sys.exit(f"quickshell exited with {shell.returncode}")
        if kind == PRESS and button in sides:
            if not held:
                menu = menu_for(menus, hyprctl("activewindow"))
                if menu is None:
                    continue
                x, y = (hyprctl("cursorpos")[k] for k in ("x", "y"))
                monitor = next(m for m in hyprctl("monitors") if m["focused"])
            held.add(button)
            # A second button while the first is held switches to the ring of both.
            side = sides[button] if len(held) == 1 else "both"
            print(f"press button {button} in {menu['title']} at {x},{y}: {side} ring", flush=True)
            ipc("open", json.dumps({
                "screen": monitor["name"],
                "x": x - monitor["x"],
                "y": y - monitor["y"],
                "side": side,
                "center": menu["center"],
                "ring": menu["rings"][side],
                "colors": load_colors(),
                "home": [x, y],
                "script": str(Path(__file__).resolve()),
            }))
        elif kind == RELEASE and button in held:
            held.discard(button)
            if held:
                continue
            key = ipc("release")
            print(f"release button {button}: {key or 'no action'}", flush=True)
            # "closed": the menu already fired or was cancelled, and the mouse is free again.
            if key != "closed":
                fire(key, x, y)


def calibrate(args):
    """Work out which button number is left and which is right, from the buttons themselves."""
    stream = events(args.socket)
    found = {}
    seen_motion = False
    print("Nudge the puck, then:", flush=True)
    for side in ("left", "right"):
        print(f"Press and release the {side} button on the SpaceMouse...", flush=True)
        for kind, button in stream:
            if kind == MOTION and not seen_motion:
                seen_motion = True
                print("  puck movement seen", flush=True)
            if kind == PRESS and button not in found.values():
                found[side] = button
                print(f"  {side} = button {button}", flush=True)
                break
    BUTTONS.parent.mkdir(parents=True, exist_ok=True)
    BUTTONS.write_text(json.dumps(found) + "\n")
    print(f"Saved to {BUTTONS}. Restart with: systemctl --user restart spacemouse-menu")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", action="version", version=version())
    parser.add_argument("--socket", default="/var/run/spnav.sock", help="spacenavd socket (default: %(default)s)")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("run", help="listen to the buttons and show the menu").set_defaults(func=run)
    commands.add_parser("calibrate", help="find out which button is left and which is right").set_defaults(func=calibrate)
    fire_parser = commands.add_parser("fire", help="put the cursor at X,Y and send KEY (the menu runs this)")
    fire_parser.add_argument("key")
    fire_parser.add_argument("x", type=int)
    fire_parser.add_argument("y", type=int)
    fire_parser.set_defaults(func=lambda args: fire(args.key, args.x, args.y))
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
