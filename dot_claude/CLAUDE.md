# Commits and pull requests

- Never add a `Co-Authored-By` trailer, a `Claude-Session` link, or any
  "Generated with Claude Code" line to commit messages, pull request
  descriptions, or anywhere else. Carmine's commits carry Carmine's name only.

# Rendering video

- Render on the GPU, one render at a time: Hyperframes only through `hf-render`
  (never `npx hyperframes render` directly), and any other GPU job (Playwright
  frame capture, ffmpeg NVENC, Blender) wrapped in `gpu-lock`. Never deliver a
  render that fell back to screenshot or software capture. Load the
  `gpu-render` skill before rendering.

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
