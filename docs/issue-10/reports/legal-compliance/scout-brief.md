# Scout brief — issue #10 (methodology-as-gate)

Mode: parallel file reads across sibling rulebook worktrees on this same
host (1 sweep round, 2 angles: `implementation-rulebook`'s hook machine,
`pricing-rulebook`'s methodology-gate), then 1 deepening round reading
core's canon-scripts clause. 2 stages total, well under budget.

## Must-bes (what every strong comparable gate has)
1. **Fail-closed on internal error / unparseable payload** — both
   `implementation-rulebook`'s gates and `pricing/hooks/methodology-gate.sh`
   trap non-zero/non-2 exit and deny rather than silently pass.
2. **Targets write surfaces by resolved, real path regex**, not by tool
   name alone — `pricing/hooks/methodology-gate.sh` resolves symlinks and
   matches `docs/issue-<n>/proposals/*pricing*.md` and
   `docs/issue-<n>/reports/pricing.md` separately, each with its own
   required-element list.
3. **A kill switch env var**, documented in the script header
   (`PRICING_METHODOLOGY_GATE_OFF`).
4. **Gate tests are real fixture files**, not prose —
   `implementation-rulebook/tests/run-gate-tests.sh` plus per-gate
   `hooks/tests/parse-check.sh`, `tests/deny-only-check.sh`: allow/deny
   cases actually executed, not "manually exercised" narration.

## Performance axes these gates compete on
- Heuristic strictness (keyword-only vs. keyword + text-order check).
- Blast radius when the gate is wrong (kill switch present on both
  reviewed gates — non-negotiable for a fail-closed hook).

## Adopt / skip
- **Adopt**: pricing's shape (single self-contained bash+python script,
  regex on resolved path, per-write-surface required-element lists,
  fail-closed, kill switch) — directly transferable to this role's two
  write surfaces (proposal + record).
- **Skip**: `implementation-rulebook`'s cross-call state machine
  (`coding-progress-gate.sh` + `hunt-state.sh`, tracking ordering across
  multiple tool calls/turns). This role's one ordering constraint
  (necessity/proportionality text before mitigations, issue-1 proposal
  (a)3) is checkable by **string-position comparison within one document
  in one gate invocation** — it never spans multiple tool calls. Adopting
  persistent cross-call state for an intra-document constraint would be a
  scope mismatch; the proposal must state this explicitly rather than
  skip the state-tracking question silently.

## Gap line (survey vs. field)
Field must-bes 1-3 (fail-closed, resolved-path targeting, kill switch) are
**missing** from this role's current `record-fields-gate.sh` (no trap, no
path resolution, no kill switch, no proposal-surface coverage at all).
Must-be 4 (real gate-test fixtures) is **entirely absent** repo-wide.

## Segment fit
Same repo family (`tokenmaxxxer` rulebook plugins), same contract v3,
directly comparable scale — no adaptation for a different segment needed.

Sources:
- `/home/jwjung/.tokenmaxxxer/work/pricing-rulebook-issue-10-pricing/pricing/hooks/methodology-gate.sh`
- `/home/jwjung/.tokenmaxxxer/work/pricing-rulebook-issue-10-pricing/pricing/hooks/hooks.json`
- `/home/jwjung/.tokenmaxxxer/work/implementation-rulebook-issue-56-implementation/tests/run-gate-tests.sh`
- `/home/jwjung/.tokenmaxxxer/work/implementation-rulebook-issue-56-implementation/coding/hooks/coding-progress-gate.sh`
- `/home/jwjung/.tokenmaxxxer/work/implementation-rulebook-issue-56-implementation/coding/hooks/hunt-state.sh`
- `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/docs/handbooks/canon-scripts.md`
