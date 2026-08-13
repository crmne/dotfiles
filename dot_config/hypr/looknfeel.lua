-- Personal look-and-feel overrides, loaded after Omarchy's defaults and the
-- current theme.

hl.config({
  general = {
    gaps_out = 10,
  },

  decoration = {
    rounding = 10,

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
