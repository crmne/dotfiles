-- Personal look-and-feel overrides, loaded after Omarchy's defaults and the
-- current theme.

-- Whether the current theme is dark. Changing theme reloads Hyprland, so this
-- follows every theme.
local function theme_is_dark()
  local state_home = require("default.hypr.paths").state_home
  local file = io.open(state_home .. "/omarchy/current/theme/colors.toml", "r")
  if not file then
    return false
  end
  local colors = file:read("*a")
  file:close()
  return colors:match('%f[%w_]mode%s*=%s*"(%a+)"') == "dark"
end

-- Black shadow alpha (focused, unfocused): lighter on dark themes, where a
-- black shadow reads as a heavy halo.
local shadow = theme_is_dark() and { "26", "0d" } or { "40", "1a" }

-- Floating cards: rounded, borderless windows on a soft drop shadow. The
-- focused window casts the deeper one.
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 0,
  },

  decoration = {
    rounding = 10,

    shadow = {
      enabled = true,
      range = 14,
      render_power = 3,
      offset = { 0, 3 },
      color = "rgba(000000" .. shadow[1] .. ")",
      color_inactive = "rgba(000000" .. shadow[2] .. ")",
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
