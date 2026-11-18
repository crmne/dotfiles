"""Run with python3 -m unittest discover -s tests -v."""

from pathlib import Path
import unittest


REPO = Path(__file__).resolve().parents[1]
FISH = REPO / "dot_config/private_fish"
SCRIPT = REPO / "run_onchange_after_fisher-update.sh.tmpl"


class FisherTest(unittest.TestCase):
    def test_fisher_update_reruns_when_the_plugin_list_changes(self):
        self.assertTrue((FISH / "fish_plugins").exists())
        self.assertIn(
            '{{ include "dot_config/private_fish/fish_plugins" | sha256sum }}',
            SCRIPT.read_text(),
        )

    def test_files_fisher_installs_are_not_pinned_here(self):
        # chezmoi would put an old copy back after every `fisher update`.
        pinned = [
            path.relative_to(REPO)
            for pattern in ["**/fisher.fish", "**/*fzf*.fish", "**/__omafish_*.fish", "**/*direnv*.fish"]
            for path in FISH.glob(pattern)
        ]
        self.assertEqual(pinned, [])


if __name__ == "__main__":
    unittest.main()
