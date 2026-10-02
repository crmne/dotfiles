"""Run with python3 -m unittest discover -s tests -v.

Loads the repository's fontconfig files through the system configuration, as
chezmoi installs them (the user files under XDG_CONFIG_HOME, the system file
before /etc/fonts/fonts.conf), and checks what each family resolves to.
Skipped where fontconfig, Omarchy's font defaults or the chosen fonts are
missing, since the answers depend on what is installed.
"""

from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


REPO = Path(__file__).resolve().parents[1]
SYSTEM_FILE = REPO / "system/etc/fonts/conf.d/49-carmine-fonts.conf"
USER_DIR = REPO / "dot_config/fontconfig"
SCRIPT = REPO / "run_onchange_after_install-fontconfig-system.sh.tmpl"


def fc_match(pattern, env):
    return subprocess.run(
        ["fc-match", "-f", "%{family[0]}", pattern],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    ).stdout


def installed(family):
    families = subprocess.run(
        ["fc-list", "--format", "%{family}\n"], capture_output=True, text=True
    ).stdout
    return any(family in line.split(",") for line in families.splitlines())


class FontconfigFilesTest(unittest.TestCase):
    def test_every_file_is_valid_fontconfig_xml(self):
        for path in [SYSTEM_FILE, USER_DIR / "fonts.conf", *USER_DIR.glob("conf.d/*.conf")]:
            with self.subTest(path=path.relative_to(REPO)):
                self.assertEqual(ET.parse(path).getroot().tag, "fontconfig")

    def test_fonts_conf_holds_only_the_monospace_rule(self):
        # `omarchy font set` rewrites fonts.conf with only a monospace rule, so
        # anything else kept there would be lost.
        root = ET.parse(USER_DIR / "fonts.conf").getroot()
        tested = [s.text for s in root.iter("string") if s.text]
        self.assertEqual(len(root.findall("match")), 1)
        self.assertIn("monospace", tested)
        self.assertEqual(root.findall("alias"), [])

    def test_the_install_script_reruns_when_the_system_file_changes(self):
        script = SCRIPT.read_text()
        self.assertIn(
            '{{ include "system/etc/fonts/conf.d/49-carmine-fonts.conf" | sha256sum }}',
            script,
        )
        self.assertIn("system", (REPO / ".chezmoiignore").read_text().split())


@unittest.skipUnless(shutil.which("fc-match"), "fontconfig is not installed")
@unittest.skipUnless(
    Path("/etc/fonts/conf.d/50-omarchy.conf").exists(), "not an Omarchy machine"
)
class FontResolutionTest(unittest.TestCase):
    def setUp(self):
        for family in ["Inter", "Noto Serif"]:
            if not installed(family):
                self.skipTest(f"{family} is not installed")
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name) / "fonts.conf"
        root.write_text(
            '<?xml version="1.0"?>\n<!DOCTYPE fontconfig SYSTEM "fonts.dtd">\n'
            f"<fontconfig>\n  <include>{SYSTEM_FILE}</include>\n"
            "  <include>/etc/fonts/fonts.conf</include>\n</fontconfig>\n"
        )
        self.env = dict(
            os.environ,
            FONTCONFIG_FILE=str(root),
            XDG_CONFIG_HOME=str(REPO / "dot_config"),
        )

    def tearDown(self):
        self.tmp.cleanup()

    def test_the_interface_families_resolve_to_inter(self):
        # A '-' in an fc-match pattern starts a size, so names carrying one are
        # escaped, as fastframe asks for them.
        for pattern in [r"system\-ui", r"sans\-serif", r"\-apple\-system", "BlinkMacSystemFont"]:
            with self.subTest(pattern=pattern):
                self.assertEqual(fc_match(pattern, self.env), "Inter")

    def test_serif_resolves_to_noto_serif(self):
        self.assertEqual(fc_match("serif", self.env), "Noto Serif")

    def test_a_font_named_before_the_generic_family_still_comes_first(self):
        if not installed("Georgia"):
            self.skipTest("Georgia is not installed")
        self.assertEqual(fc_match("Georgia,serif", self.env), "Georgia")


if __name__ == "__main__":
    unittest.main()
