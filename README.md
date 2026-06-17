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
   - The repo-specific `AGENTS.md` that adds only local facts.
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
- `templates/AGENTS.local-template.md`: thin per-repo adapter template
- `scripts/check.sh`: simple shell checker for control-plane drift

## Intended Use

Each real repo should have a thin local `AGENTS.md` file that:

1. points to this shared contract
2. adds only local repo facts
3. avoids redefining the full workflow

When you need cross-agent memory, prefer this rule:

- If a fact must be trusted by any new agent, promote it into the repo control
  plane or the external system of record that owns it.
- If a fact is only there to help a future agent move faster, keep it in
  personal memory and make it reference the authoritative source.
- Local `AGENTS.md` files own when the full reviewer loop is required. The
  shared contract only defines the portable reviewer roles and hard-gate shape
  once a repo marks a slice as review-gated.

Checker profiles are also consumer-local. The shared package ships only the
neutral example profile in `agent-contract/repos/example.env`. Real repo
profiles belong in a sibling local-only directory such as
`agent-contract-local/profiles/`, so another repo does not inherit this
workspace's overlays by copying the shared package.

## Qdrant Bootstrap

This package now includes a first workflow-memory bootstrap script:

- `scripts/qdrant_memory.sh`

Its purpose is narrow:

- manage one dedicated workflow-memory collection
- write `shared_pattern` proposal records
- list records by `status`, `memory_scope`, and `workspace_id`
- approve candidate records by state transition

It does not make Qdrant authoritative for repo tasks, plans, or evidence. The
managed collection is for cross-agent workflow memory only.

Normal reads should filter to `status=approved` only. `proposed`, `stale`,
`superseded`, and `retired` records should appear only in explicit maintenance
or audit queries. Every non-proposed record must carry a `canonical_uri`, and
every approved record must carry `verified_at` so approval means "checked
against source" rather than "helpful guess."

This package is the shared standard. The local `AGENTS.md` is the adapter.

## Adoption In Another Repo

1. Clone this repo beside the target repo or vendor its contents into the
   target workspace.
2. Create a thin local adapter from `templates/AGENTS.local-template.md`.
3. Point that adapter at the repo's real control-plane docs and verification
   commands.
4. Copy `repos/example.env` to a local checker profile under
   `<repo-root>/agent-contract-local/profiles/` and fill in the target repo's
   required, forbidden, and scratch-redirected paths.
5. Run `/path/to/agent-contract/scripts/check.sh <profile> <repo-root>`.

## Checker Usage

Run the shared checker with a consumer-local profile and repo root. The checker
first looks for `agent-contract-local/profiles/<profile>.env` at the provided
repo root and then walks upward through parent directories before falling back
to the shared `repos/<profile>.env` file.

```bash
mkdir -p agent-contract-local/profiles
cp /path/to/agent-contract/repos/example.env agent-contract-local/profiles/my-repo.env
$EDITOR agent-contract-local/profiles/my-repo.env
/path/to/agent-contract/scripts/check.sh my-repo /path/to/repo
```
