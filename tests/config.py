"""Configuration regressions. Python 3.11+; does not touch running apps."""
import pathlib
import tomllib

root = pathlib.Path(__file__).resolve().parents[1]
herdr = tomllib.loads((root / "dot_config/herdr/config.toml").read_text())
assert herdr["keys"]["prefix"] == "ctrl+space"
assert herdr["keys"]["new_tab"] == "prefix+c"
assert herdr["keys"]["new_workspace"] == "prefix+shift+c"
assert herdr["ui"]["prompt_new_tab_name"] is False
assert herdr["theme"]["name"] == "terminal"
wm = tomllib.loads((root / "dot_config/omniwm/settings.toml").read_text())
assert wm["general"]["hotkeysEnabled"] is False
assert wm["hiddenBar"]["enabled"] is False
assert wm["workspaceBar"]["enabled"] is True
assert wm["workspaceBar"]["position"] == "overlappingMenuBar"
assert wm["workspaceBar"]["reserveLayoutSpace"] is False
assert len(wm["workspaces"]) == 10
assert next(h for h in wm["hotkeys"] if h["id"] == "openCommandPalette")["binding"] == "Unassigned"
print("PASS: Herdr Omarchy prefix/name prompt and nonconflicting workspace bar")
