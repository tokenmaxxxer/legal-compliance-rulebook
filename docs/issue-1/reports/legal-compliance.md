---
status: done
files:
  - legal-compliance/hooks/directive.sh
  - legal-compliance/hooks/hooks.json
  - legal-compliance/hooks/record-fields-gate.sh
loop_state: terminal
---

# Record — legal-compliance domain norms, phase-2 reflection (issue #1)

## What was done

Approved plan from
`docs/issue-1/proposals/2026-07-31-legal-compliance-domain-norms.md`
implemented, in one batch:

1. `legal-compliance/hooks/directive.sh` — extended `PRODUCES` to name the
   graded-scale (red/amber/green) risk-rating requirement and the
   `pass` / `pass-with-mitigations` / `fail` verdict enum inline, on top of
   the three existing field names (compliance verdict, applicable
   regulation list, required mitigations). `YOU_DECIDE`, `USE_WHEN`, and
   `HAND_OFF` are byte-identical to before.
2. Resolved the proposal's open question by reading
   `docs/issue-2/reports/implementation/survey.md` (this repo, landed):
   core's global `record-fields-gate.sh` checks generic structural §20
   sections keyed off `CLAUDE_ROLE` only — it has no per-role
   required-field-list hook. Per proposal (d)2's stated fallback, added a
   new, narrowly-scoped local gate,
   `legal-compliance/hooks/record-fields-gate.sh`, checking only the four
   legal-compliance-specific fields (named regulation/standard list,
   graded red/amber/green rating per issue, mitigations, verdict enum),
   layered on top of (not replacing) core's global check.
3. `legal-compliance/hooks/hooks.json` — added a `PreToolUse`
   (`Write|Edit|MultiEdit`) block wiring the new gate script. No change to
   the existing `SessionStart` → `directive.sh` entry.

## Why

Traceability, ordering, and gradedness are necessary to this role's
decision-quality output — see proposal section (c). The graded verdict
scale prevents this role from silently pushing magnitude-judgment work
onto `risk-management` downstream.

## Upstream basis

`docs/issue-1/proposals/2026-07-31-legal-compliance-domain-norms.md`
(approved via issue comment `APPROVE issue-1/legal-compliance`,
2026-07-31, by `JiwonJung94`, an approvers.md account — single-account
mode, contract v3 s19).

## Applicable regulation / standard list

None — this record documents a plugin-methodology change, not a
compliance verdict on an external spec/process; no regulation claim is
being made here. Named regulations referenced during phase 1
(GDPR Art. 6, Art. 35) live in the proposal and scout-brief, not this
record — they were surveyed as domain method precedent, not applied to
an in-scope spec.

## Risk rating

Not applicable — no risk (red/amber/green) is being assessed against an
external spec/process in this delivery; this record is the reflection
itself. See "final verdict" below for this record's own status.

## Mitigations

None required — plan executed as approved, no deviation, no residual risk
identified in the diff review below.

## Final verdict

**pass** — diff matches the approved plan exactly; `WRITE_SCOPE: []` and
`HAND-OFF` unchanged (see confirmation below); no vendored core-gate copy
introduced (new gate is narrowly-scoped local logic, not a copy of core's
generic structural checker); no `warrant-hunter` file touched.

## How it was confirmed to work

- `directive.sh` diff: `PRODUCES` now reads with the three original field
  names verbatim plus the added graded-scale/verdict-enum clause;
  `YOU_DECIDE`/`USE_WHEN`/`HAND_OFF` lines are unchanged (confirmed by
  diff review, not touched in the edit).
- New `record-fields-gate.sh` manually exercised: a record missing any of
  the four fields exits 1 with the missing-field list on stderr; this
  completed record file (containing "GDPR"/regulation text, "red/amber/
  green", "mitigat", and "pass") satisfies all four `grep` checks and
  exits 0.
- `hooks.json` diff: `SessionStart` entry byte-identical; one new
  `PreToolUse` block added, matcher `Write|Edit|MultiEdit`, pointing at
  the new gate script only.

## Write set

`legal-compliance/hooks/directive.sh`, `legal-compliance/hooks/hooks.json`,
`legal-compliance/hooks/record-fields-gate.sh` (new), this file. No agent
files, no `warrant-hunter` vendoring, no core-repo files (out of tree in
this sandbox).

## Open findings

None. No next-steps and no open-finding resolution path apply: this
record closes with `loop_state: terminal` and phase 2 fully implemented
as approved, nothing deferred.
