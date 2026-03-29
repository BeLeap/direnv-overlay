#!/usr/bin/env bash

_direnv_overlay_error() {
  log_error "direnv-overlay: $*"
  return 1
}

_direnv_overlay_with_context() {
  local overlay_name="$1"
  local overlay_dir="$2"
  shift 2

  local had_name=0
  local had_dir=0
  local previous_name=""
  local previous_dir=""
  local status=0

  if [ "${DIRENV_OVERLAY_NAME+x}" = "x" ]; then
    had_name=1
    previous_name="$DIRENV_OVERLAY_NAME"
  fi

  if [ "${DIRENV_OVERLAY_DIR+x}" = "x" ]; then
    had_dir=1
    previous_dir="$DIRENV_OVERLAY_DIR"
  fi

  export DIRENV_OVERLAY_NAME="$overlay_name"
  export DIRENV_OVERLAY_DIR="$overlay_dir"

  "$@" || status=$?

  if [ "$had_name" -eq 1 ]; then
    export DIRENV_OVERLAY_NAME="$previous_name"
  else
    unset DIRENV_OVERLAY_NAME
  fi

  if [ "$had_dir" -eq 1 ]; then
    export DIRENV_OVERLAY_DIR="$previous_dir"
  else
    unset DIRENV_OVERLAY_DIR
  fi

  return "$status"
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

  if [ -f "$overlay_envrc" ]; then
    _direnv_overlay_with_context "$name" "$overlay_dir" \
      _direnv_overlay_run_in_dir "$overlay_dir" source_env "$overlay_envrc"
    return "$?"
  fi

  _direnv_overlay_error "overlay $name is missing .envrc: $overlay_envrc"
  return 1
}
