# Set greeting
set fish_greeting

# Add a few directories to the PATH
set -x PATH $PATH ~/.local/bin

# Editor: Visual Studio Code
set -x EDITOR "code -w"
set -x VISUAL $EDITOR

# Set language
set -x LC_ALL en_US.UTF-8
set -x LC_CTYPE en_US.UTF-8