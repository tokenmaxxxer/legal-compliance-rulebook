# legal-compliance-phase2-record-gate

A self-contained Claude Code plugin that mechanically enforces the
phase-2 "record" (산출물) norms adopted in
`docs/issue-1/proposals/2026-07-31-legal-compliance-domain-norms.md`
(norms b1–b5), per plugin 2 of
`docs/issue-10/proposals/2026-07-31-methodology-enforcement.md`.

## What it enforces

On any `Write`, `Edit`, `MultiEdit`, `Bash`, or `NotebookEdit` whose
resolved file path matches `docs/issue-<n>/reports/legal-compliance.md`,
the gate denies the write unless the resulting file content contains all
of (a `Bash` command whose tokens appear to write to a matching path is
denied outright, conservatively, since this gate cannot verify a
Bash-tool write's resulting content):

1. A named regulation/standard list.
2. A graded (`red`/`amber`/`green`) risk rating per identified issue.
3. Mitigations, present and mapped to risks.
4. A final verdict of `pass`, `pass-with-mitigations`, or `fail`.
5. **New**: a 1:1 mitigation-to-risk/clause mapping — every mitigation
   bullet (a `-`/`*` line under a "Mitigations" heading, or any bullet
   line containing "mitigat") must itself cite a specific reference
   (a regulation/standard name, a clause marker such as `Art.` or `§`,
   or a reference to a named issue like `issue-3`). The bare words
   "risk" and "section" do not count as references (both were confirmed
   self-satisfying and dropped from the citation pattern). A mitigation
   bullet with no such reference fails the gate.

Checks 1–4 are the same four checks the retired
`legal-compliance/hooks/record-fields-gate.sh` performed (same grep
patterns, ported into this plugin's Python checker); check 5 is new.

## Supersession

This plugin **supersedes and retires**
`legal-compliance/hooks/record-fields-gate.sh`. That script's four
presence checks are strictly subsumed by this plugin's five checks, so
running both would be redundant drift on the same write surface — the
same pattern this repo already closed for issue-2/issue-5. Do not wire
`record-fields-gate.sh` back into any hook config; this plugin is its
replacement.

## Kill switch

Set the environment variable `LEGAL_COMPLIANCE_PHASE2_GATE_OFF` to a
recognized on-spelling (`1`/`true`/`yes`/`on`, case-insensitive) to
disable this gate unconditionally (the gate exits 0 without checking
anything). Any other value — including the empty string or an
unrecognized typo — leaves the gate active.

## Contract

- `PreToolUse` hook, matcher `Write|Edit|MultiEdit|Bash|NotebookEdit`.
- Reads the standard hook JSON payload on stdin, resolves `file_path`,
  and computes the final file content (verbatim for `Write`; by
  reconstructing the edit against the current on-disk content for
  `Edit`/`MultiEdit`/`NotebookEdit`; a `Bash` write is denied
  conservatively without content reconstruction).
- Only fires on paths matching `docs/issue-<n>/reports/legal-compliance.md`;
  any other path is a no-op (exit 0).
- Exit 0 = allow. Exit 2 = deny, with the missing element(s) named on
  stderr.
- Fails closed: sources core's `gate-lib.sh` behind an `||` guard
  (missing/unreachable core fails closed with exit 2, not a silent
  allow), installs `gate_trap_fail_closed` as its first statement (an
  `EXIT` trap) and runs under `set -uo pipefail` (no `-e`). Malformed
  JSON, an edit that can't be reconstructed against the current
  content, and any other internal script bug all become exit 2, never
  a silent allow.

## Structure

- `.claude-plugin/plugin.json` — plugin manifest.
- `hooks/hooks.json` — wires the single `PreToolUse` entry.
- `hooks/gate.sh` — bash entrypoint: kill switch, stdin capture,
  fail-closed error handling, delegates the actual check to
  `checker.py`.
- `hooks/checker.py` — JSON parsing, path resolution, content
  reconstruction, and the five checks described above.

## Precedent

This plugin's shape (bash wrapper with fail-closed `trap` and its own
kill switch, around an embedded/companion Python check) follows the
pattern scouted from `pricing-rulebook`'s `methodology-gate.sh`, per
`docs/issue-10/proposals/2026-07-31-methodology-enforcement.md`. No
file is vendored from `pricing-rulebook` or any other rulebook's tree —
this is a new, role-specific script, referencing that plugin only as
pattern precedent.

## Part of

The `legal-compliance` rulebook's methodology-enforcement plugin set
(issue #10), alongside `legal-compliance-phase1-proposal-gate` and
`legal-compliance-fanout-completeness-gate`. See the proposal above for
the composition rule: the phase-2 record norm is the AND of this
plugin's verdict and the fan-out-completeness plugin's verdict on the
same write.
