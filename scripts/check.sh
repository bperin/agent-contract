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
[ -n "$PROFILE_KEY" ] || profile_fail "usage: check.sh <profile> [repo-root]"

profile_load "$PROFILE_KEY" "$REPO_ROOT_INPUT" "$CONTRACT_REPO_ROOT"

require_existing_path() {
  path_value=$1
  abs_path=$(profile_resolve_path "$path_value")
  [ -e "$abs_path" ] || profile_fail "$PROFILE_NAME missing required path: $path_value"
}

profile_print_lines TASK_PATHS | while IFS= read -r path_value; do require_existing_path "$path_value"; done
profile_print_lines PLAN_PATHS | while IFS= read -r path_value; do require_existing_path "$path_value"; done
profile_print_lines ARCHITECTURE_PATHS | while IFS= read -r path_value; do require_existing_path "$path_value"; done
require_existing_path "$MASTER_PLAN_PATH"
require_existing_path "$SHARED_CONTRACT_PATH"
require_existing_path "$SCRATCH_SINK"

profile_print_lines FORBIDDEN_PATHS | while IFS= read -r path_value; do
  [ ! -e "$(profile_resolve_path "$path_value")" ] || profile_fail "$PROFILE_NAME has forbidden path: $path_value"
done

path_under_dir() {
  child=$1
  parent=$2
  case "$child" in
    "$parent"|"$parent"/*) return 0 ;;
    *) return 1 ;;
  esac
}

relpath_from_dir() {
  child=$1
  parent=$2
  case "$child" in
    "$parent") printf '%s\n' "." ;;
    "$parent"/*) printf '%s\n' "${child#"$parent"/}" ;;
    *) return 1 ;;
  esac
}

task_status_from_head() {
  git_root=$1
  rel_path=$2
  git -C "$git_root" show "HEAD:$rel_path" 2>/dev/null | awk '
    /^status:[[:space:]]*/ {
      sub(/^status:[[:space:]]*/, "", $0)
      print $0
      exit
    }
  '
}

check_deleted_task_guard_for_git_root() {
  git_root=$1
  profile_print_lines TASK_PATHS | while IFS= read -r task_path; do
    task_abs=$(profile_resolve_path "$task_path")
    path_under_dir "$task_abs" "$git_root" || continue
    task_rel=$(relpath_from_dir "$task_abs" "$git_root") || continue
    git -C "$git_root" diff --name-only --diff-filter=D HEAD -- "$task_rel" | while IFS= read -r rel_path; do
      case "$rel_path" in
        *.md) ;;
        *) continue ;;
      esac
      previous_status=$(task_status_from_head "$git_root" "$rel_path")
      [ "$previous_status" = "completed" ] || \
        profile_fail "$PROFILE_NAME deleted task was not completed in last committed state: $rel_path (status: ${previous_status:-missing})"
    done
  done
}

seen_git_roots=$(mktemp)
trap 'rm -f "$seen_git_roots"' EXIT HUP INT TERM
{
  if git -C "$CONSUMER_REPO_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
    git_top=$(git -C "$CONSUMER_REPO_ROOT" rev-parse --show-toplevel)
    profile_resolve_dir "$git_top"
  fi
  find "$CONSUMER_REPO_ROOT" \
    \( -path "$CONSUMER_REPO_ROOT/.git" -o -path "$CONSUMER_REPO_ROOT/.agent-scratch" \) -prune -o \
    -name .git -type d -print | while IFS= read -r git_dir; do
      profile_resolve_dir "$(dirname "$git_dir")"
    done
} | sort -u > "$seen_git_roots"

while IFS= read -r git_root; do
  [ -n "$git_root" ] || continue
  check_deleted_task_guard_for_git_root "$git_root"
done < "$seen_git_roots"

expected_agents=$(mktemp)
trap 'rm -f "$seen_git_roots" "$expected_agents"' EXIT HUP INT TERM
render_agents > "$expected_agents"
actual_agents=$(profile_resolve_path "$GENERATED_AGENTS_PATH")
cmp -s "$expected_agents" "$actual_agents" || profile_fail "$PROFILE_NAME generated AGENTS drifted: $GENERATED_AGENTS_PATH"

registry_iter_bindings "$CONSUMER_REPO_ROOT" "$SCRATCH_SINK" | while IFS='|' read -r _root_rel _tool_name source_rel target_abs; do
  source_abs="$CONSUMER_REPO_ROOT/$source_rel"
  [ -L "$source_abs" ] || profile_fail "$PROFILE_NAME scratch path is not redirected: $source_rel"
  current_target=$(readlink "$source_abs")
  [ "$current_target" = "$target_abs" ] || profile_fail "$PROFILE_NAME scratch path points at wrong target: $source_rel -> $current_target"
  [ -d "$target_abs" ] || profile_fail "$PROFILE_NAME scratch sink target missing: $target_abs"
done

expected_paths=$(mktemp)
trap 'rm -f "$seen_git_roots" "$expected_agents" "$expected_paths"' EXIT HUP INT TERM
registry_iter_bindings "$CONSUMER_REPO_ROOT" "$SCRATCH_SINK" | while IFS='|' read -r _root_rel _tool_name source_rel _target_abs; do
  printf '%s\n' "$source_rel"
done | sort -u > "$expected_paths"

registry_scan_known_paths "$CONSUMER_REPO_ROOT" | while IFS= read -r found_rel; do
    [ -n "$found_rel" ] || continue
    grep -Fx -- "$found_rel" "$expected_paths" >/dev/null 2>&1 || \
      profile_fail "$PROFILE_NAME unmanaged known scratch path detected: $found_rel"
  done

allowed_control_plane=$(mktemp)
trap 'rm -f "$seen_git_roots" "$expected_agents" "$expected_paths" "$allowed_control_plane"' EXIT HUP INT TERM
{
  profile_print_lines TASK_PATHS
  profile_print_lines PLAN_PATHS
} | sort -u > "$allowed_control_plane"

find "$CONSUMER_REPO_ROOT" \( -path "$CONSUMER_REPO_ROOT/.git" -o -path "$CONSUMER_REPO_ROOT/.agent-scratch" \) -prune -o \( -path '*/docs/tasks' -o -path '*/docs/plans' \) -type d -print | \
  sed "s#^$CONSUMER_REPO_ROOT/##" | sort -u | while IFS= read -r control_rel; do
    [ -n "$control_rel" ] || continue
    grep -Fx -- "$control_rel" "$allowed_control_plane" >/dev/null 2>&1 || \
      profile_fail "$PROFILE_NAME rogue task/plan surface detected: $control_rel"
  done

echo "agent-contract check ($PROFILE_NAME): OK"
