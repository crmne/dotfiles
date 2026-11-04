function __agent_slice --description 'Run a coding agent in a scope of its own in agents-sessions.slice'
    # Usage: __agent_slice [-p PROPERTY=VALUE]... <command> [args...]
    # Sessions go into agents-sessions.slice, under agents.slice, which
    # yields to the desktop. Each run gets a scope of its own, even when
    # started from inside another agent or a herdr already in the slice.
    # The jobs a session starts (tests, builds, servers, browsers) belong in
    # agents-jobs.slice through agent-job, so a job that grows is killed
    # instead of the session. Elsewhere (macOS, no systemd) it just runs.
    set -l properties
    while test (count $argv) -ge 2; and test "$argv[1]" = -p
        set -a properties -p $argv[2]
        set -e argv[1..2]
    end
    set -l cmd (command -s $argv[1])
    or begin; echo "$argv[1]: command not found" >&2; return 127; end
    if command -q systemd-run; and test -d /run/systemd/system
        systemd-run --user --scope --quiet --collect --slice=agents-sessions.slice $properties \
            --description="$argv" -- $cmd $argv[2..-1]
    else
        $cmd $argv[2..-1]
    end
end
