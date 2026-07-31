import json, os, re, sys


def fail_internal(msg):
    sys.stderr.write(msg + "\n")
    sys.exit(3)


try:
    raw = sys.stdin.read()
    payload = json.loads(raw)
except Exception as e:
    fail_internal(f"could not parse hook payload JSON: {e}")

tool_name = payload.get("tool_name", "")
tool_input = payload.get("tool_input", {})
if not isinstance(tool_input, dict):
    fail_internal("tool_input missing or not an object")

file_path = tool_input.get("file_path")
if not file_path:
    fail_internal("tool_input.file_path missing")

resolved = os.path.realpath(file_path)

# Only fire on docs/issue-<n>/reports/legal-compliance.md
if not re.search(r'docs/issue-[0-9]+/reports/legal-compliance\.md$', resolved.replace(os.sep, "/")):
    sys.exit(0)

# Compute final content per tool type.
if tool_name == "Write":
    content = tool_input.get("content", "")
elif tool_name in ("Edit", "MultiEdit"):
    if os.path.isfile(resolved):
        with open(resolved, "r", encoding="utf-8") as f:
            content = f.read()
    else:
        content = ""

    if tool_name == "Edit":
        edits = [{"old_string": tool_input.get("old_string", ""),
                  "new_string": tool_input.get("new_string", "")}]
    else:
        edits = tool_input.get("edits", [])
        if not isinstance(edits, list):
            fail_internal("tool_input.edits missing or not a list for MultiEdit")

    for e in edits:
        old = e.get("old_string", "")
        new = e.get("new_string", "")
        if old not in content:
            fail_internal(f"old_string not found in current content of {resolved} — failing closed")
        content = content.replace(old, new, 1)
else:
    # Unrecognized tool_name for this matcher: nothing to check, allow.
    sys.exit(0)

missing = []

# --- The four checks carried over from record-fields-gate.sh ---
if not re.search(r'regulation|standard', content, re.IGNORECASE):
    missing.append("named regulation/standard list")

if not re.search(r'\b(red|amber|green)\b', content, re.IGNORECASE):
    missing.append("graded (red/amber/green) risk rating per issue")

if not re.search(r'mitigat', content, re.IGNORECASE):
    missing.append("mitigations mapped to risks")

if not re.search(r'\b(pass-with-mitigations|pass|fail)\b', content, re.IGNORECASE):
    missing.append("final verdict (pass / pass-with-mitigations / fail)")

# --- New heuristic: 1:1 mitigation-bullet to risk/clause reference ---
# Find the Mitigations section (a heading containing "mitigat"), and
# within it, bullet lines starting with '-' or '*'. Also treat any
# bullet line elsewhere containing "mitigat" as a mitigation bullet.
lines = content.splitlines()
mitigation_bullets = []
in_mitigations_section = False
heading_re = re.compile(r'^\s{0,3}#{1,6}\s+(.*)$')
bullet_re = re.compile(r'^\s*[-*]\s+(.*)$')

for line in lines:
    h = heading_re.match(line)
    if h:
        in_mitigations_section = bool(re.search(r'mitigat', h.group(1), re.IGNORECASE))
        continue
    b = bullet_re.match(line)
    if b:
        bullet_text = b.group(1)
        if in_mitigations_section or re.search(r'mitigat', bullet_text, re.IGNORECASE):
            mitigation_bullets.append(bullet_text)

# A bullet line "cites a risk/clause reference" if it contains a named
# regulation/standard token, a clause marker (Art., §, section, clause),
# the word "risk", or a reference to a named issue (e.g. "issue-3",
# "issue #3").
ref_re = re.compile(
    r'(Art\.|§|\bsection\b|\bclause\b|\brisk\b|\bregulation\b|\bstandard\b|'
    r'\bissue[-\s#]?\d+\b)',
    re.IGNORECASE,
)

unref_bullets = [b for b in mitigation_bullets if not ref_re.search(b)]
if unref_bullets:
    missing.append(
        "1:1 mitigation-to-risk/clause mapping: mitigation bullet(s) with no "
        "risk/clause reference: " + "; ".join(repr(b) for b in unref_bullets)
    )

if missing:
    print(f"phase2-record-gate: missing required element(s) in {resolved}:")
    for m in missing:
        print(f"  - {m}")
    sys.exit(1)

sys.exit(0)
