#!/usr/bin/env sh
set -eu

QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"
QDRANT_COLLECTION="${QDRANT_COLLECTION:-agent_workflow_memory_v1}"

fail() {
  echo "qdrant memory error: $1" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_managed_collection() {
  case "$QDRANT_COLLECTION" in
    agent_workflow_memory*) ;;
    *)
      fail "managed collection must start with agent_workflow_memory: $QDRANT_COLLECTION"
      ;;
  esac
}

timestamp_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

normalize_uuid() {
  uuidgen | tr '[:upper:]' '[:lower:]'
}

request() {
  method=$1
  path=$2
  body=${3-}
  response_file=$(mktemp) || fail "failed to create temporary response file"
  status_code=
  curl_exit=0

  if [ -n "$body" ]; then
    set +e
    status_code=$(
      curl -sS -o "$response_file" -w "%{http_code}" \
        -X "$method" \
        -H "Content-Type: application/json" \
        --data-binary "$body" \
        "$QDRANT_URL$path"
    )
    curl_exit=$?
    set -e
  else
    set +e
    status_code=$(
      curl -sS -o "$response_file" -w "%{http_code}" \
        -X "$method" \
        "$QDRANT_URL$path"
    )
    curl_exit=$?
    set -e
  fi

  if [ "$curl_exit" -ne 0 ]; then
    rm -f "$response_file"
    fail "request failed: $method $path (curl_exit=$curl_exit)"
  fi

  case "$status_code" in
    2??) cat "$response_file" ;;
    *)
      cat "$response_file" >&2
      rm -f "$response_file"
      fail "request failed: $method $path (status=$status_code)"
      ;;
  esac

  rm -f "$response_file"
}

collection_exists() {
  status_code=$(
    curl -sS -o /dev/null -w "%{http_code}" \
      "$QDRANT_URL/collections/$QDRANT_COLLECTION"
  )
  [ "$status_code" = "200" ]
}

init_collection() {
  request PUT "/collections/$QDRANT_COLLECTION?timeout=10" \
    '{"vectors":{"size":1,"distance":"Cosine"}}' >/dev/null
}

ensure_collection() {
  if ! collection_exists; then
    init_collection
  fi
}

require_collection() {
  collection_exists || fail "managed collection does not exist: $QDRANT_COLLECTION"
}

lookup_record() {
  memory_id=$1
  filter_json=$(
    jq -nc \
      --arg memory_id "$memory_id" \
      '{
        must: [
          {key: "memory_id", match: {value: $memory_id}}
        ]
      }'
  )
  body=$(
    jq -nc \
      --argjson filter "$filter_json" \
      '{
        with_payload: true,
        with_vector: false,
        limit: 1,
        filter: $filter
      }'
  )
  response=$(request POST "/collections/$QDRANT_COLLECTION/points/scroll" "$body")
  printf '%s' "$response" | jq -c '.result.points[0] // null'
}

reset_collection() {
  if collection_exists; then
    request DELETE "/collections/$QDRANT_COLLECTION?timeout=10" >/dev/null
  fi
  init_collection
}

propose_record() {
  [ "$#" -eq 5 ] || fail "usage: propose <workspace_id> <repo_id> <concept_type> <summary> <canonical_uri>"
  ensure_collection

  workspace_id=$1
  repo_id=$2
  concept_type=$3
  summary=$4
  canonical_uri=$5
  memory_id=$(normalize_uuid)
  created_at=$(timestamp_utc)

  body=$(
    jq -nc \
      --arg id "$memory_id" \
      --arg workspace_id "$workspace_id" \
      --arg repo_id "$repo_id" \
      --arg concept_type "$concept_type" \
      --arg summary "$summary" \
      --arg canonical_uri "$canonical_uri" \
      --arg created_at "$created_at" \
      '{
        points: [
          {
            id: $id,
            vector: [1],
            payload: {
              memory_id: $id,
              memory_scope: "shared_pattern",
              workspace_id: $workspace_id,
              repo_id: $repo_id,
              concept_type: $concept_type,
              summary: $summary,
              canonical_uri: $canonical_uri,
              status: "proposed",
              authority_level: "advisory",
              created_at: $created_at,
              updated_at: $created_at
            }
          }
        ]
      }'
  )

  request PUT "/collections/$QDRANT_COLLECTION/points?wait=true" "$body" >/dev/null

  jq -nc \
    --arg collection "$QDRANT_COLLECTION" \
    --arg memory_id "$memory_id" \
    '{
      collection: $collection,
      memory_id: $memory_id,
      status: "proposed"
    }'
}

list_records() {
  [ "$#" -ge 1 ] && [ "$#" -le 3 ] || fail "usage: list <status> [memory_scope] [workspace_id]"
  require_collection

  status_filter=$1
  memory_scope=${2:-shared_pattern}
  workspace_id=${3:-}
  page_limit=${QDRANT_LIST_PAGE_LIMIT:-100}

  case "$page_limit" in
    ''|0|*[!0-9]*)
      fail "QDRANT_LIST_PAGE_LIMIT must be a positive integer"
      ;;
  esac

  filter_json=$(
    jq -nc \
      --arg status "$status_filter" \
      --arg scope "$memory_scope" \
      --arg workspace_id "$workspace_id" \
      '{
        must: (
          [
            {key: "status", match: {value: $status}},
            {key: "memory_scope", match: {value: $scope}}
          ] + if $workspace_id == "" then [] else [{key: "workspace_id", match: {value: $workspace_id}}] end
        )
      }'
  )

  records_json='[]'
  next_page_offset=null

  while :; do
    body=$(
      jq -nc \
        --argjson filter "$filter_json" \
        --argjson limit "$page_limit" \
        --argjson offset "$next_page_offset" \
        '{
          with_payload: true,
          with_vector: false,
          limit: $limit,
          filter: $filter
        } + if $offset == null then {} else {offset: $offset} end'
    )

    response=$(request POST "/collections/$QDRANT_COLLECTION/points/scroll" "$body")
    page_records=$(printf '%s' "$response" | jq -c '[.result.points[]?.payload]')
    records_json=$(jq -nc \
      --argjson existing "$records_json" \
      --argjson page "$page_records" \
      '$existing + $page')
    next_page_offset=$(printf '%s' "$response" | jq -c '.result.next_page_offset // null')

    [ "$next_page_offset" = "null" ] && break
  done

  jq -nc \
    --arg collection "$QDRANT_COLLECTION" \
    --argjson records "$records_json" \
    '{
      collection: $collection,
      records: $records
    }'
}

approve_record() {
  [ "$#" -eq 1 ] || fail "usage: approve <memory_id>"
  require_collection

  memory_id=$1
  record=$(lookup_record "$memory_id")
  [ "$record" != "null" ] || fail "memory_id not found: $memory_id"
  point_id=$(printf '%s' "$record" | jq -r '.id')
  current_status=$(printf '%s' "$record" | jq -r '.payload.status // ""')
  case "$current_status" in
    proposed|stale|approved) ;;
    superseded|retired)
      fail "memory_id cannot be approved from status=$current_status: $memory_id"
      ;;
    "")
      fail "memory_id has no status payload: $memory_id"
      ;;
    *)
      fail "memory_id has unsupported status=$current_status: $memory_id"
      ;;
  esac
  verified_at=$(timestamp_utc)
  body=$(
    jq -nc \
      --arg id "$point_id" \
      --arg verified_at "$verified_at" \
      '{
        points: [$id],
        payload: {
          status: "approved",
          verified_at: $verified_at,
          updated_at: $verified_at
        }
      }'
  )

  request POST "/collections/$QDRANT_COLLECTION/points/payload?wait=true" "$body" >/dev/null

  jq -nc \
    --arg collection "$QDRANT_COLLECTION" \
    --arg memory_id "$memory_id" \
    '{
      collection: $collection,
      memory_id: $memory_id,
      status: "approved"
    }'
}

usage() {
  cat <<EOF
Usage: qdrant_memory.sh <command> [args]

Commands:
  init
  reset
  propose <workspace_id> <repo_id> <concept_type> <summary> <canonical_uri>
  list <status> [memory_scope] [workspace_id]
  approve <memory_id>
EOF
}

main() {
  require_cmd curl
  require_cmd jq
  require_cmd uuidgen
  require_managed_collection

  command=${1:-}
  case "$command" in
    init)
      init_collection
      ;;
    reset)
      reset_collection
      ;;
    propose)
      shift
      propose_record "$@"
      ;;
    list)
      shift
      list_records "$@"
      ;;
    approve)
      shift
      approve_record "$@"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
