#!/usr/bin/env bash
# Aggregates the three legal-compliance gate suites plus the gate-house
# standard's own six mandatory case shapes, run against each gate directory
# via core's compliance-check.sh (referenced, never vendored — see
# docs/handbooks/gate-house-standard.md). Mirrors
# core/hooks/tests/run-role-gates-tests.sh's aggregation role.
#
# Usage: tests/legal-compliance/run-gate-lib-tests.sh
set -uo pipefail

cd "$(dirname "$0")/../.."

CORE_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "$0")/../.." && pwd -P)/../core}"
COMPLIANCE_CHECK="$CORE_ROOT/hooks/tests/compliance-check.sh"

total_fail=0

run_suite() {
  local name="$1" script="$2"
  echo "=== $name ==="
  if bash "$script"; then
    echo "$name: OK"
  else
    echo "$name: FAILED"
    total_fail=$((total_fail + 1))
  fi
  echo
}

run_suite "phase1-proposal-gate-tests" "tests/legal-compliance/phase1-proposal-gate-tests.sh"
run_suite "phase2-record-gate-tests" "tests/legal-compliance/phase2-record-gate-tests.sh"
run_suite "fanout-completeness-gate-tests" "tests/legal-compliance/fanout-completeness-gate-tests.sh"

echo "=== compliance-check.sh (gate-house standard) ==="
if [ -x "$COMPLIANCE_CHECK" ]; then
  for dir in legal-compliance-phase1-proposal-gate legal-compliance-phase2-record-gate legal-compliance-fanout-completeness-gate; do
    if ! "$COMPLIANCE_CHECK" "$dir"; then
      total_fail=$((total_fail + 1))
    fi
  done
else
  echo "compliance-check.sh not found at $COMPLIANCE_CHECK — skipping (set CLAUDE_PLUGIN_ROOT_CORE to a core checkout to run it)"
fi

echo
if [ "$total_fail" -eq 0 ]; then
  echo "run-gate-lib-tests: all suites green"
  exit 0
else
  echo "run-gate-lib-tests: $total_fail suite(s)/check(s) failed"
  exit 1
fi
