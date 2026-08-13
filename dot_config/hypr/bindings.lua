-- Personal bindings loaded after Omarchy's defaults.

o.bind("SUPER + SHIFT + T", "Todoist", {
  webapp = "https://app.todoist.com/app",
  focus = true,
})
o.bind("SUPER + SHIFT + I", "Activity", { tui = "btop" })

-- Replace Google Photos with Immich.
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + SHIFT + P", "Immich", {
  webapp = "https://photos.paolino.me",
  focus = true,
})

-- Dictation lives on the external keyboard's microphone key.
hl.unbind("SUPER + CTRL + X")
o.bind("SHIFT + XF86AudioMicMute", "Toggle dictation", "voxtype record toggle")

-- The external keyboard sends XF86LaunchA for its calculator key.
hl.unbind("XF86Calculator")
o.bind("XF86LaunchA", "Calculator", "omacalc")

-- Replace the Agent shortcut with Claude.
hl.unbind("SUPER + SHIFT + CTRL + A")
o.bind("SUPER + SHIFT + CTRL + A", "Claude", {
  webapp = "https://claude.ai",
  focus = true,
})

o.bind(
  "SUPER + CTRL + SHIFT + W",
  "Wallpaper: Get new random wallpaper",
  "bash -lc 'omarchy-random-wallpaper --mode download'"
)

-- Replace Quattro's weather shortcut with the downloaded-wallpaper picker.
hl.unbind("SUPER + CTRL + ALT + W")
o.bind(
  "SUPER + CTRL + ALT + W",
  "Wallpaper: Pick downloaded one",
  "bash -lc 'omarchy-random-wallpaper --mode existing'"
)

o.bind(
  "SUPER + CTRL + ALT + C",
  "Toggle caffeinate",
  "/home/carmine/scripts/omarchy-caffeinate toggle"
)

-- External keyboard keys (QMK KC_F20 and KC_WWW_SEARCH).
o.bind_toggle("XF86DoNotDisturb", "Toggle silencing notifications", "notification-silencing")
o.bind("XF86Search", "Share", "omarchy menu toggle share")
