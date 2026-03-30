# overlay context env vars

## Summary
- Updated overlay loading to persist `DIRENV_OVERLAY_NAME` and `DIRENV_OVERLAY_DIR` after an overlay is selected.
- Added tests to verify both variables are visible after `overlay` and `use_direnv_overlay` execution.
- Updated README wording to describe these variables as active-overlay indicators.

## Rationale
- Users should be able to introspect which overlay name/path was selected through environment variables from project context.
- Previous behavior scoped these values to sourcing time only, which made them difficult to use for debugging and tooling.

## Validation
- Ran `test/overlay.bash`.
