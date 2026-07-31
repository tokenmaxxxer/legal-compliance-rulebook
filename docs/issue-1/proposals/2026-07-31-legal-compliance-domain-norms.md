---
status: implemented
files:
  - legal-compliance/hooks/directive.sh
  - legal-compliance/hooks/hooks.json
  - legal-compliance/hooks/record-fields-gate.sh
  - docs/issue-1/reports/legal-compliance.md
---

# Proposal — legal-compliance domain norms (phase-1 and phase-2, this rulebook)

## What was asked

Issue #1: mature this rulebook by broadly surveying recognized
legal-compliance domain methodology and deliverable norms (textbook /
industry-standard / representative-practice level), then set (a) this
rulebook's own phase-1 proposal norms, (b) this rulebook's own phase-2
deliverable norms, (c) the logical rationale tying each adopted norm to
this role's decided value ("does this spec/process pass legal/regulatory
review" → verdict + applicable regulation list + required mitigations),
and (d) a plugin-reflection plan (directive/record-field/gate changes)
as a **plan only**, gated on human approval, not executed this phase. See
`docs/issue-1/reports/legal-compliance/survey.md` for the current-state
gap this proposal closes and
`docs/issue-1/reports/legal-compliance/scout-brief.md` for the sourced
domain survey this proposal is grounded in.

## (a) Phase-1 proposal norms for this rulebook, going forward

Future phase-1 proposals under this rulebook must:

1. State the **spec/process under review** and its scope boundary
   explicitly (what is and is not in scope for this verdict) — mirrors the
   DPIA's first required element, "a systematic description of the
   envisaged processing operations and the purposes of the processing"
   (scout-brief, must-be 1). Without a bounded description up front, a
   verdict has no traceable object.
2. Enumerate **candidate applicable regulations/standards by name** before
   reasoning about risk, and state which were excluded and why. This
   mirrors the regulatory-compliance-mapping-matrix pattern (scout-brief)
   of cross-referencing named requirements against the artifact, not
   reasoning from vibes.
3. Provide a **necessity/proportionality rationale** for any risk claim
   made (why this processing/clause is or is not proportionate to its
   stated purpose) before naming mitigations — GDPR Art. 35's ordering
   (necessity/proportionality assessment, then risk assessment, then
   mitigations) is must-be 2 in the scout-brief; skipping straight to
   "here are the mitigations" without this step produces mitigations with
   no demonstrated need.
4. Use the same required-sections shape already established repo-wide
   (frontmatter with `status`/`files`; What was asked; What will be done;
   Deliberately not done; How it will be known to work; Write set; Open
   question for the approver) — kept for consistency with issue-2/issue-5
   precedent — plus one legal-compliance-specific addition: an **"Evidence
   / rationale format" section** naming, for every adopted position, either
   (i) a cited clause/article of a named regulation, (ii) a cited section
   of the spec/process under review, or (iii) an explicit "assumption,
   unsourced" label. No unlabeled claims.

## (b) Phase-2 deliverable norms for this rulebook, going forward

Future phase-2 records under this rulebook (i.e., the actual verdict
records this role produces) must contain, as required record fields:

1. **Regulation/standard list** — named, not generic (e.g. "GDPR Art. 6,
   Art. 35" not "privacy laws").
2. **Risk assessment per identified issue**, each rated on a **graded
   scale** (adopting the traffic-light red/amber/green convention —
   scout-brief's "one pattern to adopt" — over a binary pass/fail), because
   a binary verdict cannot express "conditionally acceptable pending
   mitigation X," which is the actual decision-useful output this role
   needs to hand upstream.
3. **Mitigations mapped 1:1 to the risk that produced them** — each
   mitigation entry must name which specific risk/regulation-clause pair it
   addresses (scout-brief must-be 3: DPIA's mitigations are "measures
   envisaged to address the risks," not a freestanding checklist).
4. **Final compliance verdict**, one of `pass` / `pass-with-mitigations` /
   `fail`, derived from (not independent of) the graded risk ratings above
   — no verdict may be entered that isn't traceable to the ratings feeding
   it.
5. Existing `WRITE_SCOPE: []` and hand-off boundary
   ("전사 리스크 노출 규모 판단은 → risk-management") are **unchanged and
   preserved** — this proposal adds methodology inside the existing
   record-field names (`compliance verdict`, `applicable regulation list`,
   `required mitigations`); it does not rename, remove, or loosen them.

## (c) Rationale — why these norms necessarily fit this role's value

The role's entire declared value is a **decision** ("does this pass"), not
a description. A decision-quality output requires three things that a
looser methodology cannot guarantee: (1) traceability — a verdict that
doesn't cite which regulation/clause produced it cannot be checked or
appealed, which is why every candidate surveyed (DOJ ECCP, DPIA, GRC
mapping matrices) independently converged on named-clause traceability;
(2) ordering — necessity/proportionality-then-risk-then-mitigation is not
a stylistic preference, it is the only ordering that prevents mitigations
from being invented before a risk justifying them exists (mitigation
without a named risk is unfalsifiable and unauditable downstream); (3)
gradedness — because this role's output feeds `risk-management` (per its
own hand-off line) for "전사 리스크 노출 규모 판단," a binary verdict
throws away exactly the magnitude information the downstream role needs;
a graded rating is the minimum information this role can produce without
silently pushing rating work onto risk-management, which would blur the
hand-off boundary. Each of these is necessary as a matter of what the role
outputs are used for, not merely because named frameworks happen to do it
this way — the scout-brief's must-bes are cited here because independent
convergence across DOJ/ISO/GDPR/GRC practice is separately-derived
corroboration, not the source of the requirement.

## (d) Plugin-reflection plan (PLAN ONLY — not executed this phase)

On approval, phase 2 would need to:

1. **`directive.sh`**: extend the existing `PRODUCES` value from a plain
   list to a value that also names the graded-scale requirement and the
   verdict enum (`pass` / `pass-with-mitigations` / `fail`), so the
   directive text itself states the methodology, not just the field names.
   No change to `YOU_DECIDE`/`USE_WHEN`/`HAND-OFF` — those remain as-is.
2. **Record-fields enforcement**: first confirm (open question below)
   whether core's global `record-fields-gate.sh` (issue-2's landed
   migration; core repo) supports a per-role required-field list beyond
   its generic §20 structural check. If yes, phase 2 would supply this
   role's specific field list (regulation list / graded risk ratings /
   mapped mitigations / verdict enum) through whatever per-role
   parameterization core already exposes — no new local gate file, to
   avoid reopening the local-drift problem issue-2 and issue-5 both closed.
   If core has no such per-role hook, phase 2 would need to propose a
   **new, narrowly-scoped local gate** (`record-fields-gate.sh`, or a
   name distinct from the deleted one to avoid implying it revives the old
   generic-copy pattern) that checks only the four legal-compliance-
   specific fields, layered on top of (not replacing) core's global
   structural check.
3. **No change to `warrant-hunter`/`hooks.json`'s hand-off to core**: this
   proposal introduces no new agent behavior and does not touch hunt-cadence
   text. Any future reference to the hunt agent stays a reference to the
   `warrant` plugin's canon copy (`warrant/agents/warrant-hunter.md`); this
   proposal neither vendors nor plans to vendor a copy, per the issue's own
   constraint and the issue-2 precedent.
4. This plan requires human Approve before any of items 1-2 are
   implemented, per the issue's phase-2 gate.

## What will be done (phase 2, on Approve)

Implement (d) above: edit `legal-compliance/hooks/directive.sh`'s
`PRODUCES` value; resolve the record-fields-enforcement open question by
checking core's `record-fields-gate.sh` capabilities and either
configuring it or adding the narrowly-scoped local gate described in (d)2;
record the outcome in `docs/issue-1/reports/legal-compliance.md`. No agent
files, no `warrant-hunter` copy, no changes to `YOU_DECIDE`/`USE_WHEN`/
`HAND-OFF`.

## Deliberately not done

- Full ISO 37301 PDCA management-system apparatus (org-wide roles,
  continuous-improvement audit cycle) — scout-brief's "one pattern to
  skip": this role reviews single specs/processes, not an ongoing
  organizational compliance system; adopting PDCA's full scope would be a
  scope mismatch with this role's actual unit of work.
- An independent-review/DPO-style sign-off step — noted in the scout-brief
  as a performance axis worth having, but this role's `WRITE_SCOPE: []`
  and single-role write scope in contract v3 mean a second-reviewer step
  would require inventing a new cross-role hand-off not asked for by issue
  #1; left as a candidate for a future issue, not folded in here.
- Any vendoring of `warrant-hunter.md` or any gate script copy — explicitly
  excluded per the issue's constraint.
- Any actual `directive.sh`/`hooks.json`/gate-file edit — that is phase 2,
  gated on Approve, not touched this turn.

## How it will be known to work

- Phase 2's `directive.sh` diff renders a `PRODUCES` value that still
  contains the three original field names verbatim plus the added
  graded-scale/verdict-enum text — a manual sourcing with
  `CLAUDE_ROLE=legal-compliance` reproduces the extended directive text.
- Whichever record-fields enforcement path is taken (core-parameterized or
  new local gate) is confirmed to reject a record missing any of: named
  regulation list, graded risk rating per issue, 1:1-mapped mitigation, or
  verdict enum — and to accept a conforming one.
- `WRITE_SCOPE: []` and the `HAND-OFF` line are byte-identical to today's
  after the phase-2 edit (diff review confirms no incidental change).

## Write set

This phase (phase 1): the three files under `docs/issue-1/` this proposal
and its survey/scout-brief live in — no plugin files touched. Phase 2 (on
Approve): frozen to `legal-compliance/hooks/directive.sh`,
`legal-compliance/hooks/hooks.json` (only if a new gate needs registering),
a new or reused `legal-compliance/hooks/record-fields-gate.sh`-equivalent
(only if core has no per-role hook), and this issue's own phase-2 record at
`docs/issue-1/reports/legal-compliance.md`.

## Open question for the approver

Does core's global `record-fields-gate.sh` (landed via issue-2's migration)
already support a per-role required-field list, or only its generic §20
structural check? This determines whether phase 2's item (d)2 needs a new
local gate file or can be done by configuration alone. This survey/proposal
did not open a read-only clone of the core repo to check (out of scope for
a domain-methodology survey); the approver or phase-2 executor should
confirm this before implementation, since it changes the shape of the one
plugin file this proposal is least certain about.
