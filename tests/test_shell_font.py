"""Run with python3 -m unittest discover -s tests -v.

Loads the repository's fontconfig directory as chezmoi installs it (under
XDG_CONFIG_HOME, read through the system configuration) and checks what the
Omarchy shell and other programs get when they ask for "monospace". Skipped
where fontconfig, Omarchy's font defaults or the fonts are missing, since the
answers depend on what is installed.
"""

from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


REPO = Path(__file__).resolve().parents[1]
RULE = REPO / "dot_config/fontconfig/conf.d/90-omarchy-shell-font.conf"
SHELL_FONT = "IBM Plex Sans"
ICON_FONT = "JetBrainsMono Nerd Font"
SHELL = "monospace:prgname=quickshell"

# What `omarchy font set "IBM Plex Mono"` writes to ~/.config/fontconfig/fonts.conf.
FONT_SET = """<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family" qual="any">
      <string>monospace</string>
    </test>
    <edit name="family" mode="prepend_first" binding="strong">
      <string>IBM Plex Mono</string>
    </edit>
  </match>
</fontconfig>
"""


def installed(family):
    families = subprocess.run(
        ["fc-list", "--format", "%{family}\n"], capture_output=True, text=True
    ).stdout
    return any(family in line.split(",") for line in families.splitlines())


class ShellFontFileTest(unittest.TestCase):
    def test_the_rule_is_valid_fontconfig_xml(self):
        self.assertEqual(ET.parse(RULE).getroot().tag, "fontconfig")

    def test_fontconfig_is_installed_on_linux_only(self):
        ignore = (REPO / ".chezmoiignore").read_text()
        linux_only = ignore.split('{{ if ne .chezmoi.os "linux" }}')[1].split("{{ end }}")[0]
        self.assertIn(".config/fontconfig", linux_only.split())


@unittest.skipUnless(shutil.which("fc-match"), "fontconfig is not installed")
@unittest.skipUnless(
    Path("/etc/fonts/conf.d/50-omarchy.conf").exists(), "not an Omarchy machine"
)
class ShellFontResolutionTest(unittest.TestCase):
    def setUp(self):
        for family in [SHELL_FONT, ICON_FONT]:
            if not installed(family):
                self.skipTest(f"{family} is not installed")
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.home = Path(tmp.name) / "config"
        (self.home / "fontconfig/conf.d").mkdir(parents=True)
        shutil.copy(RULE, self.home / "fontconfig/conf.d" / RULE.name)
        self.bare = Path(tmp.name) / "bare"
        self.bare.mkdir()

    def families(self, pattern, home=None):
        env = dict(os.environ, XDG_CONFIG_HOME=str(home or self.home))
        out = subprocess.run(
            ["fc-match", "-s", "-f", "%{family[0]}\n", pattern],
            env=env, capture_output=True, text=True, check=True,
        ).stdout
        return out.splitlines()

    def test_the_shell_gets_its_own_face_with_the_icon_font_next(self):
        self.assertEqual(self.families(SHELL)[:2], [SHELL_FONT, ICON_FONT])

    def test_other_programs_keep_omarchys_monospace_font(self):
        self.assertEqual(
            self.families("monospace")[0], self.families("monospace", self.bare)[0]
        )

    def test_the_shells_sans_serif_is_left_alone(self):
        self.assertEqual(
            self.families(r"sans\-serif:prgname=quickshell")[0],
            self.families(r"sans\-serif", self.bare)[0],
        )

    def test_omarchy_font_set_does_not_take_the_shell_back(self):
        if not installed("IBM Plex Mono"):
            self.skipTest("IBM Plex Mono is not installed")
        (self.home / "fontconfig/fonts.conf").write_text(FONT_SET)
        self.assertEqual(self.families("monospace")[0], "IBM Plex Mono")
        self.assertEqual(self.families(SHELL)[:2], [SHELL_FONT, ICON_FONT])


if __name__ == "__main__":
    unittest.main()
