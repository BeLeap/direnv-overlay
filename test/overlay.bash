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

assert_contains() {
  case "$2" in
    *"$1"*) ;;
    *)
      printf 'assert_contains failed\nneedle: %s\nhaystack: %s\n' "$1" "$2" >&2
      exit 1
      ;;
  esac
}

LAST_ERROR=""
LAST_WATCH_DIR=""
log_error() {
  LAST_ERROR="$*"
}

watch_dir() {
  LAST_WATCH_DIR="$1"
}

source_env() {
  source "$1"
}

source "$repo_root/lib/direnv-overlay.sh"

test_requires_one_name() {
  if overlay >/dev/null 2>&1; then
    echo "expected overlay with no args to fail" >&2
    exit 1
  fi

  assert_contains "usage: overlay <name>" "$LAST_ERROR"
}

test_rejects_nested_name() {
  LAST_ERROR=""
  if overlay foo/bar >/dev/null 2>&1; then
    echo "expected nested overlay name to fail" >&2
    exit 1
  fi

  assert_contains "single path segment" "$LAST_ERROR"
}

test_errors_when_overlay_missing() {
  LAST_ERROR=""
  HOME="$tmpdir/home"
  mkdir -p "$HOME"

  if overlay missing >/dev/null 2>&1; then
    echo "expected missing overlay to fail" >&2
    exit 1
  fi

  assert_contains "overlay not found" "$LAST_ERROR"
}

test_sources_overlay_envrc_in_overlay_directory() {
  local project_dir="$tmpdir/project-envrc"
  local home_dir="$tmpdir/home-envrc"
  local overlay_dir="$home_dir/.direnv-overlay/foo"

  mkdir -p "$project_dir" "$overlay_dir"
  HOME="$home_dir"
  LAST_WATCH_DIR=""

  cat >"$overlay_dir/.envrc" <<EOF
export OVERLAY_RESULT="\$PWD|\$DIRENV_OVERLAY_NAME|\$DIRENV_OVERLAY_DIR"
EOF

  builtin cd "$project_dir"
  overlay foo
  assert_eq "$project_dir" "$PWD"
  assert_eq "$overlay_dir" "$LAST_WATCH_DIR"
  assert_eq "$overlay_dir|foo|$overlay_dir" "$OVERLAY_RESULT"
}

test_errors_when_overlay_has_no_entrypoint() {
  local home_dir="$tmpdir/home-empty"
  local overlay_dir="$home_dir/.direnv-overlay/empty"

  mkdir -p "$overlay_dir"
  HOME="$home_dir"
  LAST_ERROR=""

  if overlay empty >/dev/null 2>&1; then
    echo "expected overlay without supported files to fail" >&2
    exit 1
  fi

  assert_contains "missing .envrc" "$LAST_ERROR"
}

test_requires_one_name
test_rejects_nested_name
test_errors_when_overlay_missing
test_sources_overlay_envrc_in_overlay_directory
test_errors_when_overlay_has_no_entrypoint

echo "ok"
