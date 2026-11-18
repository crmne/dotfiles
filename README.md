# Carmine's Dotfiles

My dotfiles as managed by [chezmoi](https://www.chezmoi.io/).

Configs may assume you're running [Omarchy](https://omarchy.org/).

## macOS desktop

The Mac desktop configuration follows [Omacase](https://github.com/crmne/omacase).
Installation instructions, shortcut documentation and limitations live there.
This repository keeps the personal configuration synced through chezmoi.
OmniWM remains on the stable release; no development build is installed.


Install them with:

```bash
chezmoi init crmne
```


Check what's different from yours with

```bash
chezmoi diff
```


Apply them with

```bash
chezmoi apply
```

On Linux, `~/.config/user-dirs.dirs` routes desktop files, downloads, documents,
music, pictures, and videos to their standard folders under home. Omarchy uses
Pictures for screenshots and Videos for screen recordings. Documents, Pictures,
and Videos continue to use existing Nextcloud symlinks.

`run_before_create-user-dirs.sh.tmpl` creates missing folders on each apply,
before writing the mappings. `~/.config/user-dirs.conf` disables automatic
directory updates so login cannot reset a missing folder or temporarily
unavailable sync target to home. Change the saved mappings in
`dot_config/private_user-dirs.dirs` and run `chezmoi apply` to use another location.
Existing files are not moved. These settings are skipped on other operating
systems.

On Linux, `~/.config/fontconfig/conf.d/90-omarchy-shell-font.conf` sets the
Omarchy shell (bar, panels, notifications and launcher) in IBM Plex Sans, from
`ttf-ibm-plex`, while the terminals keep Omarchy's monospace font. The rule
matches only the shell's `quickshell` process, so other programs are not
affected, and it still applies after `omarchy font set`. JetBrainsMono Nerd
Font stays next in line for the shell's icons, and the shell falls back to it
entirely if IBM Plex Sans is missing. To try another face, change the family
in that file and run `omarchy restart shell`. Choose one with equal-width
digits, or the clock and stats change width as they update: IBM Plex Sans has
them, Inter and Geist don't. `omarchy font set` writes its own
`~/.config/fontconfig/fonts.conf`, which this rule outlasts.

Fish plugins come from Fisher. `~/.config/fish/fish_plugins` lists them
(Fisher itself, fzf.fish, fish-direnv and omafish), and
`run_onchange_after_fisher-update.sh.tmpl` runs `fisher update` whenever the list
changes, installing Fisher first on a new machine. The files those plugins
install are not in this repository, so `fisher update` is never undone by an
apply. Only personal fish files live here: `config.fish`, `conf.d/paths.fish`,
`conf.d/elio.fish` and the agent wrappers.

On Omarchy machines, `~/.config/omarchy/shell.json` controls plugin enablement,
widget positions, and widget settings. Both machines share one layout, but a
few widget settings differ by machine: chalk's omastats shows its GPU and its
two NVMe drives, and Google Calendar is signed in only where `googleEnabled` is
on. So the source is a template, `dot_config/omarchy/private_shell.json.tmpl`,
and `chezmoi re-add` skips templates. After changing the bar or plugins, run:

```bash
python3 ~/.local/share/chezmoi/tools/re-add-shell-json.py
```

It saves the live file into the template, puts the per-machine expressions
back (they are listed in the tool), and regenerates
`.chezmoidata/omarchy-plugins.json`. The `add`/`re-add` post hook regenerates the
list too, from the saved shell configuration. It records
only enabled third-party plugins, including services and custom bars. Git origins
provide their URLs. `tools/omarchy-plugin-sources.json` supplies URLs for local
development copies without Git metadata (currently OmaStats and OmaTasks).
An unknown plugin without a URL fails with instructions instead of silently
omitting it. Already recorded URLs can be reused on a machine missing a plugin.

Commit and push both the shell configuration and generated list as usual. On
another Omarchy machine, `chezmoi update` applies the configuration and installs
missing plugins using `omarchy plugin add`. The saved configuration enables
them in the same positions. Every apply checks for missing plugins, even when
the list has not changed. Existing installations, including development copies,
are kept. Plugin versions can be updated separately with `omarchy plugin update`.
Disabled plugins drop out of the generated list; installed copies are not deleted.

Fresh `chezmoi init` installs the capture hooks automatically. For an existing
checkout adopting this setup, use `chezmoi update --init` once (or `chezmoi init`
after pulling) to generate the local chezmoi config. The hooks skip machines
without Omarchy and respect `--dry-run`. They use Python 3; installation uses
Omarchy's Git and jq dependencies. Plugin source trees and account credentials
are not stored here; sign in to plugins on each machine as needed.

The automation is in `tools/capture-omarchy-plugins.py` and
`run_after_install-omarchy-plugins.sh.tmpl`. This is a chezmoi command hook and
apply script; it does not depend on Git checkout hooks.
