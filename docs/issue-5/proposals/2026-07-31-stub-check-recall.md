---
status: proposed
files:
  - legal-compliance/hooks/tests/stub-check.sh
  - docs/issue-5/reports/implementation.md
---

# Proposal — recall vendored `stub-check.sh` copy (core #69 rollout)

What was asked: issue #5 — core #69's canon says `stub-check.sh` must be run
by reference against the core install, never vendored into a rulebook.
Delete this repo's copy and, if `hooks.json` registers it, remove that too.
See `docs/issue-5/reports/implementation/survey.md` for the full
current-state findings this proposal is based on.

## What will be done (phase 2, on Approve)

1. Delete `legal-compliance/hooks/tests/stub-check.sh` — the sole vendored
   copy (survey confirms no other copies exist in this repo).
2. No `hooks.json` edit needed — survey confirmed `stub-check.sh` was never
   registered as a `PreToolUse`/`SessionStart` hook; it was only a
   standalone file under `hooks/tests/`.
3. Record a passing reference-run of `stub-check.sh` in
   `docs/issue-5/reports/implementation.md`: invoke the core-canon path
   (`${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/tests/stub-check.sh
   legal-compliance/`) rather than a local copy, and paste the exit-0
   output into the record — mirroring how `directive.sh` already resolves
   `role-directive.sh` by reference (issue-2 precedent).

## Deliberately not done

- No change to `legal-compliance/hooks/directive.sh` — already
  reference-only, out of scope for this issue.
- No `docs/handbooks/canon-scripts.md` vendored into this repo — that file
  lives in core and is read by reference per issue-2's "no manifest pointer
  needed" precedent.

## How it will be known to work

- `find legal-compliance/hooks -name stub-check.sh` returns nothing.
- `legal-compliance/hooks/hooks.json` unchanged (already had no
  `stub-check.sh` entry) and still validates as JSON.
- A reference invocation of core's `stub-check.sh` against
  `legal-compliance/` exits 0, and that output is pasted into
  `docs/issue-5/reports/implementation.md`.

## Write set

Frozen to the two paths listed in this file's frontmatter — one deletion,
one new phase-2 record file.

## Open question for the approver

None — target shape is fully determined by core #69's landed canon; the
`hooks.json` question the issue raised ("있으면") resolved to "no entry
exists, nothing to remove" during survey.
