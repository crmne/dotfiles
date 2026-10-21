# Commits and pull requests

- Never add a `Co-Authored-By` trailer, a `Claude-Session` link, or any
  "Generated with Claude Code" line to commit messages, pull request
  descriptions, or anywhere else. Carmine's commits carry Carmine's name only.

# Linking issues and pull requests

- When you mention an issue, pull request, discussion or commit to Carmine,
  write it as a clickable Markdown link to its page, e.g.
  [#909](https://github.com/owner/repo/pull/909), never a bare `#909` or SHA.
  This applies to every summary, triage list and decision list.

# Rendering video

- Render on the GPU, one render at a time: Hyperframes only through `hf-render`
  (never `npx hyperframes render` directly), and any other GPU job (Playwright
  frame capture, ffmpeg NVENC, Blender) wrapped in `gpu-lock`. Never deliver a
  render that fell back to screenshot or software capture. Load the
  `gpu-render` skill before rendering.
- Render with one worker. With several, each worker captures every Nth frame
  and can hold different animation state, so motion flickers on every Nth
  frame. `hf-render` enforces it and runs `hf-flicker` on the result; never
  deliver a render with pops, unless you looked and each is a designed
  one-frame effect such as a screen shake.

# Processes

- Each session runs in a systemd scope of its own (the fish wrappers for
  `claude`, `codex` and the other agents), so running out of memory kills one
  session, not herdr and every session with it.
- Stop processes by exact PID you started, never `pkill -f`, `killall`, or a
  `pgrep -f` pattern, which also match your own shell and other sessions.
- Never open URLs in the desktop browser (`open`, `xdg-open`); use headless
  Playwright or `curl`. The exception is Playwriter (`npx -y playwriter`),
  which drives Carmine's own Chromium for vendor consoles that block headless
  browsers: work only in tabs in its "vendors" tab group, screenshot before
  every submit, and never touch billing or payment details unless Carmine
  asked for that purchase or account (then use the card in 1Password, and keep
  auto-recharge off).
- Local model servers run only while something uses them. GPUStack's
  container (`gpustack-<version>`, restart policy `no`) serves RubyLLM's
  `gpustack` specs on port 11444: `docker start` it before recording those
  cassettes and `docker stop` it after, so it doesn't hold GPU memory.

# Rust builds

- Cargo runs through mbx (Mr. Boxington, enabled by mise's `mr_boxington`
  Rust option), which makes every checkout's `target/` a symlink into its
  cache at `/mnt/scratch-disk/mbx`, on the Samsung NVMe. Never put build
  output on the root disk: don't set `CARGO_TARGET_DIR`, `build.target-dir`
  or `build.build-dir` to a path under `/home`, and don't replace the
  `target` symlink with a real directory. Heavy builds there saturate the
  root drive and freeze the desktop.
- A `target` link that still points into `~/.cache/mbx` is from before the
  move: delete the link (not what it points to) before building, and mbx
  makes a new one on the Samsung.
- If `/mnt/scratch-disk` isn't mounted, stop and tell Carmine instead of
  building elsewhere.
- Run one heavy build or test suite per project at a time (`cargo test
  --all-targets`, release builds with LTO): each links large binaries, and
  several at once still saturate a disk.

# Test machines

- Windows: test on the Windows 11 VM on the NUC, never on Carmine's Windows
  laptop (`windows-box`, 192.168.8.231), which is his to use. Control it
  through SSH to `nuc.local` (`ssh nuc` doesn't resolve from the desktop):
  `ssh nuc.local sudo -n /usr/local/sbin/windows11-test-vm start|status|address|display|shutdown`.
  There is one VM: run `status` first, and if it's running, another agent is
  using it, so wait or ask. Start refuses with less than 10 GiB free on the
  NUC. Always `shutdown` when you're done, then check `status`.
- Get into it over SSH through the NUC. Its address is fixed at
  192.168.122.11 (`address` prints it). The login shell is PowerShell, so
  pass PowerShell directly:
  `ssh -o IdentitiesOnly=yes -i ~/.ssh/windows11-test-vm -J nuc.local vm-tester@192.168.122.11 '$PSVersionTable.PSVersion'`.
  Copy files with `scp` using the same options. `IdentitiesOnly=yes` is
  required, or the 1Password agent's other keys exhaust sshd's attempts.
  Windows takes about a minute to boot after `start`, so retry SSH until it
  answers.
- Use the VM to install and run, not to build. The NUC is weak and also
  runs Home Assistant, media and backups. Build Windows binaries in CI
  (`windows-latest`) or by cross-compiling on the desktop, then copy the
  artifact in with `scp` or download it inside Windows. Compile inside the
  VM only when nothing else can produce the build, and say so first.
- VNC is still there for the GUI: read the display number from `display`
  (`:N` is TCP port 5900 + N), forward it with
  `ssh -N -L 590N:127.0.0.1:590N nuc.local`, and drive it with `vncdo`.
  Basic graphics only, with no GPU acceleration, camera or microphone, so it
  can't prove GPU, video, call or low-latency audio behaviour. It's a 90-day
  Enterprise evaluation. Recipe and details: Ansible role `windows11_vm` in
  `~/Work/terraform`.
- macOS: the Mac mini, `ssh carmines-mac-mini.local` (Apple Silicon,
  macOS 27).

# Secrets

- Read 1Password secrets with `op-cache read "op://..."` (or `op-cache run`
  for environment variables), never `op read`. `op-cache` caches them, so you
  don't trigger a 1Password approval prompt on every read. Project `.env`
  files already use it.
- When you don't know an item's `op://` path, look in the repository first
  (`.envrc`, `.env`, Makefile, docs, Terraform), then search 1Password with
  `op item list` or `op item get`. Each search raises an approval prompt, so
  search once for what you need rather than item by item.
- Use `op` only where `op-cache` can't do the job, which is creating or
  editing an item, with the value passed through a file or stdin, never in
  arguments, and as few calls as possible.
- When you start a subagent that may touch secrets, put these rules in its
  prompt.
- `op-cache` is Carmine's AUR package, `op-cache-git`, at `/usr/bin/op-cache`.
- Two-step login: prefer an authenticator app whose secret lives in 1Password
  (a one-time password field on the service's login item) over SMS, and turn
  SMS off where the service allows. Save backup codes in the same item.
- If it fails or times out, 1Password is probably locked or waiting for an
  approval: tell Carmine, and don't fall back to `op` or work around it.
- Never print, log or commit a secret. Check a value resolved by its length.

# Films and product videos

- Every film's source (HyperFrames project, brief, storyboard, compositions,
  tools, music generators such as score scripts, MIDI and Bitwig controller
  scripts, and the images, fonts and footage the compositions use) lives in
  the private repo `~/Code/films` (crmne/films), as
  `~/Code/films/<project>/<film>/`, e.g. `films/omacal/launch`. Never in the
  product's own repository, public or private. Start new films there.
- Never commit rendered videos anywhere: publish them as GitHub release
  assets, on the product's repository or, for a private product, on its
  public site repository. The one exception is site media: a web encode the
  product's own website serves lives with that site's code, like any other
  site asset (e.g. Chat with Work's private app repo).
- Never commit audio (exports, mixes, previews, stems): commit the
  compositions. Binary media (images, fonts, footage) goes through Git LFS
  via the repo's `.gitattributes`; keep it small anyway.
- Embed release videos so they play in the release notes: upload the file
  with `gh-attachment <file> --repo owner/repo` and put the printed
  `github.com/user-attachments/...` URL on a line of its own in the committed
  release notes (a release-asset or repository link only renders as a plain
  link). Keep the full-quality file as a release asset too, and link it.
- Rules and layout: `~/Code/films/README.md`.
