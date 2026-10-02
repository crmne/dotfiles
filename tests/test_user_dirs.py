"""Exercise real chezmoi and XDG tools in a disposable home using bubblewrap."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
DIRECTORIES = {
    "DESKTOP": "Desktop", "DOWNLOAD": "Downloads", "TEMPLATES": "Templates",
    "PUBLICSHARE": "Public", "DOCUMENTS": "Documents", "MUSIC": "Music",
    "PICTURES": "Pictures", "VIDEOS": "Videos", "PROJECTS": "Projects",
}


@unittest.skipUnless(all(shutil.which(tool) for tool in
                        ("bwrap", "chezmoi", "xdg-user-dir", "xdg-user-dirs-update")),
                     "integration tests require bubblewrap, chezmoi and xdg-user-dirs")
class UserDirectoriesTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="chezmoi-user-dirs-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.source = self.root / "source"
        self.home = self.root / "home"
        self.home.mkdir()
        for relative in (".chezmoiignore", "dot_config/private_user-dirs.dirs",
                         "dot_config/user-dirs.conf", "run_before_create-user-dirs.sh.tmpl"):
            target = self.source / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(REPO / relative, target)
        # Keep the process HOME unchanged and mount the disposable directory
        # there so scripts and XDG tools exercise their real lookup behavior.
        self.sandbox = [
            "bwrap", "--die-with-parent", "--unshare-net", "--ro-bind", "/", "/",
            "--dev", "/dev", "--bind", str(self.root), str(self.root),
            "--bind", str(self.home), str(Path.home()), "--chdir", str(self.root),
        ]
        self.chezmoi = [
            "chezmoi", "--source", str(self.source), "--destination", str(Path.home()),
            "--config", str(self.root / "chezmoi.toml"),
            "--persistent-state", str(self.root / "state.db"),
            "--cache", str(self.root / "cache"),
        ]
        self.env = dict(os.environ, XDG_CONFIG_HOME=str(Path.home() / ".config"),
                        TMPDIR=str(self.root))

    def run_command(self, *args):
        result = subprocess.run(self.sandbox + list(args), env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def apply(self, *args):
        return self.run_command(*self.chezmoi, "apply", *args)

    def test_fresh_apply_creates_directories_and_dry_run_does_not(self):
        self.apply("--dry-run")
        self.assertEqual(list(self.home.iterdir()), [])
        self.apply()
        for name, folder in DIRECTORIES.items():
            with self.subTest(directory=name):
                self.assertTrue((self.home / folder).is_dir())
                self.assertEqual(self.run_command("xdg-user-dir", name).strip(),
                                 str(Path.home() / folder))
        configuration = self.home / ".config/user-dirs.dirs"
        before = configuration.read_bytes()
        self.apply()
        self.assertEqual(configuration.read_bytes(), before)

    def test_repair_preserves_nextcloud_and_survives_unavailable_target(self):
        for folder in ("Documents", "Pictures", "Videos"):
            target = self.home / "Nextcloud" / folder
            target.mkdir(parents=True)
            (target / "existing.txt").write_text("keep this file")
            (self.home / folder).symlink_to(Path.home() / "Nextcloud" / folder)
        configuration = self.home / ".config/user-dirs.dirs"
        configuration.parent.mkdir()
        broken = ''.join(f'XDG_{name}_DIR="$HOME/"\n' for name in DIRECTORIES)
        configuration.write_text(broken)
        # Exercise the same scoped apply used to repair a real installation.
        self.apply("--source-path", *(str(self.source / relative) for relative in
                   ("run_before_create-user-dirs.sh.tmpl", "dot_config/user-dirs.conf",
                    "dot_config/private_user-dirs.dirs")))
        before = configuration.read_bytes()
        for folder in ("Documents", "Pictures", "Videos"):
            self.assertTrue((self.home / folder).is_symlink())
            self.assertEqual((self.home / "Nextcloud" / folder / "existing.txt").read_text(),
                             "keep this file")
        # Simulate a Nextcloud target being unavailable at login. The updater
        # must leave the mapping intact instead of silently pointing to HOME.
        target = self.home / "Nextcloud/Pictures"
        target.rename(self.home / "Nextcloud/Pictures-unavailable")
        self.run_command("xdg-user-dirs-update")
        self.assertEqual(configuration.read_bytes(), before)
        self.assertEqual(self.run_command("xdg-user-dir", "PICTURES").strip(),
                         str(Path.home() / "Pictures"))

    def test_non_linux_skips_configuration_and_directory_creation(self):
        self.run_command(*self.chezmoi, "--override-data", '{"chezmoi":{"os":"darwin"}}',
                         "apply")
        self.assertFalse((self.home / ".config/user-dirs.dirs").exists())
        self.assertFalse((self.home / ".config/user-dirs.conf").exists())
        for folder in DIRECTORIES.values():
            self.assertFalse((self.home / folder).exists())


if __name__ == "__main__":
    unittest.main()
