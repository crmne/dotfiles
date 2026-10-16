-- Pure data: shared by the runtime, searchable shortcut menu, and audit tests.
local M = { entries = {} }
function M.normalize(chord)
  local mods, key = {}, nil
  for token in chord:upper():gmatch('[^+]+') do
    local part = token:match('^%s*(.-)%s*$')
    if part == 'SUPER' or part == 'CTRL' or part == 'ALT' or part == 'SHIFT' then
      mods[part] = true
    else key = part end
  end
  local result = {}
  for _, m in ipairs({'SUPER','CTRL','ALT','SHIFT'}) do
    if mods[m] then result[#result+1] = m end
  end
  result[#result+1] = assert(key, chord)
  return table.concat(result, '+')
end
local function add(chord, label, action, args, status, note)
  chord = M.normalize(chord)
  assert(not M.entries[chord], 'Duplicate shortcut: '..chord)
  M.entries[chord] = { chord=chord, label=label, action=action, args=args,
    status=status or 'mapped', note=note or '' }
end
local function wm(chord, label, ...)
  add(chord, label, 'wm', {...})
end
local function app(chord, label, name, fallback)
  add(chord, label, 'app', {name, fallback}, fallback and 'equivalent' or nil,
    fallback and ('Opens '..name..' if installed, otherwise '..fallback) or nil)
end
local function url(chord, label, address) add(chord,label,'url',address) end
local function equivalent(chord,label,action,args,note)
  add(chord,label,action,args,'equivalent',note)
end
local function unsupported(chord,label,note)
  add(chord,label,'unsupported',nil,'unavailable',note)
end
for _, dir in ipairs({'left','right','up','down'}) do
  wm('SUPER+'..dir, 'Focus '..dir, 'focus',dir)
  wm('SUPER+SHIFT+'..dir, 'Swap tile '..dir, 'move-column',dir)
  equivalent('SUPER+ALT+'..dir,'Group or extract '..dir,'wm',{'move',dir},
    'OmniWM joins singleton tiles or extracts the active group member.')
  add('SUPER+SHIFT+ALT+'..dir,'Move workspace to monitor '..dir,'workspaceMonitor',dir)
end
for i=1,10 do
  local key=tostring(i%10)
  wm('SUPER+'..key,'Workspace '..i,'switch-workspace',tostring(i))
  add('SUPER+SHIFT+'..key,'Move and follow to workspace '..i,'moveFollow',tostring(i))
  wm('SUPER+SHIFT+ALT+'..key,'Move silently to workspace '..i,'move-to-workspace',tostring(i))
end
add('SUPER+W','Native close tab/window','native',nil,'native','Native macOS close action, including Ghostty tabs.')
wm('SUPER+Q','Close window','close-focused-window')
wm('SUPER+J','Toggle split','toggle-split')
add('SUPER+T','Native new tab','native',nil,'native','Native Command+T in every app. Command+O toggles floating.')
wm('SUPER+F','Fullscreen','toggle-fullscreen')
equivalent('SUPER+CTRL+F','Native fullscreen','wm',{'toggle-native-fullscreen'},'Native macOS fullscreen, not Hyprland tiled-fullscreen.')
add('SUPER+L','Native address bar / app action','native',nil,'native','Command+L belongs to the focused app; Command+Option+L restores Dwindle tiling.')
for _,key in ipairs({'SUPER+ALT+L'}) do
  equivalent(key,'Restore Dwindle tiling','wm',{'set-workspace-layout','dwindle'},'Restores screen-contained split tiling; never switches into the Niri scrolling layout.')
end
for _,key in ipairs({'SUPER+S','SUPER+GRAVE'}) do wm(key,'Toggle scratchpad','scratchpad','toggle','1') end
for _,key in ipairs({'SUPER+ALT+S','SUPER+SHIFT+GRAVE'}) do wm(key,'Assign scratchpad','scratchpad','assign','1') end
add('SUPER+M','Minimize','minimize')
add('SUPER+TAB','Next occupied workspace','cycleWorkspace',1)
add('SUPER+SHIFT+TAB','Previous occupied workspace','cycleWorkspace',-1)
wm('SUPER+CTRL+TAB','Previous workspace','switch-workspace','back-and-forth')
equivalent('ALT+TAB','Next window','cycleWindow',1,'Cycles visible windows in stable OmniWM ID order, not Hyprland ordering.')
equivalent('ALT+SHIFT+TAB','Previous window','cycleWindow',-1,'Cycles visible windows in stable OmniWM ID order, not Hyprland ordering.')
wm('CTRL+ALT+TAB','Next monitor','focus-monitor','next')
wm('CTRL+ALT+SHIFT+TAB','Previous monitor','focus-monitor','prev')
for _,v in ipairs({{'SUPER+ALT+TAB','down-or-top'},{'SUPER+ALT+SHIFT+TAB','up-or-bottom'},
  {'SUPER+CTRL+LEFT','up-or-bottom'},{'SUPER+CTRL+RIGHT','down-or-top'}}) do
  wm(v[1],'Cycle within group','focus-window',v[2])
end
equivalent('SUPER+G','Join neighboring group','wm',{'move','right'},'Directional grouping, not a toggle. Option+arrows selects the direction.')
equivalent('SUPER+ALT+G','Extract from group','wm',{'move','left'},'Extracts left from a group; on a singleton this can join a neighbor.')
for i=1,5 do
  unsupported('SUPER+ALT+'..i,'Group member '..i,'Dwindle IPC exposes group cycling, not indexed tab selection. Use Command+Option+Tab.')
end
for _,variant in ipairs({{'',2,100},{'ALT+',1,25},{'CTRL+',6,300}}) do
  for _,axis in ipairs({{'','horizontal'},{'SHIFT+','vertical'}}) do
    for _,key in ipairs({'MINUS','EQUAL'}) do
      equivalent('SUPER+'..variant[1]..axis[1]..key,'Resize '..axis[2], 'resize',
        {axis[2],key=='MINUS' and 'shrink' or 'grow',variant[2],variant[3]},
        'Floating/Niri use 25/100/300-point increments. Dwindle uses 1/2/6 proportional steps for fine/normal/coarse.')
    end
  end
end
equivalent('SUPER+ALT+F','Full-width floating window','geometry','width','Floats the window; does not reproduce Hyprland full-width tiling.')
equivalent('SUPER+P','Centered floating window','geometry','center','Pseudo-tiling is unavailable; floats and centers the window.')
equivalent('SUPER+O','Pop out window','wm',{'toggle-focused-window-floating'},'Floats the window; pinning across workspaces is unavailable.')
add('SUPER+ALT+HOME','Save floating width','saveWidth')
equivalent('SUPER+HOME','Restore floating width','geometry','restore','Restores as a floating window.')
add('SUPER+SHIFT+BACKSPACE','Toggle gaps','gaps')
equivalent('SUPER+CTRL+BACKSPACE','Square floating window','geometry','square','Floats and squares the focused window.')
unsupported('SUPER+BACKSPACE','Window transparency','macOS does not expose arbitrary app-window opacity.')
add('SUPER+MOUSE_UP','Previous workspace','scrollWorkspace',-1)
add('SUPER+MOUSE_DOWN','Next workspace','scrollWorkspace',1)
add('SUPER+ALT+MOUSE_UP','Previous group member','scrollGroup',-1)
add('SUPER+ALT+MOUSE_DOWN','Next group member','scrollGroup',1)
add('SUPER+MOUSE:272','Drag window','native',nil,'native','OmniWM Command+left drag.')
add('SUPER+MOUSE:273','Resize window','native',nil,'native','OmniWM Command+right drag.')

add('SUPER+RETURN','New Ghostty window','terminal')
add('SUPER+ALT+RETURN','Tmux','terminal','tmux new-session -A -s main')
add('SUPER+CTRL+RETURN','Herdr','terminal','herdr')
for _,key in ipairs({'SUPER+SHIFT+RETURN','SUPER+SHIFT+B'}) do app(key,'Browser','Google Chrome') end
add('SUPER+SHIFT+ALT+B','Private browser','privateBrowser')
app('SUPER+SHIFT+F','Finder','Finder')
add('SUPER+ALT+SHIFT+F','Finder at terminal directory','finderCwd',nil,'mapped','Uses Ghostty AppleScript working directory; home when no directory is reported.')
add('SUPER+SHIFT+N','Editor','terminal','nvim')
add('SUPER+SHIFT+D','Docker TUI','terminal','lazydocker')
app('SUPER+SHIFT+O','Obsidian','Obsidian')
app('SUPER+SHIFT+W','Text editor','TextEdit','file:///System/Applications/TextEdit.app')
app('SUPER+SHIFT+SLASH','Passwords','1Password')
app('SUPER+SHIFT+M','Spotifast / Spotify','Spotifast','https://open.spotify.com')
app('SUPER+SHIFT+G','ZapFast / WhatsApp','ZapFast','https://web.whatsapp.com')
app('SUPER+SHIFT+ALT+G','Signal','Signal')
equivalent('SUPER+SHIFT+ALT+M','Music','app',{'Spotify','https://open.spotify.com'},'Music app instead of Linux cliamp TUI.')
equivalent('SUPER+SHIFT+I','Activity Monitor','app',{'Activity Monitor'},'Personal Activity binding wins over the inherited input-language-back binding.')
for _,v in ipairs({
  {'A','ChatGPT','https://chatgpt.com'}, {'ALT+A','Grok','https://grok.com'},
  {'CTRL+A','Claude','https://claude.ai'}, {'C','Calendar','https://app.hey.com/calendar/weeks/'},
  {'E','Email','https://app.hey.com'}, {'ALT+E','New email','https://app.hey.com/messages/new?display=standalone&new_window=true'},
  {'Y','YouTube','https://youtube.com'}, {'CTRL+G','Google Messages','https://messages.google.com/web/conversations'},
  {'P','Immich','https://photos.paolino.me'}, {'S','Google Maps','https://maps.google.com'},
  {'X','X','https://x.com'}, {'ALT+X','X Post','https://x.com/compose/post'},
  {'T','Todoist','https://app.todoist.com/app'},
}) do url('SUPER+SHIFT+'..v[1],v[2],v[3]) end

add('SUPER+SPACE','Raycast','native',nil,'native','Raycast owns Command+Space.')
wm('SUPER+ALT+SPACE','Applications','open-command-palette','applications')
add('SUPER+ESCAPE','System menu','menu','system')
add('SUPER+CTRL+O','Toggle menu','menu','toggles')
add('SUPER+CTRL+H','Hardware menu','menu','hardware')
add('SUPER+K','Search all shortcuts','help')
add('SUPER+CTRL+ESCAPE','Toggle native shortcut passthrough','passthrough')
add('SUPER+ALT+K','Tmux shortcuts','terminal','tmux list-keys | less')
url('SUPER+CTRL+K','Herdr shortcuts','https://herdr.dev/docs/keyboard/')
add('SUPER+CTRL+E','Emoji picker','emoji')
app('SUPER+CTRL+Q','Calculator','Calculator')
equivalent('SUPER+CTRL+V','Clipboard history','url','raycast://extensions/raycast/clipboard-history/clipboard-history','Uses Raycast clipboard history and its privacy settings.')
wm('SUPER+CTRL+SLASH','Find files','open-command-palette','files')
wm('SUPER+SHIFT+SPACE','Toggle workspace bar','toggle-workspace-bar')
equivalent('SUPER+CTRL+ALT+F','Desktop overview','wm',{'toggle-overview'},'OmniWM Overview, not full-screen desktop mode.')
for _,v in ipairs({
  {'SUPER+CTRL+SPACE','Wallpaper','Wallpaper-Settings.extension'},
  {'SUPER+SHIFT+CTRL+SPACE','Appearance','Appearance-Settings.extension'},
  {'SUPER+CTRL+A','Audio','Sound-Settings.extension'},
  {'SUPER+CTRL+B','Bluetooth','BluetoothSettings'},
  {'SUPER+CTRL+D','Displays','Displays-Settings.extension'},
  {'SUPER+CTRL+W','Network','Network-Settings.extension'},
  {'SUPER+CTRL+P','Energy','Energy-Saver-Settings.extension'},
  {'SUPER+CTRL+N','Night Shift','Displays-Settings.extension'},
  {'SUPER+CTRL+COMMA','Focus','Focus-Settings.extension'},
  {'SUPER+SLASH','Display scaling','Displays-Settings.extension'},
  {'SUPER+ALT+SLASH','Display scaling','Displays-Settings.extension'},
  {'SUPER+CTRL+DELETE','Display settings','Displays-Settings.extension'},
  {'SUPER+CTRL+ALT+DELETE','Display mirroring','Displays-Settings.extension'},
}) do equivalent(v[1],v[2],'settings',v[3],'Opens native settings; no fragile UI automation or private display API.') end
app('SUPER+CTRL+T','Activity Monitor','Activity Monitor')
app('SUPER+CTRL+ALT+D','Calendar','Calendar')
app('SUPER+CTRL+ALT+E','World clock','Clock')
app('SUPER+CTRL+ALT+W','Weather','Weather')
add('SUPER+CTRL+ALT+T','Show time','time')
add('SUPER+CTRL+ALT+B','Show battery / power','battery')
equivalent('SUPER+CTRL+I','Toggle keep-awake','awake',nil,'Prevents idle sleep rather than disabling the screen-lock policy. Manual locking remains available.')
add('SUPER+CTRL+L','Lock screen','lock')
for _,v in ipairs({{'SUPER+CTRL+R','Set reminder'},{'SUPER+CTRL+ALT+R','Show reminders'},
  {'SUPER+SHIFT+CTRL+R','Manage reminders'}}) do
  equivalent(v[1],v[2],'app',{'Reminders'},'Opens Reminders; never deletes existing reminders automatically.')
end
for _,v in ipairs({{'SUPER+COMMA','Dismiss notification'},{'SUPER+SHIFT+COMMA','Dismiss all notifications'},
  {'SUPER+ALT+COMMA','Invoke notification'},{'SUPER+SHIFT+ALT+COMMA','Notification history'}}) do
  equivalent(v[1],v[2],'notificationCenter',nil,'Opens notification settings; click the menu-bar clock for history and dismissal. No stable notification-control API.')
end
for i=1,9 do
  unsupported('SUPER+CTRL+'..i,'Omarchy bar panel '..i,'Linux Omarchy shell panels are not installed. Use Command+Control+H for Mac hardware controls.')
end
equivalent('SUPER+CTRL+Z','Accessibility zoom','settings','Accessibility-Settings.extension','Configure native Zoom in Accessibility; no global zoom transform API.')
equivalent('SUPER+CTRL+ALT+Z','Reset zoom settings','settings','Accessibility-Settings.extension','Native Zoom settings; does not forcibly reset zoom.')
add('SUPER+I','Next input source','inputSource')
add('CTRL+SPACE','Terminal prefix passthrough','native',nil,'native','Passed unchanged to the terminal; check macOS input-source shortcut conflicts.')
for _,key in ipairs({'A','C','V','X'}) do add('SUPER+'..key,'Native editing','native',nil,'native') end
equivalent('PRINT','Screenshot selection','screenshot',nil,'Native selection capture to clipboard, not Omarchy screenshot editor/file workflow.')
add('ALT+PRINT','Screenshot / recording controls','capture')
add('SUPER+CTRL+C','Capture menu','capture')
equivalent('SUPER+PRINT','Color picker','app',{'Digital Color Meter'},'Native Digital Color Meter instead of Linux color picker.')
equivalent('SUPER+CTRL+PRINT','Screenshot for Live Text','capture',nil,'Capture, then use Live Text in Preview; automatic OCR is not installed.')
unsupported('SUPER+ALT+LEFTBRACKET','Shrink webcam overlay','No webcam overlay is installed.')
unsupported('SUPER+ALT+RIGHTBRACKET','Enlarge webcam overlay','No webcam overlay is installed.')
equivalent('SUPER+CTRL+S','Share files','app',{'LocalSend'},'Opens installed LocalSend; does not upload anything automatically.')
equivalent('SUPER+CTRL+PERIOD','Transcode media','app',{'Compressor'},'Opens installed Compressor; no unattended conversion is started.')
add('SHIFT+XF86AUDIOMICMUTE','Toggle dictation','dictation','toggle')
add('F9','Push-to-talk dictation','pushToTalk')
add('ALT+ALT_R','Right Option push-to-talk','rightOptionTalk')
add('XF86AUDIOMICMUTE','Mute microphone','mic')
add('XF86LAUNCHA','Raycast','url','raycast://')
wm('SHIFT+XF86LAUNCHA','Applications','open-command-palette','applications')
wm('XF86SEARCH','Find files','open-command-palette','files')
equivalent('SHIFT+XF86DONOTDISTURB','Night Shift','settings','Displays-Settings.extension','Opens display settings.')
equivalent('XF86DONOTDISTURB','Focus settings','settings','Focus-Settings.extension','Opens Focus settings, not an automatic DND toggle.')
app('XF86CALCULATOR','Calculator','Calculator')
add('XF86POWEROFF','Power menu','menu','system')
for _,key in ipairs({'XF86AUDIOLOWERVOLUME','XF86AUDIORAISEVOLUME'}) do
  add('ALT+'..key,'Fine volume','volume',key:find('LOWER') and -1 or 1)
end
for _,key in ipairs({'XF86MONBRIGHTNESSDOWN','XF86MONBRIGHTNESSUP'}) do
  add('ALT+'..key,'Fine brightness','brightness',key:find('DOWN') and -1 or 1)
  add('SHIFT+'..key,'Brightness extreme','brightness',key:find('DOWN') and -100 or 100)
end
add('SHIFT+XF86AUDIOMUTE','Switch audio output','audioOutput')
add('ALT+XF86AUDIOPLAY','Next track','media','NEXT')
add('ALT+SHIFT+XF86AUDIOPLAY','Previous track','media','PREVIOUS')
for _,key in ipairs({'XF86AUDIOPLAY','XF86AUDIOPAUSE'}) do
  equivalent('SHIFT+'..key,'Select media source','app',{'Music'},'Opens Music; no universal macOS media-source switching API.')
end
for _,key in ipairs({'XF86AUDIOLOWERVOLUME','XF86AUDIORAISEVOLUME','XF86AUDIOMUTE',
  'XF86AUDIONEXT','XF86AUDIOPREV','XF86AUDIOPLAY','XF86AUDIOPAUSE','XF86MONBRIGHTNESSDOWN',
  'XF86MONBRIGHTNESSUP','XF86KBDBRIGHTNESSDOWN','XF86KBDBRIGHTNESSUP','XF86EJECT',
  'SWITCH:OFF:APPLE SMC POWER/LID EVENTS','SWITCH:ON:APPLE SMC POWER/LID EVENTS',
  'SWITCH:OFF:LID SWITCH','SWITCH:ON:LID SWITCH'}) do
  add(key,'Native hardware behavior','native',nil,'native','macOS / keyboard firmware handles this event; lid events do not apply to a desktop Mac.')
end
for _,key in ipairs({'XF86TOUCHPADOFF','XF86TOUCHPADON','XF86TOUCHPADTOGGLE','XF86KBDLIGHTONOFF'}) do
  unsupported(key,'Linux hardware toggle','No corresponding macOS event/control; NuPhy keyboard lighting is firmware-controlled.')
end
unsupported('SUPER+SHIFT+CODE:201','Linux alternate menu key','Linux evdev code 201 has no identified macOS counterpart. Use Command+Space.')
unsupported('CTRL+ALT+DELETE','Close all windows','Deliberately not globally bound: risks closing agent work. Close individual windows with Command+W.')
-- These Linux consumer usages have no verified event translation on this Mac.
-- Preserve their intended action in the reference without claiming a live bind.
for _,chord in ipairs({'XF86SEARCH','XF86DONOTDISTURB','SHIFT+XF86DONOTDISTURB','XF86CALCULATOR'}) do
  local b=M.entries[M.normalize(chord)]
  b.status='hardware-unverified'
  b.note='NuPhy consumer-key event is not identified on macOS. Use the corresponding Command shortcut or menu.'
end
for _,chord in ipairs({'XF86LAUNCHA','SHIFT+XF86LAUNCHA'}) do
  local b=M.entries[M.normalize(chord)]
  b.status='hardware-unverified'
  b.note='Handles macOS LAUNCH_PANEL events; the physical NuPhy Mission Control key still needs testing. Command+Space / Command+Option+Space work independently.'
end
-- Explicit user policy: ordinary app commands win over their Omarchy actions.
local nativeAppKeys={
  ['SUPER+F']='Find', ['SUPER+S']='Save', ['SUPER+Q']='Quit app',
  ['SUPER+P']='Print', ['SUPER+G']='Find next', ['SUPER+COMMA']='App settings',
  ['SUPER+SHIFT+T']='Reopen closed tab', ['SUPER+SHIFT+W']='Close window',
  ['SUPER+SHIFT+N']='Private window / new folder',
}
for chord,label in pairs(nativeAppKeys) do
  local entry=assert(M.entries[chord])
  entry.label='Native '..label
  entry.action='native'
  entry.args=nil
  entry.status='native'
  entry.note='Passed unchanged to the focused app by explicit user preference.'
end
return M
