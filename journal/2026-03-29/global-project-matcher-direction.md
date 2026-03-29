Chose the stronger privacy model for `direnv-overlay`.

Decision:

- Do not require repository `.envrc` files to declare `overlay` at all.
- Treat overlay activation as a user-global concern.
- The user-owned direnv configuration should detect the current project and apply a matching overlay automatically.

Implications:

- The repository does not reveal that personal overlays exist.
- Personal overlay selection stays entirely outside version-controlled project files.
- The design focus shifts from a project-invoked helper to a global project matcher.

Likely shape:

- A global hook in user direnv config inspects the current directory.
- Matching may use repository root, repository name, git remote, or an explicit local-only mapping file under user config.
- When a match exists, the overlay is loaded from a user-owned directory.
- When no match exists, behavior should be explicit and configurable, but defaulting to no-op is likely more practical for global matching than hard failure on every unrelated directory.
