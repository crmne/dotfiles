function img2jpg-small
    set img "$argv[1]"
    set extra $argv[2..-1]
    set base (string replace -r '\.[^.]*$' '' -- "$img")
    magick "$img" $extra -resize "1080x>" -quality 95 -strip "$base-small.jpg"
end
