#!/usr/bin/env bash

set -u

cache_dir="/tmp/waybar-album-art"
mkdir -p "$cache_dir"

decode_file_url() {
  local input="$1"
  local without_scheme="${input#file://}"
  printf '%b' "${without_scheme//%/\\x}"
}

media_line="$(playerctl -p playerctld metadata --format '{{status}}|{{mpris:artUrl}}' 2>/dev/null || true)"

if [[ -z "$media_line" ]]; then
  exit 0
fi

status="${media_line%%|*}"
art_url="${media_line#*|}"

if [[ "$status" == "Stopped" || -z "$art_url" ]]; then
  exit 0
fi

if [[ "$art_url" == file://* ]]; then
  art_path="$(decode_file_url "$art_url")"
  [[ -f "$art_path" ]] && printf '%s\n' "$art_path"
  exit 0
fi

if [[ "$art_url" =~ ^https?:// ]]; then
  if command -v curl >/dev/null 2>&1; then
    hash="$(printf '%s' "$art_url" | sha256sum | awk '{print $1}')"
    base_url="${art_url%%\?*}"
    ext="${base_url##*.}"
    case "${ext,,}" in
      jpg|jpeg|png|webp|gif|bmp) ;;
      *) ext="img" ;;
    esac
    cached_art="$cache_dir/$hash.$ext"

    if [[ ! -s "$cached_art" ]]; then
      tmp_file="$cached_art.tmp"
      if curl -fsL --max-time 5 "$art_url" -o "$tmp_file"; then
        mv "$tmp_file" "$cached_art"
      else
        rm -f "$tmp_file"
      fi
    fi

    [[ -s "$cached_art" ]] && printf '%s\n' "$cached_art"
  fi
fi
