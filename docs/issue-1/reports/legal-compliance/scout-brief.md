---
subject: issue-1
role: legal-compliance
loop_state: scope-proposed
---

# Scout brief — legal-compliance domain methodology norms

## Must-bes (recognized across candidates)

1. **Named regulation/standard traceability**: every candidate (DOJ ECCP,
   ISO 37301, GDPR DPIA, GRC risk-mapping matrices) requires the verdict to
   trace back to a *named* rule/clause, not a generic "compliant/not"
   judgment — DOJ's ECCP explicitly evaluates whether tools/resources exist
   to *identify and document* risk against specific obligations; a DPIA
   under Art. 35 requires "a systematic description of the envisaged
   processing... and the purposes," tying findings to specific provisions.
2. **Necessity/proportionality-style risk assessment before the verdict**:
   DPIA methodology requires "an assessment of the necessity and
   proportionality of the processing operations" and "an assessment of the
   risks to the rights and freedoms" *before* mitigations are proposed —
   i.e., risk-then-mitigation ordering, not mitigation-first.
3. **Documented mitigations tied 1:1 to identified risks**: DPIA's fourth
   required element is explicitly "the measures envisaged to address the
   risks" — mitigations must map to specific risks raised, not be a
   generic boilerplate list. GRC risk matrices likewise pair each rated
   risk with a specific control/response ("mapped... to respond to
   specific high priority risk elements").

## Performance axes

- **Graded vs. binary verdict**: GRC practice consistently uses a graded
  scale (traffic-light red/amber/green, or likelihood×impact 1-5 matrices)
  rather than binary pass/fail — a graded scale carries more decision-useful
  information (how urgent, not just whether) and matches DOJ's own
  emphasis on *proportionate, risk-based* evaluation rather than checklist
  pass/fail.
- **Auditability / DPO-style independent review**: Art. 35(2) requires DPO
  review of the DPIA's methodology and risk assessment — an independent
  check on the assessor's own output, not just the output itself.

## One pattern to adopt

Adopt the **DPIA four-element shape** (systematic description of the
processing/spec → necessity/proportionality assessment → risk-to-affected-
parties assessment → mapped mitigations) as the phase-2 deliverable's
methodology backbone, plus a **graded (traffic-light) verdict scale**
instead of binary pass/fail, since GRC practice and DOJ's own
proportionality language both converge on graded urgency being more
decision-useful than a binary gate.

## One pattern to skip

Skip full ISO 37301 PDCA organizational-system scope (roles, top-management
commitment, continuous-improvement audit cycle) — that standard governs an
*entire organization's* compliance management system over time, not a
single spec/process review verdict. This role produces one-shot verdicts
per spec, not an ongoing management-system audit; importing PDCA's full
apparatus would be scope mismatch, not rigor.

## Segment-fit line

This role's decided value ("does this spec/process pass legal/regulatory
review," producing verdict + regulation list + mitigations) maps cleanly
onto the DPIA's four-step shape because DPIA is itself a per-artifact
(per-processing-operation) assessment method, not an org-wide system —
same granularity as this role's actual unit of work.

## Gap line (from survey)

- **Already met**: `PRODUCES` already names the three DPIA-shaped output
  buckets (verdict / regulation list / mitigations) — the *outputs* are
  right, only the *methodology producing them* is unspecified.
  `WRITE_SCOPE: []` and the hand-off boundary are already in force and
  need no methodology change.
- **Missing**: no risk-rating scale (binary today, by default/absence); no
  required necessity/proportionality-assessment step before mitigations;
  no requirement that each mitigation cite the specific risk/regulation
  clause it addresses; no independent-review step analogous to DPO
  sign-off; no per-role required-record-field enforcement mechanism
  confirmed to exist (survey flagged this as unknown, not confirmed
  absent).

## Stage count and mode

5 stages total: one parallel sweep round (4 angles — DOJ ECCP, ISO 37301,
GDPR DPIA, GRC risk-matrix/mapping — fired as 4 concurrent WebSearch calls
in one message) + 1 sequential deepening stage (contract/clause-review
checklist norms). Mode: parallel sweep, then batched-sequential deepening.
Under the 5-stage / ~3min cap.

## Sources

- https://ethisphere.com/news/doj-2024-compliance-updates/
- https://corpgov.law.harvard.edu/2024/10/07/key-updates-to-the-dojs-evaluation-of-corporate-compliance-programs/
- https://www.cov.com/en/news-and-insights/insights/2024/10/doj-updates-guidance-for-evaluation-of-corporate-compliance-programs-focusing-on-artificial-intelligence-data-and-whistleblower-protections
- https://blog.ansi.org/ansi/iso-37301-2021-compliance-management-systems/
- https://nimonik.com/blog/iso-37301-compliance-management-systems-key-elements/
- https://gdpr.eu/data-protection-impact-assessment-template/
- https://trustarc.com/resource/data-protection-impact-assessment-article35/
- https://www.wolterskluwer.com/en/expert-insights/common-grc-risk-methodologies
- https://www.flowgrc.com/blog/risk-assessment-matrix
- https://www.itgov-docs.com/blogs/data-governance/regulatory-compliance-mapping-matrix
- https://grokipedia.com/page/traffic_light_rating_system
- https://www.harvey.ai/blog/contract-review-checklist
- https://www.lexology.com/library/detail.aspx?g=1807ff23-b255-4008-a2c5-90e1b8294e9c
