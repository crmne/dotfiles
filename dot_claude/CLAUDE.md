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

- Each session runs in a systemd scope of its own (the fish `claude`
  function), so running out of memory kills one session, not herdr and every
  session with it.
- Stop processes by exact PID you started, never `pkill -f`, `killall`, or a
  `pgrep -f` pattern, which also match your own shell and other sessions.
- Never open URLs in the desktop browser (`open`, `xdg-open`); use headless
  Playwright or `curl`.

# Secrets

- Read 1Password secrets with `op-cache read "op://..."` (or `op-cache run`
  for environment variables), never `op read`. `op-cache` caches them, so you
  don't trigger a 1Password approval prompt on every read. Project `.env`
  files already use it.
- Never search 1Password: `op item list`, `op item get` (`--otp` included) and
  `op vault list` each raise an approval prompt. Find the `op://` reference in
  the repository (`.envrc`, `.env`, Makefile, docs, Terraform) or ask Carmine.
- Use `op` only where `op-cache` can't do the job, which is creating or
  editing an item, with the value passed through a file or stdin, never in
  arguments, and as few calls as possible.
- When you start a subagent that may touch secrets, put these rules in its
  prompt.
- `op-cache` is Carmine's AUR package, `op-cache-git`, at `/usr/bin/op-cache`.
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
