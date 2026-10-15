#!/usr/bin/env bash
# test-ask-question-gate.sh — regression battery for scripts/gate-ask-user-question.sh.
# Run after any change to the gate: bash scripts/test-ask-question-gate.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$HERE/gate-ask-user-question.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0

tx() {  # tx <file> <assistant tool_use JSON>...  — writes a transcript
  local f="$1"; shift; : > "$f"
  for tu in "$@"; do
    printf '{"type":"assistant","message":{"content":[%s]}}\n' "$tu" >> "$f"
  done
}
q() { printf '{"questions":[{"question":"%s","header":"Q","options":[{"label":"A","description":"a"},{"label":"B","description":"b"}]}]}' "$1"; }

check() {  # check <expect deny|allow> <name> <transcript> <tool_input>
  local out payload
  payload="$(printf '{"tool_name":"AskUserQuestion","transcript_path":"%s","tool_input":%s}' "$3" "$4")"
  out="$(printf '%s' "$payload" | bash "$GATE")"
  if [[ "$out" == *'"deny"'* ]]; then got=deny; else got=allow; fi
  if [ "$got" = "$1" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL [$1 expected, got $got]: $2"; fi
}

RUN="$TMP/run.jsonl"
tx "$RUN" '{"type":"tool_use","name":"Agent","input":{"subagent_type":"career-engine:cv-writer","prompt":"x"}}'
RUN2="$TMP/run2.jsonl"
tx "$RUN2" '{"type":"tool_use","name":"Write","input":{"file_path":"/o/Acme/_pipeline/cv-draft.md","content":"x"}}'
DEV="$TMP/dev.jsonl"
tx "$DEV" '{"type":"tool_use","name":"Read","input":{"file_path":"/repo/agents/cv-writer.md"}}' \
          '{"type":"tool_use","name":"Edit","input":{"file_path":"/repo/skills/career-engine-orchestrator/orchestrator-queue.md"}}'
DATA="$TMP/data.jsonl"
tx "$DATA" '{"type":"tool_use","name":"Read","input":{"file_path":"/skills/career-data/references/02-professional-background.md"}}' \
           '{"type":"tool_use","name":"WebFetch","input":{"url":"https://example.com/about"}}'
PRIO="$TMP/prio.jsonl"
tx "$PRIO" '{"type":"tool_use","name":"Agent","input":{"subagent_type":"career-engine:role-prioritizer","prompt":"x"}}'
PASTED="$TMP/pasted.jsonl"
printf '{"type":"user","message":{"content":"spawned career-engine:cv-writer, wrote _pipeline/state.json"}}\n' > "$PASTED"

# must deny — real run + scope question
check deny  "run spawn + continue question"        "$RUN"  "$(q 'The queue is long. Should I continue with the remaining roles?')"
check deny  "run write + cost question"            "$RUN2" "$(q 'This run is getting expensive. Process a subset?')"
# must deny — the 2026-10-14 prioritization run's three asks (outcome table defines every write)
check deny  "prio run + paste-the-JDs offer"       "$PRIO" "$(q 'LinkedIn blocked three postings. If you paste the three JDs here, I can score them?')"
check deny  "prio run + your-call hold"            "$PRIO" "$(q 'Viber is closed and IO River is not a job listing. Mark them Duplicate or Position Closed instead of scoring? Your call.')"
check deny  "prio run + held write on label"       "$PRIO" "$(q 'The scorer returned Fifth rather than a number, so I am holding off writing it. Which value should I write?')"
# must allow — the reported false positive and its neighbours
check allow "career-data review: years question"   "$DATA" "$(q 'Years of experience: the skill says 25+, your About page says 15+. Which should the skill use?')"
check allow "career-data review: title question"   "$DATA" "$(q 'Canonical Coro title? The skill currently holds four versions.')"
check allow "dev session scope-worded question"    "$DEV"  "$(q 'Should the fix scope include the Stop hook too?')"
check allow "pasted run output only"               "$PASTED" "$(q 'Should I continue?')"
check allow "real run, genuine blocker question"   "$RUN"  "$(q 'output_folder is missing from pipeline-preferences.json. Where should files go?')"
check allow "real run, blocker worded with proceed"  "$RUN"  "$(q 'output_folder is missing from pipeline-preferences.json. How should I proceed?')"
check allow "real run, error worded with continue"   "$RUN2" "$(q 'The Notion fetch failed with an error. Continue with the rest of the queue?')"
check deny  "prio run + paste-JDs worded as failure"  "$PRIO" "$(q 'LinkedIn fetch failed for 3 roles. Paste the JDs here and I will score them?')"
check deny  "prio run + paste-JDs worded as missing"  "$PRIO" "$(q 'Three JDs are missing. Can you paste the job descriptions?')"
check deny  "prio run + follow-up paste-or-title ask"  "$PRIO" "$(q 'I changed the status to LinkedIn-blocked. To score it, paste the JD text or the role title?')"
check allow "other run, paste-JD worded as failure" "$RUN"  "$(q 'The JD fetch failed for Acme. Paste the job description so the coach can run?')"
check allow "dev session, prioritizer wording"     "$DEV"  "$(q 'Should the outcome table treat a position closed page as Unfetchable? Your call.')"
check allow "career-data review, your-call wording" "$DATA" "$(q 'Two conflicting titles for Coro. Your call: which one does the skill keep?')"
check allow "prio run, genuine blocker"            "$PRIO" "$(q 'database_id is missing from pipeline-preferences.json. Stop here, or run scores-only?')"
check allow "missing transcript"                   "$TMP/none.jsonl" "$(q 'Continue?')"
out="$(printf 'not json' | bash "$GATE")"; [ -z "$out" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: malformed payload not allowed"; }

echo "ask-question gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
