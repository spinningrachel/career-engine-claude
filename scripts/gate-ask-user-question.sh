#!/usr/bin/env bash
# gate-ask-user-question.sh — PreToolUse hook on AskUserQuestion. Denies the call only for the
# mid-run scope-check anti-pattern (orchestrator-queue.md, Absolute Constraints): a pipeline
# run that is actually executing in this session stops to ask about scope, cost, run length,
# call volume, or whether to continue.
#
# WHY A COMMAND AND NOT A PROMPT HOOK. The first version was a type:"prompt" hook — a model
# judging "is a pipeline run executing?" from the conversation. It produced confirmed false
# positives in non-pipeline sessions: first a dev session with a pasted halt report
# (2026-07-14), then a career-data review session asking the user which of two conflicting
# profile facts was true (2026-09-28). A judgment call made on every question is a guess on
# every question. Both conditions are now checked mechanically:
#
#   (1) RUN EVIDENCE — an assistant tool_use in THIS session's transcript that only a pipeline
#       run makes: a pipeline subagent spawn, or a write into a run-scoped pipeline directory
#       or run ledger. Text in user messages never counts, and neither does reading or
#       editing the plugin's own files.
#   (2) SCOPE-SHAPED QUESTION — the question text asks about scope/cost/volume/continuing
#       (or, for a Prioritization run, asks the user to decide, reclassify, or paste a JD for a
#       role whose write the outcome table already defines), and does NOT surface a genuine blocker (an error, a missing/unreachable config key or
#       file, a failed access), which pipeline doctrine says to surface.
#
# Deny only when both hold. Any internal error allows — this hook must never wedge a session.

set -uo pipefail
PAYLOAD="$(cat 2>/dev/null || true)"
[ -z "$PAYLOAD" ] && exit 0

read -r -d '' PYBODY <<'PY'
import json, re, sys

try:
    d = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)

PIPELINE_AGENTS = re.compile(
    r'^(career-engine:)?(career-coach|cv-writer|letter-writer|gatekeeper|recruiter-reviewer|role-prioritizer)$')
RUN_PATHS = re.compile(r'(/_pipeline/|/_intake_pipeline/|(^|/)state\.json$|(^|/)halted-roles\.json$)')
RUN_BASH = re.compile(r'(/_pipeline/|/_intake_pipeline/|halted-roles\.json)')
SCOPE = re.compile(
    r'\b(scope|queue|remaining roles|rest of the roles|how many roles|which roles|subset|batch size|'
    r'fewer roles|call volume|token|cost|expensive|budget|how long|run length|duration|'
    r'time constraint|long run|continue|proceed|keep going|pause|stop here|stop now)\b', re.I)

# Prioritization-run input asks (2026-10-14): a real run ended with its writes withheld — "need your
# call first", "if you paste the three JDs here, I can score them", "candidates for Duplicate or
# Position Closed instead of scoring". Every one of those has a defined write in
# agents/role-prioritizer.md's Prioritization outcome table. Narrow on purpose; run evidence is still required.
INPUT_ASK = re.compile(
    r'(\bpaste (the |these |those |me |a |your )?(\w+ )?(jds?|job descriptions?)\b|\byour call\b|'
    r'\bneeds? your (call|decision|input|go-ahead|say-so)\b|\bh(e|o)ld(ing)? off( on)?( the)? writ|'
    r'\b(position|role) closed\b|\bnot (a )?job listings?\b|\binstead of scoring\b)', re.I)

BLOCKER = re.compile(
    r'\b(error|errors|failed|failure|missing|not found|unreachable|permission|access denied|'
    r'required key|config key|pipeline-preferences|output_folder|database_id|crash(ed)?)\b', re.I)

# In a session that spawned the prioritizer, a paste-the-JD offer is never legitimate even when the
# question also mentions a failure ("LinkedIn fetch failed for 3 roles. Paste the JDs?") — the
# pipeline's own doctrine makes a failed fetch a JD Fetch Status write, not a request for input.
PASTE_JD = re.compile(r'\bpaste (the |these |those |me |a |your )?(\w+ )?(jds?|job descriptions?)\b', re.I)
PRIORITIZER = re.compile(r'^(career-engine:)?role-prioritizer$')

def run_evidence(path):
    """Returns None (no run evidence), 'prioritizer' (a role-prioritizer spawn seen), or 'run'."""
    found = None
    try:
        f = open(path, encoding='utf-8', errors='replace')
    except Exception:
        return None
    with f:
        for line in f:
            if '"tool_use"' not in line:
                continue
            try:
                e = json.loads(line)
            except Exception:
                continue
            if e.get('type') != 'assistant':
                continue
            content = (e.get('message') or {}).get('content') or []
            if not isinstance(content, list):
                continue
            for c in content:
                if not isinstance(c, dict) or c.get('type') != 'tool_use':
                    continue
                name, inp = c.get('name', ''), c.get('input') or {}
                if name in ('Agent', 'Task') and PIPELINE_AGENTS.match(str(inp.get('subagent_type', ''))):
                    if PRIORITIZER.match(str(inp.get('subagent_type', ''))):
                        return 'prioritizer'
                    found = 'run'
                elif name in ('Write', 'Edit', 'MultiEdit') and RUN_PATHS.search(str(inp.get('file_path', ''))):
                    found = 'run'
                elif name == 'Bash' and RUN_BASH.search(str(inp.get('command', ''))):
                    found = 'run'
    return found

def question_text(tool_input):
    parts = []
    for q in (tool_input or {}).get('questions') or []:
        if not isinstance(q, dict):
            continue
        parts += [str(q.get('question', '')), str(q.get('header', ''))]
        for o in q.get('options') or []:
            if isinstance(o, dict):
                parts += [str(o.get('label', '')), str(o.get('description', ''))]
    return ' '.join(parts)

text = question_text(d.get('tool_input'))
evidence = run_evidence(d.get('transcript_path') or '')
if not evidence:
    sys.exit(0)
prioritizer_paste = evidence == 'prioritizer' and PASTE_JD.search(text)
if not prioritizer_paste:
    if not (SCOPE.search(text) or INPUT_ASK.search(text)) or BLOCKER.search(text):
        sys.exit(0)

print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": (
        "career-engine pipelines run end-to-end per orchestrator-queue.md's Absolute Constraints "
        "- do not ask the user about scope/cost/volume mid-run. Continue processing the queue; "
        "flagged or blocked roles are reported via halted-roles.json and the Final Chat Delivery. "
        "In a Prioritization run, every fetch outcome has a defined write (agents/role-prioritizer.md, "
        "the Prioritization outcome table): convert a tier label to its 1-6 number and write it; a role "
        "with no usable JD text gets JD Fetch Status (LinkedIn-blocked or Unfetchable) only and stays New; "
        "a closed posting or a non-listing URL is a line in the Step 4 report, never a question or a "
        "paste-the-JD offer. Write, then end with the report.")}}))
PY

python3 -c "$PYBODY" "$PAYLOAD" 2>/dev/null || true
exit 0
