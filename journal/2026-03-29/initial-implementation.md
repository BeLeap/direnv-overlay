# Initial Implementation

Implemented the first working version of `direnv-overlay`.

What was added:

- `lib/direnv-overlay.sh` with an `overlay <name>` helper for direnv
- `bin/install` to symlink the helper into the user's direnv lib directory
- `test/overlay.bash` covering argument validation, missing overlays, `.envrc`
  loading, and `use nix` fallback
- `README.md` installation and usage instructions

Current behavior:

- overlays are resolved under `~/.direnv-overlay/<name>/` by default
- `.envrc` is required as the overlay entrypoint
- the overlay directory is watched for changes
- the helper exports `DIRENV_OVERLAY_NAME` and `DIRENV_OVERLAY_DIR` while running
- tool-specific setup belongs inside the overlay `.envrc`

Known follow-up questions:

- whether to support nested overlay names or alternate lookup rules
- whether to support more entrypoint types than `.envrc`
- whether to add an integration test that exercises real `direnv` behavior end-to-end
