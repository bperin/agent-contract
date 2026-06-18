# Legacy Local Adapter Template

Local repos should not hand-author workflow policy from this template anymore.
Use the shared generator instead:

```bash
sh /absolute/path/to/agent-contract/scripts/apply.sh <profile> <repo-root>
```

Consumer repos should keep repo-specific facts in
`agent-contract-local/profiles/<profile>.env` and let `apply.sh` overwrite the
local `AGENTS.md` deterministically.
