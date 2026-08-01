# Scout brief — gate A+ final closeout (issue #16)

## Skip record

Sweep/deepening (external web research) skipped. Condition: "the spec
literally leaves no design decision open" applies to the D1 fix — issue
#16 explicitly mandates reference-applying core #75's already-landed,
finalized guard form and function, not designing a new one. The other
defects (D2/D3/D4) are repo-local bug fixes against this repo's own
prior-issue (issue-13) precedent, not a category with external
best-in-class exemplars to sweep.

## What was scouted instead: the one authoritative source (core main)

Per this repo's own established pattern (issue-13: "reference-adopt,
never reimplement" the gate-house standard), the exemplar to match is
`tokenmaxxxer/tokenmaxxxer-core`'s own landed fix, fetched and read in
full (survey.md's Precondition section):

- Guard form (from `core/hooks/lib/gate-lib.sh`'s own usage-contract
  comment, the canonical call site core's own 5 gates now use):
  `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh" || { echo
  "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`
- `gate_bash_write_targets` py mirror: `core/hooks/lib/gate-lib.py`,
  `_BASH_WRITE_TARGET_RE = re.compile(r"[A-Za-z0-9_./~$-]+")` — identical
  character class to this repo's existing inline token-scan regex (already
  matches; no functional change needed here, only optional simplification).
- `compliance-check.sh` rule 3 (source-guard detection): fires on any
  `*-gate.sh` file whose `gate-lib\.sh"$` line lacks a same-line `\|\|`.

Must-be (from the exemplar): the guard's error message and exit code are
uniform across core's own 5 gates (`"<gate-name>.sh: cannot source
gate-lib.sh"`, exit 2) — adopt the same message shape per gate, substituting
each gate's own name, for cross-repo consistency.

Adopt: the exact guard form verbatim (not a repo-local variant) — this is
the entire point of reference-adoption; a locally-invented guard string
would pass compliance-check's regex today but drift from core's next
revision.

Skip: no pattern skipped — the fix is a narrow, fully-specified mechanical
change.

Gap line: this repo's three gates currently have 0/3 of the guard core now
requires; the fix brings them to 3/3, matching core's own 5/5.

Sources:
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/lib/gate-lib.sh (fetched via `gh api repos/tokenmaxxxer/tokenmaxxxer-core/contents/core/hooks/lib/gate-lib.sh`, commit 52bdc15)
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/lib/gate-lib.py (same commit)
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/tests/compliance-check.sh (same commit)
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/75 (defect origin, closed)
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/77 (merged fix, test plan)

Mode: single-session sequential `gh api` reads (no parallel dispatch —
one linear source-of-truth fetch, not a multi-angle sweep; stated per the
fallback-disclosure requirement even though the sweep stage itself was
skipped for the stated reason above).
