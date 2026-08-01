# Survey — gate A+ final closeout (issue #16)

## Scope

Confirms, against this repo's current tree (branch issue-16/legal-compliance)
and against tokenmaxxxer-core main as of 2026-08-01, every residual defect
issue #16 names, plus the two named upstream preconditions.

## Precondition status (checked directly against tokenmaxxxer-core main, commit 52bdc15)

- **core #75** (source guard + `gate_bash_write_targets` py parity):
  merged (PR #77, `deliver(implementation)`). `core/hooks/lib/gate-lib.sh`'s
  usage-contract comment now mandates
  `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh" || { echo
  "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }` — an `||`
  guard on the same statement, fail-closed instead of the prior silent
  fail-open (missing source -> `gate_kill_switch_active` undefined -> 127
  -> read as "kill switch off" -> allow). `core/hooks/lib/gate-lib.py` now
  has `gate_bash_write_targets(command)`, an sh-identical token-scan mirror
  (same `[A-Za-z0-9_./~$-]+` character class). `core/hooks/tests/compliance-check.sh`
  gained a third detection rule: a `*-gate.sh` file whose `gate-lib.sh"$`
  source line has no `\|\|` on the same line fails compliance-check.
- **on-the-record #182** (`CLAUDE_PLUGIN_ROOT_CORE` injection in spawn.py):
  referenced by this issue as landed; not independently re-verified here
  (out of this repo's tree — the fallback path this repo's gates already
  use, `${CLAUDE_PLUGIN_ROOT_CORE:-$(cd .../../core && pwd -P)}`, is
  unaffected either way since it degrades to the sibling-path fallback
  when the env var is unset).

Both preconditions are landed; this repo's remediation can reference-adopt
core's now-final guard form and py-parity function directly.

## Defect-by-defect confirmation (this repo, current tree)

### D1 — unguarded `gate-lib.sh` source (issue-75-class defect, all three gates)

All three gates' source line has no `||` guard:

- `legal-compliance-phase1-proposal-gate/hooks/gate.sh:12`
- `legal-compliance-phase2-record-gate/hooks/gate.sh:14`
- `legal-compliance-fanout-completeness-gate/hooks/gate.sh:2`

Each reads: `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"` with
no trailing `|| { ... exit 2; }`. Reproduces the exact issue-75 fail-open
shape core just fixed in its own gates: a topology where
`CLAUDE_PLUGIN_ROOT_CORE` resolves to nothing reachable runs no code past
that line, so `gate_kill_switch_active` is undefined, the next call site
(`gate_kill_switch_active ... || { trap - EXIT; exit 0; }`) reads the
resulting 127 as "switch off," and every write this gate is supposed to
police is silently allowed. Confirmed by direct inspection; the same shape
core's compliance-check.sh's new rule 3 detects.

### D2 — "section" bare-word citation bypass in the 1:1 mitigation-mapping check

`legal-compliance-phase2-record-gate/hooks/checker.py:230-234`, `ref_re`:

```python
ref_re = re.compile(
    r"(Art\.|§|\bsection\b|\bclause\b|\bregulation\b|\bstandard\b|"
    r"\bissue[-\s#]?\d+\b)",
    re.IGNORECASE,
)
```

Issue-13 explicitly dropped the bare word `risk` from this alternation as
the confirmed live bug ("mitigate the risk" self-satisfying the citation
check on no real reference). `section` is left in the alternation and is
exactly as generic and self-satisfying: a mitigation bullet reading
"see the mitigations section above" cites nothing regulation-specific yet
passes both the citation-shape check and, whenever the word "section" also
appears anywhere in the Regulations section body (near-certain — any
Regulations section that itself uses the word "section" for its own
structure, or that a bullet's adjacency check happens to match against),
the adjacency check. Reproduced: a mitigation bullet
`"- mitigate this per the risk section above"` (no `Art.`/`§`/regulation
name/issue-N) passes `checker.py` today. Same defect class as the fixed
`risk` bug, left unfixed.

### D3 — necessity-before-mitigation (a3) is still keyword-offset, not structurally paired

`legal-compliance-phase1-proposal-gate/hooks/gate.sh:175-200`. Issue-13's
record claims this check "moved from a whole-document string-offset check
to a section-body ordering check." The actual code: for each heading in
document order, record the first section body containing
necessity-language and the first section body containing "mitigat"
language, then compare the two headings' *document positions*. This is a
document-order comparison of two independently-found first-occurrences —
functionally the same offset-comparison shape as before, just computed
per-section-first-hit instead of per-character-offset. It does not require
the necessity/proportionality rationale to appear in the *same* section as
(or in a section structurally preceding, by heading nesting) the mitigation
it is meant to justify. Reproduced: a proposal with an early, unrelated
section containing the word "necessity" in a throwaway sentence (e.g. an
Install/prerequisites section reading "it is not necessary to configure
X") followed by a Mitigations section with no necessity language of its
own passes a3, because *some* section anywhere earlier contains
necessity-shaped text. The issue's own wording ("여전히 첫 키워드
오프셋(구조적 페어링 미이행)") names exactly this gap.

### D4 — README/manifest stale semantics and ghost references

All three gate plugins' README.md describe superseded behavior:

- **Kill-switch semantics**: all three READMEs
  (`legal-compliance-phase1-proposal-gate/README.md:46-47`,
  `legal-compliance-phase2-record-gate/README.md:42-44`,
  `legal-compliance-fanout-completeness-gate/README.md:67-70`) say "any
  non-empty value" disables the gate. The actual, already-landed
  `gate_kill_switch_active` (core gate-lib.sh, adopted in issue-13) only
  disables on a recognized on-spelling (`1`/`true`/`yes`/`on`,
  case-insensitive); every other value — including the empty string and
  any unrecognized garbage/typo — keeps the gate active. The README text
  describes the pre-issue-13 fail-open shape, not the fixed one.
- **Trap/fail-closed semantics**: all three READMEs describe `set -euo
  pipefail` plus a `trap` on `ERR`
  (`legal-compliance-phase1-proposal-gate/README.md:55-56`,
  `legal-compliance-phase2-record-gate/README.md:57-60`,
  `legal-compliance-fanout-completeness-gate/README.md:74-76`). The actual
  code (all three `gate.sh`) calls `gate_trap_fail_closed` (an EXIT trap
  installed as the very first statement, from core's gate-lib.sh) and uses
  `set -uo pipefail` (no `-e`). Pre-issue-13 wording, unfixed.
- **Matcher/contract coverage**: `legal-compliance-phase1-proposal-gate/README.md:14`
  and `legal-compliance-phase2-record-gate/README.md:48` describe the
  `PreToolUse` matcher as `Write`/`Edit`/`MultiEdit` only. The actual
  `hooks.json` matcher on all three plugins is
  `Write|Edit|MultiEdit|Bash|NotebookEdit` (added in issue-13), and all
  three `gate.sh`/`checker.py` have a conservative Bash-write-deny branch
  and (phase1/phase2's Python payload, via `gate_reconstruct_write`)
  NotebookEdit reconstruction support that none of the three READMEs
  document.
- **`legal-compliance-fanout-completeness-gate/README.md`** additionally
  omits NotebookEdit and the Bash conservative-deny branch from its
  "Check logic" step 3 entirely (only lists Write/Edit/MultiEdit).
- No ghost *file* references remain in any of the four README.md files or
  the top-level README.md — issue-13 already de-ghosted the top-level
  Layout section, and this repo's plugin tree (checked via `find`) has no
  files beyond what each README's own "Structure" section lists except
  for the stale prose above. `legal-compliance-phase2-record-gate/README.md`'s
  reference to the retired `legal-compliance/hooks/record-fields-gate.sh`
  is an intentional, still-accurate historical supersession note (that
  file does not exist in this tree; the note explains why), not a ghost.
- Role-name check: `.claude-plugin/marketplace.json` and all four
  `plugin.json` manifests were checked against the current role name
  (`legal-compliance`) and hand-off target (`risk-management`, per the
  top-level README's own `hand-off` line) — no stale/old role name found
  in any manifest.

### D5 — hooks.json matcher / code coverage parity

Checked all three plugins' `hooks/hooks.json` against their `gate.sh`'s
actual tool-name branches:

| Plugin | matcher | code branches on |
|---|---|---|
| phase1-proposal-gate | `Write\|Edit\|MultiEdit\|Bash\|NotebookEdit` | Bash (deny-scan), Write, Edit/MultiEdit/NotebookEdit (via `gate_reconstruct_write`) |
| phase2-record-gate | `Write\|Edit\|MultiEdit\|Bash\|NotebookEdit` | same shape, in `checker.py` |
| fanout-completeness-gate | `Write\|Edit\|MultiEdit\|Bash\|NotebookEdit` | same shape |

Matcher and code are already in parity on all three — every tool the
matcher advertises is reachable and handled in the corresponding code
path; every tool the code branches on is covered by the matcher. This item
requires no code change; it requires the README fix in D4 (README text
falsely narrows the documented coverage below what's already wired and
tested).

## Not reproduced / out of this issue's stated scope

- `compliance-check.sh`'s file-discovery glob (`*-gate.sh`) still does not
  match this repo's bare `gate.sh` naming convention — a pre-existing,
  previously-flagged (issue-13 record, "Open findings") gap, unrelated to
  and unchanged by core #75. Renaming the four files plus all hooks.json
  wiring and test-harness references is a larger, unrequested write-set
  expansion; issue #16 does not ask for it. Requirement 3's "compliance-check
  통과 record 기록" is satisfied the same way issue-13's delivery satisfied
  it: direct verification of the two/three substantive detection
  conditions against each file's content (glob-miss noted, not silently
  hidden).

## Write surfaces this proposal will name (frozen in the proposal, not survey)

- `legal-compliance-phase1-proposal-gate/hooks/gate.sh`
- `legal-compliance-phase2-record-gate/hooks/{gate.sh,checker.py}`
- `legal-compliance-fanout-completeness-gate/hooks/gate.sh`
- `legal-compliance-phase1-proposal-gate/README.md`
- `legal-compliance-phase2-record-gate/README.md`
- `legal-compliance-fanout-completeness-gate/README.md`
- `tests/legal-compliance/{phase1-proposal-gate-tests.sh,phase2-record-gate-tests.sh,fanout-completeness-gate-tests.sh,run-gate-lib-tests.sh}`
