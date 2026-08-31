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
centered_music_window("[Ff]astpotify")
centered_music_window("[Ff]astsapp")
centered_music_window({ initial_title = [[(?i)(?:beta\.)?music\.apple\.com_/]] })
centered_music_window({ initial_title = [[(?i)music\.youtube\.com_/]] })

-- Fastpotify wears a transparent, borderless mini player (Winamp skins) and
-- opens a separate MilkDrop window with the same app id; the default window
-- opacity plus blur turns their opaque pixels see-through, so opt them out
-- like the players above. It manages its own geometry, so no float/center.
o.window("fastpotify", {
	tag = "-default-opacity",
	opacity = "1 1",
})

-- Steam's previous local rules are now covered by Omarchy's defaults.
