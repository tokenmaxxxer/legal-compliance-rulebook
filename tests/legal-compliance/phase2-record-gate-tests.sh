#!/usr/bin/env bash
# Fixture tests for legal-compliance-phase2-record-gate/hooks/gate.sh.
# See docs/issue-10/proposals/2026-07-31-methodology-enforcement.md,
# "phase2-record-gate-tests.sh" test list, and docs/issue-13 (gate-house
# standard adoption: gate-lib.sh/gate-lib.py, Bash-write coverage,
# section-scoped semantic checks, 1:1 mitigation-mapping adjacency fix).
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
  printf '%s' "$payload" | "$GATE" >"$tmp_out" 2>"$tmp_err"
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

# Like run_case, but lets the caller set extra env vars for the gate
# invocation (e.g. the kill switch).
run_case_env() {
  local name="$1"
  local expected_exit="$2"
  local payload="$3"
  shift 3
  # remaining args: NAME=value pairs, passed through to env.

  local actual_exit
  local tmp_out tmp_err
  tmp_out="$(mktemp)"
  tmp_err="$(mktemp)"
  printf '%s' "$payload" | env "$@" "$GATE" >"$tmp_out" 2>"$tmp_err"
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

json_edit_payload() {
  # $1 = file_path, $2 = old_string, $3 = new_string, $4 = replace_all ("true"/"false"/"")
  python3 - "$1" "$2" "$3" "$4" <<'PYEOF'
import json, sys
file_path, old, new, replace_all = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
tool_input = {"file_path": file_path, "old_string": old, "new_string": new}
if replace_all:
    tool_input["replace_all"] = (replace_all == "true")
print(json.dumps({"tool_name": "Edit", "tool_input": tool_input}))
PYEOF
}

json_multiedit_payload() {
  # $1 = file_path, $2 = edits JSON array (as text), e.g. '[{"old_string":...}]'
  python3 - "$1" "$2" <<'PYEOF'
import json, sys
file_path, edits_json = sys.argv[1], sys.argv[2]
edits = json.loads(edits_json)
print(json.dumps({
    "tool_name": "MultiEdit",
    "tool_input": {"file_path": file_path, "edits": edits},
}))
PYEOF
}

json_bash_payload() {
  # $1 = command
  python3 - "$1" <<'PYEOF'
import json, sys
command = sys.argv[1]
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": command}}))
PYEOF
}

RECORD_PATH="$REPO_ROOT/docs/issue-42/reports/legal-compliance.md"

# --- Case 1: missing graded rating (no risk-rating heading) -> deny ------
content_missing_rating='# Legal Compliance Record — issue-42

## Regulations
- GDPR Art. 32 (data protection)
- ISO 27001 standard, clause 9 (security)

## Mitigations
- Encrypt data at rest to address risk under GDPR Art. 32 (issue-42)
- Add audit logging to mitigate risk in ISO 27001 clause 9

## Verdict
pass-with-mitigations
'
run_case "missing graded rating denies" 2 "$(json_write_payload "$RECORD_PATH" "$content_missing_rating")"

# --- Case 2: mitigation bullet citing no risk/clause -> deny -------------
content_unref_mitigation='# Legal Compliance Record — issue-42

## Regulations
- GDPR Art. 32 (data protection)
- ISO 27001 standard, clause 9 (security)

## Risk Rating
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

# --- Case 3: fully conforming record -> allow ----------------------------
content_conforming='# Legal Compliance Record — issue-42

## Regulations
- GDPR Art. 32 (data protection)
- ISO 27001 standard, clause 9 (security)

## Risk Rating
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

# --- Case 4: unrelated path -> allow/no-op -------------------------------
UNRELATED_PATH="$REPO_ROOT/README.md"
run_case "unrelated path is a no-op / allows" 0 "$(json_write_payload "$UNRELATED_PATH" "no checks should apply here")"

# ==========================================================================
# New cases (issue-13 gate-house-standard adoption)
# ==========================================================================

FIXTURE_ROOT="$REPO_ROOT/docs/issue-97531/reports"
mkdir -p "$FIXTURE_ROOT"
cleanup_fixtures() {
  rm -rf "$REPO_ROOT/docs/issue-97531" "$REPO_ROOT/docs/issue-97532" "$REPO_ROOT/docs/issue-97533"
}
trap cleanup_fixtures EXIT

# --- Case 5: Edit with replace_all fixing a twice-occurring defect -------

FIXTURE_1="$FIXTURE_ROOT/legal-compliance.md"
base_defect_content='# Legal Compliance Record — issue-97531

## Regulations
- GDPR Art. 32 (data protection)
- ISO 27001 standard, clause 9 (security)

## Risk Rating
- Data retention: red
- Access control: amber
- Logging: green

## Mitigations
- Encrypt data at rest to mitigate exposure FIXME-CITE
- Add audit logging to mitigate risk FIXME-CITE

## Verdict
pass-with-mitigations
'
printf '%s' "$base_defect_content" > "$FIXTURE_1"
run_case "Edit replace_all:true fixes twice-occurring defect -> allow" 0 \
  "$(json_edit_payload "$FIXTURE_1" "FIXME-CITE" "under GDPR Art. 32 (issue-97531)" "true")"

# Reset fixture and try again without replace_all (defaults false): only
# the first occurrence gets fixed, the second bullet is still unreferenced.
printf '%s' "$base_defect_content" > "$FIXTURE_1"
run_case "Edit replace_all absent leaves one occurrence unfixed -> deny" 2 \
  "$(json_edit_payload "$FIXTURE_1" "FIXME-CITE" "under GDPR Art. 32 (issue-97531)" "")"

# --- Case 6: MultiEdit with mixed replace_all true/false -----------------

FIXTURE_2="$FIXTURE_ROOT/../../issue-97532-legal-compliance.md"
FIXTURE_2="$REPO_ROOT/docs/issue-97532/reports/legal-compliance.md"
mkdir -p "$(dirname "$FIXTURE_2")"
base_multiedit_content='# Legal Compliance Record — issue-97532

## Regulations
- GDPR Art. 32 (data protection)
- ISO 27001 standard, clause 9 (security)

## RATING_PLACEHOLDER
- Data retention: red
- Access control: amber
- Logging: green

## Mitigations
- Encrypt data at rest to mitigate exposure CITE_PLACEHOLDER
- Add audit logging to mitigate risk CITE_PLACEHOLDER

## Verdict
pass-with-mitigations
'
printf '%s' "$base_multiedit_content" > "$FIXTURE_2"
multiedit_edits='[
  {"old_string": "## RATING_PLACEHOLDER", "new_string": "## Risk Rating", "replace_all": false},
  {"old_string": "CITE_PLACEHOLDER", "new_string": "under GDPR Art. 32 (issue-97532)", "replace_all": true}
]'
run_case "MultiEdit mixed replace_all builds compliant record -> allow" 0 \
  "$(json_multiedit_payload "$FIXTURE_2" "$multiedit_edits")"

# --- Case 7: malformed JSON: truncated, non-object, empty ----------------

run_case "malformed JSON: truncated payload denies" 2 '{"tool_name": "Write", "tool_input": {'
run_case "malformed JSON: non-object top level denies" 2 '["Write", {"file_path": "x"}]'
run_case "malformed JSON: empty payload denies" 2 ''

# --- Case 8: kill switch set to unrecognized value stays active ---------

run_case_env "kill switch unrecognized value ('xyz') stays active -> deny" 2 \
  "$(json_write_payload "$RECORD_PATH" "$content_missing_rating")" \
  "LEGAL_COMPLIANCE_PHASE2_GATE_OFF=xyz"

# --- Case 9: absolute and ./-prefixed file_path variants -----------------

REL_RECORD_PATH="docs/issue-42/reports/legal-compliance.md"
run_case "absolute file_path, conforming record -> allow" 0 \
  "$(json_write_payload "$RECORD_PATH" "$content_conforming")"
run_case "./-prefixed file_path, conforming record -> allow" 0 \
  "$(json_write_payload "./$REL_RECORD_PATH" "$content_conforming")"

# --- Case 10: Bash-tool write reaching the record path -> deny -----------

run_case "Bash-tool write to docs/issue-N/reports/legal-compliance.md denies" 2 \
  "$(json_bash_payload "printf 'pass' >> docs/issue-97533/reports/legal-compliance.md")"

# --- Case 11: confirmed audit-bug fix — "risk" alone is not a reference --

content_bare_risk_mitigation='# Legal Compliance Record — issue-42

## Regulations
- GDPR Art. 32 (data protection)
- ISO 27001 standard, clause 9 (security)

## Risk Rating
- Data retention: red
- Access control: amber
- Logging: green

## Mitigations
- mitigate the risk

## Verdict
pass-with-mitigations
'
run_case "mitigation bullet 'mitigate the risk' with no citation denies (audit-bug fix)" 2 \
  "$(json_write_payload "$RECORD_PATH" "$content_bare_risk_mitigation")"

# --- Case 12: section-scoping fix — keywords outside proper headings ----

content_unscoped_keywords='# Legal Compliance Record — issue-42

## Overview

This record touches on green initiatives and past mitigat efforts, and
the team hopes this will pass eventually, but none of that lives under a
properly named section below.

## Notes

- GDPR
- ISO 27001
'
run_case "keywords outside proper section headings denies (section-scoping fix)" 2 \
  "$(json_write_payload "$RECORD_PATH" "$content_unscoped_keywords")"

# --- Case 13: fully section-scoped compliant record -> allow -------------

content_section_scoped_conforming='# Legal Compliance Record — issue-42

## Regulations
- GDPR Art. 32 (data protection)
- ISO 27001 standard, clause 9 (security)

## Risk Rating
- Data retention: red
- Access control: amber
- Logging: green

## Mitigations
- Encrypt data at rest to address risk under GDPR Art. 32 (issue-42)
- Add audit logging to mitigate risk in ISO 27001 clause 9

## Verdict
pass-with-mitigations
'
run_case "fully section-scoped compliant record allows" 0 \
  "$(json_write_payload "$RECORD_PATH" "$content_section_scoped_conforming")"

# --- Case 14: issue-16 audit-bug fix — bare "section" is not a reference -

content_bare_section_mitigation='# Legal Compliance Record — issue-42

## Regulations
- GDPR Art. 32 (data protection)
- ISO 27001 standard, clause 9 (security)

## Risk Rating
- Data retention: red
- Access control: amber
- Logging: green

## Mitigations
- mitigate this per the risk section above

## Verdict
pass-with-mitigations
'
run_case "mitigation bullet citing bare 'section' denies (issue-16 audit-bug fix)" 2 \
  "$(json_write_payload "$RECORD_PATH" "$content_bare_section_mitigation")"

# --- Case 15: missing-core (core #75-class defect) -> deny exit 2 --------

missing_core_output="$(printf '%s' "$(json_write_payload "$RECORD_PATH" "$content_conforming")" | CLAUDE_PLUGIN_ROOT_CORE=/nonexistent/core bash "$GATE" 2>&1)"
missing_core_exit=$?
if [ "$missing_core_exit" -eq 2 ] && printf '%s' "$missing_core_output" | grep -q "cannot source gate-lib.sh"; then
  echo "PASS: missing-core (CLAUDE_PLUGIN_ROOT_CORE unreachable) denies with guard message"
  pass_count=$((pass_count + 1))
else
  echo "FAIL: missing-core (CLAUDE_PLUGIN_ROOT_CORE unreachable) denies with guard message (exit=$missing_core_exit)"
  echo "  output: $missing_core_output"
  fail_count=$((fail_count + 1))
fi

cleanup_fixtures
trap - EXIT

echo ""
echo "$pass_count passed, $fail_count failed"
if [ "$fail_count" -eq 0 ]; then
  exit 0
else
  exit 1
fi
