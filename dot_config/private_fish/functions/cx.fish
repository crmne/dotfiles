function cx --wraps=claude --description 'clear terminal and run claude skipping permission prompts'
    printf "\033[2J\033[3J\033[H"
    # Through the claude function, never `command claude`, so the session
    # gets its own scope in agents.slice.
    claude $argv
end
