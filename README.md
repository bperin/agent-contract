# Shared Agent Contract Package

This repo is the shared workflow contract for any codebase that wants the same
control-plane and reviewer-gate model.

It is intentionally:

- repo-agnostic
- language-agnostic
- editor-agnostic
- runtime-agnostic

The goal is to keep one durable operating model that can be cloned, vendored,
or referenced as a sibling repo without depending on Go, Node, Python, this
workspace layout, or `trakt2`-specific path conventions.

## Portable Context Stack

To make context survive across Codex, Claude, Gemini, Cursor, IDE plugins, and
CLI tools, keep the layers separate:

1. Shared contract
   - The reusable workflow rules in this package.
2. Local adapter
   - The generated repo-specific `AGENTS.md` plus the local profile that feeds
     it.
3. Canonical control plane
   - The repo's approved planning and architecture docs.
4. Scratch sink
   - Disposable tool-specific output redirected away from the control plane.
5. Optional personal memory
   - A user-owned cache outside the repo that summarizes and points back to the
     canonical sources of truth.

Only layers 1 through 3 are authoritative. Layer 4 is disposable. Layer 5 is
helpful but non-authoritative.

## Contents

- `AGENT_CONTRACT.md`: the portable workflow contract
- `workflow.mmd`: Mermaid source for the canonical execution flow
- `policy.yaml`: machine-readable policy surface for future CI or lint checks
- `templates/AGENTS.generated.md.tmpl`: generated local adapter template
- `repos/profile.schema.env`: consumer profile contract
- `scripts/apply.sh`: install or refresh the shared workflow in a consumer repo
- `scripts/check.sh`: validate a consumer repo against the generated workflow
- `scripts/doctor.sh`: explain adoption failures in human-readable form
- `scripts/qdrant_memory.sh`: optional advisory workflow-memory helper

## Intended Use

Each real repo should carry:

1. a local profile under `agent-contract-local/profiles/`
2. a generated `AGENTS.md`
3. a repo-owned scratch sink such as `.agent-scratch/`

The local profile provides facts, not workflow prose.
The generated `AGENTS.md` is overwritten by `apply.sh` and should never be
maintained by hand.

## Consumer Profile Model

See `repos/profile.schema.env` for the current contract.

The important rule is:

- keep local facts in the profile
- keep workflow policy in the shared contract
- let `apply.sh` generate the local adapter deterministically

If a workspace has subtrees that are not nested git repos but still need tool
scratch interception, declare them in `MANAGED_WORKTREE_ROOTS`.

## Commands

### Apply

```bash
sh /path/to/agent-contract/scripts/apply.sh <profile> <repo-root>
```

What it does:

- loads the consumer profile
- overwrites the generated local `AGENTS.md`
- creates `.agent-scratch/`
- reconciles known tool scratch paths into that sink

### Check

```bash
sh /path/to/agent-contract/scripts/check.sh <profile> <repo-root>
```

What it does:

- verifies generated `AGENTS.md` matches current shared output
- verifies required planning surfaces exist
- verifies known scratch paths are redirected into the sink
- fails on unmanaged known scratch paths, rogue task/plan surfaces, or
  forbidden local drift

### Doctor

```bash
sh /path/to/agent-contract/scripts/doctor.sh <profile> <repo-root>
```

What it does:

- runs targeted contract diagnostics
- prints `BLOCK`, `WARN`, and `INFO` style operator feedback
- helps explain why adoption currently fails

## Known Tool Scratch Paths

The shared registry currently manages these repo-local paths:

- `.claude`
- `.cursor`
- `.gemini`
- `.kilocode`
- `.kilo`
- `.antigravity`
- `.roo`
- `.windsurf`
- `docs/superpowers`

Known paths are redirected into `.agent-scratch/` for the repo root and each
nested git root discovered under the consumer workspace.

## Qdrant Bootstrap

This package includes a workflow-memory bootstrap script:

- `scripts/qdrant_memory.sh`

Its purpose is narrow:

- manage one dedicated workflow-memory collection
- write `shared_pattern` proposal records
- list records by `status`, `memory_scope`, and `workspace_id`
- approve candidate records by state transition

It does not make Qdrant authoritative for repo tasks, plans, evidence, or code.
The managed collection is for cross-agent workflow memory only.

## Adoption In Another Repo

1. Create `agent-contract-local/profiles/<profile>.env` from
   `repos/example.env`.
2. Fill in the repo facts.
3. Run `apply.sh`.
4. Run `check.sh`.
5. Run `doctor.sh` if `check.sh` reports drift.

## Checker Usage

The checker looks for `agent-contract-local/profiles/<profile>.env` at the
provided repo root and then walks upward through parent directories.
