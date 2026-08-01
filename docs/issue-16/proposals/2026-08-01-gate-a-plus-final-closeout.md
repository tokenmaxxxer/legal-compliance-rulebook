# Proposal — gate A+ final closeout (issue #16)

## Scope

In scope: fixing every residual defect the 2026-08-01 re-audit named
(survey.md D1-D5), reference-applying core #75's now-landed guard form and
`gate_bash_write_targets` py parity, and closing requirement 3
(missing-core test case + green suite + compliance-check record) and
requirement 4 (README/manifest ghost/stale-name zero).

Out of scope: renaming `gate.sh` -> `*-gate.sh` to satisfy
`compliance-check.sh`'s file-discovery glob (survey.md, "Not reproduced /
out of scope" — pre-existing, previously flagged, not requested by this
issue's text); any change to the gates' semantic *policy* not named by the
audit (a1-a4, b1-b5, and the fan-out completeness rule stay as currently
designed, only their implementation bugs are fixed).

## Regulation / standard list (applicable norms this proposal must satisfy)

- Issue #1's phase-1/phase-2 domain norms (a1-a4, b1-b5) — unchanged by
  this proposal, referenced for continuity.
- core's gate-house standard (issue #72), as amended by core #75 — the
  mandatory `||`-guarded source form and `gate_bash_write_targets` py
  parity this proposal must reference-adopt verbatim (scout-brief.md).
- This repo's own issue-13 precedent — reference-adopt-not-reimplement
  posture, six-mandatory-test-case-group requirement (now seven with
  missing-core added by core #75).
- No exclusions: every named upstream norm applies to all three gates
  uniformly; no gate is carved out.

## Necessity / proportionality rationale

Each fix is the minimum change that closes a specific, reproduced defect
(survey.md), not a rewrite:

- D1 (source guard): a one-line addition (`|| { ... exit 2; }`) per
  gate's existing source statement — necessary because the current form
  is confirmed fail-open under the exact missing-core topology core #75
  was opened to fix, and proportionate because it is the identical,
  already-reviewed guard core's own 5 gates now carry (no local
  variant invented).
- D2 (`section` bare-word bypass): drop one alternation branch
  (`\bsection\b`) from `ref_re` — necessary because it is proven
  self-satisfying exactly like the already-fixed `risk` bug, and
  proportionate because no other part of the check needs to change.
- D3 (necessity/mitigation structural pairing): requires an actual
  algorithm change (see Mitigations) since the current per-section
  first-occurrence comparison is not equivalent to structural pairing —
  necessary because the issue explicitly names this as unresolved, and
  proportionate because the fix stays within a3's existing helper
  functions (`extract_headings`/`section_body`), no new check surface.
- D4 (README/manifest staleness): documentation-only edits to the exact
  paragraphs survey.md quotes; no behavior change.
- D5 (matcher/code parity): already satisfied (survey.md D5) — no code or
  config change; only the D4 README fix, since the gap is the README
  under-documenting already-correct code, not a matcher/code mismatch.

Only after establishing necessity/proportionality above does this
proposal name mitigations below — mitigations never precede this section
in this document's structure (a1-style ordering, applied to the proposal's
own writing, not only the gates' enforcement of it).

## Mitigations (mapped 1:1 to survey.md's defects)

- **D1** (mitigates: fail-open on unreachable core, all 3 gates) — replace
  each gate's bare `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"`
  with the guard verbatim from core's gate-lib.sh usage-contract comment
  (scout-brief.md), substituting each gate's own name in the error
  message:
  `. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`
  applied to: `legal-compliance-phase1-proposal-gate/hooks/gate.sh:12`,
  `legal-compliance-phase2-record-gate/hooks/gate.sh:14`,
  `legal-compliance-fanout-completeness-gate/hooks/gate.sh:2`. Closes red
  -> green (core #75-class defect).
- **D2** (mitigates: bare-word "section" self-satisfying the 1:1
  mitigation-citation check) — in
  `legal-compliance-phase2-record-gate/hooks/checker.py`'s `ref_re`, drop
  the `\bsection\b` alternative, same as `risk` was dropped in issue-13.
  Closes red -> green.
- **D3** (mitigates: necessity/proportionality-before-mitigation still
  effectively keyword-offset) — change a3's check from "does *any* earlier
  section contain necessity language" to true structural pairing: for
  every section whose body contains "mitigat" language, that section (or
  an ancestor section by heading nesting, walked via the existing
  `headings`/level list) must itself contain necessity/proportionality
  language at or before the first "mitigat" occurrence within that same
  section body; a mitigation section with no necessity language in its own
  scope (own body or an ancestor's) fails, regardless of unrelated
  necessity-shaped text elsewhere in the document. Implemented via the
  existing `extract_headings`/`section_body` helpers already shared with
  phase2's checker — no new parsing primitive. Closes red -> green
  (issue-16-named unresolved gap).
- **D4** (mitigates: stale kill-switch/trap semantics prose, undocumented
  Bash/NotebookEdit coverage, in all three plugin READMEs) — rewrite the
  quoted paragraphs in `legal-compliance-{phase1-proposal,phase2-record,fanout-completeness}-gate/README.md`
  to state: `gate_kill_switch_active`'s actual on-spelling-only semantics
  (`1`/`true`/`yes`/`on` disables; every other value, including
  unrecognized, stays active); `gate_trap_fail_closed`'s EXIT-trap
  mechanism (not a local `set -euo pipefail` + `ERR` trap); the actual
  `Write|Edit|MultiEdit|Bash|NotebookEdit` matcher and each gate's
  Bash-conservative-deny + NotebookEdit-reconstruction coverage. Closes
  amber -> green.
- **D5** (mitigates: nothing — parity already holds) — no gate/hooks.json
  change; folded into D4's README fix, which is the only place the gap
  (docs under-stating already-correct coverage) actually lives.

## Test / verification plan (phase 2, previewed here per requirement 3)

- Add a `missing-core` deny test case (per core #75's own new mandatory
  group) to all three suites: point `CLAUDE_PLUGIN_ROOT_CORE` at a
  nonexistent path, assert exit 2 and the guard's own stderr message (not
  a silent allow / not an unrelated crash).
- Add a `section`-bare-word regression case to the phase2 suite: a
  mitigation bullet citing only "the section above," asserting deny (mirrors
  the existing "mitigate the risk" audit-bug-reproduction case already in
  that suite).
- Add a structural-pairing regression case to the phase1 suite: a document
  with necessity language only in an unrelated early section and a
  Mitigations section with no necessity language of its own, asserting
  deny (previously a false-allow).
- Re-run the existing six-group suites (replace_all Edit, mixed-replace_all
  MultiEdit, three malformed-JSON shapes, unrecognized kill-switch value,
  absolute/dot-slash path variants, Bash-write-reaching-scope) unchanged —
  no regression expected since D1-D3's fixes are additive/narrowing, not
  structural rewrites of those paths.
- Run `core/hooks/tests/compliance-check.sh` against each of the three
  gate directories; expect the D1 fix to make the source-guard condition
  pass structurally (the file-discovery glob-miss on bare `gate.sh` names
  stays, per survey.md's "Not reproduced" section — verify the two/three
  substantive conditions directly against file content, same as issue-13's
  record did, and state the glob-miss explicitly rather than omitting it).
- Full aggregator run (`tests/legal-compliance/run-gate-lib-tests.sh`)
  green, new case counts documented in the phase-2 record.

## Risk rating

- D1 source-guard fail-open (all 3 gates): red
- D2 "section" bare-word citation bypass: red
- D3 necessity/mitigation not structurally paired: red
- D4 README stale kill-switch/trap semantics + undocumented coverage (all 3): amber
- D5 matcher/code parity: green already (no residual risk; verification-only)

## Final verdict

pass-with-mitigations. All four re-audit-named defect classes (D1-D4) have
a concrete, scoped, previously-precedented fix named above; D5 requires no
code change. Phase 2 applies these fixes exactly as scoped here plus the
verification plan, then records the result in
`docs/issue-16/reports/legal-compliance.md`. This document does not
self-approve; phase 2 opens only on human Approve (contract v3 s19).

## Write set (frozen; phase 2 touches exactly these paths, no others)

- `legal-compliance-phase1-proposal-gate/hooks/gate.sh`
- `legal-compliance-phase2-record-gate/hooks/gate.sh`
- `legal-compliance-phase2-record-gate/hooks/checker.py`
- `legal-compliance-fanout-completeness-gate/hooks/gate.sh`
- `legal-compliance-phase1-proposal-gate/README.md`
- `legal-compliance-phase2-record-gate/README.md`
- `legal-compliance-fanout-completeness-gate/README.md`
- `tests/legal-compliance/phase1-proposal-gate-tests.sh`
- `tests/legal-compliance/phase2-record-gate-tests.sh`
- `tests/legal-compliance/fanout-completeness-gate-tests.sh`
- `docs/issue-16/reports/legal-compliance.md` (phase-2 record, added then)

## Open questions

- None blocking phase 2 — the source-guard form, the two check-logic
  fixes, and the README corrections are each fully specified above against
  reproduced, cited defects.
