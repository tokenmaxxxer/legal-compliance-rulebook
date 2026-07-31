---
subject: issue-2
role: implementation
loop_state: scope-proposed
---

# Current-state survey — core canon reference transition

## Scope-skip record (scout-directive)

Full scout sweep skipped: this is an infra-migration task whose target shape
is fully specified by the already-landed upstream work (core repo issues
#63/#66) rather than an open product design space. In place of web-sweep
scouting, the landed core canon (`tokenmaxxxer/tokenmaxxxer-core`) and its
own migration report were read directly as the "best-in-class exemplar" —
this is the one and only canon, not a field of competitors to sample. See
Sources below.

## This repo's current vendored state

- `legal-compliance/agents/warrant-hunter.md` — role-flavored copy of the
  hunt agent (mandate text quotes this role's own decision boundary). Core's
  canon version (`warrant` plugin's `agents/warrant-hunter.md`) is fully
  role-agnostic — no role-specific text at all, reads `CLAUDE_ROLE`/context
  from its dispatch prompt only. No hunt-cadence text exists elsewhere in
  this repo (grepped `legal-compliance/` and `docs/` for `hunt|warrant` —
  only the one file matched).
- `legal-compliance/hooks/hooks.json` registers three role-agnostic gates
  directly: `record-fields-gate.sh` (PreToolUse, Write|Edit|MultiEdit),
  `handbook-trigger-gate.sh` + `trailer-gate.sh` (PreToolUse, Bash).
- `legal-compliance/hooks/trailer-gate.sh`, `record-fields-gate.sh`,
  `handbook-trigger-gate.sh` — vendored copies, each header-commented as
  "adapted... role name substituted only (this file's logic is
  role-agnostic)" or, for record-fields-gate.sh, a placeholder skeleton
  (`REQUIRED_FIELDS = ["compliance-verdict", ...]`, substring match).
- `legal-compliance/hooks/directive.sh` — full boilerplate (trap, kill-switch
  case, `CLAUDE_ROLE` guard, heredoc) with this role's four values inlined.

## Core canon target state (read from `tokenmaxxxer/tokenmaxxxer-core`)

- `core/hooks/hooks.json`'s `PreToolUse` (`matcher: ".*"`) already fires
  `trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`
  (plus `board-gate.sh`/`approval-gate.sh`/`gh-guard.sh`) for **every**
  plugin install — core issue #66, landed. A rulebook's own copy of any of
  these three is pure drift now, not a functioning override.
- `core/hooks/record-fields-gate.sh` is materially different logic from this
  repo's skeleton copy: canon checks structural §20 sections (what-was-done,
  why, upstream-basis, `loop_state:` line, open-findings, and — only when
  `loop_state` is non-terminal — next-steps/resolution-path), keyed off
  `CLAUDE_ROLE` at runtime, not this role's own `produces` field list. The
  vendored copy's `REQUIRED_FIELDS = compliance-verdict/...` check is
  superseded, not equivalent — deleting it is a behavior change (stricter,
  role-agnostic §20 shape replaces a field-name grep), not a no-op.
- `core/hooks/lib/role-directive.sh` exposes `core_role_directive
  <you_decide> <use_when> <produces> <hand_off>`. Per its own header, a
  rulebook's `directive.sh` shrinks to: shebang, the `trap`/`set -uo
  pipefail` pair (cannot be factored into the sourced function — a trap
  inside a sourced function does not catch the sourcing script's own
  abnormal exit), the `.` source line, and the one call.
- `core/hooks/tests/stub-check.sh` — drift detector, distributed the way
  `parse-check.sh` already is. Fails if any of
  `trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh`/
  `parse-check.sh` is found under a rulebook's `hooks/` tree at all
  (absence-based), and structurally checks `directive.sh` is exactly the
  source-line + var-assignments + one `core_role_directive` call shape
  (anything else = regrown boilerplate = fail). This repo has no local copy
  of `parse-check.sh` today, so only the three gate files and `directive.sh`
  are load-bearing checks here.
- Core issue #66's implementation report states the per-rulebook follow-up
  explicitly (see Sources) — delete the three gate files + their
  `hooks.json` entries, replace `directive.sh` with the lib-call stub, drop
  `stub-check.sh` into the rulebook and wire it into its own test harness,
  and set `RECORD_FIELDS_TERMINAL_STATES` if this role's terminal
  `loop_state` set differs from the canon default (`landed`).
- `warrant/agents/warrant-hunter.md` is the canon hunter; a rulebook
  "referencing" it means simply not vendoring a copy — install/composition
  of the `warrant` marketplace plugin alongside this rulebook plugin is
  handled outside this repo (confirmed: this very session already runs
  under `core`/`warrant`-family hooks without this repo declaring any
  plugin dependency file). No in-repo manifest change is needed for item 1
  beyond deleting the vendored file.

## Terminal `loop_state` question (issue task 4)

No local evidence this role's records have ever used a non-`landed`
terminal state — `docs/issue-2/reports/legal-compliance.md` does not exist
yet (phase-2 record) and this role's `directive.sh` names no loop_state
vocabulary of its own. `WRITE_SCOPE: []` — legal-compliance produces only
its own decision record; its PR getting merged (accepted per contract v3)
lines up with the canon default `landed` as the terminal point, same as any
other role. No basis found to diverge from the default; proposal is not to
set `RECORD_FIELDS_TERMINAL_STATES` and to record that as a considered
decision rather than an oversight.

## Sources

- `tokenmaxxxer/tokenmaxxxer-core` (cloned read-only for this survey):
  `core/hooks/hooks.json`, `core/hooks/record-fields-gate.sh`,
  `core/hooks/lib/role-directive.sh`, `core/hooks/tests/stub-check.sh`,
  `warrant/agents/warrant-hunter.md`, `warrant/README.md`,
  `.claude-plugin/marketplace.json`
- `docs/issue-66/reports/implementation.md` (tokenmaxxxer-core) — landed
  migration report naming the exact per-rulebook follow-up steps
- `docs/issue-63/proposals/2026-07-31-build-warrant-hunt-canon-and-efficiency.md`
  (tokenmaxxxer-core) — warrant-hunt canon promotion (issue #63)
- `tokenmaxxxer/implementation-rulebook` (cloned read-only) — checked for
  prior art; this rulebook has **not** migrated either (still vendors
  `coding/agents/warrant-hunter.md` and the three gates), so there is no
  already-migrated sibling to copy from — this issue is a first mover, not
  a follow of an existing pattern.
