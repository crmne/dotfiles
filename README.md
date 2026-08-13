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

On Omarchy machines, applying the dotfiles also installs or updates the
published [`crmne.mpris`](https://github.com/crmne/omarchy-mpris) and
[`crmne.active-window`](https://github.com/crmne/omarchy-active-window)
plugins from GitHub. Omarchy manages their checkouts under
`~/.config/omarchy/plugins/`; the plugin source repositories are not copied or
symlinked from a machine-local development directory.
