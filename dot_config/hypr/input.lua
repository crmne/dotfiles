-- Personal input overrides, loaded after Omarchy's defaults.

hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "dvorak",
    kb_options = "ctrl:nocaps,compose:ralt,altwin:swap_lalt_lwin",

    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    accel_profile = "flat",
    natural_scroll = true,

    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },
})
