#!/usr/bin/env python3
"""Capture repository URLs for third-party plugins in the saved shell config."""

import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile


def read_json(path):
    return json.loads(path.read_text())


def enabled_plugins(config):
    bar = config.get("bar", {})
    entries = list(config.get("plugins", []))
    for section in ("left", "center", "right"):
        entries.extend(bar.get("layout", {}).get(section, []))
    ids = {entry if isinstance(entry, str) else entry["id"] for entry in entries}
    ids.difference_update(config.get("disabledPlugins", []))
    if bar.get("id"):
        ids.add(bar["id"])
    return sorted(plugin_id for plugin_id in ids if not plugin_id.startswith("omarchy."))


def portable_url(url):
    # Public GitHub HTTPS URLs also work on a machine without SSH credentials.
    url = re.sub(r"^(?:git@github\.com:|ssh://git@github\.com/)",
                 "https://github.com/", url)
    if not (re.fullmatch(r"https://[^\s@?#]+/[^\s?#]+", url)
            or re.fullmatch(r"ssh://[^\s?#]+/[^\s?#]+", url)
            or re.fullmatch(r"[\w.-]+@[\w.-]+:[^\s?#]+", url)):
        raise ValueError(f"Plugin URL must be a portable HTTPS or SSH Git URL: {url!r}")
    return url


def capture(source, destination):
    config_path = source / "dot_config/omarchy/shell.json"
    if not config_path.is_file():
        return
    data_path = source / ".chezmoidata/omarchy-plugins.json"
    previous = read_json(data_path).get("omarchyPlugins", {}) if data_path.exists() else {}
    overrides = read_json(source / "tools/omarchy-plugin-sources.json")
    plugins = {}
    # Read source state so re-adding an unrelated file cannot capture an unsaved layout.
    for plugin_id in enabled_plugins(read_json(config_path)):
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", plugin_id) or ".." in plugin_id:
            raise ValueError(f"Invalid plugin id: {plugin_id!r}")
        directory = destination / ".config/omarchy/plugins" / plugin_id
        url = None
        if (directory / "manifest.json").is_file():
            if read_json(directory / "manifest.json").get("id") != plugin_id:
                raise ValueError(f"Plugin manifest does not match {plugin_id}: {directory}")
            # Require plugin-owned Git metadata; never inherit a parent repo's origin.
            if (directory / ".git").exists():
                result = subprocess.run(
                    ["git", "-C", str(directory), "remote", "get-url", "origin"],
                    capture_output=True, text=True, check=False,
                )
                if result.returncode == 0:
                    url = result.stdout.strip()
        url = url or overrides.get(plugin_id) or previous.get(plugin_id)
        if not url:
            raise ValueError(
                f"No repository URL for enabled plugin {plugin_id}. Install it with "
                "omarchy plugin add, or add its URL to tools/omarchy-plugin-sources.json."
            )
        plugins[plugin_id] = portable_url(url)

    content = json.dumps({"omarchyPlugins": plugins}, indent=2) + "\n"
    if data_path.exists() and data_path.read_text() == content:
        return
    # Resolve every URL before replacing the list, so failures preserve the old list.
    data_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=data_path.parent, delete=False) as temp:
        temp.write(content)
        temp_path = Path(temp.name)
    try:
        temp_path.chmod(0o644)
        temp_path.replace(data_path)
    finally:
        temp_path.unlink(missing_ok=True)
    print(f"Captured {len(plugins)} Omarchy plugin repositories.")


def main():
    # chezmoi executes hooks even during dry runs. Do not mutate source state then.
    args = shlex.split(os.environ.get("CHEZMOI_ARGS", ""))
    if any(arg in ("--dry-run", "--dry-run=true")
           or re.fullmatch(r"-[A-Za-z]*n[A-Za-z]*", arg) for arg in args):
        return
    source = Path(os.environ.get("CHEZMOI_SOURCE_DIR", Path(__file__).resolve().parents[1]))
    destination = Path(os.environ.get("CHEZMOI_DEST_DIR", Path.home()))
    capture(source, destination)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError) as error:
        sys.exit(f"capture-omarchy-plugins: {error}")
