function grok --wraps grok --description 'grok in agents.slice (see __agent_slice)'
    __agent_slice grok $argv
end
