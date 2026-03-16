#!/usr/bin/env bash

set -u

status="$(playerctl -p playerctld status 2>/dev/null || true)"

if [[ "$status" != "Playing" && "$status" != "Paused" ]]; then
  echo '{"text":"","tooltip":"","class":"empty"}'
  exit 0
fi

artist="$(playerctl -p playerctld metadata --format '{{artist}}' 2>/dev/null || true)"
title="$(playerctl -p playerctld metadata --format '{{title}}' 2>/dev/null || true)"

# Normalize internal whitespace so empty/space-only metadata doesn't reserve width.
artist="$(echo "$artist" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
title="$(echo "$title" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"

if [[ -n "$artist" && -n "$title" ]]; then
  text="$artist - $title"
elif [[ -n "$title" ]]; then
  text="$title"
elif [[ -n "$artist" ]]; then
  text="$artist"
else
  echo '{"text":"","tooltip":"","class":"empty"}'
  exit 0
fi

max=32
if (( ${#text} > max )); then
  text="${text:0:max-1}…"
fi

# Escape JSON-sensitive chars.
escaped_text="${text//\\/\\\\}"
escaped_text="${escaped_text//\"/\\\"}"

echo "{\"text\":\"$escaped_text\",\"tooltip\":\"$escaped_text\",\"class\":\"${status,,}\"}"
