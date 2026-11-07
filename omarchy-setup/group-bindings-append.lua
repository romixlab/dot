
-- Group tabs: SUPER + ALT + LEFT/RIGHT reorders the active tab (mapped on the Ergodox);
-- merging into the group on the left/right moves to SUPER + CTRL + ALT. Up/down merging stays.
hl.unbind("SUPER + ALT + LEFT")
hl.unbind("SUPER + ALT + RIGHT")
o.bind("SUPER + ALT + LEFT", "Move tab left in group", hl.dsp.group.move_window({ forward = false }))
o.bind("SUPER + ALT + RIGHT", "Move tab right in group", hl.dsp.group.move_window({ forward = true }))
o.bind("SUPER + CTRL + ALT + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
o.bind("SUPER + CTRL + ALT + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
