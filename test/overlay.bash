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
LAST_WATCH_FILE=""
log_error() {
  LAST_ERROR="$*"
}

watch_dir() {
  LAST_WATCH_DIR="$1"
}

watch_file() {
  LAST_WATCH_FILE="$1"
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

test_use_global_overlay_requires_no_args() {
  LAST_ERROR=""

  if use_global_overlay extra >/dev/null 2>&1; then
    echo "expected use_global_overlay with args to fail" >&2
    exit 1
  fi

  assert_contains "usage: use_global_overlay" "$LAST_ERROR"
}

test_use_global_overlay_noops_without_map() {
  local project_dir="$tmpdir/project-no-map"
  local home_dir="$tmpdir/home-no-map"

  mkdir -p "$project_dir" "$home_dir"
  HOME="$home_dir"
  LAST_WATCH_FILE=""
  LAST_ERROR=""
  unset OVERLAY_RESULT

  : >"$project_dir/.envrc"
  builtin cd "$project_dir"

  use_global_overlay

  assert_eq "" "${OVERLAY_RESULT:-}"
  assert_eq "" "$LAST_WATCH_FILE"
  assert_eq "" "$LAST_ERROR"
}

test_use_global_overlay_loads_repo_match() {
  local project_dir="$tmpdir/project-repo-match"
  local home_dir="$tmpdir/home-repo-match"
  local overlay_dir="$home_dir/.direnv-overlay/foo"
  local map_file="$home_dir/.direnv-overlay/overlays.map"

  mkdir -p "$project_dir" "$overlay_dir" "$(dirname "$map_file")"
  HOME="$home_dir"
  LAST_WATCH_DIR=""
  LAST_WATCH_FILE=""
  LAST_ERROR=""
  unset OVERLAY_RESULT

  : >"$project_dir/.envrc"
  cat >"$overlay_dir/.envrc" <<EOF
export OVERLAY_RESULT="\$PWD|\$DIRENV_OVERLAY_NAME|\$DIRENV_OVERLAY_DIR"
EOF
  cat >"$map_file" <<EOF
repo:project-repo-match => foo
EOF

  builtin cd "$project_dir"
  use_global_overlay

  assert_eq "$map_file" "$LAST_WATCH_FILE"
  assert_eq "$overlay_dir" "$LAST_WATCH_DIR"
  assert_eq "$overlay_dir|foo|$overlay_dir" "$OVERLAY_RESULT"
}

test_use_global_overlay_prefers_path_match() {
  local project_dir="$tmpdir/project-path-match"
  local home_dir="$tmpdir/home-path-match"
  local default_overlay_dir="$home_dir/.direnv-overlay/default"
  local specific_overlay_dir="$home_dir/.direnv-overlay/specific"
  local map_file="$home_dir/.direnv-overlay/overlays.map"

  mkdir -p "$project_dir" "$default_overlay_dir" "$specific_overlay_dir" "$(dirname "$map_file")"
  HOME="$home_dir"
  LAST_ERROR=""
  unset OVERLAY_RESULT

  : >"$project_dir/.envrc"
  cat >"$default_overlay_dir/.envrc" <<EOF
export OVERLAY_RESULT="default"
EOF
  cat >"$specific_overlay_dir/.envrc" <<EOF
export OVERLAY_RESULT="specific"
EOF
  cat >"$map_file" <<EOF
repo:project-path-match => default
path:$project_dir => specific
EOF

  builtin cd "$project_dir"
  use_global_overlay

  assert_eq "specific" "$OVERLAY_RESULT"
}

test_use_global_overlay_errors_on_invalid_mapping() {
  local project_dir="$tmpdir/project-invalid-map"
  local home_dir="$tmpdir/home-invalid-map"
  local map_file="$home_dir/.direnv-overlay/overlays.map"

  mkdir -p "$project_dir" "$(dirname "$map_file")"
  HOME="$home_dir"
  LAST_ERROR=""

  : >"$project_dir/.envrc"
  cat >"$map_file" <<EOF
this is not valid
EOF

  builtin cd "$project_dir"

  if use_global_overlay >/dev/null 2>&1; then
    echo "expected invalid mapping to fail" >&2
    exit 1
  fi

  assert_contains "invalid mapping entry" "$LAST_ERROR"
}

test_requires_one_name
test_rejects_nested_name
test_errors_when_overlay_missing
test_sources_overlay_envrc_in_overlay_directory
test_errors_when_overlay_has_no_entrypoint
test_use_global_overlay_requires_no_args
test_use_global_overlay_noops_without_map
test_use_global_overlay_loads_repo_match
test_use_global_overlay_prefers_path_match
test_use_global_overlay_errors_on_invalid_mapping

echo "ok"
