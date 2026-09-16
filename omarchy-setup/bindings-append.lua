-- Extra workspace 11, bound to Z (bar icon: "Z", matches roman.workspaces).
o.bind("SUPER + Z", "Switch to workspace 11", hl.dsp.focus({ workspace = "11" }))
o.bind("SUPER + SHIFT + Z", "Move window to workspace 11", hl.dsp.window.move({ workspace = "11" }))

-- Screenshot region -> clipboard (R for Region; both keys were unbound)
o.bind("SUPER + R", "Screenshot region to clipboard", "omarchy-capture-screenshot region copy")
-- Screenshot region -> save to ~/Downloads
o.bind("SUPER + SHIFT + R", "Screenshot region to Downloads", "OMARCHY_SCREENSHOT_DIR=$HOME/Downloads omarchy-capture-screenshot region save")

-- Power menu on SUPER+SHIFT+P (was: Google Photos)
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + SHIFT + P", "Power menu", "omarchy-menu toggle system")
