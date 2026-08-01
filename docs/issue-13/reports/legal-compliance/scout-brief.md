# Scout brief — issue #13 gate remediation

Mode: batched-sequential (not parallel fan-out). Reason: the field here is
not competitive/product-shaped — issue #13 names one authoritative
adoption target (`core` issue #72's landed gate-house standard) as a
precondition, so there is no set of independent exemplars to sweep across
by category/content/time. What remained open was two things: (a) what the
standard actually provides (single source, read directly), and (b) how to
generalize "section/adjacency/structure" semantic checks — for which this
repo's own three gates already contain one exemplar worth comparing
against, found during the mandatory current-state survey (`survey.md` §8).
One deepening round on (b) followed; stage count 2, well under the 5-stage/
3-min budget.

## Must-bes (from the landed standard, `docs/handbooks/gate-house-standard.md`)

- Source `gate-lib.sh`/load `gate-lib.py`, never reimplement: kill switch,
  trap, JSON parse, path normalize, write reconstruction, deny/allow.
- Kill switch: only `1|true|yes|on` (case-insensitive) disables; every
  other value, including unrecognized ones, stays active — the inverse of
  what all three of this repo's gates do today (`survey.md` §1).
- Six mandatory test-case groups (`replace_all` on multiply-occurring
  `old_string`, mixed-`replace_all` `MultiEdit`, malformed JSON,
  unrecognized-kill-switch-value stays active, absolute + `./`-prefixed
  path parity, `Bash`-tool write reaching the same target).
- `compliance-check.sh` clean run as the evidence artifact for the
  migration, invoked by reference (never vendored) — precedent for this
  invocation shape already landed in *this* repo via
  `docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md`.

## Performance axes compared (this repo's three gates, `survey.md` §8)

1. Section-scoping — `fanout-completeness-gate` and two of `phase1`'s four
   checks (a2, a4) already scope to a heading's body; `phase2/checker.py`'s
   four keyword checks and `phase1`'s a3 do not.
2. Identity/citation strength — `fanout-completeness-gate`'s token-identity
   dedup (prefers an embedded path/URL/backtick token, collapsing
   differently-labeled bullets citing the same source) is the strongest
   citation-quality pattern in the repo; `checker.py`'s citation regex
   accepts the bare word `risk`, which self-satisfies against its own
   mitigation-bullet trigger word `mitigat` — the audit's named defect.
3. Ordering vs. structure — `phase1`'s a3 (necessity-before-mitigation) is
   a whole-document string-offset check with no section concept at all;
   nothing in the repo currently expresses "X must appear in section Y
   before section Z," which the proposal needs to add as a new primitive.

## Adopt / skip

- **Adopt**: `fanout-completeness-gate`'s heading-scoped section
  extraction + `section_end` boundary walk as the one shared primitive all
  four semantic checks (a1-a4 phase1, four phase2 checks) migrate onto,
  instead of each file re-deriving its own heading regex.
- **Adopt**: `gate_reconstruct_write`/`gate_kill_switch_active`/
  `gate_trap_fail_closed`/`gate_parse_json_or_deny`/`gate_normalize_path`
  verbatim per the standard's usage contract — no local reimplementation,
  matching this repo's own already-landed precedent (issue #2) of
  reference-not-copy for `stub-check.sh`.
- **Skip**: building a bespoke cross-section ordering DSL. The one
  ordering requirement (necessity before mitigation) is expressible as
  "necessity-bearing section's heading line-index precedes the
  mitigation-bearing section's heading line-index," reusing the same
  heading-index list every other check already builds — no new abstraction
  needed.

## Gap line

Current state already meets: absolute-path resolution (all three gates
`realpath` today, unlike the audit's general cross-repo finding #1),
stderr-only deny delivery (survey §7), fail-closed trap presence and
ordering (survey §2, just not house-shaped).
Missing: kill-switch convention (inverted — the worst gap, live fail-open
bug), `replace_all` handling (silently wrong on every gate today), section
scoping on 5 of 8 semantic checks (phase2's four + phase1's a3), citation
strength (bare "risk" self-satisfies), Bash-write coverage, all six
mandatory test groups, and README accuracy.

Sources:
- `docs/handbooks/gate-house-standard.md` (tokenmaxxxer/tokenmaxxxer-core, main).
- `docs/issue-13/reports/legal-compliance/survey.md` §§1-10 (this repo, current-state findings feeding the gap line).
- `docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md` (this repo) — reference-invocation precedent.
