#!/usr/bin/env sh

profile_fail() {
  echo "agent-contract error: $1" >&2
  exit 1
}

profile_resolve_dir() {
  CDPATH= cd -- "$1" && pwd
}

profile_find_file() {
  profile_key=$1
  search_dir=$2
  while :; do
    candidate="$search_dir/agent-contract-local/profiles/$profile_key.env"
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    parent=$(dirname "$search_dir")
    if [ "$parent" = "$search_dir" ]; then
      return 1
    fi
    search_dir=$parent
  done
}

profile_get() {
  var_name=$1
  eval "printf '%s' \"\${$var_name-}\""
}

profile_print_lines() {
  var_name=$1
  value=$(profile_get "$var_name")
  printf '%s\n' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed '/^$/d'
}

profile_require_field() {
  var_name=$1
  value=$(profile_get "$var_name")
  [ -n "$value" ] || profile_fail "missing required profile field: $var_name"
}

profile_load() {
  PROFILE_KEY=$1
  REPO_ROOT_INPUT=${2:-.}
  CONTRACT_REPO_ROOT=$3

  CONSUMER_REPO_ROOT=$(profile_resolve_dir "$REPO_ROOT_INPUT")
  PROFILE_FILE=$(profile_find_file "$PROFILE_KEY" "$CONSUMER_REPO_ROOT") || \
    profile_fail "missing local profile: agent-contract-local/profiles/$PROFILE_KEY.env"

  PARSED_PROFILE_FILE=$(mktemp)
  trap 'rm -f "$PARSED_PROFILE_FILE"' EXIT HUP INT TERM
  awk '
    function shell_quote(str,    out, i, ch) {
      out = "'\''"
      for (i = 1; i <= length(str); i++) {
        ch = substr(str, i, 1)
        if (ch == "'\''") {
          out = out "'\''\"'\''\"'\''"
        } else {
          out = out ch
        }
      }
      return out "'\''"
    }
    function emit_record(k, v) {
      printf("%s=%s\n", k, shell_quote(v))
    }
    BEGIN {
      in_multiline = 0
      key = ""
      value = ""
    }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    {
      line = $0
      if (in_multiline) {
        if (line ~ /"$/) {
          sub(/"$/, "", line)
          if (value == "") {
            value = line
          } else {
            value = value "\n" line
          }
          emit_record(key, value)
          in_multiline = 0
          key = ""
          value = ""
        } else {
          if (value == "") {
            value = line
          } else {
            value = value "\n" line
          }
        }
        next
      }
      if (line !~ /^[A-Za-z_][A-Za-z0-9_]*=/) {
        printf("invalid profile line: %s\n", line) > "/dev/stderr"
        exit 2
      }
      key = line
      sub(/=.*/, "", key)
      rhs = line
      sub(/^[A-Za-z_][A-Za-z0-9_]*=/, "", rhs)
      if (rhs ~ /^".*"$/) {
        sub(/^"/, "", rhs)
        sub(/"$/, "", rhs)
        emit_record(key, rhs)
        next
      }
      if (rhs ~ /^"/) {
        sub(/^"/, "", rhs)
        in_multiline = 1
        value = rhs
        if (value == "\"") {
          value = ""
        }
        next
      }
      emit_record(key, rhs)
    }
    END {
      if (in_multiline) {
        print "unterminated quoted value in profile" > "/dev/stderr"
        exit 2
      }
    }
  ' "$PROFILE_FILE" > "$PARSED_PROFILE_FILE" || profile_fail "invalid profile file: $PROFILE_FILE"

  # shellcheck disable=SC1090
  . "$PARSED_PROFILE_FILE"
  rm -f "$PARSED_PROFILE_FILE"
  trap - EXIT HUP INT TERM

  : "${PROFILE_NAME:=$PROFILE_KEY}"
  : "${GENERATED_AGENTS_PATH:=AGENTS.md}"
  : "${SCRATCH_SINK:=.agent-scratch}"
  SHARED_CONTRACT_PATH="$CONTRACT_REPO_ROOT/AGENT_CONTRACT.md"

  profile_require_field PROFILE_NAME
  profile_require_field REPO_DISPLAY_NAME
  profile_require_field REPO_ROOT
  profile_require_field PRIMARY_MODULE_TYPE
  profile_require_field MAIN_SOURCE_ROOTS
  profile_require_field GENERATED_AGENTS_PATH
  profile_require_field MASTER_PLAN_PATH
  profile_require_field TASK_PATHS
  profile_require_field PLAN_PATHS
  profile_require_field ARCHITECTURE_PATHS
  profile_require_field VERIFICATION_COMMANDS
  profile_require_field SCRATCH_SINK

  RESOLVED_PROFILE_REPO_ROOT=$(profile_resolve_dir "$REPO_ROOT")
  [ "$RESOLVED_PROFILE_REPO_ROOT" = "$CONSUMER_REPO_ROOT" ] || \
    profile_fail "profile REPO_ROOT does not match consumer repo root: $RESOLVED_PROFILE_REPO_ROOT != $CONSUMER_REPO_ROOT"
}

profile_resolve_path() {
  path_value=$1
  case "$path_value" in
    /*) printf '%s\n' "$path_value" ;;
    *) printf '%s/%s\n' "$CONSUMER_REPO_ROOT" "$path_value" ;;
  esac
}
