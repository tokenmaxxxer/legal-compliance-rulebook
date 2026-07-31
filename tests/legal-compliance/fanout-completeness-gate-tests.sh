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

echo ""
echo "Results: $pass_count passed, $fail_count failed"
if [ "$fail_count" -eq 0 ]; then
  exit 0
else
  exit 1
fi
