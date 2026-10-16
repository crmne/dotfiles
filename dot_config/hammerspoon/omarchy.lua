local bindings = require('bindings')
local M = { bindings=bindings.entries, hotkeys={}, tasks={}, failures={}, fallbacks={}, enabled=true }
local home = os.getenv('HOME')
local ctl = '/opt/homebrew/bin/omniwmctl'
local vox = home..'/.local/bin/voxtype'
local actions, queue, busy = {}, {}, false
local function alert(message) hs.alert.show(message, 3) end
local function task(path,args,callback)
  local t
  t = hs.task.new(path,function(code,out,err)
    M.tasks[t] = nil
    if callback then callback(code,out,err)
    elseif code ~= 0 then alert('Command failed: '..path:match('[^/]+$')); print(err) end
  end,args)
  if not t then alert('Cannot start '..path); return end
  M.tasks[t] = true
  if not t:start() then M.tasks[t]=nil; alert('Could not launch '..path) end
  return t
end
local function processQueue()
  if busy or #queue==0 then return end
  busy=true
  local item=table.remove(queue,1)
  task(ctl,item.args,function(code,out,err)
    local decoded=hs.json.decode(out) or hs.json.decode(err)
    local success=decoded and ((code==0 and decoded.ok) or decoded.code=='no_change')
    busy=false
    if item.callback then
      local ok,message=pcall(item.callback,success,decoded and decoded.result and decoded.result.payload)
      if not ok then print(message); alert('OmniWM callback failed') end
    elseif code~=0 then
      if not success then alert(decoded and (decoded.message or decoded.code) or 'OmniWM command failed') end
      print(err)
    end
    processQueue()
  end)
end
local function omni(args,callback)
  local jsonArgs={}
  for _,v in ipairs(args) do jsonArgs[#jsonArgs+1]=v end
  jsonArgs[#jsonArgs+1]='--json'
  queue[#queue+1]={args=jsonArgs,callback=callback}; processQueue()
end
local function wm(args,callback)
  local all={'command'}; for _,v in ipairs(args) do all[#all+1]=v end
  omni(all,callback)
end
local function openURL(url) task('/usr/bin/open',{url}) end
local function focused() return hs.window.focusedWindow() end
local function dispatch(entry)
  if not entry then return end
  local ok,err=pcall(actions[entry.action],entry.args,entry)
  if not ok then alert('Shortcut failed: '..entry.label); print(err) end
end
-- dispatch also supplies the binding descriptor. It is not a completion callback.
actions.wm=function(args) wm(args) end
actions.native=function() end
actions.unsupported=function(_,entry) alert(entry.note) end
actions.url=openURL
actions.app=function(args)
  if not hs.application.launchOrFocus(args[1]) then
    if args[2] then openURL(args[2]) else alert(args[1]..' is not installed') end
  end
end
actions.terminal=function(command)
  if not command then
    local app=hs.application.get('com.mitchellh.ghostty')
    if app then
      app:activate()
      if not app:selectMenuItem({'File','New Window'}) then alert('Ghostty New Window menu unavailable') end
    else hs.application.launchOrFocus('Ghostty') end
    return
  end
  local shellCommand='/opt/homebrew/bin/fish -lc '.."'"..command:gsub("'", "'\\''").."'"
  local script='on run argv\nwith timeout of 10 seconds\ntell application "Ghostty"\n'
    ..'set cfg to new surface configuration\n'
    ..'if (count argv) > 0 then set command of cfg to item 1 of argv\n'
    ..'new window with configuration cfg\nactivate\nend tell\nend timeout\nend run'
  -- Probe read-only first: never retry a timed-out mutating launch, which could
  -- start a command twice. Older running Ghostty instances may not answer AE.
  task('/usr/bin/osascript',{'-e','with timeout of 3 seconds\ntell application "Ghostty" to count windows\nend timeout'},function(code)
    if code==0 then task('/usr/bin/osascript',{'-e',script,shellCommand})
    else
      alert('Ghostty scripting unavailable; opening command in macOS Terminal')
      task('/usr/bin/osascript',{'-e','on run argv\nwith timeout of 15 seconds\ntell application "Terminal"\ndo script (item 1 of argv)\nactivate\nend tell\nend timeout\nend run',shellCommand})
    end
  end)
end
actions.privateBrowser=function() task('/usr/bin/open',{'-a','Google Chrome','--args','--incognito'}) end
actions.settings=function(pane) openURL('x-apple.systempreferences:com.apple.'..pane) end
actions.finderCwd=function()
  local w=focused(); local app=w and w:application()
  if not app or app:bundleID()~='com.mitchellh.ghostty' then openURL(home); return end
  task('/usr/bin/osascript',{'-e','with timeout of 3 seconds\ntell application "Ghostty" to return working directory of focused terminal of selected tab of front window\nend timeout'},function(code,out)
    local directory=out:match('^%s*(.-)%s*$')
    if code==0 and directory:sub(1,1)=='/' then task('/usr/bin/open',{'--',directory})
    else openURL(home) end
  end)
end
actions.minimize=function() local w=focused(); if w then w:minimize() end end
actions.moveFollow=function(number)
  -- Follow the exact window, not whichever window acquires focus after moving.
  omni({'query','windows','--focused','--fields','id'},function(found,p)
    local window=found and p.windows and p.windows[1]
    if not window then alert('No focused window to move'); return end
    omni({'window','move-to-workspace',window.id,number},function(ok)
      if ok then omni({'window','navigate',window.id})
      else alert('Window could not move') end
    end)
  end)
end
actions.workspaceMonitor=function(direction)
  omni({'query','active-workspace'},function(ok,p)
    if ok and p.workspace then omni({'workspace','move-to-monitor',p.workspace.rawName,direction,'--force'}) end
  end)
end
actions.cycleWorkspace=function(direction)
  omni({'query','workspaces','--fields','raw-name,window-counts,is-current'},function(ok,p)
    if not ok then return end
    local candidates,current={},1
    for _,w in ipairs(p.workspaces or {}) do
      if w.isCurrent or (w.counts and w.counts.total>0) then candidates[#candidates+1]=w end
    end
    table.sort(candidates,function(a,b) return tonumber(a.rawName)<tonumber(b.rawName) end)
    for i,w in ipairs(candidates) do if w.isCurrent then current=i end end
    if #candidates>1 then wm({'switch-workspace',candidates[(current-1+direction)%#candidates+1].rawName}) end
  end)
end
actions.cycleWindow=function(direction)
  omni({'query','windows','--visible','--fields','id,is-focused'},function(ok,p)
    if not ok then return end
    local windows=p.windows or {}; table.sort(windows,function(a,b) return a.id<b.id end)
    local index=1
    for i,w in ipairs(windows) do if w.isFocused then index=i end end
    if #windows>1 then omni({'window','focus',windows[(index-1+direction)%#windows+1].id}) end
  end)
end
actions.resize=function(args)
  local target=focused()
  omni({'query','windows','--focused','--fields','mode'},function(ok,p)
    if not ok then return end
    local window=p.windows and p.windows[1]
    if not window then return end
    if window.mode=='floating' then
      local current=focused()
      if not target or not current or target:id()~=current:id() then return end
      local frame,screen=target:frame(),target:screen():frame()
      local dimension=args[1]=='horizontal' and 'w' or 'h'
      local delta=(args[2]=='grow' and 1 or -1)*args[4]
      frame[dimension]=math.max(100,math.min(screen[dimension],frame[dimension]+delta))
      target:setFrameInScreenBounds(frame,0)
      return
    end
    omni({'query','workspaces','--current','--fields','layout'},function(layoutOK,workspace)
      if not layoutOK then return end
      if workspace.workspaces[1] and workspace.workspaces[1].layout=='niri' then
        wm({args[1]=='horizontal' and 'set-container-primary-span' or 'set-window-secondary-span',
          (args[2]=='grow' and '+' or '-')..tostring(args[4])})
      else for _=1,args[3] do wm({'resize',args[1],args[2]}) end end
    end)
  end)
end
actions.saveWidth=function()
  local w=focused(); if w then hs.settings.set('omarchy.savedWidth',w:frame().w); alert('Window width saved') end
end
actions.geometry=function(mode)
  local w=focused(); if not w then return end
  local function resize()
    if not w:id() then return end
    local f,s=w:frame(),w:screen():frame()
    if mode=='width' then f.x=s.x; f.w=s.w
    elseif mode=='square' then f.w=math.min(f.h,s.w); f.h=f.w
    elseif mode=='restore' then f.w=math.min(hs.settings.get('omarchy.savedWidth') or f.w,s.w)
    else f.w=s.w*0.7; f.h=s.h*0.75; f.x=s.x+(s.w-f.w)/2; f.y=s.y+(s.h-f.h)/2 end
    w:setFrameInScreenBounds(f,0)
  end
  omni({'query','windows','--focused','--fields','mode'},function(ok,p)
    if not ok then return end
    local window=p.windows and p.windows[1]
    if window and window.mode=='floating' then resize()
    else wm({'toggle-focused-window-floating'},function(changed)
      if changed then M.resizeTimer=hs.timer.doAfter(0.15,resize) end
    end) end
  end)
end
actions.gaps=function()
  local path=home..'/.config/omniwm/settings.toml'
  local f=io.open(path,'r'); if not f then return end
  local text=f:read('*a'); f:close()
  local current=tonumber(text:match('%[gaps%].-\nsize = ([%d.]+)'))
  if not current then alert('Cannot locate OmniWM gap setting'); return end
  local nextSize=current==0 and (hs.settings.get('omarchy.gapSize') or 8) or 0
  if current>0 then hs.settings.set('omarchy.gapSize',current) end
  text=text:gsub('(%[gaps%].-\nsize = )[%d.]+','%1'..tostring(nextSize),1)
  f=assert(io.open(path..'.tmp','w')); f:write(text); f:close()
  assert(os.rename(path..'.tmp',path)); alert('Gaps: '..nextSize)
end
actions.emoji=function() task('/usr/bin/open',{'/System/Library/Input Methods/CharacterPalette.app'}) end
actions.notificationCenter=function()
  -- A supported trackpad gesture is preferable to brittle AX hierarchy walks.
  actions.settings('Notifications-Settings.extension')
  alert('Notification controls: click the menu-bar clock to open Notification Center.')
end
actions.time=function() alert(os.date('%A, %d %B  %H:%M')) end
actions.battery=function()
  local pct=hs.battery.percentage()
  alert(pct and pct>0 and string.format('Battery %.0f%%, %s',pct,hs.battery.powerSource()) or 'Desktop Mac: running on AC power')
end
actions.awake=function()
  local enabled=not hs.caffeinate.get('systemIdle')
  hs.caffeinate.set('systemIdle',enabled)
  alert(enabled and 'Keep-awake ON; display may sleep' or 'Keep-awake OFF')
end
actions.lock=function() hs.caffeinate.lockScreen() end
actions.inputSource=function()
  local ids=hs.keycodes.layouts(true); local current=hs.keycodes.currentSourceID()
  for _,id in ipairs(hs.keycodes.methods(true)) do ids[#ids+1]=id end
  for i,id in ipairs(ids) do if id==current then hs.keycodes.currentSourceID(ids[i%#ids+1]); return end end
end
actions.screenshot=function() task('/usr/sbin/screencapture',{'-i','-c'}) end
actions.capture=function() task('/usr/bin/open',{'-a','Screenshot'}) end
actions.dictation=function(command) task(vox,{'record',command}) end
actions.pushToTalk=function() actions.dictation('start') end
actions.rightOptionTalk=actions.pushToTalk
actions.mic=function()
  local device=hs.audiodevice.defaultInputDevice()
  if device then device:setInputMuted(not device:inputMuted()); alert(device:inputMuted() and 'Microphone muted' or 'Microphone unmuted') end
end
actions.volume=function(delta)
  local device=hs.audiodevice.defaultOutputDevice()
  if device and device:outputVolume() then device:setOutputVolume(math.max(0,math.min(100,device:outputVolume()+delta))) end
end
actions.brightness=function(delta)
  local current=hs.brightness.get()
  if current then hs.brightness.set(math.max(0,math.min(100,current+delta)))
  else alert('This display does not expose native brightness control; use BetterDisplay.') end
end
actions.audioOutput=function()
  local devices=hs.audiodevice.allOutputDevices(); local current=hs.audiodevice.defaultOutputDevice()
  for i,d in ipairs(devices) do if current and d:uid()==current:uid() then
    local nextDevice=devices[i%#devices+1]; nextDevice:setDefaultOutputDevice(); alert(nextDevice:name()); return
  end end
end
actions.media=function(key)
  hs.eventtap.event.newSystemKeyEvent(key,true):post()
  hs.eventtap.event.newSystemKeyEvent(key,false):post()
end
actions.help=function()
  local choices={}
  for chord,b in pairs(bindings.entries) do
    choices[#choices+1]={text=chord..'  '..b.label,subText=b.status..(b.note~='' and ': '..b.note or ''),entry=b}
  end
  table.sort(choices,function(a,b) return a.text<b.text end)
  M.chooser=hs.chooser.new(function(choice) if choice then
    if choice.entry.status=='unavailable' then alert(choice.entry.note)
    else alert(choice.entry.label..': '..choice.entry.chord) end
  end end):choices(choices):searchSubText(true)
  M.chooser:show()
end
actions.menu=function(kind)
  local lists={
    system={{'Lock screen','lock'},{'Keep awake on/off','awake'},{'Shortcuts','help'},
      {'System Settings','app',{'System Settings'}},{'Sleep','sleep'}},
    toggles={{'Keep awake on/off','awake'},{'Toggle gaps','gaps'},
      {'Workspace bar','wm',{'toggle-workspace-bar'}},{'Appearance','settings','Appearance-Settings.extension'},
      {'Night Shift settings','settings','Displays-Settings.extension'}, {'Native shortcuts on/off','passthrough'}},
    hardware={{'Sound','settings','Sound-Settings.extension'},{'Bluetooth','settings','BluetoothSettings'},
      {'Displays','settings','Displays-Settings.extension'},{'Network','settings','Network-Settings.extension'},
      {'Microphone mute','mic'},{'Switch audio output','audioOutput'},{'Activity Monitor','app',{'Activity Monitor'}}},
  }
  local choices={}
  for _,item in ipairs(lists[kind]) do choices[#choices+1]={text=item[1],action=item[2],args=item[3]} end
  M.chooser=hs.chooser.new(function(choice) if choice then actions[choice.action](choice.args) end end):choices(choices)
  M.chooser:show()
end
actions.sleep=function() hs.caffeinate.systemSleep() end
actions.scrollWorkspace=actions.cycleWorkspace
actions.scrollGroup=function(direction) wm({'focus-window',direction>0 and 'down-or-top' or 'up-or-bottom'}) end
actions.passthrough=function()
  M.enabled=not M.enabled
  for _,h in ipairs(M.hotkeys) do if M.enabled then h:enable() else h:disable() end end
  if M.enabled then M.events:start() else M.events:stop() end
  alert(M.enabled and 'Omarchy shortcuts ON' or 'Native shortcuts ON; Command+Control+Escape restores Omarchy')
end

local modifierNames={SUPER='cmd',CTRL='ctrl',ALT='alt',SHIFT='shift'}
local keyNames={RETURN='return',GRAVE='`',MINUS='-',EQUAL='=',LEFTBRACKET='[',RIGHTBRACKET=']',
  SLASH='/',COMMA=',',PERIOD='.',BACKSPACE='delete',DELETE='forwarddelete',PRINT='f13',XF86AUDIOMICMUTE='f20'}
local systemNames={SOUND_UP='XF86AUDIORAISEVOLUME',SOUND_DOWN='XF86AUDIOLOWERVOLUME',
  MUTE='XF86AUDIOMUTE',BRIGHTNESS_UP='XF86MONBRIGHTNESSUP',BRIGHTNESS_DOWN='XF86MONBRIGHTNESSDOWN',
  PLAY='XF86AUDIOPLAY',LAUNCH_PANEL='XF86LAUNCHA',POWER='XF86POWEROFF'}
local function eventChord(flags,key)
  local pieces={}
  for _,m in ipairs({'SUPER','CTRL','ALT','SHIFT'}) do if flags[modifierNames[m]] then pieces[#pieces+1]=m end end
  pieces[#pieces+1]=key; return table.concat(pieces,'+')
end
local lastScroll=0
M.events=hs.eventtap.new({hs.eventtap.event.types.keyDown,hs.eventtap.event.types.keyUp,
  hs.eventtap.event.types.scrollWheel,hs.eventtap.event.types.systemDefined,
  hs.eventtap.event.types.flagsChanged},function(event)
  if not M.enabled then return false end
  local kind,flags=event:getType(),event:getFlags()
  if kind==hs.eventtap.event.types.keyDown or kind==hs.eventtap.event.types.keyUp then
    local b=M.fallbacks[eventChord(flags,tostring(event:getKeyCode()))]
    if b then
      if kind==hs.eventtap.event.types.keyDown then dispatch(b) end
      return true
    end
  elseif kind==hs.eventtap.event.types.scrollWheel then
    if not flags.cmd or flags.ctrl or flags.shift then return false end
    local delta=event:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1)
    if delta==0 then return false end
    local b=bindings.entries[eventChord(flags,delta>0 and 'MOUSE_UP' or 'MOUSE_DOWN')]
    if not b then return false end
    local now=hs.timer.secondsSinceEpoch()
    if now-lastScroll>0.2 then lastScroll=now; dispatch(b) end
    return true
  elseif kind==hs.eventtap.event.types.systemDefined then
    local key=event:systemKey(); local name=systemNames[key.key]
    if not name then return false end
    local b=bindings.entries[eventChord(flags,name)]
    if not b or b.action=='native' or b.status=='unavailable' then return false end
    if key.down and not key['repeat'] then dispatch(b) end
    return true
  elseif event:getKeyCode()==61 then -- physical right Option; preserve typing
    if flags.alt and not M.rightOptionDown then
      M.rightOptionDown=true
      if not flags.cmd and not flags.ctrl and not flags.shift then
        M.rightOptionRecording=true; actions.dictation('start')
      end
    elseif not flags.alt and M.rightOptionDown then
      M.rightOptionDown=false
      if M.rightOptionRecording then M.rightOptionRecording=false; actions.dictation('stop') end
    end
  end
  return false
end)
for chord,entry in pairs(bindings.entries) do
  if entry.action~='native' and entry.status~='unavailable' and entry.action~='rightOptionTalk'
    and not chord:find('MOUSE') then
    local mods,key={},nil
    for part in chord:gmatch('[^+]+') do
      if modifierNames[part] then mods[#mods+1]=modifierNames[part] else key=keyNames[part] or part:lower() end
    end
    if not key:find('xf86') and hs.keycodes.map[key] then
      local release=entry.action=='pushToTalk' and function() actions.dictation('stop') end or nil
      local repeatAction=entry.action=='resize' and function() dispatch(entry) end or nil
      -- Omarchy uses evdev code:20/21, physical keys, not layout characters.
      -- macOS ANSI minus/equals are 27/24 even with Dvorak active.
      local physical=entry.action=='resize' and ({['-']=27,['=']=24})[key] or nil
      local h=hs.hotkey.new(mods,physical or key,function() dispatch(entry) end,release,repeatAction)
      if h then
        local enabled=h:enable()
        if entry.action=='passthrough' then M.escape=h else M.hotkeys[#M.hotkeys+1]=h end
        if not enabled then
          local flags={}; for _,m in ipairs(mods) do flags[m]=true end
          M.fallbacks[eventChord(flags,tostring(physical or hs.keycodes.map[key]))]=entry
        end
      else M.failures[#M.failures+1]=chord end
    elseif not key:find('xf86') then M.failures[#M.failures+1]=chord end
  end
end
M.events:start()
M.actions=actions
M.dispatch=dispatch
function M.status()
  local pending={}
  for chord,b in pairs(bindings.entries) do if b.status=='hardware-unverified' then pending[#pending+1]=chord end end
  table.sort(pending)
  return {accessibility=hs.accessibilityState(),enabled=M.enabled,registered=#M.hotkeys,
    failures=M.failures,eventTap=M.events:isEnabled(),keepAwake=hs.caffeinate.get('systemIdle'),
    secureInput=hs.eventtap.isSecureInputEnabled(),hardwarePending=pending,
    fallbacks=hs.fnutils.map(M.fallbacks,function(b) return b.chord end)}
end
hs.shutdownCallback=function()
  if M.rightOptionRecording then hs.execute(vox..' record cancel') end
  hs.caffeinate.set('systemIdle',false)
end
print('Omarchy bridge: '..#M.hotkeys..' shortcuts, '..#M.failures..' registration failures')
return M
