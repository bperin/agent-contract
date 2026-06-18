#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
CONTRACT_REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/profile.sh"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/registry.sh"

PROFILE_KEY=${1:-}
REPO_ROOT_INPUT=${2:-.}
[ -n "$PROFILE_KEY" ] || profile_fail "usage: migrate.sh <profile> [repo-root]"

profile_load "$PROFILE_KEY" "$REPO_ROOT_INPUT" "$CONTRACT_REPO_ROOT"

report_line() {
  printf '%s\n' "$1"
}

ensure_directory() {
  target_dir=$1
  if [ -d "$target_dir" ]; then
    return 0
  fi
  mkdir -p "$target_dir"
}

ensure_declared_directory() {
  path_value=$1
  abs_path=$(profile_resolve_path "$path_value")
  if [ -d "$abs_path" ]; then
    report_line "OK   $path_value"
    return 0
  fi
  mkdir -p "$abs_path"
  report_line "MKDIR $path_value"
}

ensure_master_plan_parent() {
  abs_path=$(profile_resolve_path "$MASTER_PLAN_PATH")
  ensure_directory "$(dirname "$abs_path")"
  if [ -e "$abs_path" ]; then
    report_line "OK   $MASTER_PLAN_PATH"
    return 0
  fi
  report_line "WARN $MASTER_PLAN_PATH missing; create the canonical master plan before expecting check.sh to pass"
}

repair_managed_root_gitignore() {
  managed_roots=$(mktemp)
  remove_lines=$(mktemp)
  add_lines=$(mktemp)
  filtered=$(mktemp)
  trap 'rm -f "$managed_roots" "$remove_lines" "$add_lines" "$filtered"' EXIT HUP INT TERM

  profile_print_lines MANAGED_WORKTREE_ROOTS > "$managed_roots"
  if [ ! -s "$managed_roots" ]; then
    rm -f "$managed_roots" "$remove_lines" "$add_lines" "$filtered"
    trap - EXIT HUP INT TERM
    report_line "SKIP .gitignore managed-root repair"
    return 0
  fi

  while IFS= read -r root_rel; do
    [ -n "$root_rel" ] || continue
    printf '%s\n' "$root_rel" >> "$remove_lines"
    printf '/%s\n' "$root_rel" >> "$remove_lines"
    printf '%s/\n' "$root_rel" >> "$remove_lines"
    printf '/%s/\n' "$root_rel" >> "$remove_lines"
    registry_entries | while IFS='|' read -r _tool_name tool_path; do
      printf '/%s/%s\n' "$root_rel" "$tool_path" >> "$add_lines"
    done
  done < "$managed_roots"

  gitignore_path="$CONSUMER_REPO_ROOT/.gitignore"
  [ -f "$gitignore_path" ] || : > "$gitignore_path"

  changed=0
  : > "$filtered"
  while IFS= read -r line || [ -n "$line" ]; do
    if grep -Fx -- "$line" "$remove_lines" >/dev/null 2>&1; then
      changed=1
      continue
    fi
    printf '%s\n' "$line" >> "$filtered"
  done < "$gitignore_path"

  appended=0
  while IFS= read -r ignore_line; do
    [ -n "$ignore_line" ] || continue
    if grep -Fx -- "$ignore_line" "$filtered" >/dev/null 2>&1; then
      continue
    fi
    if [ "$appended" -eq 0 ]; then
      if [ -s "$filtered" ]; then
        printf '\n' >> "$filtered"
      fi
      if ! grep -Fx -- '# agent-contract managed worktree scratch' "$filtered" >/dev/null 2>&1; then
        printf '%s\n' '# agent-contract managed worktree scratch' >> "$filtered"
      fi
    fi
    printf '%s\n' "$ignore_line" >> "$filtered"
    appended=$((appended + 1))
    changed=1
  done < "$add_lines"

  if [ "$changed" -eq 1 ]; then
    mv "$filtered" "$gitignore_path"
    report_line "WRITE .gitignore"
  else
    rm -f "$filtered"
    report_line "OK   .gitignore"
  fi

  rm -f "$managed_roots" "$remove_lines" "$add_lines"
  trap - EXIT HUP INT TERM
}

profile_print_lines TASK_PATHS | while IFS= read -r path_value; do
  ensure_declared_directory "$path_value"
done
profile_print_lines PLAN_PATHS | while IFS= read -r path_value; do
  ensure_declared_directory "$path_value"
done
profile_print_lines ARCHITECTURE_PATHS | while IFS= read -r path_value; do
  ensure_declared_directory "$path_value"
done

ensure_master_plan_parent
ensure_directory "$(profile_resolve_path "$SCRATCH_SINK")"
repair_managed_root_gitignore

sh "$SCRIPT_DIR/apply.sh" "$PROFILE_KEY" "$CONSUMER_REPO_ROOT"
sh "$SCRIPT_DIR/check.sh" "$PROFILE_KEY" "$CONSUMER_REPO_ROOT"
