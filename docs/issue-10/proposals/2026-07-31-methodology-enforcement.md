---
status: proposed
revision: 2
files:
  - legal-compliance/hooks/directive.sh
  - legal-compliance/hooks/hooks.json
  - legal-compliance/hooks/plugins/phase1-proposal-gate.sh
  - legal-compliance/hooks/plugins/phase2-record-gate.sh
  - legal-compliance/hooks/plugins/fanout-completeness-gate.sh
  - tests/legal-compliance/phase1-proposal-gate-tests.sh
  - tests/legal-compliance/phase2-record-gate-tests.sh
  - tests/legal-compliance/fanout-completeness-gate-tests.sh
  - docs/handbooks/legal-compliance/phase-checklist.md
  - docs/issue-10/reports/legal-compliance.md
---

# Proposal — enforce the adopted methodology as a plugin set (issue #10)

## Revision note (addressing reviewer's 요구 정정)

Revision 1 of this proposal shipped a single monolithic
`methodology-gate.sh` covering both phases plus one hand-wave on
fan-out. The reviewer's feedback on PR #11 rejected that shape:

> 단일 게이트/디렉티브 심화가 아니라 **플러그인 세트**: 방법론 1개 =
> 독립 플러그인 1개(freelunch 완성도, 룰북당 여러 개), 기획서·산출물
> 규범 각각을 플러그인 조합으로, proposal에 플러그인 목록(이름·담당
> 방법론·구성요소·조합 관계) 필수.

This revision restructures the design accordingly:

1. Each adopted methodology now maps to exactly one independent plugin
   (a plugin = one gate script + its own test file + its own scope),
   not one gate branching on write-surface regex internally.
2. Freelunch (parallel fan-out) completeness — the sourcing discipline
   this very issue's own research phase used (scout-brief.md's 2-angle
   parallel sweep) and that this rulebook's phase-1 work is expected to
   keep using — is promoted to its own plugin, on equal footing with the
   two domain-content gates, not folded into either of them.
3. The phase-1 "기획서" (proposal) norm and phase-2 "산출물" (record)
   norm are each expressed as **a composition of plugins** rather than
   one plugin owning "everything about phase 1" or "everything about
   phase 2": the fan-out-completeness plugin applies to *both* surfaces
   (a proposal and a record can each fail it independently), while the
   content-shape plugins are surface-specific. See "Plugin List" and
   "Composition" below for the explicit mapping.
4. All everything else from revision 1 (survey, scout-brief, the
   specific required elements per surface, the ordering-without-state
   analysis) is kept — restructured into the plugin boundaries below,
   not replaced.

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
sourced comparison this proposal is grounded in. The approver's
follow-up correction (above) additionally requires the enforcement to
be delivered as an explicit, enumerated **set of independent plugins**
rather than a single gate file.

## Plugin list (required by reviewer feedback)

| # | Plugin name | Methodology it enforces | Write surface(s) it fires on | Composes with |
|---|---|---|---|---|
| 1 | `phase1-proposal-gate` | Issue-1 proposal norms (a)1–(a)4: scope boundary, regulation enumeration + exclusions, necessity/proportionality-before-mitigation ordering, evidence/citation-or-assumption-label format | `docs/issue-<n>/proposals/*legal-compliance*.md` | Runs alongside `fanout-completeness-gate` on the same write (both must pass; independent exit codes, see Composition) |
| 2 | `phase2-record-gate` | Issue-1 record norms (b)1–(b)5: named regulation/standard list, graded red/amber/green rating, mitigations with 1:1 risk/clause mapping, verdict traceable to ratings | `docs/issue-<n>/reports/legal-compliance.md` | Runs alongside `fanout-completeness-gate` on the same write; supersedes `record-fields-gate.sh` (retired, see below) |
| 3 | `fanout-completeness-gate` | Freelunch / parallel-fan-out completeness: any proposal or record whose "How it was confirmed to work" / evidence section claims a multi-source or multi-angle sweep must show the sweep actually covered independent angles (not one source restated), per this repo's own `parallel-decomposition`/scout-brief precedent | Both `docs/issue-<n>/proposals/*legal-compliance*.md` and `docs/issue-<n>/reports/legal-compliance.md` | Fires on the same two surfaces as plugins 1 and 2, independently of them — a doc can pass its phase-specific plugin and still fail this one, and vice versa |

Each plugin is a **separate script** under
`legal-compliance/hooks/plugins/`, wired as three separate
`PreToolUse` entries in `hooks.json` (not three branches inside one
script), and ships its own fixture test file under `tests/legal-compliance/`.
This is the concrete difference from revision 1: previously
`methodology-gate.sh` matched on write-surface regex *inside* one
script and branched; now write-surface matching is still per-script
(each plugin still ignores paths outside its own surface and exits 0),
but the three methodologies are physically independent files that can
be changed, tested, disabled (each keeps its own kill switch), or
retired one at a time without touching the other two.

## Composition (how the plugins combine on 기획서 / 산출물)

Neither "기획서 규범" (the phase-1 proposal norm) nor "산출물 규범"
(the phase-2 record norm) is a single plugin. Each is the **AND** of
two independent plugin verdicts on the same write:

- **기획서 (proposal) norm** = `phase1-proposal-gate` PASS **and**
  `fanout-completeness-gate` PASS, both evaluated on the same
  `docs/issue-<n>/proposals/*legal-compliance*.md` write. A proposal
  that states scope/enumeration/ordering/evidence correctly but claims
  an unverifiable "surveyed multiple sources" without showing
  independent angles fails the norm via plugin 3 even though it passes
  plugin 1.
- **산출물 (record) norm** = `phase2-record-gate` PASS **and**
  `fanout-completeness-gate` PASS, both evaluated on
  `docs/issue-<n>/reports/legal-compliance.md`.
- The two content plugins (1, 2) never both fire on the same write —
  their surfaces are disjoint by construction (proposal path vs.
  record path) — while plugin 3 fires on both, which is why it is
  modeled as its own independent plugin instead of being duplicated
  inside plugins 1 and 2.
- `hooks.json` wires all three as independent `PreToolUse` matchers;
  Claude Code runs all matching hooks for a given tool call and denies
  the write if any one of them exits non-zero — so the AND composition
  above is enforced by the hook runner itself, not by extra glue code
  in this rulebook.

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

### 2. Three independent plugin gates

All three follow the shape scouted from `pricing-rulebook`'s
`methodology-gate.sh` (referenced as a pattern, not copied — no file
from `core/hooks/` or another rulebook's tree is vendored; each is a
new, role-specific script per the canon-scripts clause): a bash wrapper
(fail-closed `trap` on non-0/non-2 exit, its own kill switch env var)
around an embedded Python check. What changes from revision 1 is that
these are now **three separate files**, each owning exactly one
methodology and one write-surface match, instead of one file branching
on path regex internally.

**Plugin 1 — `legal-compliance/hooks/plugins/phase1-proposal-gate.sh`**
(`PreToolUse`, `Write|Edit|MultiEdit`, kill switch
`LEGAL_COMPLIANCE_PHASE1_GATE_OFF`). Fires only on resolved paths
matching `docs/issue-<n>/proposals/.*legal-compliance.*\.md`; any other
write exits 0 immediately. Requires: a stated scope/boundary phrase; a
regulation-enumeration section that also states at least one exclusion
(or "no exclusions" explicitly); necessity/proportionality language
whose text position precedes the first mitigation mention (the one
ordering check this plugin performs, by string-offset comparison within
the single document being written — no cross-call state needed, see
"Ordering without state tracking" below); an Evidence/rationale section
with at least one citation-or-assumption-label per adopted position
(heuristic: at least one "assumption, unsourced" or a
regulation-citation pattern like `Art\.` / `§` / named-act-plus-clause
per bullet under that section).

**Plugin 2 — `legal-compliance/hooks/plugins/phase2-record-gate.sh`**
(`PreToolUse`, `Write|Edit|MultiEdit`, kill switch
`LEGAL_COMPLIANCE_PHASE2_GATE_OFF`). Fires only on resolved paths
matching `docs/issue-<n>/reports/legal-compliance\.md`; any other write
exits 0. Supersedes `record-fields-gate.sh`'s four presence checks with
the same four plus one 1:1-mapping heuristic: the count of mitigation
bullets must not exceed the count of distinct risk/regulation-clause
references they cite (best-effort structural check, not a full parse —
a mitigation bullet with no clause/risk reference in its own line fails
it). `legal-compliance/hooks/record-fields-gate.sh` is retired in the
same change (its four checks are strictly subsumed by this plugin)
rather than left running in parallel — two gates checking overlapping
ground on the same write surface is exactly the kind of drift
issue-2/issue-5 already closed for this repo.

**Plugin 3 — `legal-compliance/hooks/plugins/fanout-completeness-gate.sh`**
(`PreToolUse`, `Write|Edit|MultiEdit`, kill switch
`LEGAL_COMPLIANCE_FANOUT_GATE_OFF`). Fires on **both** surfaces above
(proposal and record); any other write exits 0. Enforces the freelunch
/ parallel-fan-out completeness methodology this rulebook's own phase-1
research already practices (scout-brief.md's 2-angle sweep): if the
document under write claims a multi-source or multi-angle
survey/sourcing basis (heuristic: a "Sources" list, or phrases like
"scout", "sweep", "compared against", "survey" in a heading), it must
list at least two independently-attributed sources/angles (e.g. two
distinct file paths or named repos under a "Sources" heading, or two
distinct named angles under a "Must-bes"/"angle" heading) — a document
that narrates a sweep but cites one source, or cites the same source
twice, fails. A document that makes no such claim at all is not
required to have a sweep (this plugin checks internal consistency of a
completeness *claim*, it does not mandate that every write include a
fan-out).

All three scripts independently: resolve the write's real path before
matching (no matching on the tool-supplied path string); fail closed
(exit 2, message naming the missing element(s)) on unparseable JSON
payload, an Edit/MultiEdit whose `old_string` cannot be found in the
pre-write content, and any internal exception; and are wired as three
separate `PreToolUse` matcher entries in `hooks.json` rather than one
entry pointing at a dispatcher script — so any one plugin can be
disabled via its own kill switch, edited, or retired without touching
the other two's matcher config.

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

### 3. Gate tests — one fixture file per plugin

Per-plugin test files at the repo root (not under `docs/`, per contract
v3's `test/` output-layout rule), following
`implementation-rulebook/tests/run-gate-tests.sh`'s shape: a small
runner that feeds synthetic `PreToolUse` JSON payloads (a `Write` with
`tool_input.content` set to fixture text) to the plugin script on
stdin and asserts the exit code. Splitting one shared test file into
three keeps each plugin's regression fixtures independently runnable
and independently owned, matching the "one plugin, one everything"
structure above.

**`tests/legal-compliance/phase1-proposal-gate-tests.sh`**
1. Proposal missing a scope-boundary statement → deny (exit 2).
2. Proposal stating a mitigation before its necessity/proportionality
   rationale (ordering violation) → deny.
3. Proposal with scope, regulation enumeration + exclusion, correctly
   ordered rationale, and a fully cited Evidence section → allow (exit 0).
4. Proposal with one adopted position carrying no citation and no
   "assumption, unsourced" label → deny.
5. A write to an unrelated path (e.g. `README.md`) → allow, no-op
   (confirms resolved-path targeting doesn't over-fire).

**`tests/legal-compliance/phase2-record-gate-tests.sh`**
1. Record missing the graded red/amber/green rating → deny.
2. Record with a mitigation bullet citing no risk/clause → deny (1:1
   heuristic).
3. Record conforming to all four fields plus the mapping heuristic →
   allow.
4. A write to an unrelated path → allow, no-op.

**`tests/legal-compliance/fanout-completeness-gate-tests.sh`**
1. Proposal with a "Sources" heading listing only one source, after
   prose claiming a "sweep"/"survey" → deny.
2. Proposal with a "Sources" heading listing two independently-named
   sources → allow.
3. Record making no sweep/survey claim at all (no such heading/phrase)
   → allow (nothing to check).
4. Record claiming a multi-angle comparison but citing the same source
   twice under two different bullet labels → deny.
5. A write to an unrelated path → allow, no-op.

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
  `implementation-rulebook` script — each plugin script is new and
  role-specific; the scouted repos are referenced as pattern precedent
  only, per `core`'s canon-scripts clause.
- No single dispatcher script branching on write-surface regex — that
  was revision 1's shape and is exactly what the reviewer's feedback
  rejected; this revision keeps the three plugins as physically
  separate files and separate `hooks.json` entries.
- No change to `YOU_DECIDE`, `USE_WHEN`, `HAND_OFF`, or `WRITE_SCOPE: []`.
- No new regulation/methodology content — this issue mechanizes issue-1's
  already-adopted norms; it does not adopt new domain methodology, and
  the fan-out-completeness plugin mechanizes this repo's own existing
  sourcing practice (scout-brief.md), not a newly invented one.

## How it will be known to work

- Each of the three test files under "Gate tests" above runs its own
  fixture cases and each asserts the exit code the case name implies;
  the phase1/phase2 content plugins and the fan-out plugin can be run
  and pass/fail independently of each other.
- `record-fields-gate.sh` no longer exists (or is a no-op stub with a
  pointer comment) and `hooks.json` has three separate `PreToolUse`
  entries, one per plugin in the Plugin List table, none of which is a
  dispatcher pointing at the other two.
- A single proposal write can be constructed that passes
  `phase1-proposal-gate` but fails `fanout-completeness-gate` (an
  unverifiable "surveyed multiple sources" claim with one source
  listed), demonstrating the AND-composition described under
  "Composition" actually holds and is not silently satisfied by either
  plugin alone.
- Manually sourcing `directive.sh` with `CLAUDE_ROLE=legal-compliance`
  reproduces the four original phase-2 field names verbatim plus the new
  phase-1/phase-2 facet text; `YOU_DECIDE`/`USE_WHEN`/`HAND_OFF`/
  `WRITE_SCOPE` are byte-identical to today's via diff review.

## Write set

This phase (phase 1): the two files under
`docs/issue-10/reports/legal-compliance/` and this proposal file only —
no plugin, hook, test, or handbook files touched. Phase 2 (on Approve):
frozen to the files listed in this document's frontmatter (three plugin
scripts, three per-plugin test files, `hooks.json`, `directive.sh`, the
handbook checklist, and the phase-2 record).

## Open question for the approver (carried from revision 1, unchanged)

`record-fields-gate.sh` retirement: this proposal folds its four checks
into `phase2-record-gate` and removes the old file rather than keeping
both. Confirm that's preferred over leaving `record-fields-gate.sh`
running as a redundant secondary check — the proposal's default is "one
gate per write surface, one plugin per methodology," matching the
drift-avoidance precedent issue-1's own plan already cited (core's gate
vs. a local gate), but this is the approver's call to make explicit
before phase 2 executes.
