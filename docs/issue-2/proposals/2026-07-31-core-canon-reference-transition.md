---
status: proposed
files:
  - legal-compliance/agents/warrant-hunter.md
  - legal-compliance/hooks/trailer-gate.sh
  - legal-compliance/hooks/record-fields-gate.sh
  - legal-compliance/hooks/handbook-trigger-gate.sh
  - legal-compliance/hooks/directive.sh
  - legal-compliance/hooks/hooks.json
  - legal-compliance/hooks/tests/stub-check.sh
  - docs/issue-2/reports/implementation.md
---

# Proposal — transition to core canon references (core #63/#66 rollout)

What was asked: issue #2, five items in one batch — remove this rulebook's
warrant-hunter copy, remove the three role-agnostic gate copies (+ their
hook registrations), reduce `directive.sh` to the core stub, preserve any
real per-role difference (terminal `loop_state` set) via
`RECORD_FIELDS_TERMINAL_STATES` if one exists, and record a passing
`stub-check.sh` run. See `docs/issue-2/reports/implementation/survey.md`
for the full current-vs-canon comparison this proposal is based on.

## What will be done (phase 2, on Approve)

1. Delete `legal-compliance/agents/warrant-hunter.md`. No other hunt-cadence
   text exists in this repo (survey confirms), so nothing else to touch for
   item 1.
2. Delete `legal-compliance/hooks/trailer-gate.sh`,
   `record-fields-gate.sh`, `handbook-trigger-gate.sh`. Edit
   `legal-compliance/hooks/hooks.json` to drop the `PreToolUse` block
   entirely (its only two matchers, `Write|Edit|MultiEdit` and `Bash`, exist
   solely to fire these three files) — `SessionStart` → `directive.sh`
   stays.
3. Replace `legal-compliance/hooks/directive.sh` with the stub form:
   shebang; the `trap .../set -uo pipefail` pair (kept locally per
   `role-directive.sh`'s own doc comment — a trap inside the sourced
   function can't catch the sourcing script's own abnormal exit); the
   `.`-source line resolving `core`'s `hooks/lib/role-directive.sh`
   (`${CLAUDE_PLUGIN_ROOT_CORE:-...}` fallback pattern from the lib's own
   usage header); one `core_role_directive` call carrying this role's four
   existing values verbatim (`YOU DECIDE`, `USE WHEN`, `PRODUCES`,
   `HAND-OFF` — unchanged text, just relocated out of the local heredoc).
4. `RECORD_FIELDS_TERMINAL_STATES`: **not set**. Survey found no evidence
   this role's records ever used a non-`landed` terminal `loop_state`, and
   `WRITE_SCOPE: []` puts this role's own PR-merge (→ `landed`) as its
   natural terminal point same as any other role. Recorded here as a
   considered "no override" rather than left silent, per the issue's own
   phrasing ("있으면" — only if a real difference exists).
5. Copy `core/hooks/tests/stub-check.sh` into
   `legal-compliance/hooks/tests/stub-check.sh` (distributed the same way
   `parse-check.sh` already is, per the file's own header and the issue-66
   report) and run it against `legal-compliance/` in phase 2; record the
   pass/fail output in `docs/issue-2/reports/implementation.md`.

## Deliberately not done

- No `hooks.json` entry replaces the deleted three gates — core fires them
  globally (`core/hooks/hooks.json`, confirmed landed). Re-registering them
  locally would itself be the drift `stub-check.sh` exists to catch.
- No dependency/manifest change to reference the `warrant` plugin — this
  repo declares no plugin dependencies today and installation/composition
  of marketplace plugins happens outside this repo (confirmed: this very
  session already runs the `core`/`warrant`-family hooks without any such
  declaration here). "Reference core canon" for item 1 is "stop vendoring
  a copy," not "add a manifest pointer."

## How it will be known to work

- `stub-check.sh legal-compliance/` exits 0 (no vendored copies of the three
  gates found; `directive.sh` matches the structural stub shape).
- `legal-compliance/hooks/hooks.json` still validates as JSON and only
  registers `directive.sh` under `SessionStart`.
- This role's four `directive.sh` values (`YOU DECIDE`/`USE WHEN`/
  `PRODUCES`/`HAND-OFF`) render unchanged when sourced — a manual invocation
  with `CLAUDE_ROLE=legal-compliance` reproduces the same directive text
  the current heredoc produces today, modulo the `RECORD:` line format
  (core's lib appends its own fixed `RECORD:` line — confirmed
  byte-comparable to this role's current one).

## Write set

Frozen to the eight paths listed in this file's frontmatter — deletions and
edits only, no new files beyond the vendored `stub-check.sh` copy and this
issue's own phase-2 record.

## Open question for the approver

None — the target shape is fully determined by the landed core canon
(#63/#66); item 4's only real judgment call (terminal-state override) is
resolved above with its rationale, not left open.
