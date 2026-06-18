# Agent-Contract Application System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `agent-contract` into a real adoption system that overwrites local `AGENTS.md`, manages known agent scratch paths through a registry, and enforces repo workflow through `apply`, `check`, and `doctor` commands.

**Architecture:** Keep the shared contract authoritative in prose and add a small deterministic shell runtime around it. Consumer repos provide only structured profile facts; shared scripts generate adapters, install scratch redirects, and fail drift when a repo diverges from the contract.

**Tech Stack:** POSIX shell, existing `agent-contract` markdown/yaml/env assets, deterministic generated markdown, grep/find/readlink-based validation.

---

### Task 1: Add shared generation assets and profile model

**Files:**
- Create: `docs/plans/2026-06-17-agent-contract-application-system.md`
- Create: `templates/AGENTS.generated.md.tmpl`
- Create: `repos/profile.schema.env`
- Modify: `README.md`
- Modify: `docs/tasks/20260617-agent-contract-application-system.md`

- [ ] **Step 1: Write the failing asset-coverage test**

Run: `test -f /Users/brian/code/agent-contract/templates/AGENTS.generated.md.tmpl && test -f /Users/brian/code/agent-contract/repos/profile.schema.env`
Expected: command exits non-zero because the new generation assets do not exist yet.

- [ ] **Step 2: Create the generated AGENTS template**

Create `templates/AGENTS.generated.md.tmpl` with placeholders for repo root, shared contract path, master plan path, task/plan paths, verification commands, scratch sink, reviewer gates, and repo-specific constraints. Mark the file as generated-output source and include strict “do not edit generated AGENTS.md” language.

- [ ] **Step 3: Create the profile schema contract**

Create `repos/profile.schema.env` documenting required keys, optional keys, delimiter rules, and known-tool registry expectations. Keep it data-contract oriented rather than prose-heavy.

- [ ] **Step 4: Update README adoption section**

Document the new model: local profile is data-only, `apply` generates `AGENTS.md`, and `check` validates generated output plus scratch/path drift.

- [ ] **Step 5: Run the asset-coverage check again**

Run: `test -f /Users/brian/code/agent-contract/templates/AGENTS.generated.md.tmpl && test -f /Users/brian/code/agent-contract/repos/profile.schema.env`
Expected: command exits zero.

### Task 2: Build a shared tool-path registry and AGENTS generator

**Files:**
- Create: `scripts/lib/profile.sh`
- Create: `scripts/lib/registry.sh`
- Create: `scripts/lib/render.sh`
- Modify: `policy.yaml`
- Test: `scripts/check.sh`

- [ ] **Step 1: Write the failing generator test**

Run: `sh /Users/brian/code/agent-contract/scripts/apply.sh workspace /Users/brian/code/trakt2 >/tmp/agent-contract-apply.out 2>&1`
Expected: command exits non-zero because `apply.sh` and its generator plumbing do not exist yet.

- [ ] **Step 2: Implement profile loading helpers**

Create `scripts/lib/profile.sh` to find, source, and validate consumer profiles, normalize multi-line fields, and expose required/optional values to other scripts.

- [ ] **Step 3: Implement tool registry helpers**

Create `scripts/lib/registry.sh` with known scratch-path entries for `.claude`, `.cursor`, `.gemini`, `.kilocode`, `.kilo`, `.antigravity`, `.roo`, `.windsurf`, and `docs/superpowers`. Include functions to enumerate known paths and to compute sink targets under `.agent-scratch/`.

- [ ] **Step 4: Implement AGENTS renderer**

Create `scripts/lib/render.sh` to render `templates/AGENTS.generated.md.tmpl` deterministically from profile data. Keep output stable so `check` can diff it byte-for-byte.

- [ ] **Step 5: Update policy surface for generated adapter enforcement**

Extend `policy.yaml` with generated-adapter semantics and explicit known-tool registry ownership.

### Task 3: Implement `apply.sh`

**Files:**
- Create: `scripts/apply.sh`
- Modify: `README.md`
- Test: consumer repo `/Users/brian/code/trakt2/AGENTS.md` and `/Users/brian/code/trakt2/.agent-scratch/`

- [ ] **Step 1: Write the failing apply smoke test**

Run: `sh /Users/brian/code/agent-contract/scripts/apply.sh workspace /Users/brian/code/trakt2`
Expected: command exits non-zero before implementation.

- [ ] **Step 2: Implement generated AGENTS overwrite flow**

`apply.sh` should load the profile, render the target AGENTS content, and overwrite the target path every time.

- [ ] **Step 3: Implement scratch sink creation and known-path reconciliation**

`apply.sh` should create `.agent-scratch/`, create per-tool target directories, and replace missing repo-local known scratch paths with symlinks into the sink where safe.

- [ ] **Step 4: Emit deterministic apply report**

Print created/updated/skipped/conflict entries in stable order so operators can understand what changed.

- [ ] **Step 5: Run apply against `trakt2`**

Run: `sh /Users/brian/code/agent-contract/scripts/apply.sh workspace /Users/brian/code/trakt2`
Expected: generated `AGENTS.md` updated and scratch sink/redirects reconciled without deleting unknown paths.

### Task 4: Strengthen `check.sh`

**Files:**
- Modify: `scripts/check.sh`
- Test: `/Users/brian/code/trakt2/agent-contract-local/profiles/workspace.env`
- Test: generated `/Users/brian/code/trakt2/AGENTS.md`

- [ ] **Step 1: Write the failing drift check**

After `apply`, intentionally compare current `check.sh` expectations against generated output. Run: `sh /Users/brian/code/agent-contract/scripts/check.sh workspace /Users/brian/code/trakt2`
Expected: command either passes without checking generated AGENTS fidelity or misses known scratch drift, proving the enforcement gap.

- [ ] **Step 2: Add generated AGENTS fidelity checks**

Make `check.sh` render expected AGENTS content and fail if local output differs.

- [ ] **Step 3: Add known-tool scratch-path checks**

Make `check.sh` verify known repo-local scratch paths are symlinks into the configured sink or absent when managed otherwise.

- [ ] **Step 4: Add profile/schema validation checks**

Make `check.sh` fail when required profile keys are missing or delimiter semantics are invalid.

- [ ] **Step 5: Run check on `trakt2`**

Run: `sh /Users/brian/code/agent-contract/scripts/check.sh workspace /Users/brian/code/trakt2`
Expected: command exits zero only after generated AGENTS and scratch policy are actually in compliance.

### Task 5: Add `doctor.sh` and harden operator guidance

**Files:**
- Create: `scripts/doctor.sh`
- Modify: `README.md`
- Modify: `docs/tasks/20260617-agent-contract-application-system.md`

- [ ] **Step 1: Write the failing doctor smoke test**

Run: `sh /Users/brian/code/agent-contract/scripts/doctor.sh workspace /Users/brian/code/trakt2`
Expected: command exits non-zero because `doctor.sh` does not exist yet.

- [ ] **Step 2: Implement doctor diagnostics**

`doctor.sh` should run profile discovery and targeted checks, then print categorized findings (`BLOCK`, `WARN`, `INFO`) plus remediation hints.

- [ ] **Step 3: Document apply/check/doctor workflow**

Update `README.md` with exact operator commands and the intended consumer adoption sequence.

- [ ] **Step 4: Run doctor against `trakt2`**

Run: `sh /Users/brian/code/agent-contract/scripts/doctor.sh workspace /Users/brian/code/trakt2`
Expected: command prints a human-readable state report with no block-level findings after successful adoption.

### Task 6: Prove adoption on `trakt2`

**Files:**
- Modify: `/Users/brian/code/trakt2/AGENTS.md`
- Modify: `/Users/brian/code/trakt2/agent-contract-local/profiles/workspace.env`
- Modify: `/Users/brian/code/trakt2/docs/MASTER_PLAN.md` if generated workflow paths require correction
- Test: `/Users/brian/code/trakt2`

- [ ] **Step 1: Inspect current `trakt2` profile and generated target assumptions**

Verify the local profile contains enough structured facts for generation and enforcement. Add only missing facts needed by the shared scripts.

- [ ] **Step 2: Run `apply` and reconcile drift**

Use the shared `apply.sh` to overwrite `trakt2`’s `AGENTS.md` and install scratch redirects. Fix consumer-side mismatches exposed by the shared tooling rather than patching around them in the repo.

- [ ] **Step 3: Run `check` and fix failures**

Iterate until the consumer repo passes the shared enforcement checks cleanly.

- [ ] **Step 4: Run `doctor` and capture operator evidence**

Record the proving-consumer outcome in the task file, including any unsupported tool-path cases left in detect-only mode.
