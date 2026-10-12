
-- Russian as a real XKB layout; keyd picks the group (see dot/keyd_mac):
-- Ctrl+LeftWin -> us, Ctrl+Menu -> ru.
hl.config({
  input = {
    kb_layout = "us,ru",
    kb_options = "compose:caps,shift:both_capslock_cancel,grp:lctrl_lwin_rctrl_menu",
  },
})
