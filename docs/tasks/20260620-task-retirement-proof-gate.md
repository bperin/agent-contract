---
id: 20260620-task-retirement-proof-gate
title: Add task retirement proof gate to agent contract
author: codex
status: completed
created_at: 2026-06-20
completed_at: 2026-06-20
---

# Description
Harden the portable workflow so agents cannot retire task records unless completion, reviewer disposition, and durable evidence propagation are explicit.

# Acceptance Criteria
- [x] Shared contract defines a task retirement proof gate.
- [x] Generated adapter template renders the proof gate.
- [x] Mermaid workflow shows proof before deletion.
- [x] Policy surface records the stricter retention mode.
- [x] Check script rejects tracked task deletions when the last committed task status was not completed.
- [x] README documents the stricter checker behavior.

# Verification
- `sh scripts/check.sh workspace /Users/brian/code/trakt2`
- Negative temp-repo check proves deleted non-completed tracked tasks fail.

# Evidence
- Positive consumer check passed:
  - `sh /Users/brian/code/agent-contract/scripts/check.sh workspace /Users/brian/code/trakt2`
  - output: `agent-contract check (workspace): OK`
- Negative temp-repo check passed:
  - committed task status: `in_progress`
  - deleted tracked task file
  - checker failed with:
    `deleted task was not completed in last committed state: docs/tasks/active.md (status: in_progress)`
- Additional negative checks passed:
  - deleted task filename with a space failed:
    `docs/tasks/active task.md (status: in_progress)`
  - moved task out of `docs/tasks` failed:
    `docs/tasks/move-me.md (status: in_progress)`
  - deleted task in a nested git repo failed:
    `docs/tasks/nested.md (status: blocked)`
- Shell syntax check passed:
  - `sh -n /Users/brian/code/agent-contract/scripts/check.sh`
  - `sh -n /Users/brian/code/agent-contract/scripts/lib/profile.sh`
