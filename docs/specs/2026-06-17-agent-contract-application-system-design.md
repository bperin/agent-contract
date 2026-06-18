# Agent-Contract Application System Design

Date: 2026-06-17
Owner: `agent-contract`
Status: proposed

## Goal

Turn `agent-contract` from a shared prose contract plus a few helper scripts into
a real application system that can be applied to a consumer repo and make that
repo follow one strict workflow.

The system must:

- generate and overwrite local `AGENTS.md`
- reduce consumer repos to structured local facts instead of hand-written
  workflow prose
- normalize known agent scratch/task/plan paths into one repo-owned sink
- detect and fail drift from the generated workflow
- keep Qdrant optional and advisory rather than part of the workflow core

## Non-Goals

- Qdrant-based codebase indexing
- replacing canonical repo docs as the source of truth
- supporting arbitrary unknown tools without first adding them to the registry
- forcing all repos to share the same test commands or doc layout

## Problem Statement

The current shape is only a partial adoption model.

- The shared repo defines a portable contract.
- Consumer repos manually point at it.
- Consumer repos still carry large amounts of hand-authored workflow prose.
- Scratch-path redirection is mostly policy, not applied enforcement.
- The checker exists, but the system does not yet install the repo into a
  deterministic contract-managed state.

This leaves room for drift:

- local `AGENTS.md` files can accumulate custom workflow logic
- scratch directories can reappear in multiple places
- repos can claim adoption without a reproducible application step
- agents can invent alternate task and plan surfaces when the local adapter is
  too loose

## Design Principles

1. Shared contract is authoritative for workflow.
2. Consumer repos provide facts, not workflow prose.
3. Generated local adapter files are overwritten, not manually curated.
4. Known tool scratch paths are normalized into one sink path.
5. Drift must fail loudly.
6. The system must work without Qdrant.
7. Qdrant, when used, is workflow-memory only and never the authority.

## System Overview

The system has four major pieces:

1. Shared contract
2. Consumer profile
3. Apply engine
4. Drift checker

### 1. Shared contract

The shared repo owns:

- workflow order
- task lifecycle and retention rules
- reviewer role definitions
- scratch sink policy
- allowed control-plane model
- generated local adapter template
- known tool path registry
- apply and check commands

### 2. Consumer profile

Each consumer repo owns one structured local profile with repo-specific facts.
That profile is data only. It does not define workflow.

Minimum profile responsibilities:

- repo root
- master plan path
- active task path set
- active plan path set
- architecture doc path set
- verification command list
- scratch sink path
- forbidden path list
- repo-specific runtime constraints

### 3. Apply engine

`agent-contract apply` is the installation and reconciliation command.

It must:

- load the consumer profile
- validate required fields
- generate and overwrite local `AGENTS.md`
- create the repo scratch sink
- install known tool-path redirects where supported
- create required local stub/config files when the adoption model expects them
- report what it created, updated, skipped, or could not safely manage

### 4. Drift checker

`agent-contract check` is the enforcement command.

It must fail when:

- local `AGENTS.md` differs from generated output
- rogue task or plan surfaces exist outside the allowed control plane
- forbidden tool scratch paths exist outside the sink
- required repo-local profile files are missing
- generated adoption artifacts drifted or were manually edited

## Consumer Repo Shape

After adoption, the consumer repo should contain:

- generated `AGENTS.md`
- local data-only profile under `agent-contract-local/profiles/`
- repo-owned scratch sink, default `.agent-scratch/`

The consumer repo should not contain hand-authored workflow policy beyond
repo-specific facts that the shared system intentionally leaves local.

## Generated `AGENTS.md`

The generated file must be strict and deterministic.

Requirements:

- clearly marked as generated and not for manual editing
- includes the execution order agents must follow
- points to the master plan and canonical local planning surfaces
- defines reviewer gates
- defines retention and deletion rules
- defines scratch-sink rules
- embeds the local verification commands from the consumer profile
- embeds repo-specific constraints from the consumer profile in a bounded,
  structured section

The generated file must not rely on a human to merge or interpret workflow
fragments from old local policy.

## Local Profile Model

Initial consumer profile format can remain shell-env style for speed, but the
schema must be strict.

Required fields:

- `REPO_ROOT`
- `MASTER_PLAN_PATH`
- `TASK_PATHS`
- `PLAN_PATHS`
- `ARCHITECTURE_PATHS`
- `VERIFICATION_COMMANDS`
- `SCRATCH_SINK`

Optional but expected fields:

- `FORBIDDEN_PATHS`
- `LOCAL_CONSTRAINTS`
- `GENERATED_AGENTS_PATH`
- `TOOL_PATH_REGISTRY_MODE`

Constraint:

- multi-value fields must have a deterministic delimiter and parser behavior

Future upgrade path:

- move to JSON or YAML only if shell-env format becomes too fragile for
  multi-line commands or richer structured constraints

## Tool Path Registry

`agent-contract` must own a registry of known tool scratch/task/plan paths.

Initial registry targets:

- Codex
- Claude
- Gemini
- Cursor
- Kilo
- KiloCode
- Antigravity
- VS Code agent/plugin paths

Each registry entry must define:

- tool name
- path pattern
- scope: repo-local or home-dir based
- redirection strategy
- check behavior
- fallback behavior when redirection is not safe

### Supported strategies

Supported redirection strategies:

- symlink repo-local path into `.agent-scratch/<tool>/...`
- generate repo-local stub directory or file
- install tool-specific config when that tool supports path configuration
- detect-only mode when automatic interception is not yet safe

### Enforcement rule

Known tools must not be allowed to leave unmanaged scratch/task/plan directories
outside the configured sink without causing `check` to fail.

Unknown tools are not auto-managed, but their paths should be detectable through
fallback heuristics so the repo can fail closed and add a new registry rule.

## Apply Command

### Responsibilities

`apply` must:

1. load and validate profile
2. materialize generated `AGENTS.md`
3. create scratch sink structure
4. reconcile known tool paths
5. create adoption support files if missing
6. emit a deterministic report

### Idempotency

`apply` must be idempotent.

Running it repeatedly should produce the same resulting repo state when inputs
do not change.

### Safety

`apply` must never silently delete unknown paths.

Allowed behaviors:

- overwrite generated files it owns
- replace its own symlinks
- create missing directories
- report unmanaged conflicting paths as explicit failures or warnings

Disallowed behavior:

- blindly remove unknown repo directories just because they resemble tool
  scratch

## Check Command

`check` must verify:

- generated files still match the current shared templates and profile
- required planning surfaces exist
- forbidden planning surfaces do not exist
- known scratch paths are redirected or absent
- rogue scratch paths are detected
- consumer repo overlays remain thin and compliant

`check` is the hard gate that keeps consumer repos from drifting back into local
workflow invention.

## Doctor Command

Add a `doctor` command after `apply` and `check`.

Purpose:

- explain what is wrong in human-readable form
- classify findings as block, warn, or info
- propose exact remediation steps

This is useful because strict `check` failures alone may be too terse during
initial rollout.

## Qdrant Position

Qdrant remains outside the core adoption path.

It can help with:

- shared workflow-memory proposals
- approved workflow patterns
- canonical pointers back to authoritative docs

It does not:

- generate `AGENTS.md`
- define repo workflow
- replace task state
- replace code or doc inspection

The current Qdrant script is a workflow-memory registry, not a semantic codebase
retrieval layer. That distinction should remain explicit.

## Rollout Strategy

### Phase 1: Harden `agent-contract`

- add strict consumer profile schema rules
- add generated `AGENTS.md` template
- add tool path registry
- add `apply`
- strengthen `check`
- add `doctor`

### Phase 2: Prove on `trakt2`

- replace hand-authored local workflow content with generated output
- keep only structured local repo facts
- run `apply`
- run `check`
- fix adoption failures until `trakt2` is clean

### Phase 3: Reuse in other repos

- use the same shared system on another repo such as `trader`
- only add repo-local facts and missing tool rules

## Verification Plan

The first implementation must prove:

1. `apply` overwrites `AGENTS.md`
2. `apply` is idempotent
3. `check` fails on manual drift in generated `AGENTS.md`
4. `check` fails on rogue task or plan surfaces
5. `check` fails on unmanaged known-tool scratch paths
6. `apply` plus `check` can bring `trakt2` into compliance

## Risks

### Tool variability

Some tools may need different handling per environment. A path may be repo-local
in one setup and home-dir based in another.

Mitigation:

- encode scope and strategy per tool
- support detect-only mode until safe redirection is understood

### Over-broad cleanup

The system could accidentally become destructive if it starts deleting anything
that looks like scratch.

Mitigation:

- never auto-delete unknown paths
- fail closed
- require explicit managed-path ownership before rewrite/remove behavior

### Consumer repo divergence

Existing repos may already violate the contract heavily.

Mitigation:

- use `doctor` to explain drift
- adopt in one proving repo first

## Recommendation

Build the application system in `agent-contract` first and use `trakt2` as the
proving consumer. Do not expand Qdrant beyond advisory workflow memory until the
apply/check/generated-adapter model is stable.
