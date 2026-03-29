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

1. A user installs a global `direnv` helper.
2. Their personal `direnvrc` calls `use_direnv_overlay`.
3. `direnv-overlay` matches the current project against a user-owned mapping file.
4. The selected overlay is resolved to a user-owned directory such as
   `~/.direnv-overlay/work-api/`.
5. That overlay's own `.envrc` is loaded and can choose whatever tools it wants to use.

This keeps overlay existence and overlay selection entirely out of upstream
repositories. Repositories do not need to declare an `overlay` hook at all.

## Desired Properties

- Personal overlays live outside the project working tree.
- Missing overlays should fail clearly, not silently.
- Shared project config and personal config stay separate.
- The mechanism should integrate with normal `direnv` global configuration.
- The interface should keep overlay selection in user-owned config, not project files.

## Example

Global `direnvrc`:

```sh
use_direnv_overlay
```

Personal mapping file:

```text
~/.direnv-overlay/overlays.map
```

```text
path:/Users/alice/src/work/api => work-api
repo:direnv-overlay => personal-dev
```

Personal overlay:

```text
~/.direnv-overlay/work-api/.envrc
```

Expected behavior when `direnv` evaluates inside `/Users/alice/src/work/api`:

- `use_direnv_overlay` reads `~/.direnv-overlay/overlays.map`
- `path:/Users/alice/src/work/api` matches first
- `work-api` resolves to `~/.direnv-overlay/work-api/`
- the overlay's `.envrc` is loaded
- the overlay can then decide for itself whether to use `nix`, `mise`, or something else
- nothing personal needs to be committed to the upstream repository

## Installation

`direnv` loads custom helpers from `~/.config/direnv/lib/*.sh` (or the matching
`$XDG_CONFIG_HOME` path). This project installs a standalone helper file there.

Recommended:

```sh
curl -fsSL https://raw.githubusercontent.com/BeLeap/direnv-overlay/refs/heads/master/bin/install | sh
```

This writes `~/.config/direnv/lib/direnv-overlay.sh`.

If you have a local checkout, running the installer there produces the same result:

```sh
bin/install
```

After installation, enable the matcher from your personal `direnvrc`:

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/direnv"
printf '%s\n' 'use_direnv_overlay' >> "${XDG_CONFIG_HOME:-$HOME/.config}/direnv/direnvrc"
```

To uninstall:

```sh
curl -fsSL https://raw.githubusercontent.com/BeLeap/direnv-overlay/refs/heads/master/bin/uninstall | sh
```

If you have a local checkout, `bin/uninstall` removes the same file.

## Usage

In your personal `direnvrc`:

```sh
use_direnv_overlay
```

`use_direnv_overlay` resolves the current project to an overlay name using
`~/.direnv-overlay/overlays.map` by default. You can override the file path with
`DIRENV_OVERLAY_MAP_FILE`.

Supported mapping entries:

- `path:/absolute/project/root => overlay-name`
- `repo:directory-name => overlay-name`

Lookup behavior:

- `path:` matches the detected project root exactly and has priority
- `repo:` matches the final path segment of the detected project root
- if there is no mapping, `use_direnv_overlay` does nothing
- invalid mapping lines fail explicitly

The detected overlay then resolves to `~/.direnv-overlay/<name>/` by default. It
supports this entry point:

1. `~/.direnv-overlay/foo/.envrc`

Behavior:

- the mapping file is watched so `direnv` reloads when it changes
- `.envrc` is sourced from inside the overlay directory, so relative paths resolve there
- the overlay directory is watched for changes so `direnv` reloads when files change
- missing overlays or a missing overlay `.envrc` fail with explicit errors
- tool-specific setup stays inside the overlay `.envrc`

Project root detection looks upward from `$PWD` for the nearest `.envrc`, `.git`, or
`.jj` directory.

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
use_direnv_overlay
```

When `DIRENV_OVERLAY_ROOT` is set, the default mapping path moves with it to
`$DIRENV_OVERLAY_ROOT/overlays.map`.

Inside overlay scripts, these variables are available:

- `DIRENV_OVERLAY_NAME`
- `DIRENV_OVERLAY_DIR`

## Limitations

`direnv` still needs to evaluate a directory somehow before global helpers run. In
practice that means the project must already participate in `direnv` evaluation, such as
having a `.envrc`. If a project has no `.envrc` at all, the overlay matcher has no entry
point and you will need a local, uncommitted `.envrc` to activate `direnv` there.

## Low-Level Helper

The explicit helper remains available:

```sh
overlay foo
```

That loads `~/.direnv-overlay/foo/.envrc` directly. It is useful for manual or legacy
setups, but the preferred interface is `use_direnv_overlay`.

## Scope For Initial Implementation

The first useful version only needs to answer a small set of questions well:

- How does the current project map to an overlay name?
- How does an overlay name map to an overlay directory?
- Which files are supported inside an overlay?
- What error message is shown when a mapping or overlay is invalid?
- How should the overlay matcher integrate with normal `direnv` stdlib patterns?
