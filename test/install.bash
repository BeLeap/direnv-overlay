#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

assert_eq() {
  if [ "$1" != "$2" ]; then
    printf 'assert_eq failed\nexpected: %s\nactual: %s\n' "$1" "$2" >&2
    exit 1
  fi
}

test_install_replaces_existing_file_with_embedded_copy() {
  local config_home="$tmpdir/config-file"
  local target_file="$config_home/direnv/lib/direnv-overlay.sh"

  mkdir -p "$(dirname "$target_file")"
  printf 'old contents\n' >"$target_file"

  XDG_CONFIG_HOME="$config_home" "$repo_root/bin/install" >/dev/null

  if [ -L "$target_file" ]; then
    echo "expected install to create a regular file" >&2
    exit 1
  fi

  if [ ! -f "$target_file" ]; then
    echo "expected install to create a file" >&2
    exit 1
  fi
}

test_install_replaces_existing_symlink_without_touching_repo_file() {
  local config_home="$tmpdir/config-symlink"
  local target_file="$config_home/direnv/lib/direnv-overlay.sh"
  local before_sha=""
  local after_sha=""

  mkdir -p "$(dirname "$target_file")"
  ln -s "$repo_root/lib/direnv-overlay.sh" "$target_file"

  before_sha=$(shasum -a 256 "$repo_root/lib/direnv-overlay.sh")
  XDG_CONFIG_HOME="$config_home" "$repo_root/bin/install" >/dev/null
  after_sha=$(shasum -a 256 "$repo_root/lib/direnv-overlay.sh")

  if [ -L "$target_file" ]; then
    echo "expected install to replace symlink with regular file" >&2
    exit 1
  fi

  if [ ! -f "$target_file" ]; then
    echo "expected install to create a file" >&2
    exit 1
  fi

  assert_eq "$before_sha" "$after_sha"
}

test_install_replaces_existing_file_with_embedded_copy
test_install_replaces_existing_symlink_without_touching_repo_file

echo "ok"
