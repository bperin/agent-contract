---
id: 20260617-agent-contract-application-system
title: Design the agent-contract application and enforcement system
status: in_progress
assignee: codex
created_at: 2026-06-17
completed_at:
---

# Description
Design the shared `agent-contract` system so it can apply itself to consumer repos, overwrite local `AGENTS.md`, normalize known agent scratch paths into a common sink, and enforce one strict workflow through generated adapters plus drift checks.

# Acceptance Criteria
- [ ] Shared-repo design clearly defines the generated local adapter model.
- [ ] Shared-repo design clearly defines the tool-path interception registry and enforcement model.
- [ ] Shared-repo design clearly defines `apply`, `check`, and consumer-repo profile responsibilities.
- [ ] Written spec exists in the owning `agent-contract` repo before implementation planning starts.

# Verification
- shared repo surface inspected
- spec written in `docs/specs/`
- spec reviewed for consistency, scope, and ambiguity

# Evidence
- created owning-repo design task
- wrote spec: [`docs/specs/2026-06-17-agent-contract-application-system-design.md`](/Users/brian/code/agent-contract/docs/specs/2026-06-17-agent-contract-application-system-design.md)
- self-review:
  - placeholder scan: no `TBD`/`TODO`/template residue found
  - scope check: focused on shared-repo application system first, with `trakt2` as proving consumer in rollout phase
  - ambiguity check: local repos provide structured facts only; shared contract owns workflow policy
- shared runtime implemented:
  - generated adapter template: [`templates/AGENTS.generated.md.tmpl`](/Users/brian/code/agent-contract/templates/AGENTS.generated.md.tmpl)
  - profile schema: [`repos/profile.schema.env`](/Users/brian/code/agent-contract/repos/profile.schema.env)
  - profile/registry/render helpers under [`scripts/lib/`](/Users/brian/code/agent-contract/scripts/lib/profile.sh)
  - `apply`, `check`, and `doctor` commands under [`scripts/`](/Users/brian/code/agent-contract/scripts/apply.sh)
- proving-consumer results against `/Users/brian/code/trakt2`:
  - `sh /Users/brian/code/agent-contract/scripts/apply.sh workspace /Users/brian/code/trakt2` -> generated `AGENTS.md` and normalized known scratch paths into `.agent-scratch/`
  - `sh /Users/brian/code/agent-contract/scripts/check.sh workspace /Users/brian/code/trakt2` -> `agent-contract check (workspace): OK`
  - `sh /Users/brian/code/agent-contract/scripts/doctor.sh workspace /Users/brian/code/trakt2` -> `INFO  contract check passed`
  - follow-up finding: `trakt2-shared` required explicit declaration via `MANAGED_WORKTREE_ROOTS` because it is not a nested git repo but still has managed scratch paths

# Reviewer Sweep
## Implementation Review
- Reviewer: Halley
- Status: completed
- Findings: 4
- Finding entries:
  - fixed: `apply.sh` nested existing scratch directories one level too deep during migration
  - fixed: `apply.sh` wrote generated `AGENTS.md` before scratch reconciliation completed
  - fixed: known-path scan matched third-party dependency/build trees such as `node_modules`
  - deferred: deeper nested repo/worktree discovery remains bounded; current registry covers the proving consumer and declared extra roots
- Disposition: 3 fixed, 1 deferred with scope note

## Architecture/DDD Review
- Reviewer: Anscombe
- Status: completed
- Findings: 5
- Finding entries:
  - fixed: consumer profile loading no longer executes raw shell profile files directly
  - fixed: shared contract path now comes from the enforcing `agent-contract` repo instead of the consumer profile
  - partial: local profile remains newline-delimited env data rather than a stricter structured format such as JSON; safe parser landed, richer schema remains future work
  - partial: local constraints were reduced, but some repo-specific prose remains in the consumer profile
  - partial: registry/check/policy still share conceptual path inventory across multiple surfaces; executable registry is now the main scan source, but docs still mirror it
- Disposition: 2 fixed, 3 deferred as follow-up hardening

## Drift/Governance Review
- Reviewer: Franklin
- Status: completed
- Findings: 7
- Finding entries:
  - fixed: generated `AGENTS.md` now includes reviewer-gate and retention rules
  - fixed: `check.sh` now rejects rogue task/plan surfaces outside declared control-plane paths
  - fixed: legacy `agent-contract-local/profiles/{api,executor,shared,web}.env` workflow overlays were removed from `trakt2`
  - fixed: `docs/architecture/engineering-workflow.md` no longer contradicts the generated control-plane task/plan model
  - partial: `doctor.sh` remains a lightweight wrapper plus warnings rather than a fully rich diagnostic engine
  - deferred: profile/schema validation is still lighter than the long-term design target
  - deferred: consumer repos still need broader rollout beyond the proving `trakt2` workspace
- Disposition: 4 fixed, 3 deferred as next-slice work
