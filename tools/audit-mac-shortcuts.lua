-- Collect actual global bindings, including loops and personal unbinds.
-- Usage: lua tools/audit-mac-shortcuts.lua /path/to/omarchy ~/.config/hypr/bindings.lua
local root, overrides = assert(arg[1]), assert(arg[2])
local bindings = {}
local function normalize(key)
  key = key:upper():gsub("%s*%+%s*", "+")
  key = key:gsub("CODE:(%d+)", function(n)
    n = tonumber(n)
    if n >= 10 and n <= 18 then return tostring(n - 9) end
    return ({[19]="0",[20]="MINUS",[21]="EQUAL",[34]="LEFTBRACKET",[35]="RIGHTBRACKET"})[n] or "CODE:" .. n
  end)
  local mods, base = {}, nil
  for part in key:gmatch('[^+]+') do
    if part=='SUPER' or part=='CTRL' or part=='ALT' or part=='SHIFT' then mods[part]=true else base=part end
  end
  local result={}
  for _,m in ipairs({'SUPER','CTRL','ALT','SHIFT'}) do if mods[m] then result[#result+1]=m end end
  result[#result+1]=assert(base)
  return table.concat(result,'+')
end
local proxy
proxy = setmetatable({}, {__index=function() return proxy end, __call=function() return proxy end})
hl = {dsp=proxy, unbind=function(k) bindings[normalize(k)] = nil end, on=function() end}
local function record(k,d)
  k=normalize(k)
  bindings[k]=bindings[k] and (bindings[k]..'; '..d) or d
end
o = setmetatable({
  bind=function(k,d) record(k,d or "Hardware event") end,
  bind_toggle=record,
  bind_hold=function(k,d,_,stop) record(k,d .. "; " .. stop) end,
  preinstalled_bindings_enabled=function() return true end,
  cmd_present=function() return true end, cmd_missing=function() return false end,
}, {__index=function() return function() return proxy end end})
package.preload['default.hypr.keyboard'] = function() return {jis=function() return false end} end
local popen = io.popen
io.popen = function(cmd)
  if cmd:find("omarchy%-default%-dictation") then
    return {read=function() return "voxtype" end, close=function() end}
  end
  return popen(cmd)
end
for _,file in ipairs({'applications','clipboard','dictation','input-method','jis','media','tiling','utilities'}) do
  dofile(root .. '/default/hypr/bindings/' .. file .. '.lua')
end
dofile(overrides)
local keys = {}
for k in pairs(bindings) do table.insert(keys, k) end
table.sort(keys)
if arg[3] then
  local mac=dofile(arg[3]..'/bindings.lua')
  local missing=0
  for _,k in ipairs(keys) do
    local b=mac.entries[k]
    if not b then missing=missing+1 end
    print(table.concat({k,bindings[k],b and b.status or 'MISSING',b and b.note or ''},'\t'))
  end
  assert(missing==0,tostring(missing)..' Omarchy shortcuts have no macOS disposition')
else
  for _,k in ipairs(keys) do print(k .. '\t' .. bindings[k]) end
end
