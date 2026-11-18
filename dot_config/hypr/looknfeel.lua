-- Personal look-and-feel overrides, loaded after Omarchy's defaults and the
-- current theme.

hl.config({
  -- Apps may request attention, but must not take keyboard focus.
  misc = { focus_on_activate = false },
  general = {
    gaps_in = 0,
    gaps_out = 0,
    border_size = 0,
  },

  decoration = {
    rounding = 0,

    -- Mark the focused window by dimming the others instead of a border.
    dim_inactive = true,
    dim_strength = 0.2,

    shadow = {
      enabled = true,
      range = 10,
      render_power = 3,
      color = "rgba(00000044)",
      color_inactive = "rgba(00000011)",
    },
  },
})

-- Omarchy disables workspace animations by default in Quattro. Restore the
-- previous animation without reviving the obsolete Walker layer rule.
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "default" })

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.
