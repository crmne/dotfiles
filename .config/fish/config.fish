# Set greeting
set fish_greeting

# Add a few directories to the PATH
if [ -d ~/.local/bin ]
    set -x PATH $PATH ~/.local/bin
end
## Homebrew M1
if [ -d /opt/homebrew/bin ]
    set -gx PATH /opt/homebrew/sbin /opt/homebrew/bin /opt/homebrew/opt $PATH
end

# Editor
if type -q code
    set -x EDITOR "code -w"
else if type -q code-exploration
    alias code code-exploration
    set -x EDITOR "code-exploration -w"
else if type -q vim
    set -x EDITOR "vim"
end
set -x VISUAL $EDITOR

# Set language
set -x LC_ALL en_US.UTF-8
set -x LC_CTYPE en_US.UTF-8

