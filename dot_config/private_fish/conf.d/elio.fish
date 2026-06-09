# >>> elio shell integration >>>
function elio
    switch "$argv[1]"
        case shell '-*'
            command elio $argv
            return $status
    end

    set -l tmp (mktemp -t "elio-cwd.XXXXXX")
    or return

    command elio --cwd-file "$tmp" $argv
    set -l status_code $status

    if test -s "$tmp"
        set -l cwd (string collect < "$tmp")
        rm -f "$tmp"
        if test -n "$cwd"; and test "$cwd" != "$PWD"; and test -d "$cwd"
            cd "$cwd"; or return $status
        end
    else
        rm -f "$tmp"
    end

    return $status_code
end
# <<< elio shell integration <<<
