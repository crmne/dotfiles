# Carmine's Dotfiles

My dotfiles as managed by [chezmoi](https://www.chezmoi.io/).

Configs may assume you're running [Omarchy](https://omarchy.org/).

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

On Omarchy machines, `~/.config/omarchy/shell.json` controls plugin enablement,
widget positions, and widget settings. After changing the bar or plugins, run:

```bash
chezmoi re-add
# Or capture just the shell configuration:
chezmoi re-add ~/.config/omarchy/shell.json
```

The `add`/`re-add` post hook regenerates
`.chezmoidata/omarchy-plugins.json` from the saved shell configuration. It records
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
