
-- Keep both external monitors' brightness in sync instead of only
-- adjusting the focused display.
hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")
hl.unbind("SHIFT + XF86MonBrightnessUp")
hl.unbind("SHIFT + XF86MonBrightnessDown")
hl.unbind("ALT + XF86MonBrightnessUp")
hl.unbind("ALT + XF86MonBrightnessDown")

o.bind("XF86MonBrightnessUp", "Brightness up (synced)", "omarchy-brightness-display-sync +5%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down (synced)", "omarchy-brightness-display-sync 5%-", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum (synced)", "omarchy-brightness-display-sync 100%", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum (synced)", "omarchy-brightness-display-sync 1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise (synced)", "omarchy-brightness-display-sync +1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise (synced)", "omarchy-brightness-display-sync 1%-", { locked = true, repeating = true })
