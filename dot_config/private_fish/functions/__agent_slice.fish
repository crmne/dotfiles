function __agent_slice --description 'Run a coding agent in a scope of its own in agents.slice'
    # Usage: __agent_slice [-p PROPERTY=VALUE]... <command> [args...]
    # Agents (and the tests, builds and browsers they start) go into
    # agents.slice, a low CPU, IO and memory priority, so the desktop stays
    # responsive while they work. Each run gets a scope of its own, even when
    # started from inside another agent or a herdr already in the slice, so
    # systemd-oomd kills only the session that grew. Anywhere a terminal
    # starts (herdr from Ghostty included) is app.slice, whose oomd rule
    # kills at 50% pressure. Elsewhere (macOS, no systemd) it just runs.
    set -l properties
    while test (count $argv) -ge 2; and test "$argv[1]" = -p
        set -a properties -p $argv[2]
        set -e argv[1..2]
    end
    set -l cmd (command -s $argv[1])
    or begin; echo "$argv[1]: command not found" >&2; return 127; end
    if command -q systemd-run; and test -d /run/systemd/system
        systemd-run --user --scope --quiet --collect --slice=agents.slice $properties \
            --description="$argv" -- $cmd $argv[2..-1]
    else
        $cmd $argv[2..-1]
    end
end
