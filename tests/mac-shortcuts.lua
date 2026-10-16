-- Run from the chezmoi source root: lua tests/mac-shortcuts.lua
package.path='./dot_config/hammerspoon/?.lua;'..package.path
local bindings=require('bindings')
assert(bindings.normalize('SUPER + SHIFT + ALT + G')=='SUPER+ALT+SHIFT+G')
assert(bindings.normalize('ALT+SUPER+SHIFT+G')=='SUPER+ALT+SHIFT+G')
local count,counts=0,{}
for line in io.lines('tests/fixtures/omarchy-shortcuts.tsv') do
  if line:sub(1,1)~='#' and line~='' then
    local chord=line:match('^([^\t]+)')
    local b=assert(bindings.entries[chord],'Missing disposition: '..chord)
    assert(({mapped=true,equivalent=true,native=true,unavailable=true,['hardware-unverified']=true})[b.status])
    if b.status~='mapped' and b.status~='native' then assert(b.note~='',chord..' needs an explanation') end
    counts[b.status]=(counts[b.status] or 0)+1; count=count+1
  end
end
assert(count==246,'Update snapshot count intentionally when upstream bindings change')
for _,key in ipairs({'A','C','V','X','SPACE','T','W','L'}) do assert(bindings.entries['SUPER+'..key].action=='native') end
assert(bindings.entries['SUPER+ALT+L'].args[1]=='set-workspace-layout')
assert(bindings.entries['SUPER+ALT+L'].args[2]=='dwindle','Layout shortcut must never enter scrolling mode')
for _,entry in pairs(bindings.entries) do
  if entry.action=='wm' then assert(entry.args[1]~='toggle-workspace-layout') end
end
assert(bindings.entries['SHIFT+XF86AUDIOMICMUTE'].args=='toggle')
for _,chord in ipairs({'SUPER+F','SUPER+S','SUPER+Q','SUPER+P','SUPER+G',
  'SUPER+COMMA','SUPER+SHIFT+T','SUPER+SHIFT+W','SUPER+SHIFT+N'}) do
  assert(bindings.entries[chord].action=='native',chord..' belongs to the focused app')
end
assert(bindings.entries['SUPER+CTRL+SPACE'].action=='settings')
assert(bindings.entries['SUPER+CTRL+Q'].args[1]=='Calculator')
assert(bindings.entries['SUPER+CTRL+E'].action=='emoji')
assert(bindings.entries['SUPER+CTRL+L'].action=='lock')
assert(bindings.entries['PRINT'].action=='screenshot')
assert(bindings.entries['ALT+PRINT'].action=='capture')
assert(not bindings.entries['SUPER+CTRL+X'],'Personal unbind must remain unbound')
for i=1,10 do
  assert(bindings.entries['SUPER+'..i%10].args[2]==tostring(i))
  assert(bindings.entries['SUPER+SHIFT+'..i%10].action=='moveFollow')
  assert(bindings.entries['SUPER+ALT+SHIFT+'..i%10].action=='wm')
end

-- Exercise the real runtime against inert OS adapters. No windows or apps open.
local started,hotkeys,alerts={},{},{}
-- Dvorak character positions must not relocate physical resize bindings.
local codes={tab=48,escape=53,f20=90,f13=105,['-']=39,['=']=30}
setmetatable(codes,{__index=function(t,k)
  if k:find('xf86') then return nil end
  local v=200; for _ in pairs(t) do v=v+1 end; rawset(t,k,v); return v
end})
local eventHandler
hs={
  keycodes={map=codes}, alert={show=function(message) alerts[#alerts+1]=message end},
  task={new=function(path,callback,args)
    local t={path=path,args=args,callback=callback}
    function t:start() started[#started+1]=self; return true end
    return t
  end},
  json={decode=function(value) return type(value)=='table' and value or nil end},
  window={focusedWindow=function() return nil end},
  hotkey={new=function(mods,key,callback,release,repeatAction)
    local h={mods=mods,key=key,callback=callback,release=release,repeatAction=repeatAction}
    function h:enable() self.enabled=true; if key=='tab' and #mods==1 and mods[1]=='cmd' then return nil end; return self end
    function h:disable() self.enabled=false; return self end
    hotkeys[#hotkeys+1]=h; return h
  end},
  eventtap={event={types={keyDown=1,keyUp=2,scrollWheel=3,systemDefined=4,flagsChanged=5},
      properties={scrollWheelEventDeltaAxis1=1}},
    new=function(_,callback)
      eventHandler=callback
      return {start=function(self) self.enabled=true end,stop=function(self) self.enabled=false end,
        isEnabled=function(self) return self.enabled end}
    end},
}
local runtime=require('omarchy')
assert(#runtime.failures==0)
assert(#started==0,'Loading config must not run commands')
for _,b in pairs(bindings.entries) do assert(type(runtime.actions[b.action])=='function',b.action) end
local function finish(success,payload,code)
  local t=started[#started]
  t.callback(success and 0 or 1,{ok=success,code=code,result={payload=payload}},'')
end
-- Real hotkeys call dispatch, not actions directly. The descriptor must never
-- leak into wm's callback slot after a successful command.
runtime.dispatch(bindings.entries['SUPER+LEFT'])
finish(true)
assert(#alerts==0,'A successful dispatched WM action must not report callback failure')
assert(table.concat(started[#started].args,' ')=='command focus left --json')
runtime.dispatch(bindings.entries['SUPER+RIGHT'])
started[#started].callback(1,'',{ok=false,code='no_change'})
assert(#alerts==0,'No-op errors emitted on stderr are harmless')
started={}
runtime.dispatch(bindings.entries['SUPER+SHIFT+0'])
assert(table.concat(started[1].args,' ')=='query windows --focused --fields id --json')
finish(true,{windows={{id='test-window'}}})
assert(table.concat(started[2].args,' ')=='window move-to-workspace test-window 10 --json')
finish(true)
assert(table.concat(started[3].args,' ')=='window navigate test-window --json','Must follow the same moved window')
finish(true)
runtime.actions.moveFollow('9'); finish(true,{windows={{id='test-window'}}})
local n=#started; finish(false)
assert(#started==n,'Failed move must not change workspace')
runtime.actions.moveFollow('9'); finish(true,{windows={{id='test-window'}}})
finish(false,nil,'no_change')
assert(started[#started].args[2]=='navigate','Already-moved window can still be followed')
finish(true)
runtime.actions.resize({'horizontal','grow',1,100})
finish(true,{windows={{mode='tiled'}}})
finish(true,{workspaces={{layout='niri'}}})
assert(table.concat(started[#started].args,' ')=='command set-container-primary-span +100 --json')
finish(true)
runtime.actions.resize({'vertical','shrink',1,25})
finish(true,{windows={{mode='tiled'}}})
finish(true,{workspaces={{layout='dwindle'}}})
assert(table.concat(started[#started].args,' ')=='command resize vertical shrink --json')
finish(true)
-- All twelve resize chords have distinct step sizes and a repeat handler.
assert(bindings.entries['SUPER+MINUS'].args[3]==2)
assert(bindings.entries['SUPER+ALT+MINUS'].args[3]==1)
assert(bindings.entries['SUPER+CTRL+MINUS'].args[3]==6)
for _,h in ipairs(hotkeys) do
  if h.key==27 or h.key==24 then assert(h.repeatAction,'Resize must repeat when held') end
  assert(h.key~='-' and h.key~='=','Resize must use physical keycodes, not Dvorak characters')
end
local resizeCount=0
for _,h in ipairs(hotkeys) do if h.key==27 or h.key==24 then resizeCount=resizeCount+1 end end
assert(resizeCount==12,'All twelve resize shortcuts need physical keycodes')
local frame={x=0,y=0,w=600,h=400}
local fakeWindow={id=function() return 7 end,frame=function() return frame end,
  screen=function() return {frame=function() return {x=0,y=0,w=1200,h=900} end} end,
  setFrameInScreenBounds=function(_,f) frame=f end}
hs.window.focusedWindow=function() return fakeWindow end
for _,size in ipairs({25,100,300}) do
  local before=frame.w
  runtime.actions.resize({'horizontal','grow',1,size})
  finish(true,{windows={{mode='floating'}}})
  assert(frame.w==before+size,'Floating growth must use the requested distance')
end
runtime.actions.resize({'vertical','shrink',1,300})
finish(true,{windows={{mode='floating'}}})
assert(frame.h==100,'Floating height must not become zero or negative')
runtime.actions.resize({'horizontal','shrink',1,25})
hs.window.focusedWindow=function() return nil end
local unchanged=frame.w
finish(true,{windows={{mode='floating'}}})
assert(frame.w==unchanged,'Do not resize after focus changes during the query')
runtime.actions.cycleWorkspace(1)
finish(true,{workspaces={{rawName='1',isCurrent=true,counts={total=1}},
  {rawName='2',counts={total=0}},{rawName='10',counts={total=1}}}})
assert(started[#started].args[3]=='10','Cycle skips empty workspaces')
finish(true)
runtime.actions.terminal('herdr')
assert(started[#started].args[2]:find('count windows'),'Probe read-only before launch')
finish(true)
assert(started[#started].path=='/usr/bin/osascript','Use one Ghostty instance, not app state restoration')
assert(started[#started].args[3]=="/opt/homebrew/bin/fish -lc 'herdr'")
finish(true)
runtime.actions.terminal('herdr')
finish(false)
assert(started[#started].args[2]:find('tell application "Terminal"'),'Read-only probe failure uses stock Terminal')
assert(started[#started].args[3]=="/opt/homebrew/bin/fish -lc 'herdr'")
local launches=#started
finish(false)
assert(#started==launches,'Never retry a failed/timed-out mutating command')
local event={getType=function() return 1 end,getFlags=function() return {cmd=true} end,
  getKeyCode=function() return 48 end}
assert(eventHandler(event)==true,'Reserved Command+Tab must be intercepted')
assert(started[#started].args[1]=='query')
finish(true,{workspaces={}})
runtime.actions.passthrough()
assert(not runtime.enabled and not runtime.events:isEnabled())
assert(runtime.escape.enabled,'Emergency toggle remains active')
assert(eventHandler(event)==false,'Passthrough must not consume keys')
runtime.actions.passthrough()
assert(runtime.enabled and runtime.events:isEnabled())
print('PASS: '..count..' source bindings covered; runtime queue, follow, native keys, fallback, launch and passthrough regressions')
for status,n in pairs(counts) do print(status..': '..n) end

-- The OSD observes status only, and handles stream chunks crossing line edges.
local stream,termination,osdProcess
hs.task.new=function(path,onExit,onStream,args)
  assert(args[1]=='status' and args[2]=='--follow','OSD must never issue a recording command')
  stream=onStream; termination=onExit
  osdProcess={start=function() end,terminate=function() end}
  return osdProcess
end
hs.json.decode=function(value) return {class=value} end
hs.mouse={getCurrentScreen=function() return {frame=function() return {x=0,y=0,w=1000,h=800} end} end}
hs.canvas={new=function()
  local c={}
  for _,method in ipairs({'level','behavior','canvasMouseEvents','frame'}) do c[method]=function(self) return self end end
  function c:appendElements(...) for i,v in ipairs({...}) do self[i]=v end end
  function c:show() self.visible=true end
  function c:hide() self.visible=false end
  function c:delete() self.visible=false end
  return c
end}
hs.timer={doAfter=function() error('Unexpected retry') end}
local osd=require('voxtype-osd').start()
stream(osdProcess,'rec',''); assert(osd.canvas==nil)
stream(osdProcess,'ording\n',''); assert(osd.canvas.visible and osd.state=='recording')
stream(osdProcess,'transcribing\n',''); assert(osd.canvas.visible and osd.state=='transcribing')
stream(osdProcess,'idle\n',''); assert(not osd.canvas.visible)
osd.stop(); termination(); assert(osd.canvas==nil)
print('PASS: Voxtype OSD recording/transcribing/idle, chunked stream, shutdown without audio access')
