#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
QDRANT_SCRIPT="$SCRIPT_DIR/qdrant_memory.sh"

[ -x "$QDRANT_SCRIPT" ] || {
  echo "missing executable script: $QDRANT_SCRIPT" >&2
  exit 1
}

export QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"
export QDRANT_COLLECTION="agent_workflow_memory_test_$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')"

cleanup() {
  curl -sS -o /dev/null -X DELETE \
    "$QDRANT_URL/collections/$QDRANT_COLLECTION?timeout=10" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

assert_eq() {
  expected=$1
  actual=$2
  message=$3
  if [ "$expected" != "$actual" ]; then
    echo "assertion failed: $message (expected=$expected actual=$actual)" >&2
    exit 1
  fi
}

assert_fails() {
  message=$1
  shift
  if "$@" >/dev/null 2>&1; then
    echo "assertion failed: $message" >&2
    exit 1
  fi
}

assert_fails "list should fail before the collection exists" \
  sh "$QDRANT_SCRIPT" list proposed shared_pattern trakt2

sh "$QDRANT_SCRIPT" init >/dev/null

proposal_json=$(sh "$QDRANT_SCRIPT" propose \
  trakt2 \
  trakt2 \
  workflow \
  "Control-plane authority chain" \
  "/Users/brian/code/trakt2/docs/MASTER_PLAN.md")

memory_id=$(printf '%s' "$proposal_json" | jq -r '.memory_id')
proposal_status=$(printf '%s' "$proposal_json" | jq -r '.status')

assert_eq "proposed" "$proposal_status" "proposal status should default to proposed"

second_proposal_json=$(sh "$QDRANT_SCRIPT" propose \
  trakt2 \
  trakt2 \
  workflow \
  "Nested repo workflow guardrails" \
  "/Users/brian/code/trakt2/AGENTS.md")

second_memory_id=$(printf '%s' "$second_proposal_json" | jq -r '.memory_id')

proposed_count=$(QDRANT_LIST_PAGE_LIMIT=1 sh "$QDRANT_SCRIPT" list proposed shared_pattern trakt2 | jq '.records | length')
assert_eq "2" "$proposed_count" "proposed list should include all paginated records"

approved_before=$(sh "$QDRANT_SCRIPT" list approved shared_pattern trakt2 | jq '.records | length')
assert_eq "0" "$approved_before" "approved list should be empty before approval"

approval_json=$(sh "$QDRANT_SCRIPT" approve "$memory_id")
approved_status=$(printf '%s' "$approval_json" | jq -r '.status')
assert_eq "approved" "$approved_status" "approve should flip the record status"

assert_fails "approve should fail for a nonexistent id" \
  sh "$QDRANT_SCRIPT" approve "00000000-0000-0000-0000-000000000000"

approved_after=$(sh "$QDRANT_SCRIPT" list approved shared_pattern trakt2 | jq '.records | length')
assert_eq "1" "$approved_after" "approved list should contain the approved record"

sh "$QDRANT_SCRIPT" reset >/dev/null

post_reset_count=$(sh "$QDRANT_SCRIPT" list approved shared_pattern trakt2 | jq '.records | length')
assert_eq "0" "$post_reset_count" "reset should clear the managed collection"

post_reset_proposed_count=$(sh "$QDRANT_SCRIPT" list proposed shared_pattern trakt2 | jq '.records | length')
assert_eq "0" "$post_reset_proposed_count" "reset should clear proposed records as well"

assert_fails "approve should fail after reset when the id no longer exists" \
  sh "$QDRANT_SCRIPT" approve "$second_memory_id"

echo "qdrant memory smoke test: OK"
