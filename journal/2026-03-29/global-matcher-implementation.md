Implemented the global project matcher model for `direnv-overlay`.

What changed:

- Added `use_global_overlay` as the preferred entrypoint for personal `direnvrc`.
- Added mapping lookup from `~/.direnv-overlay/overlays.map` or `DIRENV_OVERLAY_MAP_FILE`.
- Supported two mapping keys:
  - `path:/absolute/project/root => overlay-name`
  - `repo:directory-name => overlay-name`
- Kept `overlay <name>` as a low-level direct loader.
- Updated installer payload and install output to point users at `use_global_overlay`.
- Reworked README around the global-matcher workflow.
- Added tests for global matching no-op behavior, repo matching, path priority, and invalid mappings.

Important design details:

- No mapping is a no-op.
- Invalid mapping syntax is an explicit error.
- The mapping file is watched for reloads.
- A command-substitution bug would have hidden `watch_file` side effects; the final implementation uses a status code plus `DIRENV_OVERLAY_MATCH` instead.
