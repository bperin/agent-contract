# Shared Agent Contract

This is the portable engineering workflow contract for any coding agent working
in a repo that adopts this package.

It is meant to be reused across repos and languages. Do not make the workflow
depend on a specific editor, model vendor, CLI, or programming language.

## Execution Order

1. Read the local repo adapter file, commonly `AGENTS.md`.
2. Read the repo's active master planning surface.
3. Open the linked active task if one exists.
4. If no task exists, create one granular task in the approved task location.
5. Execute the smallest clear slice of work.
6. If the slice matches the local repo's implementation-review gate, run the
   required reviewer roles for that slice.
7. Disposition findings before treating the slice as complete.
8. Commit stable slices routinely, including on feature branches. Do not leave
   reviewer-cleared or otherwise workflow-complete work sitting uncommitted.
9. If lasting product, workflow, or architecture truth changed, update the
   canonical doc that owns that truth.
10. When a task is complete and its lasting guidance has been propagated, delete
   the completed task file.

## Skill Routing

Consumer repos may declare required skills in their local profile. The generated
adapter must surface those declarations before local constraints so agents can
load the right skill before changing matching code, docs, or workflow surfaces.

Skill declarations are routing requirements, not a second planning system. They
do not override the shared contract, the generated adapter, or canonical repo
docs. They tell agents which reusable local instruction set to apply before
starting work in a matching area.

## Control-Plane Rules

- There is one authoritative planning chain per repo.
- Active planning docs must be obvious and few.
- Completed tasks are disposable execution records, not permanent history.
- Unlinked plans are not active instructions.
- Historical notes must not compete with current workflow docs.
- When a repo defines review as part of a slice's gate, that review is part of
  completion, not optional cleanup.

## Reviewer Roles

For slices that the local repo marks as review-gated, the minimum portable
review loop is:

- implementation reviewer: bugs, regressions, duplicate logic, unnecessary code, missing tests
- architecture and DDD reviewer: package boundaries, typed contracts, workflow shape, anti-patterns
- drift and governance reviewer: doc drift, stale control-plane surfaces, workflow-policy violations

Implementation review, architecture review, and drift/governance review are all
hard gates for these slices. A task is not retireable until findings are fixed,
explicitly deferred, or disproven with evidence.

External review tools are optional signals. The required gate is the repo's own
specialized reviewer-agent loop, not a specific third-party service.

This shared contract names the portable role set and the minimum hard gates once
review is required. It does not require the full three-review loop for every
trivial, docs-only, or otherwise non-gated slice unless the local repo adapter
adds that requirement.

## Scratch Output Rules

Agent-specific output paths such as `.claude/`, `.cursor/`, `.gemini/`,
`.kilocode/`, `.kilo/`, `.antigravity/`, `.roo/`, `.windsurf/`, and
`docs/superpowers/` are scratch-only.

- They are never authoritative planning surfaces.
- They should be redirected into a disposable sink path.
- Durable workflow or product truth must not live there.

## Shared Context Model

If context must survive across different LLMs, CLIs, IDEs, or editor plugins,
split it into these layers:

1. Canonical repo truth
   - Store durable workflow, product, architecture, and active-task truth in
     the repo control plane.
   - If another agent must be able to trust it without prior chat history, it
     belongs here.
2. Evidence and execution state
   - Keep task-specific verification, reviewer findings, and execution evidence
     in the approved task and plan surfaces or in the external system of record
     that owns the fact.
   - Do not hide critical status only in a chat transcript or vendor memory.
3. Tool scratch
   - Redirect tool-generated plans, notes, and transient memory into the
     scratch sink.
   - Treat this as disposable cache, never as authority.
4. Personal or external memory
   - A user-maintained memory system outside the repo is allowed for speed, but
     it is advisory only.
   - Memory entries should summarize and point back to canonical docs, tasks,
     plans, tickets, logs, or databases instead of becoming a second control
     plane.

An external memory store such as Qdrant belongs only in layer 4. It may hold
workflow-memory records, shared-pattern proposals, and canonical pointers, but
it must not replace repo task state, repo planning authority, or the live
system of record for evidence.

The rule is simple: if a new agent must discover and trust the context from the
repo alone, write it into the repo's canonical surfaces; if the information is
only helpful acceleration, keep it in memory or scratch.

## Qdrant Workflow Memory

If Qdrant is used for cross-agent workflow memory, the baseline model is:

- a dedicated managed collection for workflow memory only
- workspace-aware payload fields such as `workspace_id` and `repo_id`
- `memory_scope=shared_pattern` for reusable workflow and structure concepts
- `status=proposed|approved|stale|superseded|retired`
- `canonical_uri` or equivalent source pointers for every non-proposed record
- `verified_at` for every approved record
- `supersedes` or an equivalent forward/back reference when one record replaces
  another

Normal agent retrieval must filter to `status=approved` by default. Reads that
include `proposed`, `stale`, `superseded`, or `retired` records are maintenance,
audit, or migration queries and must be explicit.

Approval is a verification state inside the external memory store, not a
promotion of authority over the repo control plane. A record may be `approved`
only after it has been checked against its `canonical_uri`. If verification is
missing, fails, or later drift is suspected and not yet resolved, the record
must stay `proposed` or move to `stale` rather than being served as approved.

When a newer verified record replaces an approved record for the same fact, mark
the older record `superseded` and link it to the replacement. When a record is
no longer safe, relevant, or worth serving even for maintenance recall, mark it
`retired` instead of treating it as current.

## Shared / Local Split

The shared contract owns:

- workflow order
- retention policy
- scratch sink policy
- control-plane boundaries
- shared context-layer rules

The local repo adapter owns:

- repo root and module shape
- build and test commands
- local docs and codegen paths
- deployment and runtime constraints
- repo-specific exceptions
- checker profile files and path overlays for that consumer repo
