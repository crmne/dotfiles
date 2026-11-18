"""Run tmp-sweep and worktree-sweep against disposable directories and repositories."""

import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time
import unittest


REPO = Path(__file__).resolve().parents[1]
TMP_SWEEP = REPO / "dot_local/bin/executable_tmp-sweep"
WORKTREE_SWEEP = REPO / "dot_local/bin/executable_worktree-sweep"
TWO_DAYS_AGO = time.time() - 2 * 86400
A_MONTH_AGO = time.time() - 30 * 86400


def age(path, when):
    for root, dirs, files in os.walk(path):
        for name in dirs + files:
            os.utime(os.path.join(root, name), (when, when), follow_symlinks=False)
    os.utime(path, (when, when), follow_symlinks=False)


@unittest.skipUnless(Path("/proc/self/cwd").exists(), "the sweeps read /proc")
class TmpSweepTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="tmp-sweep-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)

    def sweep(self, *args):
        return subprocess.run([str(TMP_SWEEP), "--root", str(self.root), *args],
                              check=True, capture_output=True, text=True).stdout

    def test_removes_old_leftovers_and_keeps_everything_else(self):
        profile = self.root / "org.chromium.Chromium.scoped_dir.abc123"
        (profile / "Default").mkdir(parents=True)
        (profile / "Default/Cookies").write_text("x")
        age(profile, TWO_DAYS_AGO)
        fresh = self.root / "org.chromium.Chromium.scoped_dir.fresh1"
        fresh.mkdir()
        half_fresh = self.root / ".tmpAbCdEf"
        (half_fresh / "inner").mkdir(parents=True)
        age(half_fresh, TWO_DAYS_AGO)
        (half_fresh / "inner/new").write_text("written just now")
        unrelated = self.root / "someone-elses-file"
        unrelated.write_text("x")
        age(unrelated, TWO_DAYS_AGO)

        self.assertIn("would remove 1 entries", self.sweep("--dry-run"))
        self.assertTrue(profile.exists())

        self.sweep()
        self.assertFalse(profile.exists())
        self.assertTrue(fresh.exists())
        self.assertTrue(half_fresh.exists())
        self.assertTrue(unrelated.exists())

    def test_keeps_what_a_process_uses(self):
        busy = self.root / "playwright-artifacts-busy"
        busy.mkdir()
        (busy / "trace").write_text("x")
        age(busy, TWO_DAYS_AGO)
        with open(busy / "trace"):
            self.sweep()
            self.assertTrue(busy.exists())

        listening = self.root / ".org.chromium.Chromium.sock01"
        listening.mkdir()
        server = socket.socket(socket.AF_UNIX)
        self.addCleanup(server.close)
        server.bind(str(listening / "SingletonSocket"))
        age(listening, TWO_DAYS_AGO)
        self.sweep()
        self.assertTrue(listening.exists())


@unittest.skipUnless(shutil.which("git"), "worktree-sweep needs git")
class WorktreeSweepTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="worktree-sweep-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.env = {**os.environ, "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1",
                    "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.com",
                    "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.com"}
        self.git("init", "--quiet", "--bare", "-b", "main", str(self.root / "origin.git"))
        self.repo = self.root / "repo"
        self.git("clone", "--quiet", str(self.root / "origin.git"), str(self.repo))
        self.commit(self.repo, "one")
        self.git("-C", str(self.repo), "push", "--quiet", "origin", "main")
        self.git("-C", str(self.repo), "remote", "set-head", "origin", "main")

    def git(self, *args):
        return subprocess.run(["git", *args], check=True, capture_output=True, text=True, env=self.env).stdout

    def commit(self, where, name):
        (where / name).write_text(name)
        self.git("-C", str(where), "add", name)
        self.git("-C", str(where), "commit", "--quiet", "-m", name)

    def worktree(self, name, branch):
        path = self.root / name
        self.git("-C", str(self.repo), "worktree", "add", "--quiet", "-b", branch, str(path), "origin/main")
        return path

    def sweep(self, *args):
        return subprocess.run([str(WORKTREE_SWEEP), "--no-gc", *args, str(self.repo)],
                              check=True, capture_output=True, text=True, env=self.env).stdout

    def test_removes_only_merged_clean_and_untouched_worktrees(self):
        merged = self.worktree("merged", "merged")
        (merged / "node_modules/pkg").mkdir(parents=True)
        (self.repo / ".gitignore").write_text("node_modules/\nnotes.txt\n")
        self.git("-C", str(self.repo), "add", ".gitignore")
        self.git("-C", str(self.repo), "commit", "--quiet", "-m", "ignore")
        self.git("-C", str(self.repo), "push", "--quiet", "origin", "main")
        self.git("-C", str(merged), "merge", "--quiet", "--ff-only", "origin/main")

        unmerged = self.worktree("unmerged", "unmerged")
        self.commit(unmerged, "work")
        dirty = self.worktree("dirty", "dirty")
        (dirty / "one").write_text("changed")
        notes = self.worktree("notes", "notes")
        self.git("-C", str(notes), "merge", "--quiet", "--ff-only", "origin/main")
        (notes / "notes.txt").write_text("ignored, but not build output")
        recent = self.worktree("recent", "recent")
        for path in (merged, unmerged, dirty, notes):
            age(path, A_MONTH_AGO)

        output = self.sweep()

        self.assertFalse(merged.exists(), output)
        self.assertTrue(unmerged.exists())
        self.assertTrue(dirty.exists())
        self.assertTrue(notes.exists())
        self.assertTrue(recent.exists())
        self.assertIn("refs/heads/merged", self.git("-C", str(self.repo), "show-ref"))

    def test_dry_run_changes_nothing(self):
        merged = self.worktree("merged", "merged")
        age(merged, A_MONTH_AGO)
        self.assertIn("would remove 1 worktrees", self.sweep("--dry-run"))
        self.assertTrue(merged.exists())


if __name__ == "__main__":
    unittest.main()
