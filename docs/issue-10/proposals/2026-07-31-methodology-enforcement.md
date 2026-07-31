---
status: proposed
files:
  - legal-compliance/hooks/directive.sh
  - legal-compliance/hooks/hooks.json
  - legal-compliance/hooks/methodology-gate.sh
  - tests/legal-compliance/methodology-gate-tests.sh
  - docs/handbooks/legal-compliance/phase-checklist.md
  - docs/issue-10/reports/legal-compliance.md
---

# Proposal — enforce the adopted methodology as a gate (issue #10)

## What was asked

Issue #10: the domain methodology adopted in issue #1
(`docs/issue-1/proposals/2026-07-31-legal-compliance-domain-norms.md`)
landed as directive prose and one shallow presence-check gate
(`record-fields-gate.sh`). Bring this rulebook's enforcement up to
`implementation-rulebook`'s bar: deepened phase-1/phase-2 directives,
a methodology gate that mechanically checks the required elements (with
state tracking if an ordering constraint needs it), gate tests, and
agents/checklists if the methodology has a repeated procedure. See
`docs/issue-10/reports/legal-compliance/survey.md` for the current gap
and `docs/issue-10/reports/legal-compliance/scout-brief.md` for the
sourced comparison this proposal is grounded in.

## What will be done (phase 2, on Approve)

### 1. Directive deepening (`directive.sh`)

Replace the current one-line `PRODUCES` string with facet-level text for
both phases, sourced verbatim from issue-1's adopted norms (no new
methodology invented here — this issue mechanizes what #1 already
adopted):

- **Phase 1 (proposal) facet**: steps — (i) state the spec/process under
  review and its scope boundary; (ii) enumerate candidate regulations by
  name and state exclusions; (iii) give a necessity/proportionality
  rationale *before* naming any mitigation; (iv) an Evidence/rationale
  section citing, per adopted position, either a named regulation clause,
  a cited section of the reviewed spec, or an explicit "assumption,
  unsourced" label. Judgment criterion: a claim with no traceable source
  is an assumption, stated as one, never presented as a finding.
  Prohibition: no mitigation may be named before its risk/proportionality
  rationale is stated (ordering, not just presence).
- **Phase 2 (record) facet**: required fields — named regulation/standard
  list; graded (red/amber/green) risk rating per identified issue;
  mitigations, each naming the specific risk/clause pair it addresses;
  final verdict (`pass`/`pass-with-mitigations`/`fail`) derived from the
  ratings above, never independent of them. Prohibition: no verdict may
  be entered that does not trace to a rating already stated in the same
  record.

`YOU_DECIDE`, `USE_WHEN`, `HAND_OFF`, and `WRITE_SCOPE: []` stay
byte-identical — this only deepens `PRODUCES`.

### 2. Methodology gate (`legal-compliance/hooks/methodology-gate.sh`)

New `PreToolUse` (`Write|Edit|MultiEdit`) hook, in the shape scouted from
`pricing-rulebook`'s `methodology-gate.sh` (referenced as a pattern, not
copied — no file from `core/hooks/` or another rulebook's tree is
vendored; this is a new, role-specific script per the canon-scripts
clause). Bash wrapper (fail-closed `trap` on non-0/non-2 exit, kill switch
`LEGAL_COMPLIANCE_METHODOLOGY_GATE_OFF`) around an embedded Python check
that:

- Resolves the write's real path and matches it against two surfaces
  independently:
  - `docs/issue-<n>/proposals/.*legal-compliance.*\.md` (phase-1) —
    requires: a stated scope/boundary phrase; a regulation-enumeration
    section that also states at least one exclusion (or "no exclusions"
    explicitly); necessity/proportionality language whose text position
    precedes the first mitigation mention (the one ordering check this
    gate performs, done by string-offset comparison within the single
    document being written — no cross-call state needed, see "Ordering
    without state tracking" below); an Evidence/rationale section with at
    least one citation-or-assumption-label per adopted position (heuristic:
    at least one "assumption, unsourced" or a regulation-citation pattern
    like `Art\.` / `§` / named-act-plus-clause per bullet under that
    section).
  - `docs/issue-<n>/reports/legal-compliance\.md` (phase-2) — supersedes
    `record-fields-gate.sh`'s four presence checks with the same four
    plus one 1:1-mapping heuristic: the count of mitigation bullets must
    not exceed the count of distinct risk/regulation-clause references
    they cite (best-effort structural check, not a full parse — a
    mitigation bullet with no clause/risk reference in its own line fails
    it).
  - Any other write is out of this gate's business (exits 0 immediately),
    same as the scouted pattern.
- Fails closed (exit 2, message naming the missing element(s)) on:
  unparseable JSON payload, an Edit/MultiEdit whose `old_string` cannot be
  found in the pre-write content (matches the resolved-content-unknown
  case the scouted pattern already handles), and any internal exception.
- `legal-compliance/hooks/record-fields-gate.sh` is retired in the same
  change (its four checks are strictly subsumed by the new gate's
  phase-2 branch) rather than left running in parallel — two gates
  checking overlapping ground on the same write surface is exactly the
  kind of drift issue-2/issue-5 already closed for this repo.

### Ordering without state tracking

Issue #10 asks for state tracking "필요 시" (if needed). This role's only
ordering constraint — necessity/proportionality before mitigations — is
**intra-document**: both the constraint and its violation are fully
visible inside the single file content the gate already receives on one
`Write`/`Edit`/`MultiEdit` call. It never spans multiple tool calls or
turns the way `implementation-rulebook`'s hunt-cadence ordering does
(scout-brief's "one pattern to skip"). No `hunt-state.sh`-equivalent
state file is proposed. If a future issue introduces a genuinely
cross-call ordering constraint for this role, that would be the trigger
to revisit this decision — not before.

### 3. Gate tests (`tests/legal-compliance/methodology-gate-tests.sh`)

New fixture-based test file at the repo root (not under `docs/`, per
contract v3's `test/` output-layout rule), following
`implementation-rulebook/tests/run-gate-tests.sh`'s shape: a small runner
that feeds synthetic `PreToolUse` JSON payloads (a `Write` with
`tool_input.content` set to fixture text) to `methodology-gate.sh` on
stdin and asserts the exit code. Fixture cases:

1. Proposal missing a scope-boundary statement → deny (exit 2).
2. Proposal stating a mitigation before its necessity/proportionality
   rationale (ordering violation) → deny.
3. Proposal with scope, regulation enumeration + exclusion, correctly
   ordered rationale, and a fully cited Evidence section → allow (exit 0).
4. Proposal with one adopted position carrying no citation and no
   "assumption, unsourced" label → deny.
5. Record missing the graded red/amber/green rating → deny.
6. Record with a mitigation bullet citing no risk/clause → deny (1:1
   heuristic).
7. Record conforming to all four fields plus the mapping heuristic →
   allow.
8. A write to an unrelated path (e.g. `README.md`) → allow, gate is a
   no-op (confirms the resolved-path targeting doesn't over-fire).

### 4. Agents / checklist

No `agents/` addition. The methodology's "repeated procedure" is a fixed
set of required sections applied identically to every proposal and every
record — a static structural checklist, not an iterative multi-step
behavior (no hunting/searching loop the way `warrant-hunter` has). A
lightweight `docs/handbooks/legal-compliance/phase-checklist.md` is
proposed instead: the same four phase-1 items and four phase-2 items
listed above, as a human-readable checklist mirroring what the gate
checks mechanically — for a proposal author to self-check before the
gate runs, not a new enforcement surface. This mirrors issue-1's own
precedent of declining to add agent files for this role.

## Deliberately not done

- No `agents/` directory or new agent file (see above).
- No cross-call state-tracking file — see "Ordering without state
  tracking" above.
- No vendoring of any `core/hooks/` or `pricing/hooks/`/
  `implementation-rulebook` script — `methodology-gate.sh` is a new,
  role-specific file; the scouted repos are referenced as pattern
  precedent only, per `core`'s canon-scripts clause.
- No change to `YOU_DECIDE`, `USE_WHEN`, `HAND_OFF`, or `WRITE_SCOPE: []`.
- No new regulation/methodology content — this issue mechanizes issue-1's
  already-adopted norms; it does not adopt new domain methodology.

## How it will be known to work

- `tests/legal-compliance/methodology-gate-tests.sh` runs all 8 fixture
  cases above and each asserts the exit code the case name implies.
- `record-fields-gate.sh` no longer exists (or is a no-op stub with a
  pointer comment) and `hooks.json`'s `PreToolUse` entry points only at
  `methodology-gate.sh`.
- Manually sourcing `directive.sh` with `CLAUDE_ROLE=legal-compliance`
  reproduces the four original phase-2 field names verbatim plus the new
  phase-1/phase-2 facet text; `YOU_DECIDE`/`USE_WHEN`/`HAND_OFF`/
  `WRITE_SCOPE` are byte-identical to today's via diff review.

## Write set

This phase (phase 1): the two files under
`docs/issue-10/reports/legal-compliance/` and this proposal file only —
no plugin, hook, test, or handbook files touched. Phase 2 (on Approve):
frozen to the files listed in this document's frontmatter.

## Open question for the approver

`record-fields-gate.sh` retirement: this proposal folds its four checks
into the new gate and removes the old file rather than keeping both.
Confirm that's preferred over leaving `record-fields-gate.sh` running
as a redundant secondary check — the proposal's default is "one gate per
write surface," matching the drift-avoidance precedent issue-1's own
plan already cited (core's gate vs. a local gate), but this is the
approver's call to make explicit before phase 2 executes.
