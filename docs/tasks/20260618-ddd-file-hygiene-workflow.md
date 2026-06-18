# 20260618 DDD And File Hygiene Workflow

## Request

Promote DDD-style boundary discipline, focused file ownership, redundancy
review, and readability checks into the shared workflow so consumer repos do
not rely on one-off plan reminders.

## Acceptance Criteria

- [x] Shared contract includes a portable implementation-hygiene gate.
- [x] Generated repo adapters surface the hygiene gate.
- [x] The gate is language-agnostic but explicitly covers architecture/DDD
  review when a repo declares DDD boundaries.
- [x] The gate requires focused files, duplicate-logic review, and disposition
  before a slice is complete.
- [x] `trader2` generated `AGENTS.md` is refreshed from the updated template.
- [x] Contract changes are committed separately from consumer repo changes.

## Verification

- `git -C /Users/brian/code/agent-contract diff --check`: PASS.
- `sh /Users/brian/code/agent-contract/scripts/apply.sh workspace /Users/brian/code/trader2`: PASS; regenerated `trader2/AGENTS.md`.
- `sh /Users/brian/code/agent-contract/scripts/check.sh workspace /Users/brian/code/trader2`: PASS after regeneration.

## Reviewer Disposition

- Implementation hygiene is now in the shared contract and generated adapter
  template, not buried in a single consumer plan.
- Existing unrelated dirty work in `scripts/lib/registry.sh` was left untouched.

## Notes

- Do not edit consumer profiles to add workflow prose. Profiles provide facts;
  workflow policy belongs in the shared contract and generated template.
- Do not touch unrelated dirty files in this repo.
