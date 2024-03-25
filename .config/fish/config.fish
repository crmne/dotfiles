# Set greeting
set fish_greeting

# Add a few directories to the PATH
fish_add_path ~/.local/bin

# Homebrew specific
if [ -d /opt/homebrew ]
    set -gx CPATH /opt/homebrew/include $CPATH
    set -gx LIBRARY_PATH /opt/homebrew/lib $LIBRARY_PATH
    fish_add_path /opt/homebrew/sbin /opt/homebrew/bin /opt/homebrew/opt
    fish_add_path /opt/homebrew/opt/yq@3/bin
    fish_add_path /opt/homebrew/opt/mysql-client/bin
end

# PyCharm
if [ -d "/Applications/PyCharm CE.app/Contents/MacOS" ]
    fish_add_path "/Applications/PyCharm CE.app/Contents/MacOS"
end
if [ -d "/Applications/PyCharm.app/Contents/MacOS" ]
    fish_add_path "/Applications/PyCharm.app/Contents/MacOS"
end

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Editor
if type -q nvim
    alias vim=nvim
    set -x EDITOR "nvim"
else if type -q code
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

# The next line updates PATH for the Google Cloud SDK.
if [ -f ~/google-cloud-sdk/path.fish.inc ]; . ~/google-cloud-sdk/path.fish.inc; end

test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish

# rbenv
status --is-interactive; and rbenv init - fish | source
