Discussed the privacy tradeoff in requiring `overlay <name>` inside a committed project `.envrc`.

Takeaway:

- The current interface leaks one piece of user choice into the repository: the overlay slot name.
- That is still better than committing the actual toolchain setup, but it does not fully avoid personal config showing up in shared files.
- A better long-term design is to let the repository declare only a stable hook, while the user chooses the concrete overlay mapping outside the repo.

Recommended direction:

- Prefer a zero-arg or project-derived hook such as `overlay` that resolves from repository identity.
- Alternatively support a committed logical slot name such as `overlay local`, with per-user mapping from `(project, slot)` to an actual overlay directory in user-owned config.
- Keep failures explicit when no user mapping exists; do not silently skip overlays.

Why:

- This preserves the project's ability to say "there is a personal extension point here" without committing a developer-specific overlay identifier.
- It keeps the tidy boundary between shared repo config and user-owned environment choices.
