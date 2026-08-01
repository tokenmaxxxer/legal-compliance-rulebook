# Record — gate A+ final closeout (issue #16)

loop_state: landed

## What was done

Fixed all four residual defects (D1-D4) the 2026-08-01 re-audit named
against `legal-compliance`'s three gate plugins (issue #16), per the
approved proposal (`docs/issue-16/proposals/2026-08-01-gate-a-plus-final-closeout.md`,
approved via `APPROVE issue-16/legal-compliance`): guarded all three
gates' `gate-lib.sh` source line, fixed the `section` bare-word citation
bypass, rewrote the necessity/mitigation check to true structural
pairing, corrected stale README semantics, added missing-core and
regression test cases to all three suites, and recorded the result here.

## Why

Issue #16 requires closing the re-audit's named residual defects before
this rulebook's gate set can be considered A+ complete: D1 was a
confirmed fail-open (silently allows every write the gate exists to
police) under the exact unreachable-core topology core #75 was opened to
fix; D2/D3 were confirmed self-satisfying/bypassable check logic;
D4/requirement 4 kept the plugin READMEs and manifests accurate against
already-shipped behavior so operators are not misled about what the
gates actually enforce.

## Upstream basis

- core #75 (merged, PR #77 — `tokenmaxxxer/tokenmaxxxer-core`): the
  reference-adopted `||`-guarded source form and `gate_bash_write_targets`
  py parity.
- This repo's own issue-13 precedent (PR #14/#15): reference-adopt-not-
  reimplement posture, the `risk` bare-word drop this issue-16's D2
  mirrors.
- `docs/issue-16/proposals/2026-08-01-gate-a-plus-final-closeout.md`
  (this issue-16's own approved phase-1 proposal), approved via the
  issue-level `APPROVE issue-16/legal-compliance` comment.

## Regulations / standards applied

- Issue #1's phase-1/phase-2 domain norms (a1-a4, b1-b5) — unchanged,
  referenced for continuity.
- core's gate-house standard (issue #72), as amended by core #75
  (merged, PR #77): the mandatory `||`-guarded source form and
  `gate_bash_write_targets` py parity.
- This repo's own issue-13 precedent (reference-adopt, not reimplement).
- Issue-16's own 2026-08-01 re-audit findings (D1-D5), remediated by this
  record.
- No exclusions: every named upstream norm applies to all three gates
  uniformly.

## Risk rating (post-fix)

- D1 source-guard fail-open (all 3 gates, issue-16): green (fixed)
- D2 "section" bare-word citation bypass (issue-13 precedent): green
  (fixed)
- D3 necessity/mitigation-pairing check (issue-16): green (fixed)
- D4 README stale kill-switch/trap semantics + undocumented coverage,
  issue-16 (all 3 plugins): green (fixed)
- D5 matcher/code parity (issue-16): green (no code change needed;
  verified)

## Mitigations applied (1:1 with the audit's defects, per the approved
proposal)

- **D1** (issue-16): added `|| { echo "<gate-name>.sh: cannot source
  gate-lib.sh" >&2; exit 2; }` to the `gate-lib.sh` source line, verbatim
  per core #75's usage-contract comment, in
  `legal-compliance-phase1-proposal-gate/hooks/gate.sh`,
  `legal-compliance-phase2-record-gate/hooks/gate.sh`, and
  `legal-compliance-fanout-completeness-gate/hooks/gate.sh`.
- **D2** (issue-13 precedent): dropped `\bsection\b` from `ref_re` in
  `legal-compliance-phase2-record-gate/hooks/checker.py` (same class of
  fix as issue-13's `risk` drop).
- **D3** (issue-16): rewrote a3 in
  `legal-compliance-phase1-proposal-gate/hooks/gate.sh` from a
  whole-document first-occurrence comparison to true structural pairing:
  for every heading whose own direct body (text before its next heading,
  not the whole subtree) contains "mitigat" language, that heading or an
  ancestor (by heading-level nesting) must itself contain
  necessity/proportionality language — at or before the first "mitigat"
  occurrence for the heading's own body, anywhere in an ancestor's own
  body. Implemented via the existing `extract_headings`/`section_body`
  helpers plus a new `own_body`/`ancestor_indices` pair (no new parsing
  primitive; `own_body` is a narrower window than `section_body`, needed
  because `section_body` on a document's single top-level heading spans
  the entire document and would otherwise make the check vacuous).
- **D4** (issue-16): rewrote the kill-switch, trap/fail-closed, and
  matcher/coverage paragraphs in all three plugins' `README.md` to state
  the actual on-spelling-only kill-switch semantics, the actual
  `gate_trap_fail_closed` EXIT-trap mechanism (`set -uo pipefail`, no
  `-e`), and the actual `Write|Edit|MultiEdit|Bash|NotebookEdit` matcher
  with each gate's Bash-conservative-deny and NotebookEdit-reconstruction
  coverage. `legal-compliance-phase2-record-gate/README.md` additionally
  corrected a stale reference to "the word risk" as an accepted citation
  (it and "section" are both confirmed self-satisfying and excluded).
- **D5** (issue-16): no code/config change (matcher and code were
  already in parity); the gap was folded into D4's README fix.

## Test / verification results

- `tests/legal-compliance/phase1-proposal-gate-tests.sh`: 19 passed, 0
  failed. Added case 13 (structural-pairing regression: necessity
  language only in an unrelated early section, Mitigations section with
  none of its own — previously false-allowed, now denies) and case 14
  (missing-core: `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path
  asserts exit 2 and the guard's own stderr message).
- `tests/legal-compliance/phase2-record-gate-tests.sh`: 19 passed, 0
  failed. Added case 14 (a mitigation bullet citing only "the risk
  section above" — no `Art.`/`§`/regulation name/issue-N — asserts
  deny) and case 15 (missing-core, same shape as above).
- `tests/legal-compliance/fanout-completeness-gate-tests.sh`: 17 passed,
  0 failed. Added case 12 (missing-core, same shape as above).
- All pre-existing cases (replace_all Edit, mixed-replace_all MultiEdit,
  malformed-JSON shapes, unrecognized kill-switch value, absolute/
  dot-slash path variants, Bash-write-reaching-scope, and the phase-2
  section-scoping/`risk`-bare-word regressions from issue-13) re-run
  unchanged and stay green — D1-D3's fixes were additive/narrowing, not
  structural rewrites of those paths.
- Full aggregator (`tests/legal-compliance/run-gate-lib-tests.sh`): all
  three suites report OK; total 55 cases green (19 + 19 + 17).
- `core/hooks/tests/compliance-check.sh` (issue-16 precondition, core
  #75) run against all three gate directories via the aggregator
  (`CLAUDE_PLUGIN_ROOT_CORE` resolved to the landed core #75 checkout):
  reports "no `*-gate.sh` files found — nothing to check" for all
  three, because this repo's gate scripts are named `gate.sh`, not
  `<role>-gate.sh` — the pre-existing, previously flagged (issue-13
  record) file-discovery glob-miss, unchanged by this issue-16 and
  explicitly out of scope per the approved proposal. Verified the
  substantive condition directly instead: all three `gate.sh` files'
  `gate-lib.sh"` source line now carries a same-line `||` guard (manual
  grep + read confirmed on all three, matching core #75's rule-3 shape).
- Role-name / manifest check (issue-16): `.claude-plugin/marketplace.json`
  and all four `plugin.json` manifests checked against the current role
  name (`legal-compliance`) and hand-off target (`risk-management`) — no
  stale role name or ghost file reference found in any manifest or
  README (confirms the audit's D4 finding; no manifest change was
  needed).

## Open findings

None open (issue-16). All four re-audit-named defect classes (D1-D4)
are fixed and tested; D5 required no code change and is verified green.
The `compliance-check.sh` file-discovery glob-miss on this repo's
`gate.sh` naming (not `*-gate.sh`) remains a known, pre-existing,
previously flagged (issue-13) gap — explicitly out of this issue-16's
stated scope per the approved proposal, not silently hidden.

## Final verdict

pass. All four re-audit-named defect classes (D1-D4) are fixed per the
approved proposal's scoped mitigations (issue-16); D5 required no code
change and is verified green. Requirement 3 (missing-core test case +
green suite + compliance-check record) and requirement 4 (README/
manifest ghost/stale-name zero) are both closed, with the pre-existing
glob-miss explicitly named rather than hidden.

## Write set (as actually touched — matches the frozen proposal write set)

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
- `docs/issue-16/reports/legal-compliance.md` (this file)
