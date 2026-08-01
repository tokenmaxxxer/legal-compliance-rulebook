# Survey — issue #13 current-state audit (gate grade C+)

Scope: the three live PreToolUse gates in this rulebook
(`legal-compliance-phase1-proposal-gate/hooks/gate.sh`,
`legal-compliance-phase2-record-gate/hooks/{gate.sh,checker.py}`,
`legal-compliance-fanout-completeness-gate/hooks/gate.sh`), their test
suites (`tests/legal-compliance/*.sh`), and the top-level `README.md`.

## 1. Kill switches — confirmed fail-open bug (all three gates)

All three gates use the pre-issue-72 idiom:

- `phase1-proposal-gate/hooks/gate.sh:20`: `[[ -n "${LEGAL_COMPLIANCE_PHASE1_GATE_OFF:-}" ]]`
- `phase2-record-gate/hooks/gate.sh:17`: `[ -n "${LEGAL_COMPLIANCE_PHASE2_GATE_OFF:-}" ]`
- `fanout-completeness-gate/hooks/gate.sh:35`: `[ -n "${LEGAL_COMPLIANCE_FANOUT_GATE_OFF:-}" ]`

Each treats **any non-empty value** as "disable" — a stray typo in the env
var (e.g. `LEGAL_COMPLIANCE_PHASE1_GATE_OFF=0` set by mistake, which is
non-empty) silently turns the gate off. This is exactly the defect class
`core/hooks/lib/gate-lib.sh`'s `gate_kill_switch_active` was built to fix
(core issue #72, "kill-switch default-on-unrecognized-value" — the same
bug core's own seven gates had before migrating).

## 2. Fail-closed trap — present but not house-shaped

All three scripts install a `trap ... ERR`/`trap ... EXIT` before
`set -euo pipefail`, so the ordering requirement (trap before the set
line, so an early abort is still caught) is already met structurally. But
none call `gate_trap_fail_closed` — each hand-rolls its own trap body, so
this repo has three slightly different re-derivations of one shape
instead of the one canon trap.

## 3. `replace_all` — ignored (Edit and MultiEdit both wrong)

- `phase1-proposal-gate/hooks/gate.sh:83,97`: `current.replace(old_string, new_string, 1)` — first-occurrence only, `tool_input.get("replace_all")` never read.
- `phase2-record-gate/hooks/checker.py:53`: same — `content.replace(old, new, 1)` for both `Edit` and every `MultiEdit` edit, `replace_all` never read.
- `fanout-completeness-gate/hooks/gate.sh:108,122`: same pattern (`content.replace(old, new, 1)`).

This is the issue-72-confirmed bug class `gate_lib.gate_reconstruct_write`
exists to fix. A proposal or record edited with `replace_all: true` against
a multiply-occurring `old_string` is checked against a wrong
reconstruction in all three gates today — the check can pass or fail on
stale content that Claude's actual edit never produces.

## 4. NotebookEdit — unmatched everywhere

None of the three gates' hook matchers include `NotebookEdit`, and none of
their Python payloads handle it. Not a live risk for this role today (no
`.ipynb` in `docs/issue-*/`), but `gate_reconstruct_write` covers it for
free once migrated, closing the gap issue #72 flagged repo-wide.

## 5. Bash-tool write bypass — confirmed, all three gates

All three matchers wire only `Write|Edit|MultiEdit` (`hooks.json` per
plugin — confirmed by inspection, matcher strings mirror the audit's
finding #4). A `Bash` tool call doing `cat > docs/issue-N/proposals/...`
or `python3 -c "open(...).write(...)"` reaches none of these checks today.
`gate_bash_write_targets` (already used by `core/hooks/approval-gate.sh`/
`board-gate.sh`) is the house answer; not yet adopted anywhere in this
repo.

## 6. Path matching — already realpath'd, but ad hoc per-gate

All three gates call `os.path.realpath(file_path)` before matching — so
absolute paths already work, unlike the audit's cross-repo finding #1
(`^docs/...` anchors that never match an absolute `file_path`). But each
gate re-derives its own `resolved.replace(os.sep, "/")` + regex instead of
using `gate_lib.gate_normalize_path`, and **none of the three test suites
exercise a `./`-prefixed or genuinely relative `file_path` fixture** — the
audit's claim that "테스트가 상대경로 픽스처만 써서 은폐" doesn't apply
verbatim here (these suites use absolute fixtures, which do pass), but the
inverse gap holds: no test proves the relative/`./`-prefixed case also
resolves correctly, so a future regression in the ad hoc regex would go
undetected.

## 7. Deny-reason delivery — already correct

All three: `print(..., file=sys.stderr)` / `sys.exit(2)` (phase1, fanout)
or bash `echo "$result" >&2; exit 2` (phase2, relaying checker.py's
stdout-to-stderr). Confirmed already stderr-only, no fix needed here — but
call this out explicitly in the proposal so A+ review doesn't assume it's
still broken.

## 8. Semantic checks — pure substring/keyword-offset, the issue's core complaint

- **checker.py (phase2), most severe**: four of five checks are
  whole-document keyword search with no section scoping at all —
  `regulation|standard`, `\b(red|amber|green)\b`, `mitigat`,
  `\b(pass-with-mitigations|pass|fail)\b` each just need the word to
  appear *anywhere* in the record. A record could open with "no
  regulations apply, risk is green, mitigations: none, verdict: pass" as
  a single throwaway sentence in an unrelated section and pass all four.
- **checker.py's 1:1 mitigation-mapping heuristic, the audit's named
  example**: `ref_re` includes `\brisk\b` as an accepted reference token
  (`checker.py:99`). Since the heuristic's own trigger condition for
  "is this bullet a mitigation" already matches on the substring
  `mitigat` (`checker.py:86,91`), a bullet like "- mitigate the risk"
  contains both trigger words and satisfies the citation check purely
  from the word "risk" — no actual clause/regulation/issue reference
  needed. Confirmed reproducible: any bullet containing both `mitigat`
  and `risk` passes with zero citation.
- **phase1-proposal-gate, better but still substring-adjacent**: (a1)
  scope/boundary is a single regex requiring `scope`/`boundary` within
  120 chars of `in scope`/`out of scope` — an improvement over pure
  substring but still a proximity window, not a real section check. (a2)
  and (a4) already scope to the heading's section body (heading regex +
  next-heading boundary) — structurally sound, the strongest of the
  three files' checks. (a3) necessity/proportionality-before-mitigation
  is a pure string-offset ordering check across the *entire* document,
  with no concept of "which section" either term is in — two unrelated
  sections that happen to mention the words in the wrong global order
  fail the check even if each section is internally correct.
- **fanout-completeness-gate**: already the most structural of the three
  — heading-scoped section extraction (`section_end`), bullet counting,
  and a token-identity dedup (`identity()`) so two bullets citing the same
  underlying source collapse to one. No substring-keyword defect found
  here; kept as the house-standard pattern to generalize *from*, not a
  target of the semantic-check upgrade.

## 9. README ghost documentation — confirmed

Top-level `README.md`'s Layout section documents five files that do not
exist in this tree: `legal-compliance/hooks/record-fields-gate.sh`,
`legal-compliance/hooks/trailer-gate.sh`,
`legal-compliance/hooks/handbook-trigger-gate.sh`,
`legal-compliance/agents/warrant-hunter.md` (all four removed by the
landed `docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md`
migration to core canon — confirmed deleted, `hooks.json` now registers
only `SessionStart` → `directive.sh`), plus it never mentions the three
gates that actually exist and fire today
(`legal-compliance-phase1-proposal-gate`, `legal-compliance-phase2-record-gate`,
`legal-compliance-fanout-completeness-gate`).

## 10. Test coverage — zero of the six mandatory case groups present

`grep` across all three suites (`tests/legal-compliance/*.sh`, 427 lines
total) for `replace_all`, `MultiEdit`, malformed-JSON, kill-switch-off-spelling,
and absolute/`./`-prefixed path fixtures returns no matches. None of the
six case groups `core/hooks/tests/run-gate-lib-tests.sh` makes mandatory
(issue-72's own standard test harness) exist anywhere in this repo's
suites today.

## What core already landed (issue #72, PR #74, merged to main)

- `core/hooks/lib/gate-lib.sh` — `gate_trap_fail_closed`,
  `gate_kill_switch_active` (fixed convention: only `1|true|yes|on`,
  case-insensitive, disables; everything else — empty, a recognized
  off-spelling, or an unrecognized value — stays active), `gate_deny`,
  `gate_allow`, `gate_bash_write_targets`.
- `core/hooks/lib/gate-lib.py` — `gate_parse_json_or_deny`,
  `gate_normalize_path`, `gate_reconstruct_write` (full
  `Write`/`Edit`/`MultiEdit`/`NotebookEdit` reconstruction, `replace_all`
  honored per-edit).
- `docs/handbooks/gate-house-standard.md` — the reference-not-copy usage
  contract, the six-case mandatory test list, and a five-step per-repo
  migration checklist this proposal follows directly (§ below).
- `core/hooks/tests/compliance-check.sh` — the detector this proposal's
  "how it will be known to work" section runs against this repo's gates,
  referenced (not vendored) the same way `stub-check.sh` already is per
  `docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md`
  (landed precedent for the reference-invocation shape in *this* repo).

Sources:
- `docs/issue-13` issue body (`gh issue view 13`) — the audit findings this survey verifies against real files.
- `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py` (tokenmaxxxer/tokenmaxxxer-core, main, post-PR #74).
- `docs/handbooks/gate-house-standard.md`, `docs/handbooks/role-gates-tests.md`, `core/hooks/tests/compliance-check.sh` (same repo/ref).
- `docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md` (this repo) — precedent for the reference-invocation pattern already approved and landed for `stub-check.sh`.
- This repo's own `legal-compliance-*-gate/hooks/*.sh`, `legal-compliance-*-gate/hooks/checker.py`, `tests/legal-compliance/*.sh`, `README.md`.
