# direnv-overlay

`direnv-overlay` keeps personal `direnv` setup out of upstream repositories.

Instead of committing user-specific `.envrc` changes into each project, you install a
global helper once and keep per-project overlays under a user-owned directory such as
`~/.direnv-overlay/`.

## Quick Start

Install the helper:

```sh
curl -fsSL https://raw.githubusercontent.com/BeLeap/direnv-overlay/master/bin/install | sh
```

Enable it from your global `direnvrc`:

```sh
use_direnv_overlay
```

Create the overlay root and a mapping file:

```sh
mkdir -p ~/.direnv-overlay/work-api
cat > ~/.direnv-overlay/overlays.map <<'EOF'
repo:api => work-api
EOF
```

Create the overlay entrypoint:

```sh
cat > ~/.direnv-overlay/work-api/.envrc <<'EOF'
use nix
PATH_add bin
EOF
```

Now entering a project whose detected repo name is `api` will load that overlay.

## Install

Install the helper:

```sh
curl -fsSL https://raw.githubusercontent.com/BeLeap/direnv-overlay/master/bin/install | sh
```

This writes a standalone helper file to:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/direnv/lib/direnv-overlay.sh
```

If you want to remove it later:

```sh
curl -fsSL https://raw.githubusercontent.com/BeLeap/direnv-overlay/master/bin/uninstall | sh
```

If you already have the repository checked out, you can run the same installers
locally instead:

```sh
./bin/install
./bin/uninstall
```

## Home Manager

If you use Nix with Home Manager, this repository also exposes a reusable module.

From a flake input:

```nix
{
  inputs.direnv-overlay.url = "github:BeLeap/direnv-overlay";

  outputs = { nixpkgs, home-manager, direnv-overlay, ... }: {
    homeConfigurations.alice = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      modules = [
        direnv-overlay.homeManagerModules.default
        {
          programs.direnv.enable = true;
          programs.direnv-overlay = {
            enable = true;
            overlayRoot = "\${config.home.homeDirectory}/.direnv-overlay";
          };
        }
      ];
    };
  };
}
```

This module:

- installs the helper into `~/.config/direnv/lib/direnv-overlay.sh`
- appends `use_direnv_overlay` to Home Manager's `programs.direnv.stdlib`
- optionally exports `DIRENV_OVERLAY_ROOT` and `DIRENV_OVERLAY_MAP_FILE`

The flake also exposes a package at `packages.<system>.default`.

## Overlay Setup

The default mapping file is:

```text
~/.direnv-overlay/overlays.map
```

Overlay names resolve under:

```text
~/.direnv-overlay/<name>/
```

Each overlay must contain:

```text
~/.direnv-overlay/<name>/.envrc
```

Example:

```text
repo:api => work-api
```

```sh
use nix
PATH_add bin
```

## Mapping Rules

Supported entries:

```text
path:/absolute/project/path => overlay-name
repo:repository-directory-name => overlay-name
```

Example:

```text
path:/Users/alice/src/work/api => work-api
repo:direnv-overlay => personal-dev
```

Behavior:

- `path:` matches the detected project root exactly.
- `repo:` matches the final path segment of the detected project root.
- `path:` takes priority over `repo:`.
- blank lines and `#` comments are ignored.
- invalid mapping lines fail explicitly.
- if no mapping matches, `use_direnv_overlay` does nothing.

## How It Works

1. Install the helper into your global `direnv` lib directory.
2. Call `use_direnv_overlay` from your global `direnvrc`.
3. Keep a personal mapping file at `~/.direnv-overlay/overlays.map`.
4. Map a project path or repo name to an overlay name.
5. Put that overlay's `.envrc` in `~/.direnv-overlay/<name>/.envrc`.

When `direnv` evaluates a project, `direnv-overlay` finds the matching overlay and
loads that overlay's `.envrc` from the overlay directory.

## Why

Projects often need local-only `direnv` customizations:

- `use nix`
- `mise` activation
- extra environment variables
- personal tool paths

Those settings are often useful for one developer, but noisy or inappropriate to commit
upstream. `direnv-overlay` separates shared project config from personal machine config.

## Overlay Details

Example overlay:

```sh
use nix
layout python
PATH_add bin
```

Another overlay can use different tooling entirely:

```sh
PATH_add bin
eval "$(mise activate bash)"
```

When an overlay is loaded:

- the overlay directory is watched for changes
- the overlay `.envrc` is sourced from inside the overlay directory
- relative paths inside the overlay resolve from that overlay directory
- `DIRENV_OVERLAY_NAME` and `DIRENV_OVERLAY_DIR` are exported to indicate the active overlay

## Project Detection

`use_direnv_overlay` detects the project root by walking upward from `$PWD` until it
finds the nearest one of:

- `.envrc`
- `.git/`
- `.jj/`

That detected root is what `path:` and `repo:` matching uses.

## Configuration

You can move the overlay root with `DIRENV_OVERLAY_ROOT`:

```sh
export DIRENV_OVERLAY_ROOT="$HOME/.config/direnv/overlays"
use_direnv_overlay
```

When set, overlays resolve under that directory and the default map file becomes:

```text
$DIRENV_OVERLAY_ROOT/overlays.map
```

You can also override the mapping file directly:

```sh
export DIRENV_OVERLAY_MAP_FILE="$HOME/.config/direnv/overlays/projects.map"
use_direnv_overlay
```

## Errors

`direnv-overlay` fails explicitly for invalid states, including:

- invalid mapping entries
- invalid overlay names
- missing overlay directories
- missing overlay `.envrc`
- incorrect helper usage

If the mapping file is missing, or no project matches, `use_direnv_overlay` exits
cleanly without loading anything.

## Limitations

`direnv-overlay` still needs `direnv` to evaluate the directory in the first place. In
practice, that usually means the project already has a `.envrc`, or you keep a local,
uncommitted `.envrc` as an entrypoint for `direnv`.

## Low-Level Helper

The lower-level helper is still available:

```sh
overlay foo
```

That directly loads `~/.direnv-overlay/foo/.envrc` and is useful for manual or legacy
setups. For normal use, prefer `use_direnv_overlay`.
