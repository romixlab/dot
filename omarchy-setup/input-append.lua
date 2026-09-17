-- Natural (inverted) scrolling. Hyprland has no per-axis scroll invert, so
-- this flips both vertical and horizontal scroll direction together.
hl.config({
  input = {
    touchpad = {
      natural_scroll = true,
    },
  },
})
