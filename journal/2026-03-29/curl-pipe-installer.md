# curl | sh installer support

## What changed
- Updated `bin/install` to support two installation modes:
  - Repository mode: if `lib/direnv-overlay.sh` is present relative to the script, install as a symlink (existing behavior).
  - Piped mode: if repository files are unavailable (e.g., `curl .../bin/install | sh`), install a standalone embedded copy of `direnv-overlay.sh`.
- Updated `README.md` installation docs to describe both clone-based and `curl | sh` install paths.

## Why
- The user asked for a one-liner install path that matches common CLI tool onboarding.
- Keeping explicit behavior for each mode avoids silent assumptions and makes failures easier to debug.

## Follow-up considerations
- Embedded payload duplicates `lib/direnv-overlay.sh`. If the library evolves, installer payload must be kept in sync.
- A future tidy-up could generate the payload from `lib/direnv-overlay.sh` during release automation.
