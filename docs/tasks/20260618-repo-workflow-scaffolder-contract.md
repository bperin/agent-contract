---
id: 20260618-repo-workflow-scaffolder-contract
title: Define repo workflow scaffolder contract
status: done
assignee: codex
created_at: 2026-06-18
completed_at: 2026-06-18
---

# Description
Define `agent-contract` as the repo workflow scaffolder and adopter that creates
and enforces the same control-plane pattern for new and existing repos,
regardless of which LLM, CLI, IDE, or agent runtime is operating in the repo.

# Acceptance Criteria
- [x] Define the new-repo scaffold path.
- [x] Define the existing-repo adoption path.
- [x] Define tool-independent reviewer/subagent role requirements.
- [x] Define machine-checkable artifacts that force the workflow pattern.
- [x] Identify required docs and implementation follow-up slices.

# Product Boundary
- `agent-contract` owns the workflow scaffold, generated local adapter,
  canonical planning directories, scratch sink, enforcement checks, and reviewer
  artifact contract.
- Consumer repos provide facts and repo-specific constraints, not workflow
  policy.
- Individual CLIs and IDEs may spawn tuned reviewer subagents differently, but
  they must satisfy the same reviewer roles and artifact/disposition contract.
- External memory and tool-local scratch remain advisory or disposable; they are
  never the authoritative workflow state.

# Initial Design Notes
- Add a first-class scaffold command for new repos that creates the profile,
  generated `AGENTS.md`, master plan, task/plan/architecture directories,
  scratch sink, gitignore entries, and optional CI/check wrapper.
- Keep `apply` as deterministic regeneration for repos already under the
  contract.
- Keep `migrate` as legacy adoption, not a general rewrite tool.
- Strengthen `check` so it validates the authority graph and reviewer artifacts,
  not just path existence and generated-file drift.
- Define reviewer outputs in task files so implementation, architecture, and
  governance reviews can be supplied by any agent runtime.

# Evidence
- Wrote the owning design spec:
  [`docs/specs/2026-06-18-repo-workflow-scaffolder-contract-design.md`](/Users/brian/code/agent-contract/docs/specs/2026-06-18-repo-workflow-scaffolder-contract-design.md)
- The design defines `scaffold`, `apply`, `check`, `doctor`, and `migrate`
  responsibilities.
- The design defines a tool-independent reviewer/subagent artifact contract.
- The design identifies implementation slices for self-adoption, scaffolding,
  authority-graph validation, reviewer artifact enforcement, policy/registry
  consolidation, and Qdrant verification hardening.
