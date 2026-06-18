---
id: 20260618-agent-contract-control-plane-review
title: Review agent-contract control-plane enforceability
status: done
assignee: codex
created_at: 2026-06-18
completed_at: 2026-06-18
---

# Description
Review whether `agent-contract` is strong enough to serve as the shared
cross-repo control plane for agents operating through different CLIs, IDEs, and
model providers.

Confirmed product boundary: this repo is intended to scaffold new repos and
adopt existing repos into a forced workflow pattern regardless of which LLM,
CLI, IDE, or agent runtime is used.

# Acceptance Criteria
- [x] Identify gaps that let consumer repos drift away from the shared workflow.
- [x] Identify gaps in self-adoption of the control-plane repo itself.
- [x] Identify whether canonical docs need updates after the review.
- [x] Report findings with concrete file and line references.

# Evidence
- Manual review started from the shared contract, generated adapter template,
  apply/check/doctor scripts, profile schema, policy surface, and active task
  docs.
- CodeRabbit CLI was not used per operator preference.
- Review incorporated the operator constraint that any agent can spawn tuned
  reviewer subagents; the shared contract should define the portable role
  contract and artifact requirements rather than binding to one CLI.

# Findings
1. High: `agent-contract` does not yet self-adopt its own generated control
   plane. The repo lacks a root generated `AGENTS.md`, local profile, scratch
   sink, master plan, and architecture directory even though the README says
   each real repo should carry those surfaces.
2. High: `check.sh` validates that configured planning paths exist, but it does
   not validate the actual authority graph from master plan to active task to
   active plan, nor completed-task retirement.
3. High: reviewer gates are only prose. The repo names reviewer roles, but does
   not define portable subagent reviewer prompts, required task-file artifacts,
   or machine-checkable reviewer disposition.
4. Medium: the tool-path registry is fixed and shallow, so unknown CLIs/IDEs can
   still create alternate planning or scratch surfaces without a fail-closed
   detection path.
5. Medium: `policy.yaml` mirrors behavior but is not consumed by the scripts, so
   policy drift can occur without changing enforcement.
6. Medium: Qdrant memory approval can set `approved` without verifying the
   `canonical_uri`, contrary to the contract's authority model.

# Docs Update Review
- Canonical docs should be updated in a follow-up implementation slice to cover
  self-adoption, subagent reviewer protocol, checkable reviewer artifacts,
  registry expansion/detect-only semantics, and policy-as-source alignment.
- Follow-up task created for the repo-scaffolder product contract:
  [`docs/tasks/20260618-repo-workflow-scaffolder-contract.md`](/Users/brian/code/agent-contract/docs/tasks/20260618-repo-workflow-scaffolder-contract.md)
