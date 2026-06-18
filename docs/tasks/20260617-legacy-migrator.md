---
id: 20260617-legacy-migrator
title: Add legacy repo migrator bootstrap command
status: done
assignee: codex
created_at: 2026-06-17
completed_at: 2026-06-17
---

# Description
Add a migration command to `agent-contract` that can reconcile common legacy
repo drift instead of only generating and checking the workflow contract. This
is a one-time adoption/bootstrap helper, not a general repo rewriter.

# Acceptance Criteria
- [x] `agent-contract` exposes a migration command.
- [x] The migration command bootstraps missing declared control-plane paths.
- [x] The migration command repairs the common managed-root `.gitignore` drift
  for profile-declared managed worktree roots.
- [x] The migration command runs `apply` and `check` as part of the migration flow.
- [x] The migration command does not author the consumer repo's canonical
  master-plan file.

# Verification
- architecture/workflow reviewer findings recorded and dispositioned in this task file

# Evidence
- implementation adds [`scripts/migrate.sh`](/Users/brian/code/agent-contract/scripts/migrate.sh)
- documentation updated in [`README.md`](/Users/brian/code/agent-contract/README.md)
- review findings fixed:
  - removed placeholder master-plan authoring from `migrate.sh`
  - tightened `README.md` to describe `migrate.sh` as a one-time adoption/bootstrap helper
  - replaced `shell-owned` wording with portable `profile-declared managed worktree root` wording
  - expanded acceptance criteria so the task covers both `.gitignore` rewriting and the non-authoring master-plan boundary

# Reviewer Sweep
## Architecture/Workflow Review
- Reviewer: Chandrasekhar
- Status: addressed
- Findings: 4
- Finding entries:
  - High: migrator must not author a canonical master-plan file. Fixed by removing placeholder master-plan creation and leaving missing master-plan definition to the consumer repo.
  - Medium: `migrate.sh` needed to be explicitly framed as a one-time adoption/bootstrap helper. Fixed in `README.md` and this task record.
  - Medium: task acceptance criteria/evidence were incomplete for the actual migration behavior introduced. Fixed in this task record.
  - Low: shared docs used `trakt2`-shaped `shell-owned` terminology. Fixed with portable `profile-declared managed worktree root` language.
- Disposition: all findings fixed
