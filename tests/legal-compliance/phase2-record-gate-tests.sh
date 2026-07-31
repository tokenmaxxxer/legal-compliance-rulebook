#!/usr/bin/env bash
# Fixture tests for legal-compliance-phase2-record-gate/hooks/gate.sh.
# See docs/issue-10/proposals/2026-07-31-methodology-enforcement.md,
# "phase2-record-gate-tests.sh" test list.
set -uo pipefail

cd "$(dirname "$0")/../.."
REPO_ROOT="$(pwd)"
GATE="$REPO_ROOT/legal-compliance-phase2-record-gate/hooks/gate.sh"

pass_count=0
fail_count=0

run_case() {
  local name="$1"
  local expected_exit="$2"
  local payload="$3"

  local actual_exit
  local tmp_out tmp_err
  tmp_out="$(mktemp)"
  tmp_err="$(mktemp)"
  echo "$payload" | "$GATE" >"$tmp_out" 2>"$tmp_err"
  actual_exit=$?

  if [ "$actual_exit" -eq "$expected_exit" ]; then
    echo "PASS: $name (exit $actual_exit as expected)"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $name (expected exit $expected_exit, got $actual_exit)"
    echo "  stderr: $(cat "$tmp_err")"
    fail_count=$((fail_count + 1))
  fi
  rm -f "$tmp_out" "$tmp_err"
}

json_write_payload() {
  # $1 = file_path, $2 = content
  python3 - "$1" "$2" <<'PYEOF'
import json, sys
file_path, content = sys.argv[1], sys.argv[2]
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": file_path, "content": content},
}))
PYEOF
}

RECORD_PATH="$REPO_ROOT/docs/issue-42/reports/legal-compliance.md"

# --- Case 1: missing graded rating -> deny ---
content_missing_rating='# Legal Compliance Record — issue-42

## Regulations
- GDPR
- ISO 27001 standard

## Mitigations
- Encrypt data at rest to address risk under GDPR Art. 32 (issue-42)
- Add audit logging to mitigate risk in ISO 27001 clause 9

## Verdict
pass-with-mitigations
'
run_case "missing graded rating denies" 2 "$(json_write_payload "$RECORD_PATH" "$content_missing_rating")"

# --- Case 2: mitigation bullet citing no risk/clause -> deny ---
content_unref_mitigation='# Legal Compliance Record — issue-42

## Regulations
- GDPR
- ISO 27001 standard

## Ratings
- Data retention: red
- Access control: amber
- Logging: green

## Mitigations
- Encrypt data at rest to address risk under GDPR Art. 32 (issue-42)
- Do the thing that fixes it

## Verdict
pass-with-mitigations
'
run_case "mitigation bullet with no risk/clause reference denies" 2 "$(json_write_payload "$RECORD_PATH" "$content_unref_mitigation")"

# --- Case 3: fully conforming record -> allow ---
content_conforming='# Legal Compliance Record — issue-42

## Regulations
- GDPR
- ISO 27001 standard

## Ratings
- Data retention: red
- Access control: amber
- Logging: green

## Mitigations
- Encrypt data at rest to address risk under GDPR Art. 32 (issue-42)
- Add audit logging to mitigate risk in ISO 27001 clause 9

## Verdict
pass-with-mitigations
'
run_case "fully conforming record allows" 0 "$(json_write_payload "$RECORD_PATH" "$content_conforming")"

# --- Case 4: unrelated path -> allow/no-op ---
UNRELATED_PATH="$REPO_ROOT/README.md"
run_case "unrelated path is a no-op / allows" 0 "$(json_write_payload "$UNRELATED_PATH" "no checks should apply here")"

echo ""
echo "$pass_count passed, $fail_count failed"
if [ "$fail_count" -eq 0 ]; then
  exit 0
else
  exit 1
fi
