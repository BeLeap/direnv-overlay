#!/usr/bin/env bash

_direnv_overlay_error() {
  log_error "direnv-overlay: $*"
  return 1
}

_direnv_overlay_trim() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  printf '%s' "$value"
}

_direnv_overlay_config_home() {
  printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
}

_direnv_overlay_map_file() {
  local root="${DIRENV_OVERLAY_ROOT:-$HOME/.direnv-overlay}"
  printf '%s\n' "${DIRENV_OVERLAY_MAP_FILE:-${root%/}/overlays.map}"
}

_direnv_overlay_project_root() {
  local dir="$PWD"

  while [ -n "$dir" ]; do
    if [ -f "$dir/.envrc" ] || [ -d "$dir/.git" ] || [ -d "$dir/.jj" ]; then
      printf '%s\n' "$dir"
      return 0
    fi

    if [ "$dir" = "/" ]; then
      break
    fi

    dir=${dir%/*}

    if [ -z "$dir" ]; then
      dir="/"
    fi
  done

  return 1
}

_direnv_overlay_lookup_name() {
  local map_file
  local project_root
  local line=""
  local matcher=""
  local overlay_name=""
  local glob_pattern=""

  DIRENV_OVERLAY_MATCH=""
  map_file="$(_direnv_overlay_map_file)"

  if [ ! -f "$map_file" ]; then
    return 2
  fi

  project_root="$(_direnv_overlay_project_root)" || return 2
  watch_file "$map_file"

  while IFS= read -r line || [ -n "$line" ]; do
    line="$(_direnv_overlay_trim "$line")"

    case "$line" in
      ""|\#*)
        continue
        ;;
      *"=>"*)
        matcher="$(_direnv_overlay_trim "${line%%=>*}")"
        overlay_name="$(_direnv_overlay_trim "${line#*=>}")"
        ;;
      *)
        _direnv_overlay_error "invalid mapping entry: $line"
        return 1
        ;;
    esac

    if [ -z "$overlay_name" ]; then
      _direnv_overlay_error "mapping entry has empty overlay name: $line"
      return 1
    fi

    case "$matcher" in
      glob:*)
        glob_pattern="${matcher#glob:}"

        if [ -z "$glob_pattern" ]; then
          _direnv_overlay_error "glob mapping must not be empty: $line"
          return 1
        fi

        if [[ "$project_root" == $glob_pattern ]]; then
          DIRENV_OVERLAY_MATCH="$overlay_name"
          return 0
        fi
        ;;
      path:*|repo:*)
        _direnv_overlay_error "unsupported mapping key: $matcher (use glob:<pattern>)"
        return 1
        ;;
      *)
        _direnv_overlay_error "invalid mapping key: $matcher"
        return 1
        ;;
    esac
  done < "$map_file"

  return 2
}

_direnv_overlay_run_in_dir() {
  local overlay_dir="$1"
  shift

  local previous_pwd="$PWD"
  local status=0

  builtin cd "$overlay_dir" || return 1
  "$@" || status=$?
  builtin cd "$previous_pwd" || return 1

  return "$status"
}

overlay() {
  if [ "$#" -ne 1 ]; then
    _direnv_overlay_error "usage: overlay <name>"
    return 1
  fi

  local name="$1"
  local root="${DIRENV_OVERLAY_ROOT:-$HOME/.direnv-overlay}"
  local overlay_dir="${root%/}/$name"
  local overlay_envrc="$overlay_dir/.envrc"

  case "$name" in
    ""|.|..|*/*)
      _direnv_overlay_error "overlay name must be a single path segment: $name"
      return 1
      ;;
  esac

  if [ ! -d "$overlay_dir" ]; then
    _direnv_overlay_error "overlay not found: $overlay_dir"
    return 1
  fi

  watch_dir "$overlay_dir"
  export DIRENV_OVERLAY_NAME="$name"
  export DIRENV_OVERLAY_DIR="$overlay_dir"

  if [ -f "$overlay_envrc" ]; then
    _direnv_overlay_run_in_dir "$overlay_dir" source_env "$overlay_envrc"
    return "$?"
  fi

  _direnv_overlay_error "overlay $name is missing .envrc: $overlay_envrc"
  return 1
}

use_direnv_overlay() {
  local status=0

  if [ "$#" -ne 0 ]; then
    _direnv_overlay_error "usage: use_direnv_overlay"
    return 1
  fi

  _direnv_overlay_lookup_name || status=$?

  case "$status" in
    0)
      overlay "$DIRENV_OVERLAY_MATCH"
      ;;
    2)
      return 0
      ;;
    *)
      return "$status"
      ;;
  esac
}
