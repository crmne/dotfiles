function zd --description 'zoxide-backed cd'
    # Preserve native cd semantics for no args, options/history, and explicit directories.
    if test (count $argv) -eq 0
        builtin cd ~
        return $status
    end

    if test (count $argv) -gt 1
        builtin cd $argv
        return $status
    end

    set -l target $argv[1]

    if string match -qr '^-' -- $target
        builtin cd $target
        return $status
    end

    if test -d $target
        builtin cd -- $target
        return $status
    end

    if not functions -q z
        echo 'Error: zoxide is not initialized in this shell'
        return 1
    end

    z -- $target
end
