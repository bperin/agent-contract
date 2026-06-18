#!/usr/bin/env sh

render_list_block() {
  var_name=$1
  prefix=$2
  value=$(profile_get "$var_name")
  if [ -z "$value" ]; then
    printf '%snone\n' "$prefix"
    return
  fi
  printf '%s\n' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed '/^$/d' | while IFS= read -r line; do
    printf '%s`%s`\n' "$prefix" "$line"
  done
}

render_text_block() {
  var_name=$1
  prefix=$2
  value=$(profile_get "$var_name")
  if [ -z "$value" ]; then
    printf '%snone\n' "$prefix"
    return
  fi
  printf '%s\n' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed '/^$/d' | while IFS= read -r line; do
    printf '%s%s\n' "$prefix" "$line"
  done
}

render_command_block() {
  profile_get VERIFICATION_COMMANDS
}

render_agents() {
  template_path=$CONTRACT_REPO_ROOT/templates/AGENTS.generated.md.tmpl
  apply_command="sh $CONTRACT_REPO_ROOT/scripts/apply.sh $PROFILE_KEY $CONSUMER_REPO_ROOT"

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '{{MAIN_SOURCE_ROOTS_BLOCK}}') render_list_block MAIN_SOURCE_ROOTS '- ' ;;
      '{{TASK_PATHS_BLOCK}}') render_list_block TASK_PATHS '- ' ;;
      '{{PLAN_PATHS_BLOCK}}') render_list_block PLAN_PATHS '- ' ;;
      '{{ARCHITECTURE_PATHS_BLOCK}}') render_list_block ARCHITECTURE_PATHS '- ' ;;
      '{{VERIFICATION_COMMANDS_BLOCK}}') render_command_block ;;
      '{{REQUIRED_SKILLS_BLOCK}}') render_text_block REQUIRED_SKILLS '- ' ;;
      '{{LOCAL_CONSTRAINTS_BLOCK}}') render_text_block LOCAL_CONSTRAINTS '- ' ;;
      '{{FORBIDDEN_PATHS_BLOCK}}') render_list_block FORBIDDEN_PATHS '- ' ;;
      *)
        printf '%s\n' "$line" | \
          sed \
            -e "s#{{REPO_DISPLAY_NAME}}#$REPO_DISPLAY_NAME#g" \
            -e "s#{{SHARED_CONTRACT_PATH}}#$SHARED_CONTRACT_PATH#g" \
            -e "s#{{APPLY_COMMAND}}#$apply_command#g" \
            -e "s#{{MASTER_PLAN_PATH}}#$MASTER_PLAN_PATH#g" \
            -e "s#{{REPO_ROOT}}#$REPO_ROOT#g" \
            -e "s#{{PRIMARY_MODULE_TYPE}}#$PRIMARY_MODULE_TYPE#g" \
            -e "s#{{SCRATCH_SINK}}#$SCRATCH_SINK#g"
        ;;
    esac
  done < "$template_path"
}
