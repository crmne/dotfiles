-- Personal look-and-feel overrides, loaded after Omarchy's defaults and the
-- current theme.

-- The current theme's mode and accent. Changing theme reloads Hyprland, so
-- these follow every theme.
local function theme_colors()
  local state_home = require("default.hypr.paths").state_home
  local file = io.open(state_home .. "/omarchy/current/theme/colors.toml", "r")
  if not file then
    return {}
  end
  local colors = file:read("*a")
  file:close()
  return {
    dark = colors:match('%f[%w_]mode%s*=%s*"(%a+)"') == "dark",
    accent = colors:match('%f[%w_]accent%s*=%s*"#(%x%x%x%x%x%x)"'),
  }
end

local theme = theme_colors()

-- Rounded windows with tight gaps and a small, soft drop shadow.
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
  },

  decoration = {
    rounding = 10,

    shadow = {
      enabled = true,
      range = 8,
      render_power = 3,
      offset = { 0, 2 },
    },
  },
})

-- A hairline draws each window's edge, in the accent for the focused window.
-- On dark themes it replaces the shadow, which barely shows against a dark
-- desktop. Unfocused windows get a faint light line on dark themes and a
-- faint dark one on light themes.
hl.config({
  general = {
    border_size = 1,
    col = {
      active_border = "rgba(" .. (theme.accent or "808080") .. "cc)",
      inactive_border = theme.dark and "rgba(ffffff12)" or "rgba(00000014)",
    },
  },
  decoration = {
    shadow = {
      color = "rgba(00000033)",
      color_inactive = "rgba(0000000d)",
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
