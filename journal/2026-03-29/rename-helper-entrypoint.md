# Rename helper entrypoint to use_direnv_overlay

Renamed the preferred `direnvrc` entrypoint from `use_global_overlay` to
`use_direnv_overlay` for clearer intent.

## Changes

- Added `use_direnv_overlay` as the primary public helper function.
- Removed `use_global_overlay` rather than keeping a compatibility alias.
- Updated README examples and installer messaging to point to the new name.
- Updated overlay tests to exercise the new entrypoint only.
