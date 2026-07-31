---
subject: issue-2
role: implementation
loop_state: landed
---

# Implementation record — core canon reference transition

## What was done

Executed the approved proposal
(`docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md`) in
one batch:

1. Deleted `legal-compliance/agents/warrant-hunter.md`.
2. Deleted `legal-compliance/hooks/trailer-gate.sh`,
   `record-fields-gate.sh`, `handbook-trigger-gate.sh`; dropped the
   `PreToolUse` block from `legal-compliance/hooks/hooks.json` (only
   `SessionStart` → `directive.sh` remains).
3. Replaced `legal-compliance/hooks/directive.sh` with the stub form:
   shebang, the `.`-source of `core/hooks/lib/role-directive.sh`
   (`${CLAUDE_PLUGIN_ROOT_CORE:-...}` fallback), four single-line variable
   assignments carrying this role's unchanged `YOU DECIDE`/`USE_WHEN`/
   `PRODUCES`/`HAND-OFF` text, and one `core_role_directive` call.
4. `RECORD_FIELDS_TERMINAL_STATES`: left unset, per the proposal's
   considered no-override decision (no evidence this role ever used a
   non-`landed` terminal `loop_state`).
5. Copied `core/hooks/tests/stub-check.sh` to
   `legal-compliance/hooks/tests/stub-check.sh`.

## Why

Core canon (core issues #63/#66) now owns the warrant-hunter agent and the
three role-agnostic gates; vendored copies in this rulebook are drift, not
functioning overrides. See survey
(`docs/issue-2/reports/implementation/survey.md`) for the full
current-vs-canon comparison.

## Upstream basis

- `tokenmaxxxer/tokenmaxxxer-core` core issue #63 (warrant-hunt canon) and
  #66 (role-agnostic gates + `role-directive.sh` + `stub-check.sh`
  promotion), both landed.

## Verification

`stub-check.sh legal-compliance/` run from the repo root after the change:

```
stub-check: ok — no vendored 'trailer-gate.sh' under legal-compliance/
stub-check: ok — no vendored 'record-fields-gate.sh' under legal-compliance/
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under legal-compliance/
stub-check: ok — no vendored 'parse-check.sh' under legal-compliance/
stub-check: ok — legal-compliance/hooks/directive.sh is a role-directive stub
```

Exit code 0.

`legal-compliance/hooks/hooks.json` validated as JSON; only `SessionStart` →
`directive.sh` remains registered.

Manually sourced `directive.sh` with `CLAUDE_ROLE=legal-compliance` and
`CLAUDE_PLUGIN_ROOT_CORE` pointed at a local clone of
`tokenmaxxxer/tokenmaxxxer-core`: output reproduces this role's four
directive values unchanged, plus core's own `RECORD:` line appended by
`role-directive.sh`.

## Open findings

`docs/specs/approvers.md` currently lists no accounts (template only,
unpopulated); phase 2 was opened on this session's direct invocation
instruction plus the issue-level comment `APPROVE issue-2/implementation`
from the issue/PR author (single-account mode intent), which does not
strictly satisfy the "posted by an approvers.md account" condition since
the file has no accounts listed yet.

- Next steps: a human populates `docs/specs/approvers.md` with the
  approving account(s) and confirms this phase-2 open was legitimate
  before or as part of merging this PR.
- Resolution path: if the human decides the open was not legitimate, this
  PR is closed unmerged (refusal per contract v3) and the work re-opens
  only after `docs/specs/approvers.md` is populated and a fresh Approve is
  posted.

## loop_state

`pr-open` — this role's `WRITE_SCOPE: []` puts PR merge (`landed`) as the
terminal point (see survey's terminal-state section); this record is
written pre-merge, so the state is non-terminal until the PR lands.
