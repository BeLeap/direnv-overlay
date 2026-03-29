# direnv-overlay

`direnv-overlay` is a helper for keeping personal `direnv` setup out of upstream repositories.

## Problem

Many projects need local `direnv` customizations such as:

- `use nix`
- local `shell.nix`
- extra environment variables
- personal tooling hooks

Those settings are often useful only for one developer. Committing them into project
`.envrc` or `shell.nix` pushes personal preferences upstream, which creates noise and
forces everyone else to inherit setup they may not want.

## Goal

This project aims to make `direnv` load per-user overlays from outside the repository.

The intended workflow is:

1. A project commits a minimal `.envrc` that can reference an overlay, for example
   `overlay foo`.
2. `direnv-overlay` resolves `foo` to a user-owned directory such as
   `~/.direnv-overlay/foo/`.
3. The overlay's own `.envrc` is loaded and can choose whatever tools it wants to use.

This lets a repository define a stable hook point without committing one developer's
private environment choices. The exact directive does not need to reuse `direnv`'s
built-in `use` naming; a dedicated helper such as `overlay <name>` may be clearer.

## Desired Properties

- Personal overlays live outside the project working tree.
- Missing overlays should fail clearly, not silently.
- Shared project config and personal config stay separate.
- The mechanism should be as simple to invoke as built-in `direnv` helpers.
- The interface should prefer a clear, project-specific directive over overloaded naming.

## Interface Direction

The initial idea was to support `use foo`, modeled after `use nix`. A clearer direction
is probably to introduce a dedicated directive such as:

```sh
overlay foo
```

That avoids overloading the meaning of `use` and makes it obvious that the command is
loading a personal overlay from outside the repository.

## Example

Project `.envrc`:

```sh
overlay foo
```

Personal files:

```text
~/.direnv-overlay/foo/.envrc
```

Expected behavior:

- `overlay foo` looks up `~/.direnv-overlay/foo/`
- the overlay's `.envrc` is loaded
- the overlay can then decide for itself whether to use `nix`, `mise`, or something else
- nothing personal needs to be committed to the upstream repository

## Installation

`direnv` loads custom helpers from `~/.config/direnv/lib/*.sh` (or the matching
`$XDG_CONFIG_HOME` path). This repository provides one helper script there.

From a cloned repository root:

```sh
bin/install
```

This creates a symlink at `~/.config/direnv/lib/direnv-overlay.sh` that points to
`lib/direnv-overlay.sh` in the clone.

If you prefer a one-liner installer (no git clone), run the install script via
`curl | sh`:

```sh
curl -fsSL https://raw.githubusercontent.com/BeLeap/direnv-overlay/refs/heads/master/bin/install | sh
```

In `curl | sh` mode, the installer writes a standalone copy to
`~/.config/direnv/lib/direnv-overlay.sh`.

## Usage

In a project `.envrc`:

```sh
overlay foo
```

`overlay foo` resolves to `~/.direnv-overlay/foo/` by default. It supports this entry
point:

1. `~/.direnv-overlay/foo/.envrc`

Behavior:

- `.envrc` is sourced from inside the overlay directory, so relative paths resolve there
- the overlay directory is watched for changes so `direnv` reloads when files change
- missing overlays or a missing overlay `.envrc` fail with explicit errors
- tool-specific setup stays inside the overlay `.envrc`

Example overlay file:

```sh
use nix
layout python
PATH_add bin
```

Another overlay could use a different tool entirely:

```sh
PATH_add bin
eval "$(mise activate bash)"
```

You can override the root path with `DIRENV_OVERLAY_ROOT`.

```sh
export DIRENV_OVERLAY_ROOT="$HOME/.config/direnv/overlays"
overlay foo
```

Inside overlay scripts, these variables are available:

- `DIRENV_OVERLAY_NAME`
- `DIRENV_OVERLAY_DIR`

## Scope For Initial Implementation

The first useful version only needs to answer a small set of questions well:

- How does `overlay <name>` map to an overlay directory?
- Which files are supported inside an overlay?
- In what order are those files evaluated?
- What error message is shown when an overlay does not exist?
- How should the custom overlay directive integrate with normal `direnv` stdlib patterns?
