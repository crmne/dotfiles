function claude --description 'claude --dangerously-skip-permissions, each session in its own systemd scope'
    # Every session used to share herdr's terminal scope, so when memory ran
    # out systemd-oomd killed herdr and all of them at once (twice on
    # 2026-10-03). A scope per session lets it kill only the one that grew,
    # and caps a single session at 16 GB. Heavy jobs go through heavy-lock,
    # which moves them into scopes of their own. Every session lives in
    # agents.slice, which gives way to the desktop (see agents.slice).
    systemd-run --user --scope --quiet --collect --slice=agents.slice \
        -p MemoryHigh=12G -p MemoryMax=16G \
        --description="claude $argv" -- (command -s claude) --dangerously-skip-permissions $argv
end
