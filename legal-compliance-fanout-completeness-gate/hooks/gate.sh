#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${LEGAL_COMPLIANCE_FANOUT_GATE_OFF:-}" || { trap - EXIT; exit 0; }
# PreToolUse gate (Write|Edit|MultiEdit|Bash|NotebookEdit) — legal-compliance-fanout-completeness-gate
#
# Enforces the freelunch / parallel-fan-out sourcing-completeness
# methodology (this rulebook's own scout-brief.md 2-angle-sweep
# precedent): any legal-compliance proposal or record that CLAIMS a
# multi-source/multi-angle survey (a "Sources" heading, or a heading
# using "scout"/"sweep"/"compared against"/"survey") must actually list
# at least two independently-attributed sources or angles. A document
# that makes no such claim is not required to have anything.
#
# Fires on BOTH write surfaces:
#   docs/issue-<n>/proposals/.*legal-compliance.*\.md
#   docs/issue-<n>/reports/legal-compliance\.md
# Any other resolved path: exit 0 immediately (no-op).
#
# Kill switch: export LEGAL_COMPLIANCE_FANOUT_GATE_OFF=1 (or true/yes/on)

deny() {
  echo "legal-compliance-fanout-completeness-gate: refused — $1" >&2
  exit 2
}

command -v python3 >/dev/null 2>&1 || deny "python3 is required but not found on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the fan-out completeness gate."

root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || deny "cannot determine project root (git rev-parse --show-toplevel failed)."

set +e
GATE_PAYLOAD="$payload" GATE_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" python3 <<'PY'
import importlib.util, json, os, re, sys

def deny(msg):
    sys.stderr.write("legal-compliance-fanout-completeness-gate: refused — %s\n" % msg)
    sys.exit(2)

_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gate_lib)

raw = os.environ.get("GATE_PAYLOAD", "")
root = os.environ.get("GATE_ROOT", "")

event = gate_lib.gate_parse_json_or_deny(raw, deny)

if not isinstance(event, dict):
    deny("malformed JSON payload on stdin (not an object).")

tool_name = event.get("tool_name")
tool_input = event.get("tool_input")
if not isinstance(tool_input, dict):
    deny("tool_input missing or not an object in payload.")

PROPOSAL_RE = re.compile(r"docs/issue-\d+/proposals/[^/]*legal-compliance[^/]*\.md$")
RECORD_RE = re.compile(r"docs/issue-\d+/reports/legal-compliance\.md$")

def matches(tail):
    return bool(tail) and bool(PROPOSAL_RE.search(tail) or RECORD_RE.search(tail))

if tool_name == "Bash":
    command = tool_input.get("command", "")
    if not isinstance(command, str):
        command = ""
    tokens = re.findall(r"[A-Za-z0-9_./~$-]+", command)
    for tok in tokens:
        tail = gate_lib.gate_normalize_path(root, tok)
        if matches(tail):
            deny(
                "Bash command appears to write to %s, which matches a "
                "legal-compliance proposal/record path; this gate cannot "
                "verify a Bash write's resulting content, so it refuses "
                "conservatively." % tail
            )
    sys.exit(0)

if tool_name not in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
    # Matcher only wires these tools, but stay fail-closed-safe rather than
    # guessing about an unrecognized tool.
    sys.exit(0)

file_path = tool_input.get("file_path")
if not isinstance(file_path, str) or not file_path:
    # No file_path to resolve/match: nothing this gate can check.
    sys.exit(0)

tail = gate_lib.gate_normalize_path(root, file_path)
if not matches(tail):
    sys.exit(0)

# --- Compute the final content that would result from this write ---
try:
    with open(file_path, "r", encoding="utf-8") as f:
        current_content = f.read()
except FileNotFoundError:
    current_content = ""
except Exception as e:
    deny("could not read existing file %s to apply edit: %s" % (file_path, e))

new_text, ok = gate_lib.gate_reconstruct_write(tool_name, tool_input, current_content)
if not ok:
    deny("could not reconstruct resulting content for %s from this %s call." % (file_path, tool_name))

content = new_text

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
