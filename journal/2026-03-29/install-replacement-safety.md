# Make install replacement safe and mode-independent

Tightened `bin/install` so reinstalling always converges on the same standalone
helper deployment without relying on a separate uninstall step.

## Changes

- Updated `bin/install` to stage a temporary file and atomically replace
  `~/.config/direnv/lib/direnv-overlay.sh`.
- Removed clone-specific installation behavior so both local and `curl | sh`
  installs now produce the same standalone helper file.
- Avoided writing installer output directly to the target path, which could
  otherwise follow an existing symlink and overwrite another file.
- Added `test/install.bash` coverage for:
  - replacing an existing regular file with the standalone helper
  - replacing an existing symlink with the standalone helper without mutating the
    symlink target

## Notes

- The cleaner model is "install is idempotent and always installs the same artifact".
- A separate uninstall step remains useful for explicit removal, but should not be a
  prerequisite for safe reinstall.
