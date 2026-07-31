---
subject: issue-5
role: implementation
loop_state: scope-proposed
---

# Current-state survey — stub-check.sh recall (core #69)

## What core #69 changed

Issue #2/#66's rollout (see `docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md`,
step 5) had this repo **copy** `core/hooks/tests/stub-check.sh` into
`legal-compliance/hooks/tests/stub-check.sh`, "distributed the same way
`parse-check.sh` already is." Core issue #69 supersedes that: canon now
states `stub-check.sh` itself must be run by **reference** against the core
install (`core/hooks/tests/stub-check.sh`), never vendored into a rulebook —
per `docs/handbooks/canon-scripts.md` (core repo). This repo's copy is
exactly the drift `stub-check.sh`'s own header warns about for the other
gate files (issue-66 pattern), now extended to the script itself.

## Grep results — `stub-check.sh` occurrences in this repo

```
$ grep -rn "stub-check.sh" . (excluding .git)
./legal-compliance/hooks/tests/stub-check.sh          # the vendored copy itself
docs/issue-2/reports/implementation.md:28-29           # historical record of the copy step
docs/issue-2/reports/implementation.md:42,47
docs/issue-2/reports/implementation/survey.md:60,72,99
docs/issue-2/proposals/.../2026-07-31-...md:10,21,50-51,60,70,84
```

- **Real file (the copy to recall):** `legal-compliance/hooks/tests/stub-check.sh`
  (89 lines, byte-for-byte the core script per its own header — confirmed by
  reading the file directly during this survey).
- All other hits are prose references inside issue-2's own docs (proposal,
  survey, implementation report) — historical record of *why* the copy
  exists, not additional copies. No occurrence under `docs/handbooks/`,
  `src/`, or `test/` in this repo.

## `hooks.json` — does it reference the copy?

`legal-compliance/hooks/hooks.json` (full contents):

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/directive.sh" } ] }
    ]
  }
}
```

`stub-check.sh` has **no entry in `hooks.json`** — it is not wired into any
`PreToolUse`/`SessionStart` hook here. It exists only as a standalone test
file under `hooks/tests/`, matching `stub-check.sh`'s own doc comment: "Every
rulebook copies this file verbatim and runs it over its own hooks/ tree" —
i.e. it was meant to be invoked manually/by a test harness, not registered
as a Claude Code hook. There is therefore no `hooks.json` edit required to
*stop* referencing a copy — only the file deletion and a switch in how it is
*invoked* (from a copy to the core-canon path) matters.

## Other current state

- No `docs/handbooks/canon-scripts.md` exists in this repo (core-repo
  artifact, referenced but not vendored here — consistent with the "no
  manifest pointer needed" precedent set in issue-2).
- No `core/` directory exists locally in this rulebook repo; core hooks
  (`role-directive.sh`, `stub-check.sh` canon copy, etc.) are supplied by the
  plugin install at runtime via `${CLAUDE_PLUGIN_ROOT_CORE}`-style resolution,
  the same pattern `directive.sh` already uses for `role-directive.sh`
  (confirmed: `legal-compliance/hooks/directive.sh` sources
  `role-directive.sh` by reference, not by copy — issue-2 already
  established this pattern for everything except `stub-check.sh`).
- `legal-compliance/hooks/directive.sh` is unaffected by this issue (already
  reference-only per issue-2).

## Sources

- `legal-compliance/hooks/hooks.json`, `legal-compliance/hooks/tests/stub-check.sh`,
  `legal-compliance/hooks/directive.sh` (read directly, this repo)
- `docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md`,
  `docs/issue-2/reports/implementation/survey.md`,
  `docs/issue-2/reports/implementation.md` (this repo — prior-art precedent)
- `gh issue view 5` (issue #5 body, this repo)
