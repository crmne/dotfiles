function __good_git_cleanup_omafish_wrappers
    set -q GOOD_GIT_ABBR_KEEP_OMAFISH_WRAPPERS; and return

    for old_fn in g gcm gcam gcad
        functions --query $old_fn; and functions --erase $old_fn
    end
end
