#!/usr/bin/env sh
set -eu

fail() {
  echo "agent-contract check failed: $1" >&2
  exit 1
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONTRACT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PROFILE=${1:-}
REPO_ROOT_INPUT=${2:-.}
REPO_ROOT=$(CDPATH= cd -- "$REPO_ROOT_INPUT" && pwd)
SHARED_PROFILE_FILE="$CONTRACT_DIR/repos/$PROFILE.env"

[ -n "$PROFILE" ] || fail "usage: check.sh <profile> [repo-root]"

find_local_profile() {
  dir=$1
  while :; do
    candidate="$dir/agent-contract-local/profiles/$PROFILE.env"
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    parent=$(dirname "$dir")
    if [ "$parent" = "$dir" ]; then
      return 1
    fi
    dir=$parent
  done
}

if LOCAL_PROFILE_FILE=$(find_local_profile "$REPO_ROOT"); then
  PROFILE_FILE=$LOCAL_PROFILE_FILE
elif [ -f "$SHARED_PROFILE_FILE" ]; then
  PROFILE_FILE=$SHARED_PROFILE_FILE
else
  fail "unknown profile: $PROFILE"
fi

# shellcheck disable=SC1090
. "$PROFILE_FILE"

check_required_path() {
  path=$1
  [ -e "$REPO_ROOT/$path" ] || fail "$PROFILE_NAME missing required path: $path"
}

check_forbidden_path() {
  path=$1
  [ ! -e "$REPO_ROOT/$path" ] || fail "$PROFILE_NAME has forbidden path: $path"
}

check_redirect_path() {
  path=$1
  if [ -e "$REPO_ROOT/$path" ] && [ ! -L "$REPO_ROOT/$path" ]; then
    fail "$PROFILE_NAME scratch path is not redirected: $path"
  fi
}

for path in $REQUIRED_PATHS; do
  check_required_path "$path"
done

for path in $FORBIDDEN_PATHS; do
  check_forbidden_path "$path"
done

for path in $SCRATCH_REDIRECT_PATHS; do
  check_redirect_path "$path"
done

echo "agent-contract check ($PROFILE_NAME): OK"
