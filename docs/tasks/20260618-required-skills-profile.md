---
id: 20260618-required-skills-profile
title: Add required skills to generated agent adapters
status: complete
assignee: codex
created_at: 2026-06-18
completed_at: 2026-06-18
---

# Description
Add first-class profile support for repo-required skills so generated
`AGENTS.md` adapters can tell agents which local skills must be used for
matching work.

# Acceptance Criteria
- [x] Shared contract explains how declared skills participate in the workflow.
- [x] Consumer profile schema documents the optional `REQUIRED_SKILLS` field.
- [x] Generated `AGENTS.md` renders declared skills deterministically.
- [x] Example profile shows the field.
- [x] A consumer repo can declare `ddd` and pass `apply`/`check`.

# Evidence
- Added `REQUIRED_SKILLS` rendering to the generated adapter template.
- Updated the profile schema and example profile.
- Regenerated `trader2` after declaring the `ddd` skill in its workspace
  profile.
