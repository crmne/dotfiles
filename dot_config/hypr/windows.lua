-- Personal window rules, loaded after Omarchy's defaults and the current
-- theme. See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

o.window("com.nextcloud.desktopclient.nextcloud", {
  float = true,
  center = true,
})

local function centered_music_window(match)
  o.window(match, {
    tag = "-default-opacity",
    float = true,
    size = { 1514, 899 },
    center = true,
    opacity = "1 1",
  })
end

centered_music_window("[Ss]potify")
centered_music_window("[Cc]ider")
centered_music_window({ initial_title = [[(?i)(?:beta\.)?music\.apple\.com_/]] })
centered_music_window({ initial_title = [[(?i)music\.youtube\.com_/]] })

-- Steam's previous local rules are now covered by Omarchy's defaults.
