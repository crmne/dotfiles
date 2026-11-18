#!/usr/bin/env python3
"""Save the live Omarchy shell configuration into the source state.

shell.json is a template because a few widget settings differ by machine, and
chezmoi re-add skips templates. This writes the live file into the template,
puts the per-machine expressions back in place of those settings, and then
records the enabled plugins, as the re-add hook does for plain files.
"""

import json
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
capture = __import__("capture-omarchy-plugins")

CHALK = 'eq .chezmoi.hostname "chalk"'

# (widget id, setting) -> template expression rendering that setting's JSON value.
PER_MACHINE = {
    # chalk shows its RTX 3090 and its two NVMe drives; other machines have
    # one disk and an integrated GPU.
    ("crmne.omastats", "modules"):
        '{{ if ' + CHALK + ' }}"cpu,memory,network,gpu,disks"{{ else }}"cpu,memory,network,disks"{{ end }}',
    ("crmne.omastats", "barDisks"):
        '{{ if ' + CHALK + ' }}"nvme-Samsung_SSD_970_EVO_Plus_1TB_S4EWNF0M921645X:used,'
        'nvme-KIOXIA-EXCERIA_G3_SSD_YFWKS0TJZ3TS:used"{{ else }}""{{ end }}',
    # Google Calendar is signed in per machine (gws auth login).
    ("crmne.omacal", "googleEnabled"): '{{ ' + CHALK + ' }}',
}


def template_for(config):
    placeholders = {}

    def walk(node):
        if isinstance(node, dict):
            for (widget, setting), expression in PER_MACHINE.items():
                if node.get("id") == widget:
                    marker = f"@@per-machine-{len(placeholders)}@@"
                    placeholders[marker] = expression
                    node[setting] = marker
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)

    walk(config)
    # Omarchy writes shell.json key-sorted with two-space indents; match it so
    # diffs stay small.
    text = json.dumps(config, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    for marker, expression in placeholders.items():
        text = text.replace(json.dumps(marker), expression)
    return text


def main():
    home = Path.home()
    source = Path(os.environ.get("CHEZMOI_SOURCE_DIR", Path(__file__).resolve().parents[1]))
    live = home / ".config/omarchy/shell.json"
    config = json.loads(live.read_text())
    target = source / "dot_config/omarchy/private_shell.json.tmpl"
    target.write_text(template_for(json.loads(json.dumps(config))))
    # The template replaces the plain file; chezmoi refuses two sources for one target.
    for plain in ("private_shell.json", "shell.json"):
        (target.parent / plain).unlink(missing_ok=True)
    print(f"Saved {live} into {target.relative_to(source)}.")
    capture.capture(source, home, config=config)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        sys.exit(f"re-add-shell-json: {error}")
