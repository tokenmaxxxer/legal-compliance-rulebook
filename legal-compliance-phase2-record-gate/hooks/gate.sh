#!/usr/bin/env bash
# legal-compliance-phase2-record-gate / hooks/gate.sh
#
# PreToolUse gate enforcing issue-1 phase-2 record norms (b1-b5) on
# docs/issue-<n>/reports/legal-compliance.md writes, plus the 1:1
# mitigation-to-risk/clause-reference mapping heuristic. See ../README.md
# for what it checks.
#
# Contract: reads a PreToolUse JSON payload on stdin (Write/Edit/MultiEdit/
# Bash/NotebookEdit), resolves the would-be final file content, and exits
# 0 (allow) or 2 (deny, message on stderr). Fails closed on any unexpected
# error. Thin wrapper: all parsing/checking logic lives in checker.py.

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "phase2-record-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${LEGAL_COMPLIANCE_PHASE2_GATE_OFF:-}" || { trap - EXIT; exit 0; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
payload="$(cat)"

root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$root" ]; then
  echo "phase2-record-gate: could not determine project root — failing closed" >&2
  exit 2
fi

set +e
printf '%s' "$payload" | GATE_LIB_PY="$GATE_LIB_PY" GATE_ROOT="$root" python3 "$SCRIPT_DIR/checker.py"
py_status=$?
set -e

case "$py_status" in
  0)
    exit 0
    ;;
  2)
    # checker.py already wrote its deny reason to stderr; nothing to relay.
    exit 2
    ;;
  *)
    exit 2
    ;;
esac
