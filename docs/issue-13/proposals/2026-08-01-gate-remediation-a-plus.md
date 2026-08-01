---
status: proposed
files:
  - legal-compliance-phase1-proposal-gate/hooks/gate.sh
  - legal-compliance-phase2-record-gate/hooks/gate.sh
  - legal-compliance-phase2-record-gate/hooks/checker.py
  - legal-compliance-fanout-completeness-gate/hooks/gate.sh
  - tests/legal-compliance/phase1-proposal-gate-tests.sh
  - tests/legal-compliance/phase2-record-gate-tests.sh
  - tests/legal-compliance/fanout-completeness-gate-tests.sh
  - tests/legal-compliance/run-gate-lib-tests.sh
  - README.md
  - docs/issue-13/reports/legal-compliance.md
---

# Proposal — gate A+ remediation (issue #13)

What was asked: fix every defect the 2026-08-01 real-code audit found
(kill-switch/path/trap fail-open shapes, `replace_all`/MultiEdit
mishandling, deny-reason delivery, README ghosts), reference-adopt
`core`'s now-landed gate-house standard (issue #72, PR #74) instead of
reimplementing it, upgrade the four semantic checks from
substring/keyword-offset to section/adjacency/structure, and add the six
mandatory test-case groups with a green suite in delivered state. Full
current-state evidence for every defect below is in
`docs/issue-13/reports/legal-compliance/survey.md`; the standard's
must-bes and the adopt/skip reasoning are in
`docs/issue-13/reports/legal-compliance/scout-brief.md`.

## What will be done (phase 2, on Approve)

### 1. Migrate all three gates onto `gate-lib.sh`/`gate-lib.py`

Each of `phase1-proposal-gate/hooks/gate.sh`,
`phase2-record-gate/hooks/{gate.sh,checker.py}`,
`fanout-completeness-gate/hooks/gate.sh` sources/loads the canon library
by reference, per its usage header:

```bash
. "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${LEGAL_COMPLIANCE_PHASE1_GATE_OFF:-}" || { trap - EXIT; exit 0; }
```

```python
import importlib.util, os
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)
event = gate_lib.gate_parse_json_or_deny(raw, deny)
```

Concretely, per file:

- **Kill switch** (fixes the confirmed fail-open bug, survey §1): replace
  `[[ -n "${VAR:-}" ]]` with `gate_kill_switch_active "${VAR:-}"` in all
  three `gate.sh` files. Env var names unchanged
  (`LEGAL_COMPLIANCE_PHASE1_GATE_OFF`, `LEGAL_COMPLIANCE_PHASE2_GATE_OFF`,
  `LEGAL_COMPLIANCE_FANOUT_GATE_OFF`) — only the recognized-on-spelling
  semantics change.
- **Trap** (survey §2): replace each hand-rolled `trap ... EXIT/ERR` body
  with `gate_trap_fail_closed`, called before `set -uo pipefail` per the
  library's own ordering requirement.
- **JSON parse** (survey §7, already stderr-correct, now also
  house-shaped): route the initial `json.loads` through
  `gate_lib.gate_parse_json_or_deny(raw, deny)` in `checker.py` and in the
  two inline Python payloads (`phase1-proposal-gate`,
  `fanout-completeness-gate`).
- **Path normalize** (survey §6): replace each gate's ad hoc
  `os.path.realpath(file_path)` + hand-rolled regex-tail match with
  `gate_lib.gate_normalize_path(root, path)`, `root` resolved once per
  gate as the repo root (`git rev-parse --show-toplevel` at gate-script
  start, cached the way `resolved_path` is computed today — no new
  runtime dependency, `git` is already required by these scripts'
  environment). The existing `PATH_RE`/`RECORD_RE` patterns keep matching
  against the normalized root-relative tail instead of the realpath'd
  absolute string.
- **Write reconstruction** (survey §3, the confirmed `replace_all` bug in
  all three gates): replace every `content.replace(old, new, 1)` /
  `current.replace(old_string, new_string, 1)` call with
  `gate_lib.gate_reconstruct_write(tool_name, tool_input, current_content)`,
  denying (fail-closed) when it returns `ok=False` — matching the
  fail-closed posture these gates already take on an unmatched
  `old_string` today, just routed through the shared function instead of
  each gate's own inline loop.
- **Bash-write coverage** (survey §5): each `hooks.json`'s `PreToolUse`
  matcher gains `Bash` alongside `Write|Edit|MultiEdit`; each gate's
  Python payload, when `tool_name == "Bash"`, runs
  `gate_lib_sh`'s `gate_bash_write_targets "$command"` (bash) over
  `tool_input.command`, applies the existing path pattern to each
  candidate token, and — if any token matches this gate's scope — denies
  with a message naming the gate cannot verify a `Bash`-tool write's
  resulting content and refuses on principle (matching `board-gate.sh`'s
  own posture for the same tool/coverage gap, confirmed as the house
  precedent). This is intentionally the conservative branch: a `Bash`
  write into scope is refused outright, not content-checked, since no
  `gate_reconstruct_write`-equivalent exists for an arbitrary shell
  command.
- **NotebookEdit**: matcher and payload branch added per gate (mirrors
  `gate_reconstruct_write`'s existing `NotebookEdit` support) even though
  no live `.ipynb` exists under `docs/issue-*/` today — closing the gap
  for free rather than leaving it as a known-unmatched tool.

### 2. Semantic-check upgrade: substring/keyword-offset → section/adjacency/structure

All four checks migrate onto one shared primitive, generalized from
`fanout-completeness-gate`'s existing heading-scoped extraction (the
strongest pattern already in this repo — scout-brief "Adopt" #1): build
one `headings = [(line_idx, level, title)]` list per document, then locate
each semantic element by heading match + `section_end()` boundary instead
of a whole-document regex.

- **phase2/checker.py's four keyword checks** (regulation/standard,
  red/amber/green, mitigations, verdict) move from "word appears anywhere
  in the document" to "word appears inside the section whose heading
  names that concept" (`## Regulations`/`## Risk Rating`/
  `## Mitigations`/`## Verdict`-shaped headings, case-insensitive
  substring match on the heading text only — not the body). A record
  missing the heading entirely still fails (as today), but a record that
  only mentions the word in an unrelated section now also fails, closing
  the audit's "boilerplate keyword satisfies the check" gap.
- **1:1 mitigation-to-risk mapping** (the audit's named example, survey
  §8): drop `\brisk\b` from `ref_re`. Require each mitigation bullet to
  cite either a clause marker (`Art.`, `§`, `section`, `clause`), a named
  regulation/standard token, or an `issue-N`/`issue #N` reference — the
  same set minus the self-satisfying bare word. Add adjacency: the cited
  reference must resolve to a heading or bullet that exists elsewhere in
  the same document's Regulations section (string match against that
  section's already-extracted bullet/heading text), not merely "some
  clause-shaped token appears in this bullet" — closing the "mitigate the
  risk" self-satisfaction case entirely, not just the bare-word instance
  of it.
- **phase1's a3 (necessity-before-mitigation)**: replace the
  whole-document string-offset check with a section-adjacency check using
  the same `headings` list: locate the heading whose section body first
  contains necessity/proportionality language and the heading whose
  section body first contains `mitigat`; require the former section's
  heading line-index to precede the latter's. Two sections that each
  correctly contain their own concept, appearing in the wrong document
  order, still fail (matches current intent) — but a term mentioned in
  passing inside an unrelated section can no longer flip the check via
  raw string offset.
- **phase1's a1/a2/a4**: keep their existing section-body scoping (already
  the strongest of the four phase1 checks per survey §8) — only their
  heading-lookup helper is deduplicated onto the shared `headings`-list
  primitive, no behavior change.

### 3. Test suites: add all six mandatory case groups

Each of `tests/legal-compliance/{phase1-proposal-gate,phase2-record-gate,
fanout-completeness-gate}-tests.sh` gains, per the standard's mandatory
list (`docs/handbooks/gate-house-standard.md` "Standard test harness"):

1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string` — asserts the reconstructed content replaces every
   occurrence, not just the first.
2. `MultiEdit` with mixed `replace_all: true`/`false` edits in one call.
3. Malformed JSON (truncated, non-object top level, empty payload) — all
   three deny.
4. Kill switch set to an unrecognized value (e.g. a typo) — asserts the
   gate stays **active** (this is the direction the current suites get
   backwards implicitly, by never testing it at all).
5. Absolute `file_path` matching the same scope a relative-path fixture
   already matches, plus a `./`-prefixed variant.
6. A `Bash`-tool file write reaching the same target a `Write`-tool call
   would hit — asserts denial per item 1's new Bash-coverage branch.

A new `tests/legal-compliance/run-gate-lib-tests.sh` runs all three
suites plus a role-adapted copy of `core/hooks/tests/run-gate-lib-tests.sh`'s
six-case shape against this repo's three gates in one entry point, mirroring
`core/hooks/tests/run-role-gates-tests.sh`'s own aggregation role. Full
suite green in delivered state is the phase-2 acceptance bar (issue's
requirement #3).

### 4. README de-ghosting

Replace the Layout section's five nonexistent entries with the three
gates that actually fire today
(`legal-compliance-phase1-proposal-gate/hooks/gate.sh`,
`legal-compliance-phase2-record-gate/hooks/{gate.sh,checker.py}`,
`legal-compliance-fanout-completeness-gate/hooks/gate.sh`) plus the
existing accurate entries (`legal-compliance/.claude-plugin/plugin.json`,
`legal-compliance/hooks/{hooks.json,directive.sh}`,
`docs/specs/approvers.md`). One line per gate naming what it enforces
(phase-1 proposal norms a1-a4, phase-2 record norms + 1:1 mapping,
fan-out sourcing-completeness), sourced from each gate's own file-header
comment rather than re-describing behavior that could drift out of sync
again.

## Deliberately not done

- **No reimplementation of any `gate_*` function.** Every mechanical fix
  (kill switch, trap, JSON parse, path normalize, write reconstruction) is
  a call-site migration onto the landed `core` library, per the issue's
  own precondition and this repo's own already-approved precedent
  (`docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md`'s
  reference-not-copy pattern for `stub-check.sh`).
- **No new abstraction for section-adjacency beyond the shared
  `headings`-list.** Scout-brief's "skip" call: a bespoke ordering DSL is
  not needed when "heading A's line-index precedes heading B's" is
  suf­ficient for the one ordering requirement in scope.
- **No change to the five existing checks that are already
  section-scoped correctly** (fanout-completeness-gate's whole design;
  phase1's a1, a2, a4) beyond deduplicating their heading lookup onto the
  shared primitive — they are not broken, and rewriting working section
  logic to "prove the migration happened" would be scope growth the issue
  did not ask for.
- **No relaxation of the fail-closed posture anywhere** — every new
  `gate_reconstruct_write`/`gate_parse_json_or_deny` call denies on
  `ok=False`/parse failure exactly as the current inline logic already
  does; this is a call-site swap, not a leniency change.
- **`Bash`-tool writes are refused outright when in scope, not
  content-checked.** No attempt to parse or reconstruct an arbitrary
  shell command's resulting file content — deliberately the conservative
  branch (see item 1 above), matching `board-gate.sh`'s existing posture
  for the same gap.

## How it will be known to work

- `core/hooks/tests/compliance-check.sh "$(dirname "$0")/.."` run against
  each of the three gate directories, invoked by reference exactly as
  `docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md`'s
  landed pattern already establishes for `stub-check.sh` — clean (no
  `FAIL`) output recorded in `docs/issue-13/reports/legal-compliance.md`.
- `tests/legal-compliance/run-gate-lib-tests.sh` and all three existing
  gate-specific suites green, including the six new mandatory case groups
  per suite.
- Manual reproduction of the audit's two named live bugs, before and
  after: (a) a mitigation bullet reading "mitigate the risk" with no
  clause/regulation/issue citation — denied after, passed before; (b) an
  unrecognized kill-switch value (e.g. `LEGAL_COMPLIANCE_PHASE1_GATE_OFF=x`)
  — gate stays active after, was disabled before. Both captured as
  before/after transcript snippets in the phase-2 record.
- README's Layout section cross-checked against `find` output for actual
  `legal-compliance*/hooks/*.sh` and `legal-compliance*/hooks/*.py` files
  — zero mismatches.

## Write set

Frozen to the ten paths in this file's frontmatter — no new gate files,
no new plugin directories; all changes are call-site migrations, check
upgrades, test additions, and doc corrections within the existing three
gate plugins plus this issue's own phase-2 record.

## Open questions for the approver

1. **`CORE_PLUGIN_ROOT` resolution.** This proposal reuses the exact
   fallback expression `docs/issue-2`'s landed proposal used for
   `stub-check.sh` (`${CLAUDE_PLUGIN_ROOT}/../core`), but that proposal's
   own text flags it as unverified against a real marketplace-install
   sibling-path layout (this repo's dev checkout has `core/` and each
   rulebook as literal siblings, which may not hold externally). Phase 2
   will re-verify this the same way issue #2's work did before relying on
   it; flagging now so the approver knows this is inherited risk, not new
   risk introduced by this proposal.
2. **Section-heading vocabulary for phase2 records.** The upgraded
   checker requires headings shaped like `## Regulations`/`## Risk
   Rating`/`## Mitigations`/`## Verdict` (case-insensitive substring on
   the heading text, matching the pattern `fanout-completeness-gate`
   already uses for "Sources"/"Must-bes"). If any currently-passing
   record under `docs/issue-*/reports/legal-compliance.md` uses different
   heading wording, that record would newly fail re-validation post-
   migration. Phase 2 will grep existing records for this before
   finalizing the heading-match regex; flagging as a design input the
   approver may want to weigh in on (exact accepted heading synonyms) up
   front rather than have it decided unilaterally mid-implementation.
