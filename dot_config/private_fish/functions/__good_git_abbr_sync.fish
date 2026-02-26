function __good_git_abbr_sync --argument name expansion
    abbr --erase $name >/dev/null 2>/dev/null
    abbr --add -- $name $expansion
end
