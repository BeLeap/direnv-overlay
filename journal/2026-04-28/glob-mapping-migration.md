# glob mapping migration

## Summary
- Replaced mapping matcher support from `path:`/`repo:` to `glob:` in `lib/direnv-overlay.sh`.
- Added explicit failure for legacy `path:` and `repo:` keys with actionable error text.
- Updated tests to validate `glob:` matching behavior, first-match precedence, and legacy-key rejection.
- Updated README examples and mapping-rule docs to describe `glob:` semantics.

## Notes for next task
- `glob:` is currently matched against the detected project root path (`_direnv_overlay_project_root`), not `$PWD`.
- Matching uses Bash `[[ "$project_root" == $pattern ]]`, so patterns follow Bash glob semantics.
