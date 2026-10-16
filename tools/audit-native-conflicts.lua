-- Run from the project root. Every binding receives a disposition.
local b=dofile('dot_config/hammerspoon/bindings.lua')
local native={
 ['SUPER+L']='Address bar / app action',
 ['SUPER+F']='Find', ['SUPER+S']='Save', ['SUPER+Q']='Quit app',
 ['SUPER+P']='Print', ['SUPER+G']='Find next', ['SUPER+SHIFT+G']='Find previous / Go to Folder',
 ['SUPER+COMMA']='App settings', ['SUPER+I']='Get Info / formatting',
 ['SUPER+J']='Downloads / Finder view options', ['SUPER+O']='Open file',
 ['SUPER+K']='Address search / link / Connect to Server',
 ['SUPER+T']='New tab', ['SUPER+W']='Close tab/window',
 ['SUPER+A']='Select all', ['SUPER+C']='Copy', ['SUPER+V']='Paste', ['SUPER+X']='Cut',
 ['SUPER+M']='Minimize', ['SUPER+SPACE']='Spotlight (Raycast intentional replacement)',
 ['SUPER+TAB']='Switch apps', ['SUPER+SHIFT+TAB']='Switch apps backwards',
 ['SUPER+GRAVE']='Next window of current app', ['SUPER+SHIFT+GRAVE']='Previous window of current app',
 ['SUPER+SHIFT+T']='Reopen closed tab / Finder tab bar',
 ['SUPER+SHIFT+W']='Close browser window', ['SUPER+SHIFT+N']='Private window / new folder',
 ['SUPER+SHIFT+B']='Bookmarks bar', ['SUPER+SHIFT+O']='Bookmark manager / Documents',
 ['SUPER+SHIFT+J']='Downloads', ['SUPER+SHIFT+C']='Inspect element / Computer',
 ['SUPER+SHIFT+F']='Browser presentation / Finder Recents',
 ['SUPER+SHIFT+D']='Bookmark tabs / Desktop folder',
 ['SUPER+SHIFT+I']='Developer tools / iCloud Drive',
 ['SUPER+SHIFT+P']='Page setup / Finder preview pane',
 ['SUPER+SHIFT+SLASH']='Help menu',
 ['SUPER+CTRL+SPACE']='Emoji / Character Viewer',
 ['SUPER+CTRL+Q']='Lock screen', ['SUPER+CTRL+F']='Native fullscreen',
 ['SUPER+ALT+SPACE']='Finder search', ['SUPER+ALT+L']='Downloads folder',
 ['SUPER+ALT+S']='Finder sidebar',
 ['SUPER+SLASH']='Finder status bar',
 ['SUPER+BACKSPACE']='Move to Trash / delete to start of line',
 ['SUPER+LEFT']='Start of line / browser back', ['SUPER+RIGHT']='End of line / browser forward',
 ['SUPER+UP']='Start of document / parent folder', ['SUPER+DOWN']='End of document / open selection',
 ['SUPER+SHIFT+LEFT']='Select to start of line', ['SUPER+SHIFT+RIGHT']='Select to end of line',
 ['SUPER+SHIFT+UP']='Select to start of document', ['SUPER+SHIFT+DOWN']='Select to end of document',
 ['SUPER+ALT+LEFT']='Previous browser tab', ['SUPER+ALT+RIGHT']='Next browser tab',
 ['SUPER+CTRL+UP']='Open parent in new window',
 ['SUPER+CTRL+N']='New folder with selection',
 ['SUPER+CTRL+T']='Add Finder item to sidebar',
 ['SUPER+CTRL+A']='Make Finder alias',
 ['SUPER+ALT+COMMA']='Browser settings variant / app-specific',
}
for i=1,9 do native['SUPER+'..i]='Select browser tab / Finder view (1-4)' end
native['SUPER+0']='Reset browser zoom'
for i=3,5 do native['SUPER+SHIFT+'..i]='macOS screenshot controls' end
local chosen={['SUPER+O']=true,['SUPER+K']=true}
for _,chord in ipairs({'SUPER+LEFT','SUPER+RIGHT','SUPER+UP','SUPER+DOWN',
 'SUPER+SHIFT+LEFT','SUPER+SHIFT+RIGHT','SUPER+SHIFT+UP','SUPER+SHIFT+DOWN'}) do chosen[chord]=true end
for i=0,9 do chosen['SUPER+'..i]=true end
local keys={}; for key in pairs(b.entries) do keys[#keys+1]=key end; table.sort(keys)
print('Shortcut\tBridge action\tKnown native use\tReview')
local collisions=0
for _,key in ipairs(keys) do
 local entry=b.entries[key]
 local use=native[key]
 local state
 if entry.action=='native' or entry.status=='unavailable' then state='Not intercepted by bridge'
 elseif key=='SUPER+M' or key=='SUPER+CTRL+F' then state='Same broad purpose; app semantics may differ'
 elseif use then
   collisions=collisions+1
   state=chosen[key] and 'Deliberate desktop override; confirm tradeoff' or 'Native conflict; decision needed'
 else state='No match in reviewed catalog; not proof of no app conflict' end
 print(table.concat({key,entry.label,use or '',state},'\t'))
end
io.stderr:write(string.format('%d bindings inspected; %d known native conflicts (including deliberate overrides).\n',#keys,collisions))
