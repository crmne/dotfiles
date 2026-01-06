if status is-interactive
    mise activate fish | source
    zoxide init fish | source
    starship init fish | source
    direnv hook fish | source
    source ~/.config/op/plugins.sh
end
