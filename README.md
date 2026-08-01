# legal-compliance-rulebook

Rulebook for the `legal-compliance` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 이 스펙/처리가 법·규제를 통과하는가
- **use_when**: 개인정보·라이선스·계약이 걸릴 때
- **produces**: compliance verdict, applicable regulation list, required mitigations
- **write_scope**: []
- **hand-off**: 전사 리스크 노출 규모 판단은 → risk-management

## Install

```
claude plugin marketplace add tokenmaxxxer/legal-compliance-rulebook
claude plugin install legal-compliance
```

## Layout

- `legal-compliance/.claude-plugin/plugin.json` — plugin manifest
- `legal-compliance/hooks/hooks.json` — SessionStart wiring
- `legal-compliance/hooks/directive.sh` — SessionStart role directive
- `legal-compliance-phase1-proposal-gate/hooks/gate.sh` — enforces phase-1 proposal norms
  a1-a4: stated scope/boundary, regulation enumeration with exclusions, a
  necessity/proportionality rationale before any mitigation is named
  (section-ordering, not just presence), and an Evidence/rationale section
  with per-position citation or an explicit "assumption, unsourced" label.
  Kill switch: `LEGAL_COMPLIANCE_PHASE1_GATE_OFF`.
- `legal-compliance-phase2-record-gate/hooks/{gate.sh,checker.py}` — enforces
  phase-2 record norms: a named regulation/standard list, a graded
  (red/amber/green) risk rating per issue, mitigations each citing the
  regulation/clause they address (1:1, section-adjacency checked — a bare
  reference to "risk" no longer counts), and a verdict
  (pass/pass-with-mitigations/fail) traceable to the stated ratings. All
  four checks are section-scoped (heading + body), not whole-document
  keyword search. Kill switch: `LEGAL_COMPLIANCE_PHASE2_GATE_OFF`.
- `legal-compliance-fanout-completeness-gate/hooks/gate.sh` — enforces that
  any legal-compliance proposal or record claiming a multi-source/
  multi-angle survey (a "Sources" heading, or a scout/sweep/
  compared-against/survey heading) actually lists at least two
  independently-attributed sources or angles, not one restated. Kill
  switch: `LEGAL_COMPLIANCE_FANOUT_GATE_OFF`.
- `tests/legal-compliance/` — fixture test suites for the three gates above,
  plus `run-gate-lib-tests.sh` aggregating all three.
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

All three gates above source `core`'s gate-house standard library
(`core/hooks/lib/gate-lib.{sh,py}`, issue #72) by reference rather than
reimplementing the trap/kill-switch/path-normalize/write-reconstruction
machinery — see each gate's own header comment for its exact usage.

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
