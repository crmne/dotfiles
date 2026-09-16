"""Run with python3 -m unittest discover -s tests -v.

The integration test uses bubblewrap to give real chezmoi a disposable home,
and a fake Omarchy command to avoid network access or a running desktop.
"""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "capture", REPO / "tools/capture-omarchy-plugins.py"
)
CAPTURE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CAPTURE)


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data))


class CaptureTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="omarchy-capture-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        self.destination = self.root / "home"
        self.shell = self.source / "dot_config/omarchy/shell.json"
        self.data = self.source / ".chezmoidata/omarchy-plugins.json"
        self.overrides = self.source / "tools/omarchy-plugin-sources.json"
        write_json(self.overrides, {})

    def capture(self):
        CAPTURE.capture(self.source, self.destination)
        return json.loads(self.data.read_text())["omarchyPlugins"]

    def test_git_origin_add_remove_and_idempotence(self):
        plugin = self.destination / ".config/omarchy/plugins/acme.widget"
        write_json(plugin / "manifest.json", {"id": "acme.widget"})
        subprocess.run(["git", "init", "-q", str(plugin)], check=True)
        subprocess.run(["git", "-C", str(plugin), "remote", "add", "origin",
                        "git@github.com:acme/widget.git"], check=True)
        write_json(self.shell, {"bar": {"layout": {"left": [
            "omarchy.menu", {"id": "acme.widget"}, {"id": "acme.widget"}
        ]}}})
        self.assertEqual(self.capture(), {"acme.widget": "https://github.com/acme/widget.git"})
        before = self.data.stat().st_mtime_ns
        self.capture()
        self.assertEqual(self.data.stat().st_mtime_ns, before)
        write_json(self.shell, {"bar": {"layout": {"left": ["omarchy.menu"]}}})
        self.assertEqual(self.capture(), {})

    def test_services_custom_bar_and_disabled_plugins(self):
        write_json(self.shell, {
            "bar": {"id": "acme.bar", "layout": {"right": [{"id": "acme.off"}]}},
            "plugins": [{"id": "acme.service"}, {"id": "omarchy.background"}],
            "disabledPlugins": ["acme.off", "acme.bar"],
        })
        self.assertEqual(CAPTURE.enabled_plugins(json.loads(self.shell.read_text())),
                         ["acme.bar", "acme.service"])

    def test_development_copy_and_missing_plugin_keep_urls(self):
        write_json(self.shell, {"plugins": [{"id": "acme.local"}, {"id": "acme.missing"}]})
        write_json(self.destination / ".config/omarchy/plugins/acme.local/manifest.json",
                   {"id": "acme.local"})
        write_json(self.overrides, {"acme.local": "https://github.com/acme/local.git"})
        write_json(self.data, {"omarchyPlugins": {
            "acme.missing": "https://github.com/acme/missing.git",
            "acme.removed": "https://github.com/acme/removed.git",
        }})
        self.assertEqual(self.capture(), {
            "acme.local": "https://github.com/acme/local.git",
            "acme.missing": "https://github.com/acme/missing.git",
        })

    def test_unknown_plugin_preserves_previous_data(self):
        write_json(self.data, {"omarchyPlugins": {"acme.old": "https://example.com/old.git"}})
        before = self.data.read_bytes()
        write_json(self.shell, {"plugins": [{"id": "acme.unknown"}]})
        with self.assertRaisesRegex(ValueError, "No repository URL"):
            self.capture()
        self.assertEqual(self.data.read_bytes(), before)

    def test_invalid_id_and_nonportable_url_fail(self):
        write_json(self.shell, {"plugins": [{"id": "../outside"}]})
        with self.assertRaisesRegex(ValueError, "Invalid plugin id"):
            self.capture()
        for url in ("/home/user/plugin", "file:///tmp/plugin", "ext::command",
                    "https://user:token@github.com/acme/plugin.git"):
            with self.subTest(url=url), self.assertRaises(ValueError):
                CAPTURE.portable_url(url)


@unittest.skipUnless(shutil.which("bwrap") and shutil.which("chezmoi"),
                     "integration test requires bubblewrap and chezmoi")
class ChezmoiIntegrationTests(unittest.TestCase):
    def test_init_capture_apply_repair_and_dry_run(self):
        with tempfile.TemporaryDirectory(prefix="omarchy-chezmoi-test-") as temp:
            root = Path(temp)
            source = root / "source"
            fake_home = root / "home"
            fake_home.mkdir()
            for relative in (".chezmoi.toml.tmpl", ".chezmoiignore",
                             "tools/capture-omarchy-plugins.py",
                             "run_after_install-omarchy-plugins.sh.tmpl"):
                target = source / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(REPO / relative, target)
            write_json(source / "tools/omarchy-plugin-sources.json", {})
            data = source / ".chezmoidata/omarchy-plugins.json"
            write_json(data, {"omarchyPlugins": {}})
            source_shell = source / "dot_config/omarchy/shell.json"
            write_json(source_shell, {"plugins": []})
            layout = {"bar": {"layout": {"right": [{"id": "acme.widget", "size": 42}]}}}
            live_shell = fake_home / ".config/omarchy/shell.json"
            write_json(live_shell, layout)
            plugin = fake_home / ".config/omarchy/plugins/acme.widget"
            write_json(plugin / "manifest.json", {"id": "acme.widget"})
            subprocess.run(["git", "init", "-q", str(plugin)], check=True)
            subprocess.run(["git", "-C", str(plugin), "remote", "add", "origin",
                            "https://github.com/acme/widget.git"], check=True)
            fake_bin = root / "bin"
            fake_bin.mkdir()
            fake_omarchy = fake_bin / "omarchy"
            fake_omarchy.write_text('''#!/usr/bin/python3
import json, os, sys
from pathlib import Path
assert sys.argv[1:] == ["plugin", "add", "https://github.com/acme/widget.git", "--yes"], sys.argv
target = Path.home() / ".config/omarchy/plugins/acme.widget"
target.mkdir(parents=True)
(target / "manifest.json").write_text(json.dumps({"id": "acme.widget"}))
with open(os.environ["OMARCHY_TEST_LOG"], "a") as log:
    log.write("install\\n")
''')
            fake_omarchy.chmod(0o755)
            log = root / "installs.log"
            # HOME is unchanged: mount the disposable directory at the actual
            # home path, while the real home and desktop stay inaccessible.
            base = ["bwrap", "--die-with-parent", "--ro-bind", "/", "/", "--dev", "/dev",
                    "--bind", str(root), str(root),
                    "--bind", str(fake_home), str(Path.home()),
                    "--chdir", str(root), "chezmoi",
                    "--source", str(source), "--destination", str(Path.home()),
                    "--config", str(root / "chezmoi.toml"),
                    "--persistent-state", str(root / "state.db"),
                    "--cache", str(root / "cache")]
            env = dict(os.environ, PATH=str(fake_bin) + ":/usr/bin:/bin",
                       TMPDIR=str(root), OMARCHY_TEST_LOG=str(log))

            def chezmoi(*args, ok=True):
                result = subprocess.run(base + list(args), env=env, capture_output=True, text=True)
                if ok:
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                return result

            chezmoi("init")
            before = data.read_bytes()
            chezmoi("re-add", "--dry-run")
            self.assertEqual(data.read_bytes(), before)
            self.assertEqual(json.loads(source_shell.read_text()), {"plugins": []})
            chezmoi("re-add", str(Path.home() / ".config/omarchy/shell.json"))
            self.assertEqual(json.loads(source_shell.read_text()), layout)
            self.assertEqual(json.loads(data.read_text())["omarchyPlugins"], {
                "acme.widget": "https://github.com/acme/widget.git"
            })
            # Simulate another machine with no plugins installed.
            shutil.rmtree(plugin)
            chezmoi("apply", "--dry-run")
            self.assertFalse(plugin.exists())
            chezmoi("apply")
            self.assertEqual(log.read_text(), "install\n")
            self.assertEqual(json.loads(live_shell.read_text()), layout)
            chezmoi("apply")
            self.assertEqual(log.read_text(), "install\n")
            shutil.rmtree(plugin)
            chezmoi("apply")
            self.assertEqual(log.read_text(), "install\ninstall\n")
            # Removing a widget changes the list without deleting its local files.
            write_json(live_shell, {"plugins": []})
            chezmoi("re-add")
            self.assertEqual(json.loads(data.read_text()), {"omarchyPlugins": {}})
            chezmoi("apply")
            self.assertTrue(plugin.is_dir())
            # add is covered as well as re-add, using an explicit development URL.
            write_json(source / "tools/omarchy-plugin-sources.json",
                       {"acme.widget": "https://github.com/acme/widget.git"})
            write_json(live_shell, layout)
            chezmoi("add", str(Path.home() / ".config/omarchy/shell.json"))
            self.assertIn("acme.widget", json.loads(data.read_text())["omarchyPlugins"])
            # A pre-existing directory with the wrong identity is never replaced.
            write_json(plugin / "manifest.json", {"id": "acme.someone-else"})
            result = chezmoi("apply", ok=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("missing or mismatched manifest", result.stderr)


if __name__ == "__main__":
    unittest.main()
