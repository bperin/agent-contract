#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
CONTRACT_REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/profile.sh"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/registry.sh"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/render.sh"

PROFILE_KEY=${1:-}
REPO_ROOT_INPUT=${2:-.}
[ -n "$PROFILE_KEY" ] || profile_fail "usage: apply.sh <profile> [repo-root]"

profile_load "$PROFILE_KEY" "$REPO_ROOT_INPUT" "$CONTRACT_REPO_ROOT"

report_line() {
  printf '%s\n' "$1"
}

ensure_directory() {
  target_dir=$1
  [ -d "$target_dir" ] || mkdir -p "$target_dir"
}

reconcile_binding() {
  source_rel=$1
  target_abs=$2
  source_abs="$CONSUMER_REPO_ROOT/$source_rel"
  ensure_directory "$(dirname "$source_abs")"

  if [ -L "$source_abs" ]; then
    ensure_directory "$target_abs"
    current_target=$(readlink "$source_abs")
    if [ "$current_target" = "$target_abs" ]; then
      report_line "OK   $source_rel -> $target_abs"
      return 0
    fi
    rm -f "$source_abs"
    ln -s "$target_abs" "$source_abs"
    report_line "LINK $source_rel -> $target_abs"
    return 0
  fi

  if [ -e "$source_abs" ]; then
    ensure_directory "$(dirname "$target_abs")"
    if [ -e "$target_abs" ]; then
      profile_fail "managed target already contains data for $source_rel: $target_abs"
    fi
    mv "$source_abs" "$target_abs"
    ln -s "$target_abs" "$source_abs"
    report_line "MOVE $source_rel -> $target_abs"
    return 0
  fi

  ensure_directory "$target_abs"
  ln -s "$target_abs" "$source_abs"
  report_line "INIT $source_rel -> $target_abs"
}

remove_disabled_root_binding() {
  tool_name=$1
  tool_path=$2
  source_abs="$CONSUMER_REPO_ROOT/$tool_path"
  target_abs="$CONSUMER_REPO_ROOT/$SCRATCH_SINK/root/$tool_name"

  if [ ! -L "$source_abs" ]; then
    return 0
  fi

  current_target=$(readlink "$source_abs")
  if [ "$current_target" = "$target_abs" ]; then
    rm -f "$source_abs"
    report_line "REMOVE $tool_path"
  fi
}

agents_target=$(profile_resolve_path "$GENERATED_AGENTS_PATH")
agents_tmp=$(mktemp)
trap 'rm -f "$agents_tmp"' EXIT HUP INT TERM
render_agents > "$agents_tmp"

ensure_directory "$(profile_resolve_path "$SCRATCH_SINK")"
case "${MANAGE_REPO_ROOT_SCRATCH:-true}" in
  false|0|no|off)
    registry_entries | while IFS='|' read -r tool_name tool_path; do
      remove_disabled_root_binding "$tool_name" "$tool_path"
    done
    ;;
esac
registry_iter_bindings "$CONSUMER_REPO_ROOT" "$SCRATCH_SINK" | while IFS='|' read -r _root_rel _tool_name source_rel target_abs; do
  reconcile_binding "$source_rel" "$target_abs"
done

ensure_directory "$(dirname "$agents_target")"
mv "$agents_tmp" "$agents_target"
trap - EXIT HUP INT TERM
report_line "WRITE $GENERATED_AGENTS_PATH"
