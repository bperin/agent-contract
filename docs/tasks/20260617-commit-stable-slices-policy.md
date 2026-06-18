---
id: 20260617-commit-stable-slices-policy
title: Make commit cadence explicit in shared contract
status: done
assignee: codex
created_at: 2026-06-17
completed_at: 2026-06-17
---

# Description
Make the shared contract explicit that stable slices are committed routinely,
including on feature branches, once they have passed the local workflow gate.

# Acceptance Criteria
- [x] The shared contract explicitly requires committing stable slices routinely.
- [x] The rule explicitly applies even on feature branches.

# Verification
- Shared contract text updated.

# Evidence
- added explicit commit-cadence rule to [`AGENT_CONTRACT.md`](/Users/brian/code/agent-contract/AGENT_CONTRACT.md)
