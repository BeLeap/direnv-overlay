#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

config_home="$tmpdir/config"
target_file="$config_home/direnv/lib/direnv-overlay.sh"

mkdir -p "$(dirname "$target_file")"
cp "$repo_root/lib/direnv-overlay.sh" "$target_file"

XDG_CONFIG_HOME="$config_home" "$repo_root/bin/uninstall"

if [ -e "$target_file" ]; then
  echo "expected uninstall to remove target file" >&2
  exit 1
fi

if XDG_CONFIG_HOME="$config_home" "$repo_root/bin/uninstall" >/dev/null 2>&1; then
  echo "expected uninstall with missing target to fail" >&2
  exit 1
fi

echo "ok"
