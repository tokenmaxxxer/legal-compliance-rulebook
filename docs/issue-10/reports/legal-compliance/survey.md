# Survey — current enforcement gap for issue #10

## Scope of this survey

Object under review: this rulebook's own plugin tree
(`legal-compliance/`) and the enforcement mechanism it currently ships,
compared against issue #10's stated bar
(`implementation-rulebook` level: progress gates, state tracking, and
gate tests that mechanically enforce a rulebook's own adopted
methodology, not just describe it).

## What exists today

- `legal-compliance/hooks/directive.sh` — one `SessionStart` hook. Sources
  core's `role-directive.sh` and fills in four one-line/one-paragraph
  strings (`YOU_DECIDE`, `USE_WHEN`, `PRODUCES`, `HAND_OFF`). `PRODUCES`
  already names the four phase-2 record fields plus the graded-scale and
  verdict-enum requirement (added in issue #1's phase 2), but as **prose
  inside a directive string** — nothing parses or enforces it beyond
  display at session start.
- `legal-compliance/hooks/record-fields-gate.sh` — one `PreToolUse`
  (`Write|Edit|MultiEdit`) hook, ~25 lines. Fires only on writes to
  `*/reports/legal-compliance.md` (the phase-2 record). Four `grep -qiE`
  presence checks (regulation/standard keyword, red/amber/green keyword,
  "mitigat" keyword, verdict-enum keyword). No check runs against phase-1
  proposals. No check verifies mitigations map 1:1 to the risks that
  produced them (issue #1 proposal (b)3) — presence of the word
  "mitigat" anywhere satisfies it. No check verifies the necessity/
  proportionality-before-mitigation ordering issue #1's proposal (a)3
  requires. No check verifies scope-boundary or evidence/rationale-format
  requirements from proposal (a)1/(a)4.
- No gate tests anywhere in this repo: `find . -iname '*test*'` under the
  worktree returns nothing besides this session's own scratch state.
  `record-fields-gate.sh`'s own behavior is asserted only in prose, in
  `docs/issue-1/reports/legal-compliance.md`'s "How it was confirmed to
  work" section ("manually exercised") — not as a repeatable fixture.
- No agents/ directory, no checklist file under `docs/handbooks/`.
- `hooks.json` wires exactly the two hooks above; no state-tracking hook.

## The gap, named

Issue #1 already produced a full domain-methodology proposal — phase-1
proposal norms (a)1-4 and phase-2 record norms (b)1-5 — and it was
**approved and partially reflected** (the phase-2 field names went into
`PRODUCES` and a grep gate). But:

1. **Phase-1 proposal norms are unenforced.** (a)1 (scope boundary),
   (a)2 (regulation enumeration + exclusions stated), (a)3 (necessity/
   proportionality before mitigations, an ordering constraint), and (a)4
   (evidence/rationale format, citation-or-assumption-label per claim)
   exist only as prose in the issue-1 proposal doc. No `PreToolUse` gate
   targets `docs/issue-<n>/proposals/*legal-compliance*.md` at all.
2. **Phase-2 enforcement is presence-only, not structure-only.** The
   1:1 mitigation-to-risk mapping and the risk-precedes-verdict
   traceability chain (b)3/(b)4 require are not checked; a record
   containing the four keywords anywhere passes regardless of whether
   they relate to each other.
3. **No gate tests exist**, for either the current gate or any gate this
   issue would add — so a future edit to `record-fields-gate.sh` (or a
   new gate) has no regression fixture confirming it still denies what it
   should deny and allows what it should allow.
4. **No state tracking** exists for any ordering constraint, but see the
   scout-brief for whether this repo's ordering constraints actually
   need cross-call state (they are intra-document, not cross-turn/
   cross-file, per the analysis there) — named here as an open question
   this proposal must answer explicitly, not skip silently.

## Write-surface inventory (what any new gate must be able to target)

- `docs/issue-<n>/proposals/*.md` matching this role (phase-1 proposals) —
  currently ungated.
- `docs/issue-<n>/reports/legal-compliance.md` (phase-2 record) — gated,
  but shallow.
- `legal-compliance/hooks/*` (the plugin's own hook scripts) — not a
  methodology write surface, out of scope for a methodology gate.

This survey's gaps are what the scout sweep (`scout-brief.md`) aims its
search angles at: how comparable rulebooks in this same repo family
(`pricing-rulebook`, `implementation-rulebook`) closed the same four gaps.
