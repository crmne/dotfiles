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
-- nuphyctl) send the same codes from their top row. Brightness,
-- media, volume and Print Screen use Omarchy's default bindings.

-- Mission Control key (QMK KC_MISSION_CONTROL, NuPhy 0x7E06).
o.bind("XF86LaunchA", "Omarchy menu", "omarchy-menu toggle")
o.bind("SHIFT + XF86LaunchA", "Apps menu", "omarchy-menu toggle apps")

-- Search key (QMK KC_WWW_SEARCH), and Ctrl+Alt+Super+Space on any keyboard.
o.bind("XF86Search", "Find files", "omarchy-shell shell toggle crmne.files")

-- Microphone key: dictation by default, mute with Shift.
hl.unbind("SUPER + CTRL + X")
hl.unbind("XF86AudioMicMute")
hl.unbind("SHIFT + XF86AudioMicMute")
o.bind("XF86AudioMicMute", "Toggle dictation", "voxtype record toggle")
o.bind("SHIFT + XF86AudioMicMute", "Mute microphone", "omarchy-audio-input-mute", { locked = true })

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

-- Files opening shortcut (managed from Files settings).
dofile(os.getenv("HOME") .. "/.config/hypr/crmne-files.lua")

-- Super + Shift + arrow swaps the window with its neighbour on this screen,
-- as Omarchy's does, but at the screen's edge moves it to the next screen
-- instead of swapping it with a window there.
local function tiled_neighbour(window, direction)
  local x, y, w, h = window.at.x, window.at.y, window.size.x, window.size.y
  for _, other in ipairs(hl.get_workspace_windows(tostring(window.workspace.id))) do
    if other.address ~= window.address and other.mapped and not other.hidden and not other.floating then
      local ox, oy, ow, oh = other.at.x, other.at.y, other.size.x, other.size.y
      local beside = oy < y + h and y < oy + oh
      local stacked = ox < x + w and x < ox + ow
      if (direction == "l" and beside and ox + ow <= x + 1)
        or (direction == "r" and beside and ox >= x + w - 1)
        or (direction == "u" and stacked and oy + oh <= y + 1)
        or (direction == "d" and stacked and oy >= y + h - 1) then
        return true
      end
    end
  end
  return false
end

for key, direction in pairs({ LEFT = "l", RIGHT = "r", UP = "u", DOWN = "d" }) do
  o.rebind("SUPER + SHIFT + " .. key, "Swap window, or move it to the next screen", function()
    local window = hl.get_active_window()
    if not window then
      return
    end
    if window.floating or not window.workspace or tiled_neighbour(window, direction) then
      hl.dispatch(hl.dsp.window.swap({ direction = direction }))
      return
    end
    local target = hl.get_monitor(direction)
    if target then
      hl.dispatch(hl.dsp.window.move({ monitor = target.name }))
    end
  end)
end
