#!/usr/bin/env bash
# Narrowly-scoped local gate for this role's phase-2 record fields.
# Layered on top of core's global record-fields-gate.sh (structural §20
# check, keyed off CLAUDE_ROLE) — core has no per-role required-field-list
# hook, so this checks only the four legal-compliance-specific fields it
# cannot check. See docs/issue-1/proposals/2026-07-31-legal-compliance-domain-norms.md.
set -euo pipefail

[ "${CLAUDE_ROLE:-}" = "legal-compliance" ] || exit 0

RECORD_FILE="${1:-}"
[ -n "$RECORD_FILE" ] || exit 0
case "$RECORD_FILE" in
  */reports/legal-compliance.md) ;;
  *) exit 0 ;;
esac
[ -f "$RECORD_FILE" ] || exit 0

missing=()
grep -qiE 'regulation|standard' "$RECORD_FILE" || missing+=("named regulation/standard list")
grep -qiE '\b(red|amber|green)\b' "$RECORD_FILE" || missing+=("graded (red/amber/green) risk rating per issue")
grep -qiE 'mitigat' "$RECORD_FILE" || missing+=("mitigations mapped to risks")
grep -qiE '\b(pass-with-mitigations|pass|fail)\b' "$RECORD_FILE" || missing+=("final verdict (pass / pass-with-mitigations / fail)")

if [ "${#missing[@]}" -gt 0 ]; then
  echo "record-fields-gate (legal-compliance): missing required field(s) in $RECORD_FILE:" >&2
  for m in "${missing[@]}"; do echo "  - $m" >&2; done
  exit 1
fi
