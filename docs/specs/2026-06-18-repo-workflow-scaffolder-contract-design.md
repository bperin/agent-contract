# Repo Workflow Scaffolder Contract Design

Date: 2026-06-18
Owner: `agent-contract`
Status: proposed

## Goal

Make `agent-contract` the portable scaffolder and adopter for repo workflow
control planes. A repo adopted by this package should expose the same operating
model to any coding agent, regardless of LLM provider, CLI, IDE, editor plugin,
or local runtime.

The system must do two jobs:

1. Scaffold new repos into the required workflow pattern.
2. Adopt existing repos into that same pattern and keep them from drifting.

## Core Invariant

Workflow authority lives in generated repo files and canonical repo docs, not in
tool-local memory, chat history, editor state, or a specific agent product.

Different tools may execute the workflow differently. They may spawn subagents
with different APIs, names, prompts, or runtimes. They must still satisfy the
same generated adapter, task lifecycle, reviewer-role, evidence, and disposition
contract.

## Product Boundary

`agent-contract` owns:

- new-repo workflow scaffold
- existing-repo adoption and migration flow
- generated local `AGENTS.md`
- consumer profile schema
- canonical planning directory layout
- scratch sink layout and known-tool registry
- enforcement checks
- reviewer artifact schema
- task lifecycle and retention rules

Consumer repos own:

- repo facts
- source-code layout
- runtime constraints
- verification commands
- product-specific architecture docs
- implementation details

Consumer repos do not own workflow policy. They provide data that feeds the
generated adapter.

## Command Model

### `scaffold`

Creates the workflow control plane for a new repo or an empty repo that has not
yet adopted `agent-contract`.

Required behavior:

- create `agent-contract-local/profiles/<profile>.env`
- create generated `AGENTS.md` through the same renderer as `apply`
- create `docs/MASTER_PLAN.md`
- create `docs/tasks/`
- create `docs/plans/`
- create `docs/architecture/`
- create `.agent-scratch/`
- add or update `.gitignore` entries for managed scratch sinks
- optionally install a CI or local wrapper that runs `check`

`scaffold` may create starter canonical docs because the repo has no prior
workflow authority. It should keep starter docs minimal and explicit.

### `apply`

Regenerates owned workflow artifacts in an adopted repo.

Required behavior:

- load the consumer profile
- regenerate `AGENTS.md`
- reconcile scratch sink redirects
- update generated files only
- never rewrite product docs or hand-authored architecture docs

### `check`

Enforces the contract.

Required behavior:

- fail if generated `AGENTS.md` drifted
- fail if required control-plane files or directories are missing
- fail if known scratch paths are unmanaged
- fail if rogue task or plan surfaces exist
- fail if completed tasks are still active after durable truth was propagated
- fail if active tasks do not appear in the master plan index
- fail if task reviewer artifacts are missing for review-gated slices
- fail if reviewer findings are not dispositioned
- fail if policy and executable registry definitions diverge

`check` is the hard boundary that keeps tools from inventing alternate workflow
surfaces.

### `doctor`

Explains adoption failures.

Required behavior:

- run the same checks as `check`
- classify output as `BLOCK`, `WARN`, or `INFO`
- print exact remediation steps
- point to the owning generated file, profile field, or canonical doc

### `migrate`

Adopts legacy repos.

Required behavior:

- create missing declared directories
- repair common scratch and `.gitignore` drift
- preserve existing product truth
- refuse to guess at canonical product architecture
- call `apply` and `check`

`migrate` is not a general repo rewriter. It is an adoption helper.

## Generated Adapter Contract

Generated `AGENTS.md` must be the first file an agent reads in an adopted repo.
It must include:

- generated-file warning
- shared contract pointer
- master plan path
- active task and plan path sets
- architecture doc paths
- local verification commands
- scratch sink policy
- task creation rule
- reviewer gate rule
- reviewer artifact requirements
- task retention rule
- local constraints from profile data

The file must say that any agent doing work must create or update a task before
execution. It must also say that tool scratch, chat memory, and external memory
are never workflow authority.

## Consumer Profile Contract

The profile remains data-only.

Required fields:

- `PROFILE_NAME`
- `REPO_DISPLAY_NAME`
- `REPO_ROOT`
- `PRIMARY_MODULE_TYPE`
- `MAIN_SOURCE_ROOTS`
- `GENERATED_AGENTS_PATH`
- `MASTER_PLAN_PATH`
- `TASK_PATHS`
- `PLAN_PATHS`
- `ARCHITECTURE_PATHS`
- `VERIFICATION_COMMANDS`
- `SCRATCH_SINK`

Expected optional fields:

- `FORBIDDEN_PATHS`
- `LOCAL_CONSTRAINTS`
- `MANAGED_WORKTREE_ROOTS`
- `REVIEW_GATED_PATHS`
- `REVIEW_EXEMPT_PATHS`
- `CHECK_WRAPPER_COMMAND`

Profiles must not contain workflow prose that competes with the shared
contract. If a setting is policy, it belongs in `agent-contract`.

## Reviewer/Subagent Contract

The shared workflow defines reviewer roles and required artifacts. It does not
define how a tool spawns reviewers.

Required reviewer roles for gated work:

- implementation reviewer: bugs, regressions, duplicate logic, unnecessary code,
  missing tests
- architecture reviewer: boundaries, typed contracts, dependency direction,
  workflow shape, domain anti-patterns
- governance reviewer: control-plane drift, missing evidence, stale docs,
  workflow-policy violations

Allowed execution models:

- Codex subagents
- Claude subagents
- Gemini agents
- IDE-specific review agents
- local scripts that invoke model reviewers
- human reviewer notes entered in the same artifact format

Required task-file artifact format:

```markdown
## Reviewer Sweep
### Implementation Review
- Reviewer:
- Runtime:
- Status: pending|passed|findings|deferred
- Findings:
  - severity:
    file:
    issue:
    disposition:

### Architecture Review
- Reviewer:
- Runtime:
- Status: pending|passed|findings|deferred
- Findings:
  - severity:
    file:
    issue:
    disposition:

### Governance Review
- Reviewer:
- Runtime:
- Status: pending|passed|findings|deferred
- Findings:
  - severity:
    file:
    issue:
    disposition:
```

A review-gated task is not complete until each required reviewer section exists
and every finding is fixed, explicitly deferred, or disproven with evidence.

## Authority Graph

An adopted repo has one active authority graph:

1. generated `AGENTS.md`
2. shared `AGENT_CONTRACT.md`
3. `docs/MASTER_PLAN.md`
4. linked active task files
5. linked active plan files
6. stable architecture docs

`check` should validate this graph rather than only checking that directories
exist. A task listed as active must be linked from the master plan. A plan used
for current work must be linked from an active task or the master plan.
Completed task files should be deleted after durable guidance is propagated.

## Scratch And Memory Boundary

Tool scratch paths are disposable. Known repo-local tool paths must redirect
into `.agent-scratch/` or be represented in detect-only mode until safe
redirection exists.

External memory systems such as Qdrant are allowed only as advisory recall. An
approved memory record must point back to canonical repo truth and be
reverified before it is served as current.

## Policy Source

The executable registry and `policy.yaml` must not drift. One source should
generate or validate the other.

Initial implementation can keep shell helpers as executable authority if
`check` verifies that `policy.yaml` mirrors the executable registry. Long term,
the registry should be structured data consumed by scripts and rendered into
docs.

## Verification Strategy

Minimum verification for the scaffolder work:

1. Scaffold a throwaway repo and run `check`.
2. Manually edit generated `AGENTS.md` and prove `check` fails.
3. Add a rogue task directory and prove `check` fails.
4. Add an unmanaged known scratch path and prove `check` fails.
5. Create a review-gated task without reviewer artifacts and prove `check`
   fails.
6. Add reviewer artifacts with undispositioned findings and prove `check`
   fails.
7. Complete the task artifact and prove `check` passes.
8. Run `apply` twice and prove the second run is idempotent.
9. Run `migrate` against an existing fixture repo and prove it preserves
   product docs.

## Implementation Slices

Recommended order:

1. Self-adopt `agent-contract` so this repo proves its own generated control
   plane.
2. Add `scaffold` for new repos.
3. Add master-plan/task/plan graph validation.
4. Add reviewer artifact schema and check enforcement.
5. Consolidate executable registry and `policy.yaml`.
6. Harden Qdrant approval so `canonical_uri` verification is real.

## Non-Goals

- Replacing repo-specific architecture decisions.
- Making Qdrant authoritative.
- Forcing one LLM, CLI, IDE, or model provider.
- Requiring every trivial docs edit to run three model reviewers.
- Rewriting legacy repos without explicit adoption intent.
