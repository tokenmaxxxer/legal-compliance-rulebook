# Handbook — legal-compliance gate test harness

## tests/legal-compliance/run-gate-lib-tests.sh

Aggregates all three legal-compliance gate suites
(phase1-proposal-gate-tests.sh, phase2-record-gate-tests.sh,
fanout-completeness-gate-tests.sh) and runs core's compliance-check.sh
detector against each of the three gate directories.

Usage:

    tests/legal-compliance/run-gate-lib-tests.sh

Set CLAUDE_PLUGIN_ROOT_CORE to point at a core checkout (containing
hooks/lib/gate-lib.sh, hooks/lib/gate-lib.py, and
hooks/tests/compliance-check.sh) before running, if no core plugin
sibling directory is present relative to this repo. Exits 0 only if all
three suites pass and compliance-check.sh reports no failures against
any gate directory.

Each individual suite script can also be run standalone the same way
(bash tests/legal-compliance/<name>-tests.sh); all three gates it
exercises source core's gate-house standard library
(core/hooks/lib/gate-lib.{sh,py}, issue #72) by reference rather than
reimplementing kill-switch, trap, path-normalize, or write-reconstruction
logic locally.
