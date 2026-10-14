-- Personal bindings loaded after Omarchy's defaults.

-- Reserve this shortcut for Todoist, clearing any inherited binding first.
hl.unbind("SUPER + SHIFT + T")
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

-- NuPhy keyboards (Halo75 V2 with QMK keymap crmne, Air75 V3 remapped with
-- nuphyctl) send the same codes from their top row. Brightness, mic mute,
-- media, volume and Print Screen use Omarchy's default bindings.

-- Mission Control key (QMK KC_MISSION_CONTROL, NuPhy 0x7E06).
o.bind("XF86LaunchA", "Omarchy menu", "omarchy-menu toggle")
o.bind("SHIFT + XF86LaunchA", "Apps menu", "omarchy-menu toggle apps")

-- Search key (QMK KC_WWW_SEARCH), and Super+Ctrl+/ on any keyboard.
o.bind("XF86Search", "Find files", "omarchy-shell shell toggle crmne.files")
o.bind("SUPER + CTRL + SLASH", "Find files", "omarchy-shell shell toggle crmne.files")

-- Microphone key (F20): mute by default, dictation with Shift.
hl.unbind("SUPER + CTRL + X")
o.bind("SHIFT + XF86AudioMicMute", "Toggle dictation", "voxtype record toggle")

-- Moon key (QMK MAC_DND, NuPhy 0x7E16): notifications, night light with Shift.
o.bind_toggle("XF86DoNotDisturb", "Toggle silencing notifications", "notification-silencing")
o.bind("SHIFT + XF86DoNotDisturb", "Toggle night light", "omarchy-toggle-nightlight")

-- Replace the Agent shortcut with Claude.
hl.unbind("SUPER + SHIFT + CTRL + A")
o.bind("SUPER + SHIFT + CTRL + A", "Claude", {
	webapp = "https://claude.ai",
	focus = true,
})

-- Replace Omarchy's Spotify launcher with Spotifast. A plain launch is
-- enough: a second copy asks the running one to show its window and exits.
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Spotifast", { launch = "spotifast" })

-- Replace Omarchy's WhatsApp launcher with ZapFast. A plain launch is
-- enough: a second copy asks the running one to show its window and exits.
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "ZapFast", { launch = "zapfast" })

hl.unbind("SUPER + SHIFT + ALT + G")
o.bind("SUPER + SHIFT + ALT + G", "Signal", { omarchy = "signal" })
