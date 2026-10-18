function __agent_slice --description 'Run a coding agent in agents.slice, where it gives way to the desktop'
    # Usage: __agent_slice <command> [args...]
    # Agents (and the tests, builds and browsers they start) go into
    # agents.slice, a low CPU, IO and memory priority, so the desktop stays
    # responsive while they work. Elsewhere (macOS, no systemd), or when
    # already inside the slice (started from herdr), the command just runs.
    set -l cmd (command -s $argv[1])
    or begin; echo "$argv[1]: command not found" >&2; return 127; end
    if command -q systemd-run; and test -d /run/systemd/system
        and not string match -q '*agents.slice*' (cat /proc/self/cgroup 2>/dev/null)
        systemd-run --user --scope --quiet --collect --slice=agents.slice \
            --description="$argv" -- $cmd $argv[2..-1]
    else
        $cmd $argv[2..-1]
    end
end
