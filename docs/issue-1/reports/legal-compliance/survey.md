---
subject: issue-1
role: legal-compliance
loop_state: scope-proposed
---

# Current-state survey — legal-compliance rulebook's phase-1/phase-2 norms

## What this rulebook requires today

- `legal-compliance/hooks/directive.sh` — already the core-canon stub shape
  (issue-2's migration, confirmed landed): sources
  `core/hooks/lib/role-directive.sh` by reference and calls
  `core_role_directive` with four values —
  `YOU_DECIDE`: "이 스펙/처리가 법·규제를 통과하는가",
  `USE_WHEN`: "개인정보·라이선스·계약이 걸릴 때",
  `PRODUCES` (required record fields): "compliance verdict, applicable
  regulation list, required mitigations" plus `WRITE_SCOPE: []`,
  `HAND-OFF`: "전사 리스크 노출 규모 판단은 → risk-management".
- `legal-compliance/hooks/hooks.json` — registers only `directive.sh` under
  `SessionStart`. No `PreToolUse` block (issue-2 removed the vendored
  `trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh`
  triplet; core's own global `hooks.json` now fires the canon versions of
  these for every plugin install).
- `legal-compliance/.claude-plugin/plugin.json` — name, one-line role
  description (verbatim restates `YOU_DECIDE`/`USE_WHEN`/hand-off), author.
  No phase-1/phase-2 methodology content.
- No `legal-compliance/agents/` directory exists in this repo. In
  particular there is **no vendored `warrant-hunter.md` copy** — confirmed
  absent (issue-2 deleted it; re-confirmed by `ls legal-compliance/` this
  session, which lists only `hooks/`). Any reference to the hunt agent must
  point at the `warrant` plugin's canon copy, never recreate a local file.
- No local `stub-check.sh` — confirmed absent (issue-5 recalled the
  vendored copy; canon now runs it by reference against the core install).
- No record-fields gate script lives in this repo at all today
  (`record-fields-gate.sh` was deleted in issue-2 in favor of core's global,
  role-agnostic §20-structure check). That means **today, the specific
  three required-record fields this role's own directive names —
  compliance verdict, applicable regulation list, required mitigations —
  are not mechanically enforced by anything in this repo.** Core's
  `record-fields-gate.sh` checks generic §20 shape (what-was-done, why,
  upstream-basis, `loop_state:` line, open-findings, next-steps) keyed off
  `CLAUDE_ROLE`, not this role's field *names*. Whether core's gate is
  parameterized per-role to actually demand these three named fields is
  **unknown from this repo alone** — it is a core-repo implementation
  detail this survey did not open a read-only clone to check for.
- No existing phase-1 proposal or phase-2 report in this repo, for any
  issue, specifically addresses legal-compliance **domain content**
  (regulation taxonomy, risk-rating scale, DPIA-style methodology, etc.).
  All three prior issues in this repo (#2, #5, and their proposals/surveys)
  are infra/plugin-plumbing migrations (core-canon reference transitions),
  not domain-methodology work. There is no precedent in this repo for what
  "does this spec pass legal/regulatory review" should mean procedurally —
  this issue is the first to open that question.

## What's thin / unknown / contested (steers the scout)

- **Thin**: `PRODUCES` names three output artifacts (verdict, regulation
  list, mitigations) but defines no methodology for producing any of them —
  no risk-rating scale, no regulation-applicability-mapping procedure, no
  required evidence trail linking a mitigation back to a specific clause of
  a specific regulation. This is exactly the gap issue #1 asks to close.
- **Thin**: no phase-1 proposal template specific to *this* role exists
  in-repo — the two prior proposals (issue-2, issue-5) are infra-migration
  proposals whose "required sections" shape (frontmatter + What was
  asked / What will be done / Deliberately not done / How it will be known
  to work / Write set / Open question) is a repo-wide convention, not a
  legal-compliance-specific one. Whether any *domain-specific* section
  (e.g., "regulations considered and excluded," "evidence standard used")
  should be layered on top is undecided — this is what the proposal below
  must resolve.
- **Unknown**: whether core's `record-fields-gate.sh` supports a
  per-role required-field list (vs. only the generic §20 shape) — if it
  does, the phase-2 plugin-reflection plan can hook into that mechanism
  rather than inventing a new local gate; if it doesn't, a new local gate
  file may be needed, which reopens the "don't vendor / don't grow local
  drift" tension issue-2 and issue-5 both fought to close. This survey
  flags it as an open question for the scout/proposal to address, not
  something to resolve by re-cloning core mid-survey.
- **Contested/undecided**: how strict a "compliance verdict" scale should
  be (binary pass/fail vs. a graded risk-rating like traffic-light) — this
  is a real methodology choice with no in-repo precedent, and the scout
  below specifically targets this.
- **Must preserve**: `WRITE_SCOPE: []` and the existing hand-off boundary
  text ("전사 리스크 노출 규모 판단은 → risk-management") are record/
  documentation-discipline clauses already in force; any phase-2 change
  proposed later must not weaken or remove them.
- **Must preserve (constraint from issue)**: `warrant-hunter` must stay a
  core-canon reference only; this survey confirms there is currently
  nothing to un-vendor (already reference-only per issue-2) — so the
  proposal's plugin-reflection plan must be written so as not to
  reintroduce a local copy under any candidate norm.

## Sources

- `legal-compliance/hooks/directive.sh`, `legal-compliance/hooks/hooks.json`,
  `legal-compliance/.claude-plugin/plugin.json` (read directly, this repo,
  this session)
- `ls legal-compliance/` (confirms no `agents/` dir)
- `docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md`,
  `docs/issue-2/reports/implementation/survey.md`,
  `docs/issue-5/reports/implementation/survey.md` (this repo, prior-art /
  format precedent)
- `gh issue view 1` (issue #1 body, this repo)
