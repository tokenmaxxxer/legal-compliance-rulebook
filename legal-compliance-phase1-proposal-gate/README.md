# legal-compliance-phase1-proposal-gate

Part of the legal-compliance rulebook's plugin set (issue #10). This is
plugin 1 of 3 in that set — see
`docs/issue-10/proposals/2026-07-31-methodology-enforcement.md` for the
full plugin list and composition design. It follows the same
bash-wrapper-around-embedded-python shape scouted from
`pricing-rulebook`'s `methodology-gate.sh` (referenced as a pattern, not
copied — this script is new and role-specific).

## What it enforces

Issue-1's phase-1 ("기획서" / proposal) norms a1–a4, mechanized as a
`PreToolUse` gate on `Write`/`Edit`/`MultiEdit` calls.

## What it checks

Only fires on resolved write paths matching
`docs/issue-<n>/proposals/.*legal-compliance.*\.md`. Any other path is
allowed with no checks (no-op).

1. **Scope/boundary statement** — heuristic: a "scope" or "boundary"
   keyword near "in scope"/"out of scope" language, case-insensitive.
2. **Regulation enumeration + exclusions** — a heading mentioning
   regulations/enumeration whose section body states at least one
   exclusion, or explicitly says "no exclusions".
3. **Necessity/proportionality before mitigation** — the first
   occurrence of "necessity"/"proportionality"/"proportionate" must
   appear, in raw character offset, before the first occurrence of
   "mitigat" anywhere in the document. This is the plugin's one ordering
   check; it is computed by string-offset comparison within the single
   document content the hook already receives on this call — no
   cross-call state file is used or needed (the constraint is
   intra-document).
4. **Evidence/rationale section** — a heading containing "evidence" or
   "rationale" whose bullets each carry either a citation pattern
   (`Art.`, `§`, or a capitalized Act/Regulation name plus a clause
   reference) or the literal phrase "assumption, unsourced". A section
   with zero bullets is treated as missing evidence.

Any missing element causes a deny (exit 2) with the specific missing
item(s) named on stderr. All four checks pass → allow (exit 0).

## Kill switch

Set `LEGAL_COMPLIANCE_PHASE1_GATE_OFF` to any non-empty value to bypass
this gate entirely (exit 0 immediately, no checks run):

```bash
LEGAL_COMPLIANCE_PHASE1_GATE_OFF=1 <command that writes the doc>
```

## Fail-closed behavior

The script uses `set -euo pipefail` plus a trap that turns any
unexpected internal error into a deny (exit 2). Malformed stdin JSON,
an `Edit`/`MultiEdit` whose `old_string` can't be found in the current
file content, and any other internal exception all fail closed rather
than allowing the write through.

## Tests

`tests/legal-compliance/phase1-proposal-gate-tests.sh` — run from the
repo root:

```bash
bash tests/legal-compliance/phase1-proposal-gate-tests.sh
```
