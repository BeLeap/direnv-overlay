# Project Goal

Defined the project's core problem and target workflow in `README.md`.

Summary:

- The project is for personal `direnv` overlays that should not be committed upstream.
- A repository can expose a stable hook such as `overlay foo`.
- `overlay foo` should resolve to `~/.direnv-overlay/foo/`.
- Overlay-owned files such as `.envrc` and `shell.nix` should be loaded from that
  personal directory.
- The design should keep personal configuration separate from shared repository files.
- We should prefer a dedicated directive like `overlay` over overloading `use`.

Open design questions to resolve in implementation:

- exact lookup rules for overlay directories
- supported file set and evaluation order
- failure behavior for missing overlays
- how the custom `overlay <name>` hooks into `direnv` stdlib conventions
