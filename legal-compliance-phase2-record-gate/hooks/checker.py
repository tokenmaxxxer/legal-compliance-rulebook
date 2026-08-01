"""legal-compliance-phase2-record-gate / hooks/checker.py

Reads a PreToolUse JSON payload on stdin, checks it against issue-1
phase-2 record norms (b1-b5) plus the 1:1 mitigation-to-risk/clause
mapping heuristic, and:
  - prints nothing, exits 0 on allow (including non-matching paths/tools)
  - prints "phase2-record-gate: <reason>" to stderr, exits 2 on deny

Invoked by gate.sh as: python3 checker.py, with GATE_LIB_PY and GATE_ROOT
set in the environment. Uses core's gate-lib.py (loaded via importlib) for
JSON parsing, path normalization, and Write/Edit/MultiEdit/NotebookEdit
content reconstruction — see docs/issue-13 gate-house-standard adoption.
"""

import importlib.util
import os
import re
import sys

_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gate_lib)

ROOT = os.environ.get("GATE_ROOT", "")

RECORD_RE = re.compile(r"docs/issue-\d+/reports/legal-compliance\.md$")


def deny(msg):
    sys.stderr.write(f"phase2-record-gate: {msg}\n")
    sys.exit(2)


raw = sys.stdin.read()
event = gate_lib.gate_parse_json_or_deny(raw, deny)

tool_name = event.get("tool_name", "")
tool_input = event.get("tool_input", {}) or {}
if not isinstance(tool_input, dict):
    deny("tool_input missing or not an object")

# --- Bash-tool write coverage: conservative refusal, no content check ---

if tool_name == "Bash":
    command = tool_input.get("command", "")
    if not isinstance(command, str):
        command = ""
    tokens = re.findall(r"[A-Za-z0-9_./~$-]+", command)
    for token in tokens:
        tail = gate_lib.gate_normalize_path(ROOT, token)
        if tail is not None and RECORD_RE.search(tail):
            deny(
                "Bash-tool command appears to write to a path matching the "
                "phase-2 record scope, but this gate cannot verify a "
                "Bash-tool write's resulting content — refusing "
                "conservatively."
            )
    sys.exit(0)

if tool_name not in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
    # Matcher only wires these tools plus Bash above; stay fail-closed-safe
    # rather than guessing about an unrecognized tool.
    sys.exit(0)

file_path = tool_input.get("file_path")
if not file_path:
    sys.exit(0)

tail = gate_lib.gate_normalize_path(ROOT, file_path)
if tail is None:
    sys.exit(0)

if not RECORD_RE.search(tail):
    sys.exit(0)

# --- Compute final content for this write -------------------------------


def read_current_content(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return None
    except OSError:
        return None


if tool_name == "Write":
    final_content = tool_input.get("content", "")
    if not isinstance(final_content, str):
        deny("tool_input.content missing or not a string for Write")
else:
    current = read_current_content(file_path)
    if current is None:
        current = read_current_content(os.path.join(ROOT, tail))
    if current is None:
        current = ""

    new_text, ok = gate_lib.gate_reconstruct_write(tool_name, tool_input, current)
    if not ok:
        deny(
            f"{tool_name} could not be reconstructed against current file "
            f"content of {tail} — failing closed"
        )
    final_content = new_text

# --- Shared heading helpers (mirrors fanout-completeness-gate) ----------

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


lines = final_content.splitlines()
headings = extract_headings(final_content)

missing = []


def find_heading(predicate):
    for (i, lvl, title) in headings:
        if predicate(title):
            return (i, lvl, title)
    return None


# --- (1) Named regulation/standard list, section-scoped ------------------

reg_heading = find_heading(
    lambda t: "regulation" in t.lower() or "standard" in t.lower()
)
regulations_body = ""
if reg_heading is None:
    missing.append("named regulation/standard list (heading mentioning regulation/standard)")
else:
    i, lvl, _t = reg_heading
    regulations_body = section_body(lines, headings, i, lvl)
    if not re.search(r"regulation|standard", regulations_body, re.IGNORECASE):
        missing.append(
            "named regulation/standard list within the regulations section"
        )

# --- (2) Graded (red/amber/green) risk rating, section-scoped -----------

risk_heading = find_heading(lambda t: "risk" in t.lower())
if risk_heading is None:
    missing.append("graded (red/amber/green) risk rating per issue (no risk-rating heading)")
else:
    i, lvl, _t = risk_heading
    risk_body = section_body(lines, headings, i, lvl)
    if not re.search(r"\b(red|amber|green)\b", risk_body, re.IGNORECASE):
        missing.append(
            "graded (red/amber/green) risk rating per issue within the risk section"
        )

# --- (3) Mitigations mapped to risks, section-scoped ---------------------

mitigations_heading = find_heading(lambda t: "mitigat" in t.lower())
mitigations_body = ""
if mitigations_heading is None:
    missing.append("mitigations mapped to risks (no mitigations heading)")
else:
    i, lvl, _t = mitigations_heading
    mitigations_body = section_body(lines, headings, i, lvl)
    if not re.search(r"mitigat", mitigations_body, re.IGNORECASE):
        missing.append("mitigations mapped to risks within the mitigations section")

# --- (4) Final verdict, section-scoped -----------------------------------

verdict_heading = find_heading(lambda t: "verdict" in t.lower())
if verdict_heading is None:
    missing.append("final verdict (pass / pass-with-mitigations / fail) (no verdict heading)")
else:
    i, lvl, _t = verdict_heading
    verdict_body = section_body(lines, headings, i, lvl)
    if not re.search(r"\b(pass-with-mitigations|pass|fail)\b", verdict_body, re.IGNORECASE):
        missing.append(
            "final verdict (pass / pass-with-mitigations / fail) within the verdict section"
        )

# --- (5) 1:1 mitigation-bullet to risk/clause mapping, with adjacency ----
# Mitigation bullets: any bullet inside the mitigations section, plus any
# bullet elsewhere whose text mentions "mitigat" (kept from the prior
# whole-document heuristic so a stray mitigation bullet outside the named
# section is still caught).

bullet_re = re.compile(r"^\s*[-*]\s+(.*)$")

mitigations_section_range = None
if mitigations_heading is not None:
    i, lvl, _t = mitigations_heading
    end = len(lines)
    for (j, l2, _t2) in headings:
        if j > i and l2 <= lvl:
            end = j
            break
    mitigations_section_range = (i + 1, end)

mitigation_bullets = []
for idx, line in enumerate(lines):
    b = bullet_re.match(line)
    if not b:
        continue
    text = b.group(1)
    in_section = (
        mitigations_section_range is not None
        and mitigations_section_range[0] <= idx < mitigations_section_range[1]
    )
    if in_section or re.search(r"mitigat", text, re.IGNORECASE):
        mitigation_bullets.append(text)

# `\brisk\b` and `\bsection\b` dropped from ref_re per the confirmed audit
# bugs: citing the bare word "risk" or "section" is not a reference to any
# specific regulation/clause (issue-13, issue-16).
ref_re = re.compile(
    r"(Art\.|§|\bclause\b|\bregulation\b|\bstandard\b|"
    r"\bissue[-\s#]?\d+\b)",
    re.IGNORECASE,
)

unref_bullets = []
for bullet in mitigation_bullets:
    m = ref_re.search(bullet)
    if not m:
        unref_bullets.append(bullet)
        continue
    # Adjacency: the cited token must actually resolve to text present in
    # the Regulations section body (or no Regulations section exists at
    # all, in which case adjacency cannot be checked and we fall back to
    # the citation-shape check alone).
    token_text = m.group(1)
    if regulations_body and token_text.lower() not in regulations_body.lower():
        unref_bullets.append(bullet)

if unref_bullets:
    missing.append(
        "1:1 mitigation-to-risk/clause mapping: mitigation bullet(s) with no "
        "risk/clause reference that resolves to the Regulations section: "
        + "; ".join(repr(b) for b in unref_bullets)
    )

if missing:
    sys.stderr.write(f"phase2-record-gate: missing required element(s) in {tail}:\n")
    for m in missing:
        sys.stderr.write(f"  - {m}\n")
    sys.exit(2)

sys.exit(0)
