-- Read Voxtype's own state stream. This never opens the microphone or records.
local M={}
local labels={recording='●  Voxtype: recording',transcribing='Voxtype: transcribing…',
  processing='Voxtype: transcribing…',loading='Voxtype: loading model…'}
function M.setState(state)
  if state==M.state then return end
  M.state=state
  local label=labels[state]
  if not label then if M.canvas then M.canvas:hide() end; return end
  local screen=hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  local frame=screen:frame()
  local rect={x=frame.x+(frame.w-260)/2,y=frame.y+frame.h-76,w=260,h=44}
  if not M.canvas then
    M.canvas=hs.canvas.new(rect):level('overlay')
      :behavior({'canJoinAllSpaces','stationary','fullScreenAuxiliary','ignoresCycle'})
    M.canvas:canvasMouseEvents(false,false,false,false)
    M.canvas:appendElements(
      {type='rectangle',action='fill',fillColor={white=0.08,alpha=0.94},roundedRectRadii={xRadius=12,yRadius=12}},
      {type='text',text='',textSize=15,textAlignment='center',textColor={white=1,alpha=1},
        frame={x=8,y=12,w=244,h=24}})
  end
  M.canvas:frame(rect)
  M.canvas[2].text=label
  M.canvas:show()
end
function M.start()
  M.stopping=false
  local buffer=''
  M.task=hs.task.new(os.getenv('HOME')..'/.local/bin/voxtype',function()
    M.setState('offline')
    if not M.stopping then M.retry=hs.timer.doAfter(5,M.start) end
  end,function(_,out)
    buffer=buffer..(out or '')
    while buffer:find('\n',1,true) do
      local line,rest=buffer:match('^([^\n]*)\n(.*)$')
      buffer=rest
      local decoded=hs.json.decode(line)
      if decoded then M.setState(decoded.class or decoded.alt) end
    end
    return true
  end,{'status','--follow','--format','json'})
  M.task:start()
  return M
end
function M.stop()
  M.stopping=true
  if M.retry then M.retry:stop() end
  if M.task then M.task:terminate() end
  if M.canvas then M.canvas:delete(); M.canvas=nil end
end
return M
