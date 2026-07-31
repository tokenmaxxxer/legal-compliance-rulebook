#!/usr/bin/env bash
# Fixture tests for legal-compliance-phase1-proposal-gate/hooks/gate.sh
# Run from anywhere: bash tests/legal-compliance/phase1-proposal-gate-tests.sh

set -uo pipefail

cd "$(dirname "$0")/../.."

GATE="legal-compliance-phase1-proposal-gate/hooks/gate.sh"
PASS_COUNT=0
FAIL_COUNT=0

run_case() {
  local name="$1"
  local payload="$2"
  local expected_exit="$3"

  actual_output="$(printf '%s' "$payload" | bash "$GATE" 2>&1)"
  actual_exit=$?

  if [[ "$actual_exit" -eq "$expected_exit" ]]; then
    echo "PASS: $name"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL: $name (expected exit $expected_exit, got $actual_exit)"
    echo "  output: $actual_output"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# --- Case 1: missing scope-boundary -> deny -------------------------------

content_1='# Proposal

## Regulation enumeration

We enumerate GDPR and CCPA. No exclusions.

## Necessity and proportionality

This is necessary and proportionate before any mitigation is named.

Then we discuss mitigation options.

## Evidence / rationale

- Position A cites Art. 5 of GDPR.
'

payload_1=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": "docs/issue-10/proposals/x-legal-compliance.md", "content": sys.stdin.read()}}))
' <<<"$content_1")

run_case "missing scope-boundary -> deny" "$payload_1" 2

# --- Case 2: mitigation stated before necessity/proportionality -> deny ---

content_2='# Proposal

## Scope

In scope: the checkout API. Out of scope: billing.

## Regulation enumeration

We enumerate GDPR and CCPA. No exclusions.

We propose mitigation of the identified risk right away.

Only later do we discuss necessity and proportionality of the approach.

## Evidence / rationale

- Position A cites Art. 5 of GDPR.
'

payload_2=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": "docs/issue-10/proposals/x-legal-compliance.md", "content": sys.stdin.read()}}))
' <<<"$content_2")

run_case "mitigation before necessity/proportionality -> deny" "$payload_2" 2

# --- Case 3: fully conforming doc -> allow ---------------------------------

content_3='# Proposal

## Scope

In scope: the checkout API. Out of scope: billing.

## Regulation enumeration

We enumerate GDPR and CCPA. No exclusions.

## Necessity and proportionality

This approach is necessary and proportionate.

Only after establishing that do we name a mitigation for the residual risk.

## Evidence / rationale

- Position A cites Art. 5 of GDPR.
- Position B relies on assumption, unsourced due to lack of published guidance.
'

payload_3=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": "docs/issue-10/proposals/x-legal-compliance.md", "content": sys.stdin.read()}}))
' <<<"$content_3")

run_case "fully conforming doc -> allow" "$payload_3" 0

# --- Case 4: one position with no citation/assumption-label -> deny -------

content_4='# Proposal

## Scope

In scope: the checkout API. Out of scope: billing.

## Regulation enumeration

We enumerate GDPR and CCPA. No exclusions.

## Necessity and proportionality

This approach is necessary and proportionate.

Only after establishing that do we name a mitigation for the residual risk.

## Evidence / rationale

- Position A cites Art. 5 of GDPR.
- Position B is just true, trust us.
'

payload_4=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": "docs/issue-10/proposals/x-legal-compliance.md", "content": sys.stdin.read()}}))
' <<<"$content_4")

run_case "position with no citation/assumption-label -> deny" "$payload_4" 2

# --- Case 5: write to unrelated path -> allow, no-op -----------------------

payload_5=$(python3 -c '
import json
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": "README.md", "content": "irrelevant content"}}))
')

run_case "unrelated path -> allow, no-op" "$payload_5" 0

echo
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
