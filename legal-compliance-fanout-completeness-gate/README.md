# legal-compliance-fanout-completeness-gate

Part of the `legal-compliance` rulebook's plugin set (issue #10). This is
plugin 3 of 3 in that set — see
`docs/issue-10/proposals/2026-07-31-methodology-enforcement.md` for the
full plugin list and composition rules.

## Methodology enforced

The freelunch / parallel-fan-out **sourcing-completeness** discipline
this rulebook's own research phase already practices (this repo's
`scout-brief.md`-style two-angle sweep): a document is allowed to make
no completeness claim at all, but if it *does* claim to have surveyed
multiple sources or angles, that claim must be backed by at least two
independently-attributed items, not one source restated under a
different label.

## Check logic

1. Kill switch check (`LEGAL_COMPLIANCE_FANOUT_GATE_OFF`) — any
   non-empty value disables the gate and allows immediately.
2. Resolve `tool_input.file_path` to a real path and match it against
   both write surfaces this plugin fires on:
   - `docs/issue-<n>/proposals/.*legal-compliance.*\.md`
   - `docs/issue-<n>/reports/legal-compliance\.md`

   Any other resolved path: allow immediately (no-op).
3. Compute the resulting file content for the pending write:
   - `Write`: `tool_input.content` verbatim.
   - `Edit`: read the current on-disk content and replace
     `old_string` with `new_string`; if `old_string` is not found,
     fail closed (deny).
   - `MultiEdit`: same as `Edit`, applying each entry in
     `tool_input.edits` in order.
4. Scan the resulting content for a **sweep/survey claim**: a
   markdown heading containing "sources" (case-insensitive), or a
   heading containing any of "scout", "sweep", "compared against",
   "survey" (case-insensitive). If no such heading exists anywhere in
   the document, the gate allows — a document that never claims a
   multi-source sweep is not required to prove one.
5. If a claim is present, collect bullet-list items under any
   "Sources" heading or any "Must-bes"/angle-style heading (heading
   text containing "must-be" or "angle"), up to the next
   heading of equal or shallower depth. Each bullet's *identity* is
   its first embedded backtick-quoted token, URL, or path-like token
   (falling back to the normalized bullet text) — this collapses two
   differently-labeled bullets that cite the same underlying source
   into one identity, so relabeling a single source under two bullets
   does not count as two sources.
6. If fewer than two distinct identities are found, deny with a
   message naming what's missing. Otherwise allow.

## Composition

This plugin fires on **both** the proposal and record write surfaces
that plugins 1 (`phase1-proposal-gate`) and 2 (`phase2-record-gate`)
own individually. It runs independently of those two — Claude Code
evaluates all matching `PreToolUse` hooks for a write and denies if any
one of them exits non-zero, so a document can pass its phase-specific
content gate and still be denied by this one (an unverifiable "we
surveyed multiple sources" claim backed by a single citation), and vice
versa. See the proposal's "Composition" section for the full AND-gate
rationale.

## Kill switch

`LEGAL_COMPLIANCE_FANOUT_GATE_OFF` — set to any non-empty value to
disable this gate entirely (exit 0 without checking anything). Scoped
to this plugin only; it does not affect `phase1-proposal-gate` or
`phase2-record-gate`, each of which has its own kill switch.

## Pattern precedent

The overall shape (bash wrapper with `set -euo pipefail` plus a `trap`
that fails closed on any unexpected error, a dedicated kill-switch env
var, JSON parsing done in an embedded `python3` block) follows the
pattern scouted from `pricing-rulebook`'s `pricing/hooks/methodology-gate.sh`.
No content from that file (or from `core/hooks/`) is vendored here —
`hooks/gate.sh` in this plugin is a new, role-specific script written
for this methodology's checks only.
