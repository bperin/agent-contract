#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
CONTRACT_REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PROFILE_KEY=${1:-}
REPO_ROOT_INPUT=${2:-.}
[ -n "$PROFILE_KEY" ] || {
  echo "agent-contract doctor: usage: doctor.sh <profile> [repo-root]" >&2
  exit 1
}

# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/profile.sh"
profile_load "$PROFILE_KEY" "$REPO_ROOT_INPUT" "$CONTRACT_REPO_ROOT"

output_file=$(mktemp)
trap 'rm -f "$output_file"' EXIT HUP INT TERM

legacy_profiles=$(find "$CONSUMER_REPO_ROOT/agent-contract-local/profiles" -maxdepth 1 -name '*.env' | wc -l | tr -d ' ')

if sh "$SCRIPT_DIR/check.sh" "$PROFILE_KEY" "$REPO_ROOT_INPUT" >"$output_file" 2>&1; then
  echo "INFO  contract check passed"
  echo "INFO  generated adapter: $(profile_resolve_path "$GENERATED_AGENTS_PATH")"
  echo "INFO  scratch sink: $(profile_resolve_path "$SCRATCH_SINK")"
  if [ "$legacy_profiles" -gt 1 ]; then
    echo "WARN  additional profile files still exist under agent-contract-local/profiles; review whether they are legacy workflow overlays"
  fi
  cat "$output_file"
  exit 0
fi

echo "BLOCK contract check failed"
if [ "$legacy_profiles" -gt 1 ]; then
  echo "WARN  additional profile files still exist under agent-contract-local/profiles; they may still look authoritative to new agents"
fi
sed 's/^/BLOCK /' "$output_file"
exit 1
