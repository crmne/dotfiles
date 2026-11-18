-- Personal look-and-feel overrides, loaded after Omarchy's defaults and the
-- current theme.

-- Floating cards: rounded, borderless windows on a soft drop shadow. The
-- focused window casts the deeper shadow.
hl.config({
  general = {
    gaps_in = 8,
    gaps_out = 16,
    border_size = 0,
  },

  decoration = {
    rounding = 10,

    shadow = {
      enabled = true,
      range = 28,
      render_power = 2,
      offset = { 0, 6 },
      color = "rgba(00000059)",
      color_inactive = "rgba(00000026)",
    },
  },
})

-- Omarchy 4.5 turns workspace animations off; slide between them instead.
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "default" })

-- Apps may request attention, but must not take keyboard focus.
hl.config({ misc = { focus_on_activate = false } })

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.
