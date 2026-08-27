#!/bin/bash

set -euo pipefail

if ! command -v omarchy >/dev/null 2>&1; then
  echo "Skipping Omarchy plugins: Omarchy is not installed on this machine."
  exit 0
fi

plugins_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"
mkdir -p "$plugins_dir"

install_or_update_plugin() {
  local id="$1"
  local url="$2"
  local target="$plugins_dir/$id"
  local origin

  if [[ -L "$target" ]]; then
    echo "Refusing to replace symlinked plugin $id at $target." >&2
    return 1
  fi

  if [[ -d "$target/.git" ]]; then
    origin=$(git -C "$target" remote get-url origin)
    case "$origin" in
      "$url"|"${url/https:\/\/github.com\//git@github.com:}") ;;
      *)
        echo "Refusing to update $id: unexpected origin $origin" >&2
        return 1
        ;;
    esac

    omarchy plugin update "$id" --yes
    return
  fi

  if [[ -e "$target" ]]; then
    echo "Refusing to replace unmanaged plugin directory $target." >&2
    return 1
  fi

  # shell.json already controls whether and where each widget is enabled.
  omarchy plugin add "$url" --yes
}

install_or_update_plugin \
  "crmne.mpris" \
  "https://github.com/crmne/omarchy-mpris.git"

install_or_update_plugin \
  "crmne.active-window" \
  "https://github.com/crmne/omarchy-active-window.git"

install_or_update_plugin \
  "crmne.hyprmoncfg" \
  "https://github.com/crmne/omarchy-hyprmoncfg.git"

install_or_update_plugin \
  "crmne.lyrics" \
  "https://github.com/crmne/omarchy-lyrics.git"

install_or_update_plugin \
  "crmne.ultimate-guitar" \
  "https://github.com/crmne/omarchy-ultimate-guitar.git"

install_or_update_plugin \
  "stappmus.activity-monitor" \
  "https://github.com/stappmus/omarchy-activity-monitor.git"
