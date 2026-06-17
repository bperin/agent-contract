#!/usr/bin/env sh
set -eu

fail() {
  echo "agent-contract check failed: $1" >&2
  exit 1
}

PROFILE=${1:-}
REPO_ROOT_INPUT=${2:-.}
REPO_ROOT=$(CDPATH= cd -- "$REPO_ROOT_INPUT" && pwd)

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
else
  fail "missing local profile: agent-contract-local/profiles/$PROFILE.env"
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

check_required_text_match() {
  entry=$1
  file=${entry%%::*}
  pattern=${entry#*::}
  [ "$file" != "$pattern" ] || fail "$PROFILE_NAME invalid REQUIRED_TEXT_MATCHES entry: $entry"
  [ -f "$REPO_ROOT/$file" ] || fail "$PROFILE_NAME missing text-match file: $file"
  grep -F -- "$pattern" "$REPO_ROOT/$file" >/dev/null 2>&1 || \
    fail "$PROFILE_NAME missing required text match '$pattern' in $file"
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

OLD_IFS=$IFS
IFS='
'
for entry in ${REQUIRED_TEXT_MATCHES:-}; do
  [ -n "$entry" ] || continue
  check_required_text_match "$entry"
done
IFS=$OLD_IFS

echo "agent-contract check ($PROFILE_NAME): OK"
