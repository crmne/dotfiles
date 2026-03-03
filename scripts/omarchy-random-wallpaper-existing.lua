Name = "omarchyRandomWallpaperExisting"
NamePretty = "Downloaded Wallpapers"
Cache = false
HideFromProviderlist = true
SearchName = true

local function ShellEscape(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function GetEntries()
  local entries = {}
  local home = os.getenv("HOME")
  local wallpaper_dir = home .. "/Wallpapers"

  local handle = io.popen(
    "find -L " .. ShellEscape(wallpaper_dir)
      .. " -maxdepth 1 -type f \\(" ..
      " -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' " ..
      "\\) 2>/dev/null | sort"
  )

  if handle then
    for path in handle:lines() do
      local filename = path:match("([^/]+)$")
      if filename then
        table.insert(entries, {
          Text = filename,
          Value = path,
          Actions = {
            activate = "omarchy-random-wallpaper --apply-existing " .. ShellEscape(path),
          },
          Preview = path,
          PreviewType = "file",
        })
      end
    end
    handle:close()
  end

  return entries
end
