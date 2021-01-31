# Defined in /var/folders/2k/9693sr6n44705kn2zq4zrthw0000gn/T//fish.ssNReu/fish_title.fish @ line 2
function fish_title
    # emacs is basically the only term that can't handle it.
    if not set -q INSIDE_EMACS
        echo (status current-command) (prompt_pwd)
    end
end
