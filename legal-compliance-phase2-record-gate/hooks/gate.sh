#!/usr/bin/env bash
# phase2-record-gate: enforces issue-1 phase-2 record norms (b1-b5) on
# docs/issue-<n>/reports/legal-compliance.md writes. Supersedes the four
# presence checks in legal-compliance/hooks/record-fields-gate.sh (kept
# byte-compatible with its grep patterns) plus a new 1:1 mitigation-bullet
# to risk/clause-reference mapping heuristic. See
# docs/issue-10/proposals/2026-07-31-methodology-enforcement.md (plugin 2).
set -euo pipefail

on_err() {
  echo "phase2-record-gate: internal error or malformed input — failing closed" >&2
  exit 2
}
trap on_err ERR

# Kill switch: if set to any non-empty value, allow unconditionally.
if [ -n "${LEGAL_COMPLIANCE_PHASE2_GATE_OFF:-}" ]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
payload="$(cat)"

# Delegate JSON parsing, path resolution, and the field/heuristic checks
# to checker.py. It prints nothing on allow; on deny it prints the
# missing-element message(s) to stdout, which we relay to stderr. Exit
# codes:
#   0 = allow (including non-matching path)
#   1 = deny (checks failed)
#   anything else = unexpected -> trap turns it into exit 2
set +e
result="$(printf '%s' "$payload" | python3 "$SCRIPT_DIR/checker.py")"
py_status=$?
set -e

case "$py_status" in
  0)
    exit 0
    ;;
  1)
    echo "$result" >&2
    exit 2
    ;;
  *)
    exit 2
    ;;
esac
