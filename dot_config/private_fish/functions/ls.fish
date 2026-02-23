function ls --wraps='eza -lhg --group-directories-first --icons=auto' --description 'alias ls=eza -lhg --group-directories-first --icons=auto'
    eza -lhg --group-directories-first --icons=auto $argv
end
