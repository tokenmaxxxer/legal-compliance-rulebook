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

# --- Temp fixtures for Edit/MultiEdit replace_all cases --------------------

FIXTURE_DIR="docs/issue-10/proposals"
mkdir -p "$FIXTURE_DIR"
FIXTURE_1="$(mktemp "${FIXTURE_DIR}/tmp-repl-legal-compliance-XXXXXX.md")"
FIXTURE_2="$(mktemp "${FIXTURE_DIR}/tmp-multiedit-legal-compliance-XXXXXX.md")"

cleanup_fixtures() {
  rm -f "$FIXTURE_1" "$FIXTURE_2"
}
trap cleanup_fixtures EXIT

# --- Case 6: Edit replace_all:true fixes both occurrences -> allow --------

base_content_6='# Proposal

## Scope

PLACEHOLDER

## Regulation enumeration

We enumerate GDPR and CCPA. No exclusions.

## Necessity and proportionality

This approach is necessary and proportionate.

Only after establishing that do we name a mitigation for the residual risk.

## Evidence / rationale

- Position A cites Art. 5 of GDPR.
'
printf '%s' "$base_content_6" > "$FIXTURE_1"

payload_6=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Edit", "tool_input": {"file_path": sys.argv[1], "old_string": "PLACEHOLDER", "new_string": "In scope: the checkout API. Out of scope: billing.", "replace_all": True}}))
' "$FIXTURE_1")

run_case "Edit replace_all:true fixes occurrence -> allow" "$payload_6" 0

# --- Case 7: Edit replace_all:false/absent leaves an occurrence -> deny ---

base_content_7='# Proposal

## Scope

DUPTOKEN and something else DUPTOKEN too.

## Regulation enumeration

We enumerate GDPR and CCPA. No exclusions.

## Necessity and proportionality

This approach is necessary and proportionate.

Only after establishing that do we name a mitigation for the residual risk.

## Evidence / rationale

- Position A cites Art. 5 of GDPR.
'
printf '%s' "$base_content_7" > "$FIXTURE_1"

# Without replace_all, only the first DUPTOKEN gets fixed; the doc still
# lacks a proper scope/boundary statement overall because the leftover
# DUPTOKEN pollutes the section (scope_re still won't match cleanly).
payload_7=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Edit", "tool_input": {"file_path": sys.argv[1], "old_string": "DUPTOKEN", "new_string": "placeholder-not-scope-language"}}))
' "$FIXTURE_1")

run_case "Edit replace_all:false/absent leaves occurrence unfixed -> deny" "$payload_7" 2

# --- Case 8: MultiEdit two edits, one replace_all true + one false -> allow

base_content_8='# Proposal

## Scope

SCOPETOKEN and SCOPETOKEN again.

## Regulation enumeration

We enumerate GDPR and CCPA. No exclusions.

## Necessity and proportionality

MITITOKEN

Only after establishing that do we name a mitigation for the residual risk.

## Evidence / rationale

- Position A cites Art. 5 of GDPR.
'
printf '%s' "$base_content_8" > "$FIXTURE_2"

payload_8=$(python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "MultiEdit",
    "tool_input": {
        "file_path": sys.argv[1],
        "edits": [
            {"old_string": "SCOPETOKEN", "new_string": "In scope: the checkout API. Out of scope: billing.", "replace_all": True},
            {"old_string": "MITITOKEN", "new_string": "This approach is necessary and proportionate.", "replace_all": False},
        ],
    },
}))
' "$FIXTURE_2")

run_case "MultiEdit mixed replace_all edits both land -> allow" "$payload_8" 0

# --- Case 9: malformed JSON variants -> deny -------------------------------

run_case "malformed JSON: truncated -> deny" '{"tool_name": "Write", "tool_in' 2
run_case "malformed JSON: top-level string -> deny" '"just a string"' 2
run_case "malformed JSON: empty stdin -> deny" '' 2

# --- Case 10: kill switch typo value stays ACTIVE (denies) -----------------

actual_output="$(printf '%s' "$payload_1" | LEGAL_COMPLIANCE_PHASE1_GATE_OFF=xyz bash "$GATE" 2>&1)"
actual_exit=$?
if [[ "$actual_exit" -eq 2 ]]; then
  echo "PASS: kill switch typo value 'xyz' stays ACTIVE (denies)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "FAIL: kill switch typo value 'xyz' stays ACTIVE (denies) (expected exit 2, got $actual_exit)"
  echo "  output: $actual_output"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

actual_output="$(printf '%s' "$payload_1" | LEGAL_COMPLIANCE_PHASE1_GATE_OFF=0 bash "$GATE" 2>&1)"
actual_exit=$?
if [[ "$actual_exit" -eq 2 ]]; then
  echo "PASS: kill switch typo value '0' stays ACTIVE (denies)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "FAIL: kill switch typo value '0' stays ACTIVE (denies) (expected exit 2, got $actual_exit)"
  echo "  output: $actual_output"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Case 11: absolute and ./-prefixed file_path variants ------------------

abs_path="$(pwd)/docs/issue-10/proposals/x-legal-compliance.md"
dotslash_path="./docs/issue-10/proposals/x-legal-compliance.md"

payload_11a=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.stdin.read()}}))
' "$abs_path" <<<"$content_3")

run_case "absolute file_path, conforming doc -> allow" "$payload_11a" 0

payload_11b=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.stdin.read()}}))
' "$dotslash_path" <<<"$content_3")

run_case "./-prefixed file_path, conforming doc -> allow" "$payload_11b" 0

payload_11c=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.stdin.read()}}))
' "$abs_path" <<<"$content_1")

run_case "absolute file_path, denying doc -> deny" "$payload_11c" 2

# --- Case 12: Bash-tool write reaching gate scope -> deny -------------------

payload_12=$(python3 -c '
import json
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": "cp foo docs/issue-10/proposals/y-legal-compliance.md"}}))
')

run_case "Bash-tool write into gate scope -> deny" "$payload_12" 2

# --- Case 13: structural-pairing regression (issue-16 D3 fix) -------------
# Necessity language only in an unrelated early section; the Mitigations
# section itself has no necessity language of its own or in an ancestor.
# Previously false-allowed by the whole-document first-occurrence check.

content_13='# Proposal

## Scope

In scope: the checkout API. Out of scope: billing. It is not necessary to
configure anything further here.

## Regulation enumeration

We enumerate GDPR and CCPA. No exclusions.

## Mitigations

We propose mitigation of the identified risk.

## Evidence / rationale

- Position A cites Art. 5 of GDPR.
'

payload_13=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": "docs/issue-10/proposals/x-legal-compliance.md", "content": sys.stdin.read()}}))
' <<<"$content_13")

run_case "structural pairing: necessity only in unrelated section -> deny" "$payload_13" 2

# --- Case 14: missing-core (core #75-class defect) -> deny exit 2 ---------

missing_core_output="$(printf '%s' "$payload_3" | CLAUDE_PLUGIN_ROOT_CORE=/nonexistent/core bash "$GATE" 2>&1)"
missing_core_exit=$?
if [[ "$missing_core_exit" -eq 2 ]] && grep -q "cannot source gate-lib.sh" <<<"$missing_core_output"; then
  echo "PASS: missing-core (CLAUDE_PLUGIN_ROOT_CORE unreachable) denies with guard message"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "FAIL: missing-core (CLAUDE_PLUGIN_ROOT_CORE unreachable) denies with guard message (exit=$missing_core_exit)"
  echo "  output: $missing_core_output"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
