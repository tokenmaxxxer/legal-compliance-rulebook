# legal-compliance phase checklist

Mirrors what the three plugin gates (`legal-compliance-phase1-proposal-gate`,
`legal-compliance-phase2-record-gate`, `legal-compliance-fanout-completeness-gate`)
check mechanically. Self-check before writing — not a new enforcement
surface, the gates still run regardless.

## Phase 1 — proposal (`docs/issue-<n>/proposals/*legal-compliance*.md`)

- [ ] States the spec/process under review and its scope boundary
      (in-scope / out-of-scope named explicitly).
- [ ] Enumerates candidate regulations/standards by name, and states at
      least one exclusion (or explicitly "no exclusions").
- [ ] Gives a necessity/proportionality rationale **before** naming any
      mitigation (ordering, not just presence — the gate checks this by
      string offset within the document).
- [ ] Has an Evidence/rationale section where every adopted position
      cites either a named regulation clause, a cited section of the
      reviewed spec, or is explicitly labeled "assumption, unsourced".
- [ ] If it claims a multi-source/multi-angle survey (a "Sources"
      heading, or "scout"/"sweep"/"survey"/"compared against" in a
      heading), lists at least two independently-attributed sources or
      angles — not one source restated.

## Phase 2 — record (`docs/issue-<n>/reports/legal-compliance.md`)

- [ ] Named regulation/standard list (named, not generic).
- [ ] Graded (red/amber/green) risk rating per identified issue.
- [ ] Mitigations, each naming the specific risk/clause pair it
      addresses (1:1 mapping — no freestanding mitigation bullet).
- [ ] Final verdict (`pass` / `pass-with-mitigations` / `fail`) that
      traces to the ratings already stated in the same record.
- [ ] Same fan-out-completeness rule as phase 1, if a survey is claimed.

## Kill switches (emergency only, per plugin)

- `LEGAL_COMPLIANCE_PHASE1_GATE_OFF`
- `LEGAL_COMPLIANCE_PHASE2_GATE_OFF`
- `LEGAL_COMPLIANCE_FANOUT_GATE_OFF`
