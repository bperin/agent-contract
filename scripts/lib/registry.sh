#!/usr/bin/env sh

registry_entries() {
  cat <<'ENTRIES'
claude|.claude
cursor|.cursor
gemini|.gemini
kilocode|.kilocode
kilo|.kilo
antigravity|.antigravity
roo|.roo
windsurf|.windsurf
docs-superpowers|docs/superpowers
ENTRIES
}

registry_scan_known_paths() {
  repo_root=$1
  find "$repo_root" \
    \( -path "$repo_root/.git" -o -path "$repo_root/.agent-scratch" -o -path "$repo_root/*/.git" -o -path "$repo_root/*/.agent-scratch" -o -path "$repo_root/*/node_modules" -o -path "$repo_root/*/.next" -o -path "$repo_root/*/dist" -o -path "$repo_root/*/.parcel-cache" \) -prune -o \
    \( -name '.claude' -o -name '.cursor' -o -name '.gemini' -o -name '.kilocode' -o -name '.kilo' -o -name '.antigravity' -o -name '.roo' -o -name '.windsurf' -o -path "$repo_root/docs/superpowers" -o -path "$repo_root/*/docs/superpowers" \) \
    -print | sed "s#^$repo_root/##" | sort -u
}

registry_managed_roots() {
  repo_root=$1
  printf '.\n'
  profile_print_lines MANAGED_WORKTREE_ROOTS
  find "$repo_root" -mindepth 2 -maxdepth 3 -name .git -type d | \
    sed "s#^$repo_root/##" | sed 's#/.git$##' | sort -u
}

registry_root_bucket() {
  root_rel=$1
  case "$root_rel" in
    .) printf 'root\n' ;;
    *) printf '%s\n' "$root_rel" ;;
  esac
}

registry_iter_bindings() {
  repo_root=$1
  scratch_sink=$2

  registry_managed_roots "$repo_root" | while IFS= read -r root_rel; do
    [ -n "$root_rel" ] || continue
    registry_entries | while IFS='|' read -r tool_name tool_path; do
      [ -n "$tool_name" ] || continue
      case "$root_rel" in
        .) source_rel=$tool_path ;;
        *) source_rel="$root_rel/$tool_path" ;;
      esac
      bucket=$(registry_root_bucket "$root_rel")
      target_abs="$repo_root/$scratch_sink/$bucket/$tool_name"
      printf '%s|%s|%s|%s\n' "$root_rel" "$tool_name" "$source_rel" "$target_abs"
    done
  done
}
