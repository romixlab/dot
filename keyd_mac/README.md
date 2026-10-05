keyd Russian layout, standard PC ЙЦУКЕН positions (ё on `` ` ``, х ъ on `[ ]`, ж э on `; '`, б ю on `, .`, `.` on `/`).

- `ru` — shared include: layout, shift layer (`!"№;%:?*()`), AltGr+8 = ₽, Alt+Space toggle,
  and modifier layers so Ctrl/Alt/Super shortcuts emit latin keys in ru mode.
- `mac.conf` — built-in Apple keyboard: ru + capslock=esc, symbols layer on right Cmd, chords.
- `ergodox.conf` — Ergodox EZ: ru only (everything else lives in its firmware).
- `ru.compose` — Cyrillic subset of `/usr/share/keyd/keyd.compose`
  (`grep -E '"([а-яА-ЯёЁ№₽])"' /usr/share/keyd/keyd.compose`); the full file crashes GTK4.

Keys mapped in `[main]` override the ru layout, so English-only remaps go in `[en:layout]` (the default layout).

Layout state is per keyboard: toggle on each separately.
