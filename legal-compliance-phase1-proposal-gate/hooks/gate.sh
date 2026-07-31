#!/usr/bin/env bash
# legal-compliance-phase1-proposal-gate / hooks/gate.sh
#
# PreToolUse gate enforcing issue-1 phase-1 proposal norms (a1-a4) on
# legal-compliance proposal docs. See ../README.md for what it checks.
#
# Contract: reads a PreToolUse JSON payload on stdin (Write/Edit/MultiEdit),
# resolves the would-be final file content, and exits 0 (allow) or 2 (deny,
# message on stderr). Fails closed on any unexpected error.

set -euo pipefail

on_error() {
  echo "phase1-proposal-gate: internal error — failing closed (deny)" >&2
  exit 2
}
trap on_error ERR

# Kill switch: if set to any non-empty value, allow everything unchecked.
if [[ -n "${LEGAL_COMPLIANCE_PHASE1_GATE_OFF:-}" ]]; then
  exit 0
fi

payload="$(cat)"

set +e
python3 - "$payload" <<'PY'
import json
import os
import re
import sys

payload_raw = sys.argv[1]

try:
    payload = json.loads(payload_raw)
except Exception:
    print("phase1-proposal-gate: could not parse PreToolUse JSON payload", file=sys.stderr)
    sys.exit(2)

tool_name = payload.get("tool_name", "")
tool_input = payload.get("tool_input", {}) or {}
file_path = tool_input.get("file_path")

if not file_path:
    # Nothing to resolve against — no-op allow (not our surface).
    sys.exit(0)

resolved_path = os.path.realpath(file_path)

PATH_RE = re.compile(r"docs/issue-\d+/proposals/.*legal-compliance.*\.md$")
if not PATH_RE.search(resolved_path.replace(os.sep, "/")):
    sys.exit(0)

# --- Compute final content for this write -------------------------------

def read_current_content(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return None

if tool_name == "Write":
    final_content = tool_input.get("content", "")
elif tool_name in ("Edit", "MultiEdit"):
    current = read_current_content(file_path)
    if current is None:
        current = read_current_content(resolved_path)
    if current is None:
        current = ""

    if tool_name == "Edit":
        old_string = tool_input.get("old_string", "")
        new_string = tool_input.get("new_string", "")
        if old_string and old_string not in current:
            print(
                "phase1-proposal-gate: Edit old_string not found in current "
                "file content — failing closed",
                file=sys.stderr,
            )
            sys.exit(2)
        final_content = current.replace(old_string, new_string, 1) if old_string else current + new_string
    else:  # MultiEdit
        edits = tool_input.get("edits", []) or []
        content = current
        for edit in edits:
            old_string = edit.get("old_string", "")
            new_string = edit.get("new_string", "")
            if old_string and old_string not in content:
                print(
                    "phase1-proposal-gate: MultiEdit old_string not found in "
                    "current file content — failing closed",
                    file=sys.stderr,
                )
                sys.exit(2)
            content = content.replace(old_string, new_string, 1) if old_string else content + new_string
        final_content = content
else:
    # Not a write-shaped tool call on a matching path — allow, no-op.
    sys.exit(0)

# --- Checks (a1-a4) -------------------------------------------------------

missing = []
lower = final_content.lower()

# (a1) Scope/boundary statement.
scope_re = re.compile(
    r"(scope|boundary)[^\n]{0,120}(in scope|out of scope)|"
    r"(in scope|out of scope)[^\n]{0,120}(scope|boundary)",
    re.IGNORECASE,
)
if not scope_re.search(final_content):
    missing.append(
        "scope/boundary statement (expected 'scope'/'boundary' language "
        "near 'in scope'/'out of scope')"
    )

# (a2) Regulation enumeration section with at least one exclusion (or
# explicit "no exclusions").
reg_section_re = re.compile(
    r"^#{1,6}[^\n]*(regulation|enumerat)[^\n]*$", re.IGNORECASE | re.MULTILINE
)
reg_match = reg_section_re.search(final_content)
if not reg_match:
    missing.append("regulation-enumeration section (heading mentioning regulations)")
else:
    # Look at the section body: from this heading to the next heading of
    # equal-or-higher level, or end of doc.
    start = reg_match.end()
    next_heading = re.search(r"^#{1,6}\s", final_content[start:], re.MULTILINE)
    section_body = final_content[start: start + next_heading.start()] if next_heading else final_content[start:]
    exclusion_re = re.compile(r"exclu(de|des|ding|sion)|no exclusions", re.IGNORECASE)
    if not exclusion_re.search(section_body):
        missing.append(
            "exclusion statement within the regulation-enumeration section "
            "(or explicit 'no exclusions')"
        )

# (a3) Necessity/proportionality language must appear before first
# "mitigat" occurrence (pure string-offset ordering check).
necessity_re = re.compile(r"necessity|proportionality|proportionate", re.IGNORECASE)
mitigat_re = re.compile(r"mitigat", re.IGNORECASE)

necessity_match = necessity_re.search(final_content)
mitigat_match = mitigat_re.search(final_content)

if not necessity_match:
    missing.append("necessity/proportionality rationale language")
elif mitigat_match and necessity_match.start() > mitigat_match.start():
    missing.append(
        "necessity/proportionality rationale must appear before the first "
        "mention of mitigation (ordering violation)"
    )

# (a4) Evidence/rationale section: per-bullet citation or explicit
# "assumption, unsourced" label.
evidence_section_re = re.compile(
    r"^#{1,6}[^\n]*(evidence|rationale)[^\n]*$", re.IGNORECASE | re.MULTILINE
)
evidence_match = evidence_section_re.search(final_content)
if not evidence_match:
    missing.append("Evidence/rationale section (heading containing 'evidence' or 'rationale')")
else:
    start = evidence_match.end()
    next_heading = re.search(r"^#{1,6}\s", final_content[start:], re.MULTILINE)
    section_body = final_content[start: start + next_heading.start()] if next_heading else final_content[start:]

    bullet_lines = [
        line for line in section_body.splitlines()
        if re.match(r"^\s*[-*]\s+\S", line)
    ]

    if not bullet_lines:
        missing.append("Evidence/rationale section has no bullets to cite")
    else:
        citation_re = re.compile(
            r"Art\.|§|\b[A-Z][A-Za-z .]*(Act|Regulation|Directive|Ordinance)\b[^.\n]{0,40}(art|§|clause|section|\d)"
        )
        assumption_re = re.compile(r"assumption,\s*unsourced", re.IGNORECASE)
        for line in bullet_lines:
            if not (citation_re.search(line) or assumption_re.search(line)):
                missing.append(
                    f"Evidence bullet lacks a citation or 'assumption, unsourced' "
                    f"label: {line.strip()[:80]!r}"
                )

if missing:
    print("phase1-proposal-gate: proposal fails phase-1 norms:", file=sys.stderr)
    for item in missing:
        print(f"  - {item}", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
PY
py_status=$?
set -e

if [[ $py_status -ne 0 ]]; then
  exit 2
fi
exit 0
