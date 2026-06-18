---
id: 20260618-root-build-dir-scratch-scan-prune
title: Prune root dependency and build dirs during scratch scan
status: done
assignee: codex
created_at: 2026-06-18
completed_at: 2026-06-18
---

# Description
Fix `check.sh` scratch-path scanning so consumer repos with root-level
dependency/build directories do not fail adoption because third-party packages
contain folders named like managed agent scratch paths.

# Acceptance Criteria
- [x] Root-level dependency/build directories are pruned during known-path scans.
- [x] Existing nested dependency/build pruning remains intact.
- [x] Trader frontend adoption no longer fails on `node_modules/nanoid/.claude`.

# Evidence
- Trader frontend migration failed with:
  `workspace unmanaged known scratch path detected: node_modules/nanoid/.claude`
- Updated `scripts/lib/registry.sh` to prune root-level `node_modules`, `.next`,
  `dist`, and `.parcel-cache` in addition to existing one-level nested pruning.
- Reran Trader frontend migration:
  `sh /Users/brian/code/agent-contract/scripts/migrate.sh workspace /Users/brian/code/trader/trader-frontend`
  -> `agent-contract check (workspace): OK`.
