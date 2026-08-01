#!/usr/bin/env bash
# legal-compliance-phase1-proposal-gate / hooks/gate.sh
#
# PreToolUse gate enforcing issue-1 phase-1 proposal norms (a1-a4) on
# legal-compliance proposal docs. See ../README.md for what it checks.
#
# Contract: reads a PreToolUse JSON payload on stdin (Write/Edit/MultiEdit/
# Bash/NotebookEdit), resolves the would-be final file content, and exits
# 0 (allow) or 2 (deny, message on stderr). Fails closed on any unexpected
# error.

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${LEGAL_COMPLIANCE_PHASE1_GATE_OFF:-}" || { trap - EXIT; exit 0; }

payload="$(cat)"

root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$root" ]]; then
  echo "phase1-proposal-gate: could not determine project root — failing closed" >&2
  exit 2
fi

set +e
GATE_LIB_PY="$GATE_LIB_PY" GATE_ROOT="$root" python3 - "$payload" <<'PY'
import importlib.util
import json
import os
import re
import sys

_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gate_lib)

payload_raw = sys.argv[1]
root = os.environ["GATE_ROOT"]


def deny(msg):
    print(f"phase1-proposal-gate: {msg}", file=sys.stderr)
    sys.exit(2)


event = gate_lib.gate_parse_json_or_deny(payload_raw, deny)

tool_name = event.get("tool_name", "")
tool_input = event.get("tool_input", {}) or {}

PATH_RE = re.compile(r"docs/issue-\d+/proposals/.*legal-compliance.*\.md$")

# --- Shared heading helpers (mirrors fanout-completeness-gate) -----------

HEADING_RE = re.compile(r"^(#{1,6})\s+(.*\S)\s*$")


def extract_headings(text):
    return [
        (i, len(m.group(1)), m.group(2))
        for i, line in enumerate(text.splitlines())
        if (m := HEADING_RE.match(line))
    ]


def section_body(lines, headings, idx, level):
    end = len(lines)
    for (j, lvl, _t) in headings:
        if j > idx and lvl <= level:
            end = j
            break
    return "\n".join(lines[idx + 1:end])


# --- Bash-tool write coverage (conservative: deny outright on match) -----

if tool_name == "Bash":
    command = tool_input.get("command", "")
    if not isinstance(command, str):
        command = ""
    tokens = re.findall(r"[A-Za-z0-9_./~$-]+", command)
    for token in tokens:
        tail = gate_lib.gate_normalize_path(root, token)
        if tail is not None and PATH_RE.search(tail):
            deny(
                "Bash-tool command appears to write to a path matching the "
                "phase-1 proposal scope, but this gate cannot verify a "
                "Bash-tool write's resulting content — refusing on "
                "principle (conservative branch)."
            )
    sys.exit(0)

file_path = tool_input.get("file_path")

if not file_path:
    # Nothing to resolve against — no-op allow (not our surface).
    sys.exit(0)

tail = gate_lib.gate_normalize_path(root, file_path)
if tail is None:
    sys.exit(0)

if not PATH_RE.search(tail):
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
elif tool_name in ("Edit", "MultiEdit", "NotebookEdit"):
    current = read_current_content(file_path)
    if current is None:
        current = read_current_content(os.path.join(root, tail))
    if current is None:
        current = ""

    new_text, ok = gate_lib.gate_reconstruct_write(tool_name, tool_input, current)
    if not ok:
        deny(
            f"{tool_name} could not be reconstructed against current file "
            "content — failing closed"
        )
    final_content = new_text
else:
    # Not a write-shaped tool call on a matching path — allow, no-op.
    sys.exit(0)

# --- Checks (a1-a4) -------------------------------------------------------

missing = []
lines = final_content.splitlines()
headings = extract_headings(final_content)

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
reg_heading = None
for (i, lvl, title) in headings:
    if re.search(r"regulation|enumerat", title, re.IGNORECASE):
        reg_heading = (i, lvl, title)
        break

if reg_heading is None:
    missing.append("regulation-enumeration section (heading mentioning regulations)")
else:
    i, lvl, _title = reg_heading
    body = section_body(lines, headings, i, lvl)
    exclusion_re = re.compile(r"exclu(de|des|ding|sion)|no exclusions", re.IGNORECASE)
    if not exclusion_re.search(body):
        missing.append(
            "exclusion statement within the regulation-enumeration section "
            "(or explicit 'no exclusions')"
        )

# (a3) Necessity/proportionality language must appear (in some section
# body) at or before the section body first containing "mitigat".
necessity_re = re.compile(r"necessity|proportionality|proportionate", re.IGNORECASE)
mitigat_re = re.compile(r"mitigat", re.IGNORECASE)

necessity_line = None
mitigat_line = None

for (i, lvl, _title) in headings:
    body = section_body(lines, headings, i, lvl)
    if necessity_line is None:
        m = necessity_re.search(body)
        if m:
            necessity_line = i + 1 + body[:m.start()].count("\n")
    if mitigat_line is None:
        m = mitigat_re.search(body)
        if m:
            mitigat_line = i + 1 + body[:m.start()].count("\n")

if necessity_line is None:
    missing.append("necessity/proportionality rationale language")
elif mitigat_line is not None and necessity_line > mitigat_line:
    missing.append(
        "necessity/proportionality rationale must appear before the first "
        "mention of mitigation (ordering violation)"
    )

# (a4) Evidence/rationale section: per-bullet citation or explicit
# "assumption, unsourced" label.
evidence_heading = None
for (i, lvl, title) in headings:
    if re.search(r"evidence|rationale", title, re.IGNORECASE):
        evidence_heading = (i, lvl, title)
        break

if evidence_heading is None:
    missing.append("Evidence/rationale section (heading containing 'evidence' or 'rationale')")
else:
    i, lvl, _title = evidence_heading
    section = section_body(lines, headings, i, lvl)

    bullet_lines = [
        line for line in section.splitlines()
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
