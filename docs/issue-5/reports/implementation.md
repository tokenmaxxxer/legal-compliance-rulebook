---
subject: issue-5
role: implementation
loop_state: landed
---

# Implementation record — stub-check.sh recall (core #69 rollout)

## What was done

Executed the approved proposal
(`docs/issue-5/proposals/2026-07-31-stub-check-recall.md`) in one batch:

1. Deleted `legal-compliance/hooks/tests/stub-check.sh` — the sole vendored
   copy in this repo.
2. Checked `legal-compliance/hooks/hooks.json`: no `stub-check.sh`
   registration existed (only a `SessionStart` entry for `directive.sh`), so
   no edit was needed. File is unchanged and still valid JSON.
3. Ran core's `stub-check.sh` by reference against this rulebook and
   recorded the passing output below.

## Why

Core #69 finalized canon: `stub-check.sh` must be run by reference against
the core install, never vendored into a rulebook — mirroring how
`directive.sh` already resolves `role-directive.sh` by reference
(issue-2 precedent). See survey
(`docs/issue-5/reports/implementation/survey.md`) for the full
current-state findings this proposal was based on.

## Upstream basis

- `tokenmaxxxer/tokenmaxxxer-core` core issue #69 (stub-check.sh vendoring
  ban / reference-only canon), landed, documented in
  `docs/handbooks/canon-scripts.md` (core repo).

## Verification

Reference invocation of core's `stub-check.sh` against `legal-compliance/`:

```
stub-check: ok — no vendored 'trailer-gate.sh' under legal-compliance/
stub-check: ok — no vendored 'record-fields-gate.sh' under legal-compliance/
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under legal-compliance/
stub-check: ok — no vendored 'parse-check.sh' under legal-compliance/
stub-check: ok — no vendored 'stub-check.sh' under legal-compliance/
stub-check: ok — legal-compliance/hooks/directive.sh is a role-directive stub
```

Exit code 0.

`find legal-compliance/hooks -name stub-check.sh` returns nothing.
`legal-compliance/hooks/hooks.json` unchanged, validates as JSON.

## Open findings

None — target shape was fully determined by core #69's landed canon; no
open questions remained after survey.
