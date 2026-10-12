Russian layout: real XKB `us,ru` in Hyprland, switched by keyd. Standard PC ЙЦУКЕН (XKB `ru`), AltGr+8 = ₽.

- `hypr-input.lua` — appended to `~/.config/hypr/input.lua`: `kb_layout = us,ru` and
  `grp:lctrl_lwin_rctrl_menu` (Ctrl+LeftWin → us, Ctrl+Menu → ru).
- `ru` — shared include: `ru` layer that tracks the mode, Alt+Space toggle (sends the group key above).
- `mac.conf` — built-in Apple keyboard: capslock=esc, symbols layer on right Cmd, chords; `[ru]` and
  `[ru+symbols]` keep symbols and chords correct in Russian (native key where ru has the symbol,
  otherwise us for one key and back).
- `ergodox.conf` — Ergodox EZ: toggle only (everything else lives in its firmware, so its
  firmware symbols follow the active layout).

`ru` is a layer, above `[main]`: Russian-mode overrides go in `[ru]`, after `include ru`.

Esc (Caps Lock on the Mac keyboard) in ru switches to en without sending Escape — press it before typing the lock-screen password.

The XKB layout is shared by both keyboards, keyd's mode is per keyboard: after switching on one,
the other may need Alt+Space twice.
