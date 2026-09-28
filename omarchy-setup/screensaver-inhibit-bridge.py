#!/usr/bin/env python3
# D-Bus org.freedesktop.ScreenSaver -> omarchy stay-awake bridge.
#
# VLC (and other legacy apps) call Inhibit/UnInhibit on this interface to
# disable the screensaver. Nothing on Hyprland/omarchy owns that bus name,
# so the calls silently no-op. This proxies them into omarchy's own idle
# override (`omarchy-toggle-idle`), which the Wayland idle service (idle
# monitor with respectInhibitors) actually respects.
import subprocess
import sys

import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib

BUS_NAME = "org.freedesktop.ScreenSaver"
# Not /org/freedesktop/ScreenSaver - VLC's dbus_screensaver module (and the
# generic fallback in xdg-utils' xdg-screensaver) call the interface at this
# shorter conventional path.
OBJECT_PATH = "/ScreenSaver"


class ScreenSaverBridge(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, OBJECT_PATH)
        self._cookie = 0
        self._inhibitors = {}  # cookie -> sender unique name
        bus.add_signal_receiver(
            self._on_name_owner_changed,
            signal_name="NameOwnerChanged",
            dbus_interface="org.freedesktop.DBus",
        )

    def _apply(self):
        state = "stay-awake" if self._inhibitors else "allow-idle"
        subprocess.run(["omarchy-toggle-idle", state], check=False)

    def _on_name_owner_changed(self, name, old_owner, new_owner):
        if new_owner:
            return
        gone = [c for c, sender in self._inhibitors.items() if sender == old_owner]
        for cookie in gone:
            del self._inhibitors[cookie]
        if gone:
            self._apply()

    @dbus.service.method(BUS_NAME, in_signature="ss", out_signature="u",
                          sender_keyword="sender")
    def Inhibit(self, app_name, reason, sender=None):
        self._cookie += 1
        cookie = self._cookie
        self._inhibitors[cookie] = sender
        self._apply()
        return cookie

    @dbus.service.method(BUS_NAME, in_signature="u", sender_keyword="sender")
    def UnInhibit(self, cookie, sender=None):
        self._inhibitors.pop(cookie, None)
        self._apply()


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    try:
        # Must keep a reference for the process lifetime - an unassigned
        # BusName is garbage-collected immediately, releasing the name.
        name = dbus.service.BusName(BUS_NAME, bus, do_not_queue=True)
    except dbus.exceptions.DBusException:
        # Something else already owns it (real DE screensaver) - don't fight it.
        sys.exit(0)
    ScreenSaverBridge(bus)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
