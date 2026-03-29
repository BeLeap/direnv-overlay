# Add uninstall script

Implemented an explicit uninstaller for the direnv helper deployment.

Changes:

- Added `bin/uninstall`.
  - Removes `$XDG_CONFIG_HOME/direnv/lib/direnv-overlay.sh` (or `~/.config/...`).
  - Exits with clear failure when there is nothing to remove.
- Updated `README.md` with uninstall usage for both local clone and `curl | sh` flows.
- Added `test/uninstall.bash` to verify:
  - uninstall removes an existing installed helper file.
  - uninstall fails when the helper does not exist.

Notes:

- The uninstaller intentionally removes only the installed helper file and does not
  remove parent directories.
- Failure on missing file is intentional so CI/users can detect drift or wrong paths.
