#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit) — legal-compliance-fanout-completeness-gate
#
# Enforces the freelunch / parallel-fan-out sourcing-completeness
# methodology (this rulebook's own scout-brief.md 2-angle-sweep
# precedent): any legal-compliance proposal or record that CLAIMS a
# multi-source/multi-angle survey (a "Sources" heading, or a heading
# using "scout"/"sweep"/"compared against"/"survey") must actually list
# at least two independently-attributed sources or angles. A document
# that makes no such claim is not required to have anything.
#
# Shape (fail-closed trap, kill switch, resolve-then-match) follows the
# pattern scouted from pricing-rulebook's methodology-gate.sh — this
# script is new and role-specific, not a copy of that file's content.
#
# Fires on BOTH write surfaces:
#   docs/issue-<n>/proposals/.*legal-compliance.*\.md
#   docs/issue-<n>/reports/legal-compliance\.md
# Any other resolved path: exit 0 immediately (no-op).
#
# Kill switch: export LEGAL_COMPLIANCE_FANOUT_GATE_OFF=1

set -euo pipefail

__fc() {
  rc=$?
  if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then
    echo "legal-compliance-fanout-completeness-gate: fail-closed — gate aborted unexpectedly (rc=$rc)" >&2
    exit 2
  fi
}
trap __fc EXIT

# Kill switch — any non-empty value disables the gate.
if [ -n "${LEGAL_COMPLIANCE_FANOUT_GATE_OFF:-}" ]; then
  exit 0
fi

deny() {
  echo "legal-compliance-fanout-completeness-gate: refused — $1" >&2
  exit 2
}

command -v python3 >/dev/null 2>&1 || deny "python3 is required but not found on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the fan-out completeness gate."

set +e
GATE_PAYLOAD="$payload" python3 <<'PY'
import json, os, re, sys

def deny(msg):
    sys.stderr.write("legal-compliance-fanout-completeness-gate: refused — %s\n" % msg)
    sys.exit(2)

raw = os.environ.get("GATE_PAYLOAD", "")
try:
    event = json.loads(raw)
except Exception:
    deny("malformed JSON payload on stdin.")

if not isinstance(event, dict):
    deny("malformed JSON payload on stdin (not an object).")

tool_name = event.get("tool_name")
tool_input = event.get("tool_input")
if not isinstance(tool_input, dict):
    deny("tool_input missing or not an object in payload.")

file_path = tool_input.get("file_path")
if not isinstance(file_path, str) or not file_path:
    # No file_path to resolve/match: nothing this gate can check.
    sys.exit(0)

# Resolve to an absolute, real path before matching.
resolved = os.path.realpath(file_path)
resolved_posix = resolved.replace(os.sep, "/")

PROPOSAL_RE = re.compile(r"docs/issue-\d+/proposals/[^/]*legal-compliance[^/]*\.md$")
RECORD_RE = re.compile(r"docs/issue-\d+/reports/legal-compliance\.md$")

if not (PROPOSAL_RE.search(resolved_posix) or RECORD_RE.search(resolved_posix)):
    sys.exit(0)

# --- Compute the final content that would result from this write ---
if tool_name == "Write":
    content = tool_input.get("content")
    if not isinstance(content, str):
        deny("Write tool_input.content missing or not a string.")

elif tool_name in ("Edit", "MultiEdit"):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        content = ""
    except Exception as e:
        deny("could not read existing file %s to apply edit: %s" % (file_path, e))

    if tool_name == "Edit":
        old = tool_input.get("old_string")
        new = tool_input.get("new_string")
        if not isinstance(old, str) or not isinstance(new, str):
            deny("Edit tool_input missing old_string/new_string.")
        if old not in content:
            deny("Edit old_string not found in current content of %s." % file_path)
        content = content.replace(old, new, 1)
    else:
        edits = tool_input.get("edits")
        if not isinstance(edits, list) or not edits:
            deny("MultiEdit tool_input.edits missing or empty.")
        for i, e in enumerate(edits):
            if not isinstance(e, dict):
                deny("MultiEdit edits[%d] is not an object." % i)
            old = e.get("old_string")
            new = e.get("new_string")
            if not isinstance(old, str) or not isinstance(new, str):
                deny("MultiEdit edits[%d] missing old_string/new_string." % i)
            if old not in content:
                deny("MultiEdit edits[%d] old_string not found in current content of %s." % (i, file_path))
            content = content.replace(old, new, 1)
else:
    # Matcher only wires Write|Edit|MultiEdit, but stay fail-closed-safe
    # rather than guessing about an unrecognized tool.
    sys.exit(0)

# --- Methodology check ---

lines = content.splitlines()

HEADING_RE = re.compile(r"^(#{1,6})\s+(.*\S)\s*$")
SWEEP_PHRASES = ("scout", "sweep", "compared against", "survey")

def is_sources_heading(title):
    return "sources" in title.lower()

def is_sweep_claim_heading(title):
    t = title.lower()
    return any(p in t for p in SWEEP_PHRASES)

def is_angle_heading(title):
    t = title.lower()
    return "must-be" in t or "must-bes" in t or "angle" in t

# Locate headings with their line index and level.
headings = []  # (line_idx, level, title)
for i, line in enumerate(lines):
    m = HEADING_RE.match(line)
    if m:
        headings.append((i, len(m.group(1)), m.group(2)))

claims_sweep = any(
    is_sources_heading(title) or is_sweep_claim_heading(title)
    for (_, _, title) in headings
)

if not claims_sweep:
    # No completeness claim made at all: nothing to check.
    sys.exit(0)

# Collect bullet-like lines under any "Sources" or angle-style heading,
# up to (but not including) the next heading of equal-or-shallower level.
BULLET_RE = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+(.*\S)\s*$")

def section_end(idx, level):
    for (j, lvl, _t) in headings:
        if j > idx and lvl <= level:
            return j
    return len(lines)

candidate_bullets = []
for (idx, level, title) in headings:
    if is_sources_heading(title) or is_angle_heading(title):
        end = section_end(idx, level)
        for line in lines[idx + 1:end]:
            bm = BULLET_RE.match(line)
            if bm:
                candidate_bullets.append(bm.group(1).strip())

# Identity of a bullet: prefer an embedded path/URL/backtick token (so two
# differently-labeled bullets citing the same underlying source collapse
# to one identity), else fall back to the normalized full bullet text.
TOKEN_RE = re.compile(
    r"`([^`]+)`"                       # `backtick-quoted` name
    r"|(https?://\S+)"                 # URL
    r"|([\w.\-]+/[\w./\-]+)"           # path-like token
)

def identity(bullet):
    m = TOKEN_RE.search(bullet)
    if m:
        tok = next(g for g in m.groups() if g)
        return tok.strip().rstrip(".,;:)").lower()
    return re.sub(r"\s+", " ", bullet).strip().lower()

distinct = set()
for b in candidate_bullets:
    distinct.add(identity(b))

if len(distinct) < 2:
    deny(
        "document claims a multi-source/multi-angle survey (a \"Sources\" "
        "heading or a scout/sweep/compared-against/survey heading) but "
        "lists fewer than two independently-attributed sources or angles "
        "under a \"Sources\" or \"Must-bes\"/angle-style heading "
        "(found %d distinct)." % len(distinct)
    )

sys.exit(0)
PY
rc=$?
set -e

if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then
  echo "legal-compliance-fanout-completeness-gate: fail-closed — internal check error (rc=$rc)" >&2
  exit 2
fi
exit "$rc"
