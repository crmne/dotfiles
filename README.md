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

On Omarchy machines, applying the dotfiles also installs or updates these
plugins from GitHub:

- `crmne.active-window`
- `crmne.hyprmoncfg`
- `crmne.lyrics`
- `crmne.mpris`
- `crmne.ultimate-guitar`
- `quickshell.spotify`
- `stappmus.activity-monitor`

Omarchy manages their checkouts under `~/.config/omarchy/plugins/`; the plugin
source repositories are not stored in this repository. `shell.json` controls
which plugins are enabled and where their widgets appear.
