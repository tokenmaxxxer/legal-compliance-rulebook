#!/usr/bin/env bash
# Fixture tests for legal-compliance-fanout-completeness-gate/hooks/gate.sh
#
# Feeds synthetic PreToolUse JSON payloads (a Write with tool_input.content
# set to fixture text) to the gate script on stdin and asserts the exit
# code. Exits 0 only if every case passes.

set -uo pipefail

cd "$(dirname "$0")/../.."

GATE="legal-compliance-fanout-completeness-gate/hooks/gate.sh"

pass_count=0
fail_count=0

# Build a Write PreToolUse JSON payload from a file path + content, given
# on stdin as $1=file_path, $2=content (via files to avoid escaping pain).
build_payload() {
  local file_path="$1"
  local content_file="$2"
  python3 - "$file_path" "$content_file" <<'PY'
import json, sys
file_path, content_file = sys.argv[1], sys.argv[2]
with open(content_file, "r", encoding="utf-8") as f:
    content = f.read()
payload = {
    "tool_name": "Write",
    "tool_input": {"file_path": file_path, "content": content},
}
print(json.dumps(payload))
PY
}

run_case() {
  local name="$1" file_path="$2" content_file="$3" expected_rc="$4"
  local payload
  payload="$(build_payload "$file_path" "$content_file")"
  local actual_rc
  set +e
  printf '%s' "$payload" | "$GATE" >/dev/null 2>"$TMPDIR_TESTS/stderr.txt"
  actual_rc=$?
  set -e

  if [ "$actual_rc" = "$expected_rc" ]; then
    echo "PASS: $name (rc=$actual_rc)"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $name (expected rc=$expected_rc, got rc=$actual_rc)"
    echo "  stderr: $(cat "$TMPDIR_TESTS/stderr.txt")"
    fail_count=$((fail_count + 1))
  fi
}

# run_case_raw: feed a pre-built raw JSON payload string (for Edit/MultiEdit/
# Bash/malformed-JSON cases the simple Write-only build_payload can't build).
run_case_raw() {
  local name="$1" payload="$2" expected_rc="$3" env_prefix="${4:-}"
  local actual_rc
  set +e
  if [ -n "$env_prefix" ]; then
    printf '%s' "$payload" | env $env_prefix "$GATE" >/dev/null 2>"$TMPDIR_TESTS/stderr.txt"
  else
    printf '%s' "$payload" | "$GATE" >/dev/null 2>"$TMPDIR_TESTS/stderr.txt"
  fi
  actual_rc=$?
  set -e

  if [ "$actual_rc" = "$expected_rc" ]; then
    echo "PASS: $name (rc=$actual_rc)"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $name (expected rc=$expected_rc, got rc=$actual_rc)"
    echo "  stderr: $(cat "$TMPDIR_TESTS/stderr.txt")"
    fail_count=$((fail_count + 1))
  fi
}

TMPDIR_TESTS="$(mktemp -d "${TMPDIR:-/tmp}/fanout-gate-tests.XXXXXX")"
trap 'rm -rf "$TMPDIR_TESTS"' EXIT

# --- Case 1: proposal, Sources heading, sweep claim, only ONE source → deny
cat >"$TMPDIR_TESTS/case1.md" <<'EOF'
# Proposal

We ran a sweep of prior art before drafting this.

## Sources

- `docs/issue-1/proposals/legal-compliance-domain-norms.md`
EOF
run_case "case1: sweep claim with one source (deny)" \
  "docs/issue-10/proposals/2026-07-31-legal-compliance-case1.md" \
  "$TMPDIR_TESTS/case1.md" 2

# --- Case 2: proposal, Sources heading, TWO independently-named sources → allow
cat >"$TMPDIR_TESTS/case2.md" <<'EOF'
# Proposal

We surveyed two independent sources before drafting this.

## Sources

- `docs/issue-1/proposals/legal-compliance-domain-norms.md`
- `docs/issue-5/reports/core-reference.md`
EOF
run_case "case2: sweep claim with two distinct sources (allow)" \
  "docs/issue-10/proposals/2026-07-31-legal-compliance-case2.md" \
  "$TMPDIR_TESTS/case2.md" 0

# --- Case 3: record, no sweep/survey claim at all → allow (nothing to check)
cat >"$TMPDIR_TESTS/case3.md" <<'EOF'
# Legal Compliance Record

## Regulations

- GDPR Art. 6

## Ratings

- GDPR Art. 6: green

## Mitigations

- None required.

## Verdict

pass
EOF
run_case "case3: no sweep claim (allow)" \
  "docs/issue-10/reports/legal-compliance.md" \
  "$TMPDIR_TESTS/case3.md" 0

# --- Case 4: record, multi-angle claim, same source cited twice under
# different bullet labels → deny
cat >"$TMPDIR_TESTS/case4.md" <<'EOF'
# Legal Compliance Record

## Angles Compared Against

- Angle A: `docs/issue-1/proposals/legal-compliance-domain-norms.md`
- Angle B: `docs/issue-1/proposals/legal-compliance-domain-norms.md`
EOF
run_case "case4: multi-angle claim with duplicate source (deny)" \
  "docs/issue-10/reports/legal-compliance.md" \
  "$TMPDIR_TESTS/case4.md" 2

# --- Case 5: unrelated path → allow / no-op
cat >"$TMPDIR_TESTS/case5.md" <<'EOF'
# README

Nothing relevant here, not even a sweep claim.

## Sources

- one thing only
EOF
run_case "case5: unrelated path (allow, no-op)" \
  "README.md" \
  "$TMPDIR_TESTS/case5.md" 0

# --- Case 6: Edit with replace_all:true fixing a twice-occurring defect
# (base doc has "## Sources" heading with only ONE distinct source, and the
# repeated old_string "- placeholder" occurs twice; replace_all rewrites both
# so a second distinct source is added) → allow
# Baseline has 2 distinct sources (a.md, b.md) -> allow. replace_all:true
# collapses every "a.md" occurrence (including the standalone one) into
# "b.md", leaving only 1 distinct source -> deny. replace_all:false/absent
# only replaces the first occurrence, leaving both a.md and b.md present
# (still 2 distinct) -> allow. This direction actually exercises the
# replace_all bug: a first-occurrence-only reconstruction would wrongly
# leave the doc at 2 distinct sources (allow) in the replace_all:true case
# too, since only one of the two a.md bullets would flip.
FIXTURE6="docs/issue-10/proposals/2026-07-31-legal-compliance-case6.md"
mkdir -p "$(dirname "$FIXTURE6")"
cat >"$FIXTURE6" <<'EOF'
# Proposal

We surveyed sources before drafting this.

## Sources

- `docs/a.md`
- `docs/a.md`
- `docs/b.md`
EOF
payload6_true="$(python3 - "$FIXTURE6" <<'PY'
import json, sys
fp = sys.argv[1]
payload = {
    "tool_name": "Edit",
    "tool_input": {
        "file_path": fp,
        "old_string": "`docs/a.md`",
        "new_string": "`docs/b.md`",
        "replace_all": True,
    },
}
print(json.dumps(payload))
PY
)"
run_case_raw "case6: Edit replace_all:true collapses to 1 distinct source (deny)" \
  "$payload6_true" 2

# Same fixture, replace_all:false/absent -> only first a.md flips, a.md and
# b.md both still present -> 2 distinct -> allow.
cat >"$FIXTURE6" <<'EOF'
# Proposal

We surveyed sources before drafting this.

## Sources

- `docs/a.md`
- `docs/a.md`
- `docs/b.md`
EOF
payload6_false="$(python3 - "$FIXTURE6" <<'PY'
import json, sys
fp = sys.argv[1]
payload = {
    "tool_name": "Edit",
    "tool_input": {
        "file_path": fp,
        "old_string": "`docs/a.md`",
        "new_string": "`docs/b.md`",
    },
}
print(json.dumps(payload))
PY
)"
run_case_raw "case6b: Edit replace_all absent still leaves 2 distinct sources (allow)" \
  "$payload6_false" 0
rm -f "$FIXTURE6"

# --- Case 7: MultiEdit with mixed replace_all true/false building a fully
# compliant (>=2 distinct sources) doc from a non-compliant base → allow
FIXTURE7="docs/issue-10/reports/legal-compliance.md"
mkdir -p "$(dirname "$FIXTURE7")"
cat >"$FIXTURE7" <<'EOF'
# Legal Compliance Record

We surveyed sources before drafting this.

## Sources

- OLD_A
- OLD_A
EOF
payload7="$(python3 - "$FIXTURE7" <<'PY'
import json, sys
fp = sys.argv[1]
payload = {
    "tool_name": "MultiEdit",
    "tool_input": {
        "file_path": fp,
        "edits": [
            {
                "old_string": "- OLD_A",
                "new_string": "- `docs/issue-1/proposals/legal-compliance-domain-norms.md`",
                "replace_all": True,
            },
            {
                "old_string": "## Sources\n\n- `docs/issue-1/proposals/legal-compliance-domain-norms.md`",
                "new_string": "## Sources\n\n- `docs/issue-1/proposals/legal-compliance-domain-norms.md`\n- `docs/issue-5/reports/core-reference.md`",
                "replace_all": False,
            },
        ],
    },
}
print(json.dumps(payload))
PY
)"
run_case_raw "case7: MultiEdit mixed replace_all builds compliant doc (allow)" \
  "$payload7" 0
rm -f "$FIXTURE7"

# --- Case 8: malformed JSON — truncated, non-object top level, empty payload
run_case_raw "case8a: truncated JSON (deny)" '{"tool_name": "Write", "tool_inp' 2
run_case_raw "case8b: non-object top-level JSON (deny)" '["not", "an", "object"]' 2
run_case_raw "case8c: empty payload (deny)" '' 2

# --- Case 9: kill switch set to an unrecognized value → gate stays active
cat >"$TMPDIR_TESTS/case9.md" <<'EOF'
# Proposal

We ran a sweep of prior art before drafting this.

## Sources

- `docs/issue-1/proposals/legal-compliance-domain-norms.md`
EOF
payload9="$(build_payload "docs/issue-10/proposals/2026-07-31-legal-compliance-case9.md" "$TMPDIR_TESTS/case9.md")"
run_case_raw "case9: kill switch unrecognized value keeps gate active (deny)" \
  "$payload9" 2 "LEGAL_COMPLIANCE_FANOUT_GATE_OFF=xyz"

# --- Case 10: absolute file_path and ./-prefixed file_path variants of an
# already-covered fixture → same expected result as the relative-path case
REPO_ROOT="$(git rev-parse --show-toplevel)"
cat >"$TMPDIR_TESTS/case10.md" <<'EOF'
# Proposal

We ran a sweep of prior art before drafting this.

## Sources

- `docs/issue-1/proposals/legal-compliance-domain-norms.md`
EOF
run_case "case10a: relative path, one source (deny, baseline)" \
  "docs/issue-10/proposals/2026-07-31-legal-compliance-case10.md" \
  "$TMPDIR_TESTS/case10.md" 2
run_case "case10b: absolute file_path variant (deny)" \
  "$REPO_ROOT/docs/issue-10/proposals/2026-07-31-legal-compliance-case10.md" \
  "$TMPDIR_TESTS/case10.md" 2
run_case "case10c: ./-prefixed file_path variant (deny)" \
  "./docs/issue-10/proposals/2026-07-31-legal-compliance-case10.md" \
  "$TMPDIR_TESTS/case10.md" 2

# --- Case 11: Bash-tool write reaching a path matching PROPOSAL_RE or
# RECORD_RE → deny regardless of command content
payload11="$(python3 <<'PY'
import json
payload = {
    "tool_name": "Bash",
    "tool_input": {
        "command": "printf 'x' > docs/issue-10/reports/legal-compliance.md",
    },
}
print(json.dumps(payload))
PY
)"
run_case_raw "case11: Bash write to matching path (deny)" "$payload11" 2

echo ""
echo "Results: $pass_count passed, $fail_count failed"
if [ "$fail_count" -eq 0 ]; then
  exit 0
else
  exit 1
fi
