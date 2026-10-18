function herdr --description 'herdr, with its server and every session it starts in agents.slice'
    # Coding agents run under herdr, so starting herdr (its TUI and the
    # server it spawns) inside agents.slice puts them all at a low CPU, IO and
    # memory priority, and Chromium stays responsive while they work. Plain
    # subcommands (pane split, ...) only talk to the running server.
    if begin; test (count $argv) -eq 0; or contains -- $argv[1] server attach; end
        and not string match -q '*agents.slice*' (cat /proc/self/cgroup)
        systemd-run --user --scope --quiet --collect --slice=agents.slice \
            --description="herdr $argv" -- (command -s herdr) $argv
    else
        command herdr $argv
    end
end
