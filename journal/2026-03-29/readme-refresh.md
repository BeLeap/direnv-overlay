# README refresh

## What changed

- rewrote `README.md` around the actual shipped interfaces: `use_direnv_overlay`,
  `overlay`, `bin/install`, and `bin/uninstall`
- removed speculative planning-oriented sections and replaced them with task-oriented
  documentation
- added a clearer install flow, quick start, mapping rules, configuration, and error
  behavior
- reordered the README so the top-level flow matches the order a new user would follow
- switched the install examples back to the `curl | sh` path, with local scripts kept as
  an alternative
- removed the redundant `source .../direnv-overlay.sh` step from `direnvrc`

## Notes

- kept the README aligned with current implementation and tests rather than describing
  future ideas
- documented both `DIRENV_OVERLAY_ROOT` and `DIRENV_OVERLAY_MAP_FILE`
- preserved the limitation that `direnv` still needs an entrypoint in the project
- moved quick start ahead of deeper explanation so setup comes before conceptual detail
- kept the documented install path aligned with the piped installer support in `bin/install`
- aligned the enable step with direnv's automatic loading of `direnv/lib/*.sh`

## Verification

- `bash test/install.bash`
- `bash test/overlay.bash`
- `bash test/uninstall.bash`
