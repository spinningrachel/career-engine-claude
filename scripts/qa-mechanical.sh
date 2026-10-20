#!/usr/bin/env bash
# qa-mechanical.sh — mechanized grep/file-existence battery extracted from agents/qa-plugin.md.
# See docs/plans/qa-mechanization-phase-1.md and docs/plans/qa-mechanization-phase-1-notes.md.
#
# Usage: bash scripts/qa-mechanical.sh <target-dir>
# <target-dir> is either the repo root or an unzipped build directory.
set -uo pipefail
TARGET="${1:?usage: qa-mechanical.sh <target-dir>}"
PASS=0; FAIL=0

cnt()  { # count in one file (prints 0 on no match/missing file).
  # Context-diet split (2026-07-22): the two doctrine monoliths became routing files with
  # verbatim sub-files. A check targeting either SKILL.md means "the skill's doctrine",
  # so count across the whole skill directory (SKILL.md + sub-files).
  case "$2" in
    skills/writer-craft/SKILL.md|skills/gatekeeper-checks/SKILL.md)
      grep -h -c "$1" "$TARGET/$(dirname "$2")"/*.md 2>/dev/null | awk '{s+=$1} END {print s+0}';;
    *) grep -c "$1" "$TARGET/$2" 2>/dev/null || true;;
  esac
}
rcnt() { grep -rc "$1" "$TARGET/$2" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}'; }  # recursive total

report() { # id, ok(0/1), detail
  if [ "$2" -eq 1 ]; then echo "CHECK $1: PASS"; PASS=$((PASS+1));
  else echo "CHECK $1: FAIL — $3"; FAIL=$((FAIL+1)); fi
}

expect_ge() { # id, file, pattern, min
  local c; c=$(cnt "$3" "$2")
  c=${c:-0}
  if [ "$c" -ge "$4" ]; then report "$1" 1 ""; else report "$1" 0 "'$3' in $2: found $c, need >= $4"; fi
}

expect_eq0() { # id, file, pattern  (string must be ABSENT)
  local c; c=$(cnt "$3" "$2")
  c=${c:-0}
  if [ "$c" -eq 0 ]; then report "$1" 1 ""; else report "$1" 0 "'$3' in $2: found $c, must be 0"; fi
}

expect_file() { # id, path
  if [ -s "$TARGET/$2" ]; then report "$1" 1 ""; else report "$1" 0 "$2 missing or empty"; fi
}

expect_json() { # id, path
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$TARGET/$2" 2>/dev/null; \
  then report "$1" 1 ""; else report "$1" 0 "$2 is not valid JSON"; fi
}

# ================================================================
# Check 4 — No retired skill-name generations referenced
# ================================================================
c4=$(grep -rn "cv-campaign-intake\|cv-campaign-setup\|cv-campaign-steps\|cv-campaign-edit\|cv-campaign-orchestrator\|cv-campaign-export\|application-intake\|application-edit\|new-application-steps\|applications-orchestrator\|application-files-export" "$TARGET" --include="*.md" 2>/dev/null | grep -v "agents/qa-plugin.md" | grep -v "/docs/" | wc -l | tr -d ' ')
if [ "$c4" -eq 0 ]; then report "4" 1 ""; else report "4" 0 "found $c4 retired skill-name-generation occurrence(s)"; fi

# ================================================================
# Check 4b — No "campaign" branding terminology in runtime prose
# ================================================================
c4b=$(grep -rni "campaign" "$TARGET"/skills "$TARGET"/agents "$TARGET"/README.md "$TARGET"/CLAUDE.md --include="*.md" 2>/dev/null | grep -v "agents/qa-plugin.md" | grep -vi "cv-campaign-YYYY\|cv-campaign-<YYYY\|consumer campaigns\|ActiveCampaign\|drumbeat campaigns" | wc -l | tr -d ' ')
if [ "$c4b" -eq 0 ]; then report "4b" 1 ""; else report "4b" 0 "found $c4b disallowed 'campaign' occurrence(s)"; fi

# ================================================================
# Check 4d — No retired iCloud delivered-letters location
# ================================================================
c4d=$(grep -rn "final-pdfs-delivered" "$TARGET" --include="*.md" 2>/dev/null | grep -v "agents/qa-plugin.md" | grep -v "/docs/" | wc -l | tr -d ' ')
if [ "$c4d" -eq 0 ]; then report "4d" 1 ""; else report "4d" 0 "found $c4d occurrence(s) of retired final-pdfs-delivered"; fi

# ================================================================
# Check 4c — No retired Q&A wiring
# ================================================================
c4c=$(grep -rn "option=interview-questions\|interview-questions\|interview questions\|Q&A property\|Q&A bank\|Q&A answers\|Q&A questions\|Additional Letter Writer Details" "$TARGET"/skills "$TARGET"/agents "$TARGET"/references "$TARGET"/README.md --include="*.md" 2>/dev/null | grep -v "agents/qa-plugin.md" | grep -v "skills/personal-brand/" | wc -l | tr -d ' ')
if [ "$c4c" -eq 0 ]; then report "4c" 1 ""; else report "4c" 0 "found $c4c retired Q&A wiring occurrence(s)"; fi

# ================================================================
# Check 16 — Humanizer Final Gate is explicit in agent procedure
# ================================================================
expect_ge "16" "skills/humanizer/SKILL.md" "Final Gate" 1

# ================================================================
# Check 16b — Sentence-balance rule and preference-intake guards present
# ================================================================
expect_ge "16b" "skills/writer-craft/SKILL.md" "Sentence-length variation" 1
expect_ge "16b" "skills/writer-craft/SKILL.md" "reads monotone" 1
expect_ge "16b" "skills/humanizer/SKILL.md" "reads monotone" 1
expect_ge "16b" "skills/update-refs/SKILL.md" "Documented writing rules and prohibitions are protected" 1
expect_ge "16b" "skills/career-engine-setup/SKILL.md" "never silently modify documented rules" 1

# ================================================================
# Check 17 — Edit type hard gate present in career-engine-edit skill
# ================================================================
expect_ge "17" "skills/career-engine-edit/SKILL.md" "Edit type is mandatory" 1

# ================================================================
# Check 18 — Why I Want This Role voice-preservation rule present (both failure modes)
# ================================================================
expect_ge "18" "skills/writer-craft/SKILL.md" "Failure mode A" 1
expect_ge "18" "skills/writer-craft/SKILL.md" "Failure mode B" 1

# ================================================================
# Check 19 — Indeed connector fallback present in intake skill
# ================================================================
expect_ge "19" "skills/career-engine-intake/SKILL.md" "indeed.com" 1
expect_ge "19" "skills/career-engine-intake/SKILL.md" "search_jobs" 1

# ================================================================
# Check 19b — Universal fallback ladder present in intake skill (R-23)
# ================================================================
expect_ge "19b" "skills/career-engine-intake/SKILL.md" "Universal fallback ladder" 1
expect_ge "19b" "skills/career-engine-intake/SKILL.md" "usable JD content" 1
expect_ge "19b" "skills/career-engine-intake/SKILL.md" "url-fetched-via-search" 1

# ================================================================
# Check 19c — Rendering-capable extraction rung present (R-27)
# third grep must be exactly 1 (more than 1 = invalid option being written again)
# ================================================================
c19c_1=$(cnt "Rendering-capable extraction" "skills/career-engine-intake/SKILL.md"); c19c_1=${c19c_1:-0}
c19c_2=$(cnt "Rendering-capable extraction" "agents/career-coach.md"); c19c_2=${c19c_2:-0}
# 2026-07-23: the "Fetched-alternative is not a valid option" sentence was replaced by the any-working-URL=Fetched rule
c19c_3=$(cnt "a JD obtained from ANY working URL is" "agents/career-coach.md"); c19c_3=${c19c_3:-0}
if [ "$c19c_1" -ge 1 ] && [ "$c19c_2" -ge 1 ] && [ "$c19c_3" -eq 1 ]; then
  report "19c" 1 ""
else
  report "19c" 0 "intake=$c19c_1 (need>=1), career-coach=$c19c_2 (need>=1), any-working-URL-is-Fetched rule in career-coach=$c19c_3 (need exactly 1)"
fi

# ================================================================
# Check 20 — Notion view creation prohibition present (Notion adapter)
# ================================================================
expect_ge "20" "skills/database-notion/SKILL.md" "create-database-view" 1

# ================================================================
# Check 21 — Tiered Notion query ladder present in intake skill (R-1, R-25, R-35)
# ================================================================
expect_ge "21" "skills/database-notion/SKILL.md" "command -v ntn" 1
expect_ge "21" "skills/database-notion/SKILL.md" "API-query-data-source" 1
expect_ge "21" "skills/database-notion/SKILL.md" "Path B" 1
expect_ge "21" "skills/database-notion/SKILL.md" "misaligned rendered table" 1
expect_ge "21" "skills/career-engine-intake/SKILL.md" "database-notion" 1
expect_ge "21" "skills/career-engine-orchestrator/orchestrator-queue.md" "database-notion" 1
expect_ge "21" "skills/career-engine-edit/SKILL.md" "database-notion" 1
expect_ge "21" "skills/career-coach/coach-analysis.md" "database-notion" 1
expect_ge "21" "skills/source-open-roles/SKILL.md" "database-notion" 1
expect_ge "21" "agents/mind-dump.md" "database-notion" 1
expect_ge "21" "agents/content-orchestrator.md" "database-notion" 1
expect_eq0 "21" "skills/career-coach/SKILL.md" "command -v ntn"
expect_eq0 "21" "skills/career-engine-edit/SKILL.md" "command -v ntn"
expect_eq0 "21" "skills/career-engine-orchestrator/SKILL.md" "command -v ntn"

# ================================================================
# Check 21b — Pipeline command authority present in orchestrator (R-24)
# ================================================================
expect_ge "21b" "skills/career-engine-orchestrator/orchestrator-queue.md" "routing authority" 1

# ================================================================
# Check 21c — View-result discovery-only rule present at all three query sites (R-1, R-25)
# ================================================================
expect_ge "21c" "skills/database-notion/SKILL.md" "discovery" 1
expect_ge "21c" "skills/database-notion/SKILL.md" "Do NOT fetch the .collection" 1

# ================================================================
# Check 21d — Schema-fetch error path present in the adapter
# ================================================================
expect_ge "21d" "skills/database-notion/SKILL.md" "stop and report" 1

# NOTE: Check 21k is NOT migrated — see notes file (FAIL condition references
# "first five counts" but only three grep lines exist; a genuine contradiction
# per the guardrail, left fully manual).

# ================================================================
# Check 21k — Canonical Path B shape + no notion-search improvisation (R-39)
# (migrated 2026-07-13 after correcting its stale "first five counts" FAIL
# condition to match its actual three greps — see notes file)
# ================================================================
expect_ge "21k" "skills/database-notion/SKILL.md" "never the bare database URL" 1
expect_ge "21k" "skills/database-notion/SKILL.md" "cannot enumerate the queue" 1
expect_eq0 "21k" "skills/career-engine/SKILL.md" "^  - mcp__5cd94b8e-1498-421b-bc5d-1bbb07682cf7__notion-search"

# ================================================================
# Check 21l — Pointers-not-payloads, and the Mave gate survives (R-41)
# ================================================================
for a in cv-writer letter-writer recruiter-reviewer gatekeeper humanizer; do
  c=$(cnt "Output protocol (R-41)" "agents/$a.md"); c=${c:-0}
  if [ "$c" -ge 1 ]; then report "21l" 1 ""; else report "21l" 0 "Output protocol (R-41) missing in agents/$a.md"; fi
done
for a in recruiter-reviewer gatekeeper humanizer; do
  c=$(cnt "^tools:.*Write" "agents/$a.md"); c=${c:-0}
  if [ "$c" -ge 1 ]; then report "21l" 1 ""; else report "21l" 0 "Write tool grant missing in agents/$a.md"; fi
done
expect_ge "21l" "skills/career-engine-new-application/SKILL.md" "_pipeline" 1
expect_ge "21l" "skills/career-engine-new-application/SKILL.md" 'PIPE/cv-final.md\|PIPE/recruiter-cv.md' 1
c21l_5=$(grep -c 'contents of `\$PIPE' "$TARGET/skills/career-engine-new-application/SKILL.md" 2>/dev/null || true); c21l_5=${c21l_5:-0}
if [ "$c21l_5" -ge 1 ]; then report "21l" 1 ""; else report "21l" 0 "'contents of \`\$PIPE' pattern not found in career-engine-new-application/SKILL.md"; fi
expect_ge "21l" "skills/career-engine-new-application/SKILL.md" "files not found on disk" 1

# ================================================================
# Check 17b — E10 has no duplicate coach-property writeback
# ================================================================
expect_eq0 "17b" "skills/career-engine-edit/SKILL.md" "Write updated coach-owned properties"

# ================================================================
# Check 21e — Gap handling preference read from the plugin file (R-28)
# ================================================================
expect_ge "21e" "skills/career-engine-intake/SKILL.md" "pipeline-preferences.json" 1
expect_ge "21e" "skills/career-coach/SKILL.md" "pipeline-preferences.json" 1
expect_ge "21e" "skills/career-engine-setup/SKILL.md" "pipeline-preferences.json" 1
expect_file "21e" "references/pipeline-preferences.json"

# ================================================================
# Check 21f — Two-path output-access ladder present (R-30)
# ================================================================
expect_ge "21f" "skills/career-engine-orchestrator/orchestrator-queue.md" "Path B — host-bridge MCP" 1
expect_ge "21f" "skills/career-engine-edit/SKILL.md" "Path B — host-bridge MCP" 1
expect_ge "21f" "skills/career-engine-export/SKILL.md" "Environment note (R-30)" 1
expect_eq0 "21f" "skills/career-engine-orchestrator/orchestrator-queue.md" "Do not proceed and do not fall back to any other path"

# ================================================================
# Check 21g — Framework primacy, LinkedIn profile reference, and career-shift posture present
# ================================================================
expect_ge "21g" "skills/career-engine-orchestrator/orchestrator-post-run.md" "Framework primacy" 1
expect_ge "21g" "skills/career-engine-orchestrator/orchestrator-post-run.md" "Step 8-pre" 1
expect_ge "21g" "skills/linkedin-coach/SKILL.md" "Profile source ladder" 1
expect_ge "21g" "skills/career-coach/SKILL.md" "FRAMEWORK PRIMACY" 1
expect_ge "21g" "skills/career-coach/SKILL.md" "Career-shift posture" 1
expect_file "21g" "references/linkedin-profile.md"

# ================================================================
# Check 21h — Voice calibration stack present (fingerprint, humanizer wiring)
# ================================================================
expect_ge "21h" "references/03-framework.md" "Voice fingerprint" 1
expect_ge "21h" "skills/humanizer/SKILL.md" "Voice fingerprint" 1

# ================================================================
# Check 21j — Careers-page verification and remote-geography rules present (R-36)
# ================================================================
expect_ge "21j" "skills/source-open-roles/SKILL.md" "Verification Pass" 1
expect_ge "21j" "skills/source-open-roles/SKILL.md" "NEVER excluded for a geographic restriction" 1
expect_ge "21j" "agents/source-open-roles.md" "Step 4.5" 1
expect_ge "21j" "agents/career-coach.md" "Careers-page cross-check" 1
expect_ge "21j" "skills/career-coach/coach-research.md" "Location & eligibility deep-scan" 1
expect_ge "21j" "skills/career-coach/coach-analysis.md" "Remote-geography weighting" 1
expect_ge "21j" "skills/career-coach/coach-research.md" "ask-first" 1

# ================================================================
# Check 21i — Shakedown fixes present (R-34)
# ================================================================
expect_ge "21i" "skills/writer-craft/SKILL.md" "maximum 320" 1
expect_ge "21i" "skills/gatekeeper-checks/SKILL.md" "maximum 320" 1
c21i_range=$(grep -rn "230–275\|230–290\|230–320" "$TARGET"/skills "$TARGET"/agents "$TARGET"/references --include="*.md" 2>/dev/null | grep -v qa-plugin.md | wc -l | tr -d ' ')
if [ "$c21i_range" -eq 0 ]; then report "21i" 1 ""; else report "21i" 0 "found $c21i_range stale word-range occurrence(s)"; fi
expect_ge "21i" "skills/gatekeeper-checks/SKILL.md" "Calibration authority" 1
expect_ge "21i" "skills/gatekeeper-checks/SKILL.md" "repetition check skipped" 1
expect_ge "21i" "skills/gatekeeper-checks/SKILL.md" "Role named in the first sentence" 1
expect_ge "21i" "skills/writer-craft/SKILL.md" "Proof-point partitioning" 1
expect_ge "21i" "skills/writer-craft/SKILL.md" "always surfaced" 1
c21i_stealth=$(grep -hci "stealth" "$TARGET/skills/gatekeeper-checks/"*.md 2>/dev/null | awk '{s+=$1} END {print s+0}'); c21i_stealth=${c21i_stealth:-0}
if [ "$c21i_stealth" -ge 1 ]; then report "21i" 1 ""; else report "21i" 0 "'stealth' (case-insensitive) not found in gatekeeper-checks/SKILL.md"; fi

# ================================================================
# Check 21m — Single-fetch view discovery (corrected) lives only in the adapter
# ================================================================
expect_ge "21m" "skills/database-notion/SKILL.md" "remove all dashes" 1
expect_ge "21m" "skills/database-notion/SKILL.md" "Do NOT fetch the .collection" 1
c21m_bug1=$(grep -c "to get the .collection" "$TARGET/skills/career-engine-intake/SKILL.md" 2>/dev/null || true); c21m_bug1=${c21m_bug1:-0}
c21m_bug2=$(grep -c "to get the .collection" "$TARGET/skills/career-coach/SKILL.md" 2>/dev/null || true); c21m_bug2=${c21m_bug2:-0}
c21m_bug3=$(grep -c "to get the .collection" "$TARGET/skills/career-engine-edit/SKILL.md" 2>/dev/null || true); c21m_bug3=${c21m_bug3:-0}
c21m_bug4=$(grep -c "to get the .collection" "$TARGET/skills/career-engine-orchestrator/SKILL.md" 2>/dev/null || true); c21m_bug4=${c21m_bug4:-0}
c21m_bug5=$(grep -c "to get the .collection" "$TARGET/skills/source-open-roles/SKILL.md" 2>/dev/null || true); c21m_bug5=${c21m_bug5:-0}
c21m_bug6=$(grep -c "to list views" "$TARGET/skills/career-engine-orchestrator/SKILL.md" 2>/dev/null || true); c21m_bug6=${c21m_bug6:-0}
if [ "$c21m_bug1" -eq 0 ] && [ "$c21m_bug2" -eq 0 ] && [ "$c21m_bug3" -eq 0 ] && [ "$c21m_bug4" -eq 0 ] && [ "$c21m_bug5" -eq 0 ]; then
  report "21m" 1 ""
else
  report "21m" 0 "'to get the .collection' two-step bug reappeared in a consumer (intake=$c21m_bug1 coach=$c21m_bug2 edit=$c21m_bug3 orchestrator=$c21m_bug4 source-open-roles=$c21m_bug5)"
fi
if [ "$c21m_bug6" -eq 0 ]; then report "21m" 1 ""; else report "21m" 0 "'to list views' reappeared in orchestrator/SKILL.md ($c21m_bug6)"; fi

# ================================================================
# Check 21n — Job site preferences present (R-48 feature)
# ================================================================
expect_ge "21n" "references/pipeline-preferences.json" "preferred_job_sites" 1
expect_ge "21n" "references/pipeline-preferences.json" "local_job_sites" 1
expect_ge "21n" "skills/career-engine-setup/SKILL.md" "preferred_job_sites" 1
expect_ge "21n" "skills/career-engine-setup/SKILL.md" "local_job_sites" 1
expect_ge "21n" "skills/source-open-roles/SKILL.md" "preferred_job_sites" 1

# ================================================================
# Check 21o — WIWTR mandatory enumeration present (session feature)
# ================================================================
expect_ge "21o" "agents/letter-writer.md" "WIWTR-" 1
expect_ge "21o" "agents/letter-writer.md" "MANDATORY" 1
expect_ge "21o" "agents/letter-writer.md" "Step 0.5" 1
expect_ge "21o" "agents/gatekeeper.md" "WIWTR-" 1

# ================================================================
# Check 21p — Banned phrase enforcement via Grep tool required (session feature)
# ================================================================
expect_ge "21p" "skills/gatekeeper-checks/SKILL.md" "Grep tool" 1
expect_eq0 "21p" "skills/gatekeeper-checks/SKILL.md" "mental review is sufficient\|by mental review\|mental review only"

# ================================================================
# Check 21q — career-coach is the active coach; career-engine-coach is retired (R-48)
# ================================================================
c21q=$(grep -rn "career-engine-coach" "$TARGET"/skills "$TARGET"/agents --include="*.md" 2>/dev/null | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
if [ "$c21q" -eq 0 ]; then report "21q" 1 ""; else report "21q" 0 "found $c21q retired career-engine-coach reference(s)"; fi
expect_ge "21q" "agents/career-coach.md" "career-coach" 1

# ================================================================
# Check 21r — E0-pre resolves $DRAFT_DIR_URL_BASE and edit pipeline Draft Directory warning present
# ================================================================
expect_ge "21r" "skills/career-engine-edit/SKILL.md" "DRAFT_DIR_URL_BASE" 2
expect_ge "21r" "skills/career-engine-edit/SKILL.md" "Draft Directory not written" 1
expect_ge "21r" "skills/career-engine-new-application/SKILL.md" "Draft Directory not written" 1

# ================================================================
# Check 21s — Coach letter review wired at correct pipeline positions
# NOTE: the "hiring-manager-reviewer" grep against <build>/agents (a directory,
# no -r flag) in the source is buggy/mis-scoped — not migrated, see notes file.
# ================================================================
# 2026-07-22: per the user's instruction ("the coach doesn't need to be in the application pipelines anymore at all"),
# the per-role Option 4 review was replaced by gate conformance; assert the replacement is wired in BOTH pipelines
# and Option 4a remains as the legacy-WIWTR fallback.
expect_ge "21s" "skills/career-engine-new-application/SKILL.md" "Strategic conformance (coach review removed 2026-07-22)" 1
expect_ge "21s" "skills/career-engine-new-application/SKILL.md" "Option 4a — Pre-Draft Outline" 1
expect_ge "21s" "skills/career-engine-new-application/SKILL.md" "COACH LETTER PLAN" 1
expect_ge "21s" "skills/career-engine-edit/SKILL.md" "Strategic conformance (coach review removed 2026-07-22)" 1
expect_ge "21s" "skills/career-engine-edit/SKILL.md" "Option 4a — Pre-Draft Outline" 1
expect_ge "21s" "skills/career-engine-edit/SKILL.md" "COACH LETTER PLAN" 1
# 2026-07-23: markers renamed to LETTER OUTLINE (legacy COACH LETTER PLAN still recognized on old rows)
expect_ge "21s" "skills/career-engine-new-application/SKILL.md" "LETTER OUTLINE" 1
expect_ge "21s" "skills/career-engine-edit/SKILL.md" "LETTER OUTLINE" 1
expect_ge "21s" "agents/career-coach.md" "\[LETTER OUTLINE" 1
# 2026-07-24: the Opener anchor is RETIRED entirely (per the user: "Get rid of the hook. the opener anchor.
# that's what's causing this mess.") — assert the retirement landed and no live anchor slot survives.
expect_ge "21s" "agents/career-coach.md" "There is NO \`Opener anchor:\` line" 1
expect_eq0 "21s" "agents/career-coach.md" "^Opener anchor: <"
expect_ge "21s" "skills/gatekeeper-checks/coach-gates.md" "FAIL if the block contains an \`Opener anchor:\` line" 1
expect_ge "21s" "skills/gatekeeper-checks/letter-gates.md" "Opener-anchor conformance — RETIRED" 1
expect_ge "21s" "agents/letter-writer.md" "IGNORED entirely" 1
expect_ge "21s" "skills/career-engine-new-application/SKILL.md" "line .*is DROPPED\|is DROPPED" 1
expect_ge "21s" "skills/career-engine-edit/SKILL.md" "is DROPPED" 1
expect_ge "21s" "agents/career-coach.md" "bare token only" 1
# 2026-07-24 (second pass): the user's plain-language letter rule is codified verbatim in letter-core §1
expect_ge "21s" "skills/letter-core/SKILL.md" "exhaustive search of all available insights" 1
expect_ge "21s" "skills/gatekeeper-checks/letter-gates.md" "Opener source check" 1
# 2026-07-24 (third pass): Role emphasis reduced to two lines (Emphasis + Likely KPIs), <=100 words, per the user;
# capability-mapping and de-emphasis retired; hyper-focus standing rule added.
expect_ge "21s" "skills/career-coach/coach-analysis.md" "exactly these TWO labeled parts" 1
expect_ge "21s" "skills/career-coach/coach-analysis.md" "max 100 words\|≤100 words" 1
expect_eq0 "21s" "skills/career-coach/coach-analysis.md" "^\*\*Capability match:\*\*\|^\*\*De-emphasized:\*\*"
expect_ge "21s" "skills/gatekeeper-checks/coach-gates.md" "fixed two-part bulleted structure" 1
expect_ge "21s" "skills/career-coach/SKILL.md" "Hyper Focus — Governs Every Output" 1
expect_ge "21s" "agents/career-coach.md" "Hyper focus" 1
# 2026-07-24 (fourth pass): no Para 1 line in the Letter Outline — the Opener line IS paragraph 1's spec
expect_ge "21s" "agents/career-coach.md" "There is NO \`Para 1:\` line" 1
expect_ge "21s" "skills/gatekeeper-checks/coach-gates.md" "FAIL if the block contains a \`Para 1:\` line" 1
expect_ge "21s" "skills/letter-core/SKILL.md" "bounded by the template's own Block 1" 1
# 2026-07-24 (fifth pass): Opener verbatim hard gate — letter text diffed against the outline's Opener line
expect_ge "21s" "skills/gatekeeper-checks/letter-gates.md" "checks the LETTER TEXT, not just the log" 1
expect_ge "21s" "agents/letter-writer.md" "Paste it as your opening VERBATIM" 1
expect_ge "21s" "skills/letter-core/SKILL.md" "paste it verbatim as the opening" 1
expect_ge "21s" "skills/career-engine-new-application/SKILL.md" "Opener verbatim check" 1
expect_ge "21s" "skills/career-engine-edit/SKILL.md" "Opener verbatim check" 1
# 2026-10-20: Role emphasis bullets + JTBD alignment; Detailed CV length ceilings; senior-role success-measure paragraph
expect_ge "21s" "skills/career-coach/coach-analysis.md" "Emphasis = the role's jobs to be done, ranked" 1
expect_ge "21s" "skills/career-coach/coach-output.md" "3–4 bullets, most important first" 1
expect_ge "21s" "skills/gatekeeper-checks/cv-gates.md" "CV-TOTAL-WORDCOUNT" 1
expect_ge "21s" "skills/gatekeeper-checks/cv-gates.md" "890" 1
expect_ge "21s" "skills/writer-craft/cv.md" "Whole CV ≤ 890 words" 1
expect_ge "21s" "skills/letter-core/SKILL.md" "Senior roles — one paragraph on what success looks like" 1
expect_ge "21s" "skills/gatekeeper-checks/letter-gates.md" "Success measure (senior roles only" 1
expect_ge "21s" "skills/gatekeeper-checks/coach-gates.md" "senior role with no success-measure line" 1
# 2026-07-24: the coach's Opener line is a verbatim bank-variant copy/paste (per the user's direct instruction)
expect_ge "21s" "agents/career-coach.md" "COPY/PASTE selection, never composition" 1
expect_ge "21s" "skills/gatekeeper-checks/coach-gates.md" "not a verbatim bank copy" 1
expect_ge "21s" "agents/letter-writer.md" "that IS your Block 1 variant selection" 1
expect_ge "21s" "skills/letter-core/SKILL.md" "the coach picked it, the user reviewed it in Notion\|picked by the coach and user-reviewed in Notion" 1
expect_ge "21s" "skills/career-engine-new-application/SKILL.md" "\`Opener:\` line when present" 1
expect_ge "21s" "skills/career-engine-edit/SKILL.md" "\`Opener:\` line when present" 1
expect_eq0 "21s" "skills/career-engine-new-application/SKILL.md" "recruiter-reviewer.*cover-letter\|option=cover-letter.*recruiter"
expect_eq0 "21s" "skills/career-engine-edit/SKILL.md" "recruiter-reviewer.*cover-letter\|option=cover-letter.*recruiter"
expect_ge "21s" "agents/career-coach.md" "Option 4" 1
expect_ge "21s" "agents/career-coach.md" "Write" 1
expect_eq0 "21s" "skills/career-engine-new-application/SKILL.md" "hiring-manager-reviewer"
expect_eq0 "21s" "skills/career-engine-edit/SKILL.md" "hiring-manager-reviewer"
# 2026-07-13 corrected re-inclusion of the source's 9th assertion (its grep
# targeted the agents/ directory without -r — errored under GNU grep):
c21s=$(grep -rn "hiring-manager-reviewer" "$TARGET/agents" 2>/dev/null | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
if [ "$c21s" -eq 0 ]; then report "21s" 1 ""; else report "21s" 0 "hiring-manager-reviewer referenced in agents/ ($c21s hit(s)) — retired reviewer must not appear"; fi

# ================================================================
# Check 21t — Stop hook mechanically enforces the mid-run scope-check anti-pattern
# (PARTIALLY MECHANIZED — the read-and-confirm portion of this check stays manual)
# ================================================================
expect_json "21t" "hooks/hooks.json"
expect_ge "21t" "hooks/hooks.json" '"type": "command"' 1
expect_ge "21t" "hooks/hooks.json" "log-token-usage.sh" 1
expect_ge "21t" "hooks/hooks.json" '"type": "prompt"' 1
expect_ge "21t" "hooks/hooks.json" "last_assistant_message" 1
expect_ge "21t" "hooks/hooks.json" 'ok\\": false' 1
expect_ge "21t" "hooks/hooks.json" '"PreToolUse"' 1
expect_ge "21t" "hooks/hooks.json" 'AskUserQuestion' 1
expect_ge "21t" "hooks/hooks.json" 'gate-ask-user-question.sh' 1
# 2026-10-15: the manifest must NOT name hooks/hooks.json — Claude Code loads that file on its own,
# and a manifest "hooks" entry pointing at it fails the whole plugin load ("Duplicate hooks file").
expect_eq0 "21t" ".claude-plugin/plugin.json" '"hooks"'
expect_ge "21t" "scripts/gate-ask-user-question.sh" '"permissionDecision": "deny"' 1

# ================================================================
# Check 21u — CV footer injection is optional via cv_footer.inject (2026-07-12 addition)
# ================================================================
expect_ge "21u" "references/pipeline-preferences.json" '"cv_footer"' 1
expect_ge "21u" "references/pipeline-preferences.json" '"inject": true' 1
expect_ge "21u" "skills/career-engine-export/scripts/convert-cv.sh" 'if \[ -n "\${CV_FOOTER}" \]' 1
expect_eq0 "21u" "skills/career-engine-export/scripts/convert-cv.sh" '\[ -z "\${CV_FOOTER}" \] || \[ ! -f "\${CV_FOOTER}" \]'
expect_eq0 "21u" "skills/career-engine-export/scripts/assemble_brief_cv.py" '"--cv-footer", required=True'
expect_ge "21u" "skills/career-engine-export/scripts/assemble_brief_cv.py" 'if data.get("languages")' 1
expect_ge "21u" "skills/career-engine-export/scripts/assemble_brief_cv.py" 'if data.get("education")' 1
expect_ge "21u" "skills/career-engine-orchestrator/orchestrator-queue.md" "cv_footer.inject" 1
expect_ge "21u" "skills/career-engine-edit/SKILL.md" "cv_footer.inject" 1
expect_ge "21u" "skills/career-engine-export/SKILL.md" "cv_footer.inject" 1
c21u_ask=$(grep -ci "ask before assuming" "$TARGET/skills/career-engine-setup/SKILL.md" 2>/dev/null || true); c21u_ask=${c21u_ask:-0}
if [ "$c21u_ask" -ge 1 ]; then report "21u" 1 ""; else report "21u" 0 "'ask before assuming' (case-insensitive) not found in career-engine-setup/SKILL.md"; fi
expect_ge "21u" "skills/career-engine-new-application/SKILL.md" 'if \[ -n "\$CV_FOOTER_HE" \]' 1
expect_ge "21u" "skills/career-engine-edit/SKILL.md" 'if \[ -n "\$CV_FOOTER_HE" \]' 1

# ================================================================
# Check 21v — "Condensed process" anti-pattern closed; humanizer non-skippable;
# CAREER_DATA/$PIPE capability checks present (2026-07-12/13 addition)
# ================================================================
expect_ge "21v" "skills/career-engine-orchestrator/orchestrator-queue.md" "condensed process" 1
expect_ge "21v" "skills/career-engine-orchestrator/orchestrator-queue.md" "Mid-spawn CAREER_DATA loss" 1
expect_ge "21v" "skills/career-engine-orchestrator/orchestrator-queue.md" "This fallback never applies to \`cv-writer\` or \`letter-writer\`" 1
expect_ge "21v" "skills/career-engine-new-application/SKILL.md" "custom-style-wrapped text is never eligible" 1
expect_eq0 "21v" "skills/career-engine-edit/SKILL.md" "mechanical and unambiguous"
expect_ge "21v" "skills/career-engine-orchestrator/orchestrator-queue.md" "non-skippable-humanizer rule" 1
# 2026-07-26: humanizer RETIRED from both pipelines per the user; the non-skippable rule survives only as history in orchestrator-queue
expect_ge "21v" "skills/career-engine-new-application/SKILL.md" "Humanizer — RETIRED" 1
expect_ge "21v" "skills/career-engine-edit/SKILL.md" "Humanizer — RETIRED" 1
expect_ge "21v" "skills/career-engine-new-application/SKILL.md" "PIPE_FILESYSTEM_AVAILABLE" 1
# 2026-07-27: capability-claim refusal anti-pattern (the "built for Claude Code" Cowork refusal)
expect_ge "21v" "skills/career-engine-orchestrator/orchestrator-queue.md" "refusing to run on an unverified capability claim" 1
expect_ge "21v" "skills/career-engine-orchestrator/orchestrator-queue.md" "Cowork is a first-class runtime" 1
# 2026-07-28: Unmatched-keyword segment (the Jazz DLP thrash fix)
expect_ge "21v" "skills/career-coach/coach-analysis.md" "Career-data match check" 1
expect_ge "21v" "skills/gatekeeper-checks/cv-gates.md" "Unmatched:\` keywords are OUT OF SCOPE" 1
expect_ge "21v" "skills/gatekeeper-checks/coach-gates.md" "Unmatched:" 1
# 2026-07-28 (second pass): Keyword gap line in Gap handling, both modes, per the user
expect_ge "21v" "skills/career-coach/coach-analysis.md" "Keyword gap:" 1
expect_ge "21v" "skills/career-coach/coach-output.md" "Keyword gap:" 1
expect_ge "21v" "skills/gatekeeper-checks/coach-gates.md" "Keyword gap:" 1
expect_ge "21v" "skills/career-engine-intake/SKILL.md" "Keyword gap:" 1
expect_ge "21v" "skills/career-engine-edit/SKILL.md" "PIPE_FILESYSTEM_AVAILABLE" 1
expect_ge "21v" "skills/career-engine-new-application/SKILL.md" "PIPE-CANARY" 1
expect_ge "21v" "skills/career-engine-orchestrator/orchestrator-queue.md" "Manual-relay rule" 1
expect_ge "21v" "skills/career-engine-edit/SKILL.md" "Role 1's baseline spawn" 1
expect_ge "21v" "skills/career-engine-new-application/SKILL.md" "run on Path A directly in the orchestrator's own context" 1

# ================================================================
# Check 22 — Single-build model documented in CLAUDE.md
# ================================================================
expect_ge "22" "CLAUDE.md" "Single-build architecture" 1
expect_ge "22" "CLAUDE.md" "Placeholder resolution" 1
expect_ge "22" "CLAUDE.md" "career-data" 1
c22_stop=$(grep -ci "MANDATORY STOP" "$TARGET/CLAUDE.md" 2>/dev/null || true); c22_stop=${c22_stop:-0}
if [ "$c22_stop" -ge 1 ]; then report "22" 1 ""; else report "22" 0 "'MANDATORY STOP' (case-insensitive) not found in CLAUDE.md"; fi

# ================================================================
# Check 22c — Letter pipeline behavioral patterns present (three sub-checks)
# ================================================================
c22c_sb1=$(cnt "strategic builder" "skills/gatekeeper-checks/SKILL.md"); c22c_sb1=${c22c_sb1:-0}
c22c_sb2=$(cnt "strategic builder" "skills/writer-craft/SKILL.md"); c22c_sb2=${c22c_sb2:-0}
if [ "$c22c_sb1" -ge 1 ] || [ "$c22c_sb2" -ge 1 ]; then report "22c-strategic-builder" 1 ""; else report "22c-strategic-builder" 0 "'strategic builder' absent from both gatekeeper-checks/SKILL.md and writer-craft/SKILL.md"; fi

c22c_ed_wc=$(grep -hci "em dash" "$TARGET/skills/writer-craft/"*.md 2>/dev/null | awk '{s+=$1} END {print s+0}'); c22c_ed_wc=${c22c_ed_wc:-0}
if [ "$c22c_ed_wc" -ge 1 ]; then report "22c-em-dash" 1 ""; else report "22c-em-dash" 0 "'em dash'/'em dashes' (case-insensitive) absent from writer-craft/SKILL.md"; fi
# agents/letter-writer.md count is advisory only per the source check — not asserted here.

c22c_colon_lw=$(grep -ci "colon" "$TARGET/agents/letter-writer.md" 2>/dev/null || true); c22c_colon_lw=${c22c_colon_lw:-0}
c22c_colon_wc=$(grep -hci "colon" "$TARGET/skills/writer-craft/"*.md 2>/dev/null | awk '{s+=$1} END {print s+0}'); c22c_colon_wc=${c22c_colon_wc:-0}
if [ "$c22c_colon_lw" -ge 1 ] || [ "$c22c_colon_wc" -ge 1 ]; then report "22c-colon-ban" 1 ""; else report "22c-colon-ban" 0 "'colon' (case-insensitive) absent from both letter-writer.md and writer-craft/SKILL.md"; fi

# ================================================================
# Check 22b — career-data / single-build wiring present (R-37)
# ================================================================
expect_ge "22b" "skills/career-engine-orchestrator/orchestrator-queue.md" "career-data discovery" 1
expect_ge "22b" "skills/career-engine-orchestrator/orchestrator-queue.md" "Writing personal data" 1
# 2026-07-13 correction of the source's ">= 20" file-count: the 20th file was
# always agents/qa-plugin.md matching its own grep-pattern text (self-count,
# removed by mechanization). Now asserted with a self-exclusion at the true
# doctrine coverage of 19 files. See notes file + Check 22b prose.
c22b=$(grep -rl "data root (R-37)" "$TARGET/agents" "$TARGET/skills" 2>/dev/null | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
if [ "$c22b" -ge 19 ]; then report "22b" 1 ""; else report "22b" 0 "'data root (R-37)' file count: found $c22b, need >= 19 (excluding qa-plugin.md)"; fi
expect_ge "22b" "CLAUDE.md" "Placeholder resolution" 1

# ================================================================
# Check 31 — Coach mandatory-field list parity: Location and First Advertised
# ================================================================
expect_ge "31" "skills/career-engine-intake/SKILL.md" "First Advertised" 2
expect_ge "31" "skills/career-coach/coach-output.md" "\*\*Location:\*\*" 1
expect_ge "31" "skills/gatekeeper-checks/SKILL.md" "Mandatory-field presence" 1
expect_ge "31" "agents/gatekeeper.md" "Missing mandatory fields" 1

# ================================================================
# Check 32 — Notion fast-path STOP gates present
# ================================================================
expect_ge "32" "skills/database-notion/SKILL.md" "STOP — check this before running the fetch" 1
expect_ge "32" "skills/database-notion/SKILL.md" "STOP — is a fast-path URL already non-empty" 1
expect_ge "32" "skills/database-notion/SKILL.md" "do NOT \`Read\` or otherwise re-ingest that file in full" 1
expect_ge "32" "skills/database-notion/SKILL.md" 'page_id.*command.*update_properties\|"command": "update_properties"' 1

# ================================================================
# Check 33 — Orchestrator queue-building has a run-scoped $QUEUE_PIPE
# ================================================================
expect_ge "33" "skills/career-engine-orchestrator/orchestrator-queue.md" "_queue_pipeline" 1
expect_ge "33" "skills/career-engine-orchestrator/orchestrator-queue.md" "role-properties.md" 2

# ================================================================
# Check 33b — Orchestrator delegates the per-page property fetch to a subagent
# ================================================================
expect_ge "33b" "skills/career-engine-orchestrator/orchestrator-queue.md" "Spawn a lightweight subagent" 1
expect_ge "33b" "skills/career-engine-orchestrator/orchestrator-queue.md" 'does not write `\$QUEUE_PIPE` itself' 1
expect_ge "33b" "skills/career-engine-orchestrator/orchestrator-queue.md" "premature context exhaustion in real production runs" 1
expect_ge "33b" "skills/career-engine-orchestrator/orchestrator-queue.md" "general-purpose extraction/fetch subagents" 1
expect_ge "33b" "skills/career-engine-orchestrator/orchestrator-queue.md" "FAILED" 1
expect_ge "33b" "skills/career-engine-orchestrator/orchestrator-queue.md" "cannot access .notion-fetch." 1

# ================================================================
# Check 34 — Coach-output re-read discipline and hand-edit self-check strengthened
# ================================================================
expect_ge "34" "skills/career-engine-intake/SKILL.md" "exactly once for the entire Step 0.8" 1
expect_ge "34" "skills/career-engine-intake/SKILL.md" "self-check: am I about to open an \`Edit\`" 1

# ================================================================
# Check 34b — Intake Step 0.5 rung-1 batching risk flagged
# ================================================================
expect_ge "34b" "skills/career-engine-intake/SKILL.md" "held up in practice better than the equivalent instruction" 1

# ================================================================
# Check 35 — Prioritization pipeline wired end-to-end
# ================================================================
expect_file "35" "agents/role-prioritizer.md"
expect_file "35" "skills/role-prioritizer/SKILL.md"
expect_ge "35" "agents/role-prioritizer.md" "^model: haiku" 1
expect_eq0 "35" "agents/role-prioritizer.md" "^model: opus\|effort:"
expect_ge "35" "skills/career-engine/SKILL.md" "role-prioritizer" 1
expect_ge "35" "skills/database/SKILL.md" "| \`New\` |" 1
expect_ge "35" "skills/database/SKILL.md" "| \`Needs Research\` |" 1

# ================================================================
# Check 35b — Prioritization → intake always-overwrite fix present
# ================================================================
c35b=$(grep -ci "\*\*always overwrite" "$TARGET/skills/career-engine-intake/SKILL.md" 2>/dev/null || true); c35b=${c35b:-0}
# 2026-07-23: threshold 14->13 — the location-compatibility always-overwrite bullet was retired with the property
# 2026-07-29: threshold 13->12 — First Advertised moved from always-overwrite to the earliest-wins merge, per the user
if [ "$c35b" -ge 12 ]; then report "35b" 1 ""; else report "35b" 0 "'**always overwrite' (case-insensitive) count is $c35b, need >= 12"; fi
expect_ge "35b" "skills/career-engine-intake/SKILL.md" "earliest-wins" 2
expect_ge "35b" "CLAUDE.md" "Prioritization" 1

# ================================================================
# Check 55-writeback — Intake writeback default flipped to always-overwrite
# (PARTIALLY MECHANIZED — the "write if empty" line's FAIL condition requires
# tracing every match to the JD Body bullet, which is a judgment call; not
# transcribed as a strict ==0 assertion. See notes file.)
# ================================================================
expect_ge "55-writeback" "skills/career-engine-intake/SKILL.md" "Rule: always overwrite" 1
expect_ge "55-writeback" "skills/career-engine-intake/SKILL.md" "Exceptions — these three remain write-only-to-empty" 1
# 2026-07-28: bullet reworded — write-only-to-empty now scoped to gap-handling content (Keyword gap line is replace-own-line)
expect_ge "55-writeback" "skills/career-engine-intake/SKILL.md" "Gap handling\` — \*\*write-only-to-empty exception for gap-handling content\*\*" 1
expect_ge "55-writeback" "skills/career-engine-intake/SKILL.md" "so \"is it empty?\" is the wrong test" 1
expect_eq0 "55-writeback" "skills/career-coach/coach-output.md" "do not overwrite\. The user decides"
expect_ge "55-writeback" "skills/career-coach/coach-output.md" "always overwrite; call out big swings" 1

# ================================================================
# Check 56 — Coach context block terseness
# ================================================================
# 2026-07-23: the coach context block was RETIRED per the user's direct instruction; Check 56 now
# asserts the retirement landed everywhere the feature used to live, replacing the old terseness greps.
expect_ge "56" "skills/career-coach/coach-output.md" "RETIRED as a coach-context surface" 1
expect_eq0 "56" "skills/career-coach/coach-output.md" "Hard cap: 8 words per point\|Culture as a screen point\|Screen 2:"
expect_ge "56" "skills/gatekeeper-checks/coach-gates.md" "Search-narrative leakage" 1
expect_ge "56" "agents/gatekeeper.md" "search-narrative leakage check" 1
expect_eq0 "56" "skills/career-engine-intake/SKILL.md" "Write A — coach context block\|Write B — coaching prompts"
expect_ge "56" "skills/career-coach/coach-output.md" "wiwtr_questions\` — RETIRED" 1

# ================================================================
# Check 57 — Strategy=Strategic 250-word cover-letter cap wired everywhere
# ================================================================
expect_ge "57" "skills/writer-craft/SKILL.md" "Strategy = Strategic\`, where the maximum is 250 words" 1
expect_ge "57" "agents/letter-writer.md" "≤250 when \`Strategy = Strategic\`\|250 when \`Strategy = Strategic\`" 1
expect_ge "57" "skills/gatekeeper-checks/SKILL.md" "Strategy = Strategic" 3
c57_multi1=$(grep -c "Strategy\` (the coach's Step 0.8 output\|Strategy\` (from the Step E0 row payload\|Strategy\` (from the coach properties verified in Step E1\|Strategy\` (same as Step" "$TARGET/skills/career-engine-new-application/SKILL.md" "$TARGET/skills/career-engine-edit/SKILL.md" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
if [ "$c57_multi1" -ge 4 ]; then report "57" 1 ""; else report "57" 0 "Strategy-param spawn-site phrasing combined count is $c57_multi1, need >= 4 (two final-gatekeeper spawns retired with the humanizer, 2026-07-26)"; fi
expect_ge "57" "skills/career-engine-new-application/SKILL.md" "Strategy = Strategic" 1
expect_ge "57" "skills/career-engine-edit/SKILL.md" "Strategy = Strategic" 1
expect_ge "57" "references/cover-letter-templates-default.md" "Strategy = Strategic" 4
expect_ge "57" "references/cover-letter-templates-default.md" "I wrote the day I saw the" 1
# 2026-07-26: humanizer retired — the input-boundary phrasing left the pipelines with its spawns; assert the retirement instead
c57_multi2=$(grep -c "Humanizer — RETIRED" "$TARGET/skills/career-engine-new-application/SKILL.md" "$TARGET/skills/career-engine-edit/SKILL.md" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
if [ "$c57_multi2" -ge 2 ]; then report "57" 1 ""; else report "57" 0 "humanizer-retirement marker combined count is $c57_multi2, need >= 2"; fi
expect_ge "57" "skills/career-engine-new-application/SKILL.md" "same parameters as the Step 5.2 spawn above" 1
expect_ge "57" "skills/career-engine-edit/SKILL.md" "same parameters as the Step E7.3 spawn above\|same parameters as the Step E7.7 spawn above" 2

# ================================================================
# Check 58 — Cover-letter opener pattern #10 re-anchored to §8 sourcing mandate
# ================================================================
expect_ge "58" "skills/writer-craft/SKILL.md" "must itself be sourced from her documented WIWTR/Motivation Bank content" 1
expect_ge "58" "skills/writer-craft/SKILL.md" "this pattern is not available for this letter" 1

# ================================================================
# Check 59 — CV skills-section content contract wired end-to-end
# ================================================================
expect_ge "59" "skills/writer-craft/SKILL.md" "three-way test" 1
expect_ge "59" "skills/writer-craft/SKILL.md" "Cap: 3 skill groups maximum" 1
expect_ge "59" "skills/gatekeeper-checks/SKILL.md" "Gate 5 — Skills Section Content" 1
expect_ge "59" "skills/gatekeeper-checks/SKILL.md" "Gates 1-6 in order" 1
expect_eq0 "59" "CLAUDE.md" "Gate 0-4 for CV Check"
expect_ge "59" "references/background/background-cross-cutting-skills.md" "three-way test" 1
expect_ge "59" "CLAUDE.md" "CV skills-section content contract" 1

# ================================================================
# Check 60 — Mid-run scope-check anti-pattern block present
# ================================================================
# 2026-07-13: pattern updated when the block gained its canonical name prefix
# ("Named anti-pattern — the mid-run scope-check anti-pattern, ...: pausing ...")
expect_ge "60" "skills/career-engine-orchestrator/orchestrator-queue.md" "pausing mid-run over perceived call-volume" 1
expect_ge "60" "skills/career-engine-orchestrator/orchestrator-queue.md" "the mid-run scope-check anti-pattern, the canonical name" 1
expect_ge "60" "CLAUDE.md" "Mid-run scope-check anti-pattern" 1
expect_ge "60" "README.md" 'Mid-run "how do you want me to proceed" pause killed a real production run' 1

# ================================================================
# Check 61 — JD proof added to both agent-facing mandatory enumerations
# ================================================================
expect_ge "61" "skills/career-coach/coach-output.md" "JD proof\`\*\* (a fresh verbatim quote every run" 1
expect_ge "61" "agents/career-coach.md" "Priority Reason\`, and \*\*\`JD proof\`\*\* are \*\*mandatory to return\*\*" 1

# ================================================================
# Check 62 — Publications as cover-letter proof + conditional PUBLICATIONS CV section
# ================================================================
expect_ge "62" "skills/writer-craft/SKILL.md" "Published/bylined writing and original-POV talks are unusually strong letter proof" 1
expect_ge "62" "skills/writer-craft/SKILL.md" "PUBLICATIONS\`.*optional, rarely used" 1
c62_bp=$(grep -ci "if you write or speak publicly" "$TARGET/references/background/background-portfolio.md" 2>/dev/null || true); c62_bp=${c62_bp:-0}
if [ "$c62_bp" -ge 1 ]; then report "62" 1 ""; else report "62" 0 "'if you write or speak publicly' (case-insensitive) not found in background-portfolio.md"; fi
expect_ge "62" "agents/cv-writer.md" "PUBLICATIONS\` is optional and rarely used" 1
expect_ge "62" "agents/cv-writer.md" "PUBLICATIONS\` section:" 1

# ================================================================
# Check 63 (counts moved 34->35 on 2026-07-28: Gate 10 quantitative voice metrics became Tier 2 item 35)
# Check 63 — Gate 5 pattern-derivation forcing function, Tier 2, bumps checklist to 33 (34 since 2026-07-16 discourse-flow addition)
# ================================================================
expect_ge "63" "skills/writer-craft/SKILL.md" "Pattern-derivation forcing function" 1
expect_ge "63" "skills/writer-craft/SKILL.md" "would this sentence's structure work as a direct answer to" 1
expect_ge "63" "skills/gatekeeper-checks/SKILL.md" "Pattern-derivation forcing function — Tier 2, not Tier 1" 1
expect_ge "63" "skills/gatekeeper-checks/SKILL.md" "33. Novel opener construction passes the direct-answer test" 1
expect_ge "63" "skills/gatekeeper-checks/SKILL.md" "35 distinct, named check types" 1
expect_eq0 "63" "skills/gatekeeper-checks/SKILL.md" "32 distinct, named check types"
c63_all32=$(grep -Ec "all 32\b" "$TARGET/skills/gatekeeper-checks/SKILL.md" 2>/dev/null || true); c63_all32=${c63_all32:-0}
if [ "$c63_all32" -eq 0 ]; then report "63" 1 ""; else report "63" 0 "'all 32' (word boundary) found $c63_all32 time(s) in gatekeeper-checks/SKILL.md, must be 0"; fi
expect_ge "63" "skills/gatekeeper-checks/SKILL.md" "check types passed ÷ 35" 1
expect_ge "63" "agents/gatekeeper.md" "\[n\] of 35" 1
expect_eq0 "63" "agents/gatekeeper.md" "\[n\] of 32"
expect_ge "63" "CLAUDE.md" "35 named, binary check types" 1
expect_eq0 "63" "CLAUDE.md" "32 named, binary check types"
expect_ge "63" "CLAUDE.md" "35-item checklist" 1
expect_eq0 "63" "CLAUDE.md" "32-item checklist"

# ================================================================
# Check 64 — CV footer files carry zero real personal content, resolve from career-data
# (PARTIALLY MECHANIZED — FAIL condition also requires a human/LLM read of both
# footer files' actual content; the greps below are a floor, not a substitute.)
# ================================================================
# 2026-07-13 corrected re-inclusion: exclude the sanctioned "University of
# Example" hint text the original regex falsely matched (see Check 64 prose).
for f in "skills/career-engine-export/static-cv-footer.md" "skills/career-engine-export/static-cv-footer-he.md"; do
  c64=$(grep -E "University of [A-Z]|College of [A-Z]" "$TARGET/$f" 2>/dev/null | grep -v "University of Example" | wc -l | tr -d ' ')
  if [ "$c64" -eq 0 ]; then report "64" 1 ""; else report "64" 0 "real-looking institution name in $f ($c64 hit(s), excluding the Example hint)"; fi
done
expect_ge "64" "skills/career-engine-export/static-cv-footer.md" "{{USER_DEGREE_1}}" 1
expect_ge "64" "skills/career-engine-export/static-cv-footer.md" "{{USER_INSTITUTION_1}}" 1
# NOTE: the source "University of [A-Z]|College of [A-Z]" grep is NOT migrated —
# baseline-tested against the known-good repo and it self-contradicts (matches
# the file's own sanctioned "University of Example" hint text, which the check's
# own comment says should be excluded but the regex does not exclude). See notes file.
expect_ge "64" "skills/career-engine-export/static-cv-footer-he.md" "{{USER_DEGREE_1_HE}}" 1
expect_ge "64" "skills/career-engine-export/static-cv-footer-he.md" "{{USER_INSTITUTION_1_HE}}" 1
c64_named=$(grep -c "University of Liverpool\|University of Chicago" "$TARGET/skills/career-engine-export/static-cv-footer.md" "$TARGET/skills/career-engine-export/static-cv-footer-he.md" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
if [ "$c64_named" -eq 0 ]; then report "64" 1 ""; else report "64" 0 "specific leaked institution name(s) found in footer file(s): $c64_named"; fi
expect_eq0 "64" "skills/career-engine-export/scripts/convert-cv.sh" "PLUGIN_DIR.*static-cv-footer"
expect_ge "64" "skills/career-engine-export/scripts/convert-cv.sh" 'CV_FOOTER="\$4"' 1
c64_root1=$(grep -c 'CLAUDE_PLUGIN_ROOT.*static-cv-footer' "$TARGET/skills/career-engine-export/SKILL.md" 2>/dev/null || true); c64_root1=${c64_root1:-0}
c64_root2=$(grep -c 'CLAUDE_PLUGIN_ROOT.*static-cv-footer' "$TARGET/skills/career-engine-new-application/SKILL.md" 2>/dev/null || true); c64_root2=${c64_root2:-0}
c64_root3=$(grep -c 'CLAUDE_PLUGIN_ROOT.*static-cv-footer' "$TARGET/skills/career-engine-edit/SKILL.md" 2>/dev/null || true); c64_root3=${c64_root3:-0}
if [ "$c64_root1" -eq 0 ] && [ "$c64_root2" -eq 0 ] && [ "$c64_root3" -eq 0 ]; then
  report "64" 1 ""
else
  report "64" 0 "CLAUDE_PLUGIN_ROOT-relative footer path found (export=$c64_root1 new-app=$c64_root2 edit=$c64_root3)"
fi
expect_ge "64" "skills/career-engine-orchestrator/orchestrator-queue.md" '\$CV_FOOTER' 1
expect_ge "64" "skills/career-engine-edit/SKILL.md" '\$CV_FOOTER' 1
expect_ge "64" "skills/career-engine-setup/SKILL.md" "static-cv-footer.md" 1
expect_ge "64" "skills/career-engine-setup/SKILL.md" "what are your actual degrees, institutions, and languages" 1

# ================================================================
# Check 35c — Two bundled intake bug fixes present
# ================================================================
expect_ge "35c" "skills/career-engine-intake/SKILL.md" "Do not ask the user about this. The selection above is deterministic" 1
expect_ge "35c" "skills/database-notion/SKILL.md" "Steps 2–3 (the view-query call itself) must be delegated" 1

# ================================================================
# Check 35d — Prioritization resolves its own New-status view
# ================================================================
expect_ge "35d" "agents/role-prioritizer.md" "database_new_view_url" 2
expect_ge "35d" "references/pipeline-preferences.json" "database_new_view_url" 1
expect_ge "35d" "skills/career-engine-setup/SKILL.md" "database_new_view_url" 1
expect_ge "35d" "skills/database-notion/SKILL.md" "database_new_view_url" 1
expect_ge "35d" "CLAUDE.md" "database_new_view_url" 1
expect_eq0 "35d" "agents/role-prioritizer.md" "the underlying property values are what you filter on, not the view name"

# ================================================================
# Check 35e — Prioritization runs with zero human input (2026-10-14, per the user)
# ================================================================
expect_ge "35e" "agents/role-prioritizer.md" "Prioritization outcome table" 3
expect_ge "35e" "agents/role-prioritizer.md" "JD Fetch Status\` is written for every skipped role" 1
expect_ge "35e" "agents/role-prioritizer.md" "\`Fifth\`→\`6\`" 2
expect_ge "35e" "agents/role-prioritizer.md" "This report ends the run" 1
expect_ge "35e" "agents/role-prioritizer.md" "need your call first" 1
expect_ge "35e" "skills/role-prioritizer/SKILL.md" "no human input" 1
expect_ge "35e" "hooks/hooks.json" "role-prioritizer subagents" 1
expect_ge "35e" "scripts/gate-ask-user-question.sh" "INPUT_ASK" 2
expect_ge "35e" "agents/role-prioritizer.md" "open application only when the user has said so" 1
expect_ge "35e" "agents/role-prioritizer.md" "never the archived/changed row" 1
expect_ge "35e" "agents/qa-plugin.md" "Check 35e" 1
expect_ge "35e" "agents/role-prioritizer.md" "Confirmed closure is a write, never a question" 1
expect_ge "35e" "agents/role-prioritizer.md" "earned by searching" 1
expect_ge "35e" "skills/database/SKILL.md" "| \`Closed\` |" 1
expect_ge "35e" "skills/career-engine-intake/SKILL.md" "jobs-guest/jobs/api/jobPosting" 1
expect_ge "35e" "skills/career-engine-intake/SKILL.md" "closed-confirmed" 4
expect_ge "35e" "skills/career-engine-setup/SKILL.md" "Needs Editing, Closed" 1
expect_ge "35e" "skills/career-engine-edit/SKILL.md" "Closure check before any drop" 1
expect_ge "35e" "skills/source-open-roles/SKILL.md" "closed rows included" 1
expect_ge "35e" "agents/source-open-roles.md" "previously closed" 1
expect_eq0 "35e" "agents/role-prioritizer.md" "paste the JD and I"
# 2026-10-15 second run: job ID in any LinkedIn URL shape; URL class from the URL, never a note;
# a follow-up turn after a user correction is still the run.
expect_ge "35e" "skills/career-engine-intake/SKILL.md" "currentJobId=<JOBID>" 1
expect_ge "35e" "skills/career-engine-intake/SKILL.md" "IS a job listing" 1
expect_ge "35e" "agents/role-prioritizer.md" "never from a note" 1
expect_ge "35e" "agents/role-prioritizer.md" "A follow-up turn is still the run" 1
expect_ge "35e" "agents/role-prioritizer.md" "IO River follow-up" 1
expect_ge "35e" "hooks/hooks.json" "follow-up turn" 1
expect_ge "35e" "skills/role-prioritizer/SKILL.md" "A follow-up turn is still the run" 1
expect_ge "35e" "agents/career-coach.md" "jobs-guest/jobs/api/jobPosting" 1
expect_ge "35e" "skills/career-engine-edit/SKILL.md" "job ID in any URL form" 1

# ================================================================
# Check 38 — Mechanical word count enforced, not self-estimated
# ================================================================
expect_ge "38" "agents/letter-writer.md" "^tools:.*Bash" 1
expect_ge "38" "agents/gatekeeper.md" "^tools:.*Bash" 1
expect_ge "38" "agents/letter-writer.md" "wc -w" 1
expect_ge "38" "skills/gatekeeper-checks/SKILL.md" "wc -w" 1
expect_ge "38" "skills/writer-craft/SKILL.md" "wc -w" 1

# ================================================================
# Check 39 — Path B view-query delegation present at all three query sites
# ================================================================
expect_ge "39" "skills/career-engine-intake/SKILL.md" "the view-query call itself (§2 Path B steps 2–3) is delegated by the adapter" 1
expect_ge "39" "skills/career-engine-edit/SKILL.md" "the view-query call itself (§2 Path B steps 2–3) is delegated by the adapter" 1
expect_ge "39" "skills/career-engine-orchestrator/orchestrator-queue.md" "the view-query call itself (§2 Path B steps 2–3) is delegated by the adapter" 1

# ================================================================
# Check 40 — Banned-phrase family Grep (not one literal string) present
# ================================================================
expect_ge "40" "skills/gatekeeper-checks/SKILL.md" "Grep for the family, not the exact phrase" 1
expect_ge "40" "skills/gatekeeper-checks/SKILL.md" "was mine.*meant for me.*meant to be" 1

# ================================================================
# Check 41 — Opener joint-constraint guidance present
# ================================================================
expect_ge "41" "skills/writer-craft/SKILL.md" "Satisfy this jointly with the Subject-first rule" 1

# ================================================================
# Check 42 — Plugin-file-unreachable hard stop present for writer/humanizer agents
# ================================================================
expect_ge "42" "agents/letter-writer.md" "letter-core/SKILL.md.*cannot be read\|cannot be read.*letter-core" 1
expect_ge "42" "agents/cv-writer.md" "cannot be read" 1
expect_ge "42" "agents/humanizer.md" "cannot be read" 1

# ================================================================
# Check 43 — E0.7 baseline-skip rationalization closed
# ================================================================
expect_ge "43" "skills/career-engine-edit/SKILL.md" "Do not skip this step because the letter or CV will be substantially rewritten anyway" 1

# ================================================================
# Check 44 — Resume-not-respawn wired for the letter-writer revision loop
# ================================================================
expect_ge "44" "skills/career-engine-new-application/SKILL.md" "Capture the returned agent ID" 1
expect_ge "44" "skills/career-engine-edit/SKILL.md" "Capture the returned agent ID" 1
# min 3→2 (2026-07-22): the Step 5.3 coach-review revision path was removed per the user's instruction
expect_ge "44" "skills/career-engine-new-application/SKILL.md" "resume the letter-writer instance\|Resume the letter-writer instance" 2
# min 5→4 (2026-07-22): the Step E7.4 coach-review revision path was removed per the user's instruction
expect_ge "44" "skills/career-engine-edit/SKILL.md" "resume the letter-writer instance\|Resume the letter-writer instance" 4
expect_ge "44" "skills/career-engine-new-application/SKILL.md" "letter-writer-agent-id.txt" 1
expect_ge "44" "skills/career-engine-edit/SKILL.md" "letter-writer-agent-id.txt" 1

# ================================================================
# Check 45 — Skills preload, memory, and Agent-tool denial wired on writer-pipeline agents
# ================================================================
expect_ge "45" "agents/letter-writer.md" "^  - letter-core" 1
expect_ge "45" "agents/humanizer.md" "^  - humanizer" 1
expect_ge "45" "agents/humanizer.md" "^  - writer-craft" 1
expect_ge "45" "agents/gatekeeper.md" "^  - gatekeeper-checks" 1
expect_ge "45" "agents/gatekeeper.md" "^memory: project" 1
expect_ge "45" "agents/letter-writer.md" "^disallowedTools: Agent" 1
expect_ge "45" "agents/gatekeeper.md" "^disallowedTools: Agent" 1
expect_ge "45" "agents/humanizer.md" "^disallowedTools: Agent" 1

# ================================================================
# Check 46 — career-data v1.8.0 restructure wired end-to-end
# ================================================================
c46_stale=$(grep -rc "references/linkedin-post-strategy\.md\|references/personal-brand-context\.md" "$TARGET"/agents "$TARGET"/skills --include="*.md" 2>/dev/null | grep -v ":0$" | wc -l | tr -d ' ')
if [ "$c46_stale" -eq 0 ]; then report "46" 1 ""; else report "46" 0 "found $c46_stale file(s) with stale flat-path career-data references"; fi
expect_ge "46" "agents/linkedin-post-writer.md" "voice-and-identity/linkedin-post-strategy.md" 1
expect_ge "46" "skills/content-orchestrator/SKILL.md" "voice-and-identity/linkedin-post-strategy.md" 1
expect_ge "46" "skills/personal-brand/SKILL.md" "voice-and-identity/personal-brand-context.md" 1
expect_ge "46" "agents/letter-writer.md" "templates/cover_letter_templates.md" 1
expect_ge "46" "references/career-data-structure.md" "references/templates/" 1
expect_ge "46" "skills/update-refs/SKILL.md" "references/templates/" 1
expect_ge "46" "skills/career-engine-setup/SKILL.md" "references/templates/" 1

# ================================================================
# Check 47 — Cover-letter template usage procedure wired
# ================================================================
expect_ge "47" "agents/letter-writer.md" "Step 0.7 — Read the coach's template selection and outline" 1
expect_ge "47" "agents/letter-writer.md" "You do not choose the template" 1
expect_ge "47" "agents/letter-writer.md" "Dial Sheet is a hard constraint" 1
expect_ge "47" "agents/letter-writer.md" "never copy its illustrative variant text verbatim" 1
expect_ge "47" "agents/letter-writer.md" "governs how a known-true metric is phrased, never whether one may be invented" 1
expect_ge "47" "agents/letter-writer.md" "never overrides the Opener non-negotiable rule" 1

# ================================================================
# Check 48 — cv_template/word_templates_path fully retired
# ================================================================
c48_key=$(grep -rc '"cv_template"\|"word_templates_path"' "$TARGET"/agents "$TARGET"/skills "$TARGET"/references --include="*.md" --include="*.json" 2>/dev/null | grep -v ":0$" | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
if [ "$c48_key" -eq 0 ]; then report "48" 1 ""; else report "48" 0 "found $c48_key file(s) still writing cv_template/word_templates_path as a config key"; fi
expect_ge "48" "skills/career-engine-setup/SKILL.md" "renaming to the fixed filename" 1
expect_ge "48" "skills/career-engine-setup/SKILL.md" "cover-letter-templates-default.md" 1
expect_ge "48" "skills/career-engine-setup/SKILL.md" "keep the style names\|those names don't change" 1
expect_ge "48" "references/career-data-skill-handoff.md" "background/" 1
expect_ge "48" "references/career-data-skill-handoff.md" "framework/" 1
expect_ge "48" "references/career-data-skill-handoff.md" "voice-and-identity/" 1
expect_ge "48" "references/career-data-skill-handoff.md" "templates/" 1
c48_pd=$(grep -ic "rachel\|cheyfitz\|visual layer\|coro\b\|lytx" "$TARGET/references/cover-letter-templates-default.md" 2>/dev/null || true); c48_pd=${c48_pd:-0}
if [ "$c48_pd" -eq 0 ]; then report "48" 1 ""; else report "48" 0 "personal-data pattern found $c48_pd time(s) in cover-letter-templates-default.md"; fi
expect_ge "48" "references/voice-calibration-method.md" "Templates-aware format" 1
expect_ge "48" "references/voice-calibration-method.md" "Fallback: six-dimension format" 1

# ================================================================
# Check 49 — Tier 1/Tier 2 grading model, Gate 9, coach outline, verbatim-preservation
# ================================================================
c49_grade=$(grep -rc "Grade A\|Grade: A\|\[Grade:" "$TARGET"/agents "$TARGET"/skills --include="*.md" 2>/dev/null | grep -v ":0$" | grep -v "linkedin-post-reviewer" | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
if [ "$c49_grade" -eq 0 ]; then report "49" 1 ""; else report "49" 0 "found $c49_grade file(s) with a surviving Grade A-D reference"; fi
expect_ge "49" "skills/gatekeeper-checks/SKILL.md" "Tier 1" 1
expect_ge "49" "skills/gatekeeper-checks/SKILL.md" "Tier 2" 1
expect_ge "49" "CLAUDE.md" "Tier 1 / Tier 2" 1
expect_ge "49" "skills/gatekeeper-checks/SKILL.md" "Gate 9 — Structural Completeness" 1
expect_ge "49" "skills/gatekeeper-checks/SKILL.md" "Tier 1 — 100% required, no exceptions" 1
expect_ge "49" "skills/gatekeeper-checks/SKILL.md" "no floor on any of these" 1
expect_ge "49" "references/cover-letter-templates-default.md" "no floor on any of these\|no floor\|no minimum" 1
expect_ge "49" "skills/gatekeeper-checks/SKILL.md" "Syntax correctness" 1
expect_ge "49" "skills/gatekeeper-checks/SKILL.md" "distinct, named check types" 1
expect_ge "49" "skills/gatekeeper-checks/SKILL.md" "totalizing-claim family" 1
expect_ge "49" "skills/gatekeeper-checks/SKILL.md" "method-before-demonstration family" 1
expect_ge "49" "skills/writer-craft/SKILL.md" "totalizing-claim family" 1
expect_ge "49" "skills/humanizer/SKILL.md" "totalizing-claim family" 1
expect_ge "49" "agents/career-coach.md" "Option 4a — Pre-Draft Outline" 1
expect_ge "49" "agents/career-coach.md" "coach-outline.md" 1
expect_ge "49" "agents/letter-writer.md" "You do not choose the template" 1
c49_israel=$(grep -ci "israel" "$TARGET/agents/letter-writer.md" 2>/dev/null || true); c49_israel=${c49_israel:-0}
if [ "$c49_israel" -eq 0 ]; then report "49" 1 ""; else report "49" 0 "'israel' (case-insensitive) found $c49_israel time(s) in letter-writer.md"; fi
expect_ge "49" "agents/career-coach.md" "I'm convinced\|I'm not convinced because" 1
expect_ge "49" "skills/writer-craft/SKILL.md" "Verbatim-preservation principle" 1
expect_ge "49" "agents/letter-writer.md" "Verbatim-preservation principle" 1
c49_reuse=$(grep -rci "bert similarity\|n-gram.*reuse\|reuse.*across letters.*banned\|shares 10+ consecutive words with.*any prior letter" "$TARGET"/agents "$TARGET"/skills "$TARGET"/references --include="*.md" 2>/dev/null | grep -v ":0$" | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
if [ "$c49_reuse" -eq 0 ]; then report "49" 1 ""; else report "49" 0 "found $c49_reuse file(s) with a retracted reuse/repetition-policing reference"; fi
expect_file "49" "skills/humanizer/scripts/corpus-stats.py"
c49_imports=$(grep -Ec "^import (docx|requests|numpy|pandas|nltk)" "$TARGET/skills/humanizer/scripts/corpus-stats.py" 2>/dev/null || true); c49_imports=${c49_imports:-0}
if [ "$c49_imports" -eq 0 ]; then report "49" 1 ""; else report "49" 0 "corpus-stats.py imports a third-party package ($c49_imports match(es))"; fi
expect_ge "49" "skills/humanizer/SKILL.md" "corpus-stats.py" 1
# 2026-07-22: step renamed — letter plan comes from intake's Coach Letter Plan; coach spawn is the legacy fallback
# 2026-07-23: step headings renamed with the Letter Outline marker rename
expect_ge "49" "skills/career-engine-new-application/SKILL.md" "Letter plan (from intake's Letter Outline" 1
expect_ge "49" "skills/career-engine-edit/SKILL.md" "Letter plan (from intake's Letter Outline" 1
expect_ge "49" "skills/career-engine-new-application/SKILL.md" "Template selected=" 2
expect_ge "49" "skills/career-engine-edit/SKILL.md" "Template selected=" 2
expect_ge "49" "skills/career-engine-new-application/SKILL.md" "SENDMESSAGE_AVAILABLE" 1
expect_ge "49" "skills/career-engine-edit/SKILL.md" "SENDMESSAGE_AVAILABLE" 1

# ================================================================
# Check 50 — Intake page-body purity, mandatory-field parity, Job URL correction
# ================================================================
expect_ge "50" "skills/career-coach/coach-output.md" "ONLY page-body content in the entire intake pipeline" 1
expect_ge "50" "skills/gatekeeper-checks/SKILL.md" "Outreach map structural purity" 1
expect_ge "50" "skills/career-engine-intake/SKILL.md" "Extraction — the ONLY sanctioned page-body write" 1
expect_ge "50" "agents/gatekeeper.md" "outreach map structural purity check" 1
c50_wa=$(grep -rc "^## Writing Angle\|^\*\*Message [Aa]ngle:\*\*" "$TARGET"/agents "$TARGET"/skills --include="*.md" 2>/dev/null | grep -v ":0$" | wc -l | tr -d ' ')
if [ "$c50_wa" -eq 0 ]; then report "50" 1 ""; else report "50" 0 "found $c50_wa file(s) with an unauthorized Writing Angle/Message angle heading"; fi
for f in "Manager role confirmed" "Hiring manager's role" "Company Stage" "JD proof" "JD Body"; do
  c=$(cnt "$f" "skills/career-engine-intake/SKILL.md"); c=${c:-0}
  if [ "$c" -ge 2 ]; then report "50" 1 ""; else report "50" 0 "'$f' count in career-engine-intake/SKILL.md is $c, need >= 2"; fi
done
expect_ge "50" "skills/gatekeeper-checks/SKILL.md" "Company Stage" 1
expect_ge "50" "skills/gatekeeper-checks/SKILL.md" "Manager role confirmed" 1
expect_ge "50" "skills/gatekeeper-checks/SKILL.md" "Hiring manager's role" 1
expect_ge "50" "skills/career-engine-intake/SKILL.md" "Working URL (if different from Job URL)" 1
expect_ge "50" "skills/career-coach/coach-research.md" "Job URL verification (backstop only)" 1
expect_ge "50" "skills/career-coach/coach-output.md" "Corrected Job URL" 2
# 2026-07-23: Job URL correction broadened — anchor updated to the new bullet wording
expect_ge "50" "skills/career-engine-intake/SKILL.md" "write whenever the JD was actually obtained at a different URL" 1
expect_ge "50" "CLAUDE.md" "Job URL correction" 1

# ================================================================
# Check 51 — Generic-default-template reuse check, identity-idiom adjacency,
# Gate 6 Tier 1 promotion
# ================================================================
expect_ge "51" "skills/gatekeeper-checks/SKILL.md" "Generic-default-template verbatim reuse" 1
expect_ge "51" "skills/gatekeeper-checks/SKILL.md" "against a user's own" 1
expect_ge "51" "skills/gatekeeper-checks/SKILL.md" "do not run this check at all" 1
expect_ge "51" "skills/gatekeeper-checks/SKILL.md" "direction doesn't matter, adjacency does" 1
expect_ge "51" "skills/gatekeeper-checks/SKILL.md" "still fails" 1
expect_ge "51" "skills/gatekeeper-checks/SKILL.md" "Gate 6 (Banned Terms) — the curated literal-string lists only" 1
expect_ge "51" "skills/gatekeeper-checks/SKILL.md" "This is the seat" 1
expect_ge "51" "skills/writer-craft/SKILL.md" "Personal-voice exemption — same rule as the idiom exemption" 1

# ================================================================
# Check 52 — Orchestrator-side Bash mechanical backstop, humanizer Bash grant,
# coach-outline literal-path enforcement
# ================================================================
expect_ge "52" "skills/career-engine-new-application/SKILL.md" "guaranteed-mechanical enforcement of the cap" 1
expect_ge "52" "skills/career-engine-edit/SKILL.md" "guaranteed-mechanical enforcement" 1
expect_ge "52" "skills/career-engine-new-application/SKILL.md" "Gate 6 Tier 1 banned-vocabulary" 1
expect_ge "52" "skills/career-engine-edit/SKILL.md" "Gate 6 Tier 1 banned-vocabulary" 1
expect_ge "52" "agents/gatekeeper.md" "say so explicitly, do not silently substitute a hand count" 1
expect_ge "52" "agents/humanizer.md" "^tools:.*Bash" 1
expect_ge "52" "agents/humanizer.md" "never hand-tally" 1
expect_ge "52" "agents/career-coach.md" "never invent your own filename" 1

# ================================================================
# Check 53 — Post-run wrap-up (Steps 8-9c) runs on an interrupted queue
# ================================================================
expect_ge "53" "skills/career-engine-orchestrator/orchestrator-queue.md" "If the loop stops early instead" 1
expect_ge "53" "skills/career-engine-orchestrator/orchestrator-queue.md" "do not skip straight to a chat summary" 1
expect_ge "53" "skills/career-engine-orchestrator/orchestrator-post-run.md" "OR when the per-role loop stops early" 1
expect_ge "53" "skills/career-engine-orchestrator/orchestrator-post-run.md" "Interrupted run (a hard external blocker" 1
expect_ge "53" "skills/career-engine-orchestrator/orchestrator-post-run.md" '"interrupted":' 1

# ================================================================
# Check 54 — Information Sequencing (personal-affinity opener rule) wired end-to-end
# ================================================================
expect_ge "54" "skills/writer-craft/SKILL.md" "Information Sequencing" 1
expect_ge "54" "skills/gatekeeper-checks/SKILL.md" "Pattern J — Personal-affinity opener" 1
expect_ge "54" "skills/gatekeeper-checks/SKILL.md" "Pattern A-J" 1
expect_eq0 "54" "skills/gatekeeper-checks/SKILL.md" "Pattern A-I"
expect_ge "54" "agents/letter-writer.md" "Information Sequencing" 1
expect_ge "54" "references/cover-letter-templates-default.md" "Information Sequencing" 1

# ================================================================
# Check 65 (renumbered from duplicate "Check 55") — Brief CV Type wired end-to-end (main bash block)
# NOTE: the "database_property ... | head -1" sanity line in the source has no
# clear PASS/FAIL threshold (comment says "sanity" not "must be") — not migrated.
# ================================================================
expect_ge "65" "references/pipeline-preferences.json" '"cv_type"' 1
expect_ge "65" "skills/database/SKILL.md" "CV Type" 1
# 2026-07-23 (second pass): the Recommendation Matrix table was retired per the user ("couldn't possibly be
# relevant for any user") — replaced by the CV Type judgment principle + cv_type.market_norms config.
expect_ge "65" "skills/career-coach/coach-analysis.md" "CV Type judgment principle" 1
expect_ge "65" "skills/career-coach/coach-analysis.md" "market_norms" 1
expect_eq0 "65" "skills/career-coach/coach-analysis.md" "| Israel | Any |"
expect_ge "65" "references/pipeline-preferences.json" "market_norms" 1
# 2026-07-23: CV Type moved out of Role emphasis into its own returned property (write-only-to-empty).
expect_eq0 "65" "skills/career-coach/coach-output.md" "Recommended CV Type"
expect_ge "65" "skills/career-coach/coach-output.md" "CV Type:" 1
expect_ge "65" "skills/career-engine-intake/SKILL.md" "\`CV Type\` — \*\*write-only-to-empty" 1
expect_ge "65" "skills/gatekeeper-checks/coach-gates.md" "CV Type" 1
expect_ge "65" "agents/cv-writer.md" "CV Type=Detailed|Brief" 1
expect_ge "65" "agents/cv-writer.md" "Brief-Specific Rules" 1
expect_ge "65" "skills/writer-craft/SKILL.md" "§5b" 1
expect_ge "65" "agents/gatekeeper.md" "CV Type" 1
expect_ge "65" "skills/gatekeeper-checks/SKILL.md" "Brief only" 1
expect_ge "65" "skills/gatekeeper-checks/SKILL.md" "skipped entirely.*for Brief" 1
expect_ge "65" "skills/career-engine-export/SKILL.md" "CV_TEMPLATE_BRIEF" 1
expect_ge "65" "skills/career-engine-export/SKILL.md" "CONFIRMED against a real build" 1
expect_file "65" "references/cv-template-brief-default.dotx"
expect_ge "65" "skills/career-engine-new-application/SKILL.md" "Step 0.type" 1
expect_ge "65" "skills/career-engine-edit/SKILL.md" "Step E0.type" 1
expect_ge "65" "skills/career-engine-setup/SKILL.md" "CV Type — mandatory question" 1
# 2026-07-13 correction: the source naming-discipline grep lacked the
# qa-plugin.md self-exclusion most other checks carry, so it matched this very
# check's own description text. Now asserted with the exclusion added.
c65=$(grep -rn '"Summary" CV Type\|CV Type=Summary\|Summary CV Type' "$TARGET"/agents/*.md "$TARGET"/skills/*/SKILL.md 2>/dev/null | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
if [ "$c65" -eq 0 ]; then report "65" 1 ""; else report "65" 0 "naming-discipline: found $c65 'Summary CV Type' occurrence(s), must be 0 (the type is Brief, never Summary)"; fi

# ================================================================
# Check 65-2026-07-10 (renumbered from 55-brief-cv-2026-07-10) — Brief CV two-column assembly script wired (second block)
# ================================================================
expect_ge "65-2026-07-10" "skills/career-engine-export/SKILL.md" "assemble_brief_cv.py" 1
expect_eq0 "65-2026-07-10" "skills/career-engine-export/SKILL.md" "does not exist yet"
expect_file "65-2026-07-10" "skills/career-engine-export/scripts/assemble_brief_cv.py"

# ================================================================
# Check 36 — Humanizer enforcement mechanisms present
# ================================================================
expect_ge "36" "skills/humanizer/SKILL.md" "Exhaustiveness pass" 1
expect_ge "36" "skills/humanizer/SKILL.md" "could only a person actually do this" 1
expect_eq0 "36" "skills/humanizer/SKILL.md" "only people build, craft, drive"
expect_ge "36" "skills/humanizer/SKILL.md" "hollow spatial/abstract metaphors" 1
expect_ge "36" "skills/humanizer/SKILL.md" "Mandatory trigger, not just a general reminder" 1

# ================================================================
# Check 37 — Intake queue selection driven by Prioritization's scores
# ================================================================
expect_ge "37" "skills/career-engine-intake/SKILL.md" "scored. roles take priority, ordered by their existing Priority value" 1
expect_eq0 "37" "skills/career-engine-intake/SKILL.md" "unscored roles first, random tie-break among unscored, then scored roles by Priority"
expect_ge "37" "CLAUDE.md" "Prioritization → full-intake queue selection" 1

# ================================================================
# Check 30 — Changelog rules present in CLAUDE.md; README.md changelog is well-formed
# (PARTIALLY MECHANIZED — reading README's Changelog section for chronological
# ordering and heading completeness stays manual.)
# ================================================================
expect_ge "30" "CLAUDE.md" "Changelog rules" 1
expect_ge "30" "CLAUDE.md" "Newest at the top" 1
expect_ge "30" "CLAUDE.md" "never removed" 1
expect_ge "30" "README.md" "## Changelog" 1

# ================================================================
# Phase 0 Step 0C — Retired-name search (permanent banned list)
# (Steps 0A/0B are NOT migrated — they require reading grep output and judging
# whether each referenced name is a legitimate rename target, per the
# classification rule's "no pipelines into judgment" exclusion.)
# ================================================================
c0C_1=$(grep -rn "employment-coach\|career-engine-coach\b" "$TARGET"/agents "$TARGET"/skills "$TARGET"/references --include="*.md" 2>/dev/null | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
c0C_2=$(grep -rn "cv-campaign-intake\|cv-campaign-setup\|cv-campaign-steps\|cv-campaign-edit\|cv-campaign-orchestrator\|cv-campaign-export" "$TARGET" --include="*.md" 2>/dev/null | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
c0C_3=$(grep -rn "application-intake\|application-edit\|new-application-steps\|applications-orchestrator\|application-files-export" "$TARGET" --include="*.md" 2>/dev/null | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
c0C_4=$(grep -rn "cover-letter-humanizer\|voice-analyst" "$TARGET"/agents "$TARGET"/skills --include="*.md" 2>/dev/null | grep -v "qa-plugin.md" | wc -l | tr -d ' ')
if [ "$c0C_1" -eq 0 ]; then report "0C" 1 ""; else report "0C" 0 "found $c0C_1 employment-coach/career-engine-coach reference(s)"; fi
if [ "$c0C_2" -eq 0 ]; then report "0C" 1 ""; else report "0C" 0 "found $c0C_2 generation-1 cv-campaign-* reference(s)"; fi
if [ "$c0C_3" -eq 0 ]; then report "0C" 1 ""; else report "0C" 0 "found $c0C_3 generation-2 application-* reference(s)"; fi
if [ "$c0C_4" -eq 0 ]; then report "0C" 1 ""; else report "0C" 0 "found $c0C_4 cover-letter-humanizer/voice-analyst reference(s)"; fi

# ================================================================
# Check 66 — pregate-lint.py exists, is executable, and its selftest passes
# ================================================================
PREGATE_SCRIPT="$TARGET/skills/gatekeeper-checks/scripts/pregate-lint.py"
if [ -f "$PREGATE_SCRIPT" ]; then report "66" 1 ""; else report "66" 0 "pregate-lint.py missing at skills/gatekeeper-checks/scripts/"; fi
if [ -x "$PREGATE_SCRIPT" ]; then report "66" 1 ""; else report "66" 0 "pregate-lint.py is not executable"; fi
if python3 "$PREGATE_SCRIPT" --selftest >/dev/null 2>&1; then
  report "66" 1 ""
else
  report "66" 0 "python3 pregate-lint.py --selftest failed"
fi

# ================================================================
# Check 71 — Capability profile: function fit is coverage, not titles (2026-10-15, per the user)
# ================================================================
expect_file "71" "references/capability-profile.md"
expect_file "71" "skills/career-coach/coach-capability-profile.md"
expect_ge "71" "references/capability-profile.md" "{{CAPABILITY_LINE" 1
expect_ge "71" "skills/career-coach/coach-capability-profile.md" "pairwise de-duplication test" 1
expect_ge "71" "skills/career-coach/coach-capability-profile.md" "portability test" 2
expect_ge "71" "skills/career-coach/coach-capability-profile.md" "three-way test" 1
expect_ge "71" "skills/career-coach/coach-capability-profile.md" "wait for confirmation" 1
expect_ge "71" "agents/role-prioritizer.md" "Function fit is responsibility coverage against the capability profile" 1
expect_ge "71" "agents/role-prioritizer.md" "The title list is advisory" 1
expect_ge "71" "agents/role-prioritizer.md" "CAPABILITY_PROFILE = none" 2
expect_ge "71" "skills/role-prioritizer/SKILL.md" "Function fit — coverage, not titles" 1
expect_ge "71" "agents/career-coach.md" "generate my capability profile" 1
expect_ge "71" "skills/career-coach/SKILL.md" "coach-capability-profile.md" 1
expect_ge "71" "skills/career-engine-setup/SKILL.md" "Phase 4 — Capability profile" 1
expect_ge "71" "skills/career-engine-setup/SKILL.md" "un-profiled" 1
expect_ge "71" "agents/qa-plugin.md" "Check 71" 1
expect_ge "71" "agents/role-prioritizer.md" "In both branches:" 1
expect_ge "71" "agents/role-prioritizer.md" "never divide by zero" 1
expect_ge "71" "agents/role-prioritizer.md" "capability profile: present|missing" 1
expect_ge "71" "references/capability-profile.md" "DROPPED FROM THE GENERATED FILE" 1
expect_ge "71" "skills/career-coach/coach-capability-profile.md" "two-file fix" 1
# 2026-10-19, per the user: cap 30, early-career cap 25 — the doctrine, the template and the setup skill must agree.
expect_ge "71" "skills/career-coach/coach-capability-profile.md" "Cap the file at 30 lines" 1
expect_ge "71" "skills/career-coach/coach-capability-profile.md" "Early-career cap" 1
expect_eq0 "71" "skills/career-coach/coach-capability-profile.md" "Cap the file at 25 lines"
expect_ge "71" "references/capability-profile.md" "At most 30 capability lines" 1
expect_ge "71" "skills/career-engine-setup/SKILL.md" "≤30 lines" 1
expect_ge "71" "references/career-data-skill-handoff.md" "references/capability-profile.md contents" 1
expect_eq0 "71" "agents/role-prioritizer.md" "Step 0 item 4 determined the secondary mode"
expect_eq0 "71" "agents/role-prioritizer.md" "generate the capability profile yourself"

# ================================================================
# Check 70 — Role-tailoring plan (CV Titles) wired end-to-end (2026-09-17, per the user's
# direct instruction: titles aligned to the target role, unrelated roles folded, level matched —
# inside fixed honesty limits; coach proposes at intake, user-owned preferences field)
# ================================================================
expect_ge "70" "skills/writer-craft/cv.md" "§5c — Role Tailoring" 1
expect_ge "70" "skills/writer-craft/cv.md" "Never above her real level" 1
expect_ge "70" "skills/writer-craft/cv.md" "Nothing is hidden" 1
expect_ge "70" "skills/writer-craft/cv.md" "Do not be timid" 1
expect_ge "70" "skills/career-coach/coach-analysis.md" "Retitle — the default" 1
expect_ge "70" "skills/career-coach/coach-analysis.md" "USER CV TITLE PREFERENCES" 1
expect_ge "70" "skills/career-coach/coach-output.md" "CV Titles:" 1
expect_ge "70" "skills/gatekeeper-checks/coach-gates.md" "Over-caution is a defect too" 1
expect_ge "70" "skills/gatekeeper-checks/cv-gates.md" "Gate 6 — Role Tailoring" 1
expect_ge "70" "skills/gatekeeper-checks/cv-gates.md" "exempt from every honesty judgment" 1
expect_ge "70" "agents/cv-writer.md" "CV_TITLES_PATH" 1
expect_ge "70" "agents/gatekeeper.md" "CV_TITLES_PATH" 1
expect_ge "70" "agents/recruiter-reviewer.md" "CV_TITLES_PATH" 1
expect_ge "70" "skills/career-engine-new-application/SKILL.md" "Step 0.titles" 1
expect_ge "70" "skills/career-engine-edit/SKILL.md" "Step E0.titles" 1
expect_ge "70" "skills/career-engine-intake/SKILL.md" "Never write \`CV Title Preferences\`" 1
expect_ge "70" "skills/database/SKILL.md" "No agent ever writes it" 1
expect_ge "70" "skills/career-engine-setup/SKILL.md" "CV Title Preferences" 1
expect_ge "70" "references/job-applications-template.csv" "CV Titles," 1
expect_ge "70" "references/cv-self-check.md" "Role tailoring" 1

# ================================================================
# Check 72 — Frontmatter parses as YAML in every shipped .md that carries one (2026-10-15)
# The Desktop installer rejected a shipped build: career-coach.md's description carried
# unescaped inner double quotes. Every prior check here was a grep; this one parses.
# Runs against $TARGET, so it validates the unzipped artifact as well as the repo.
# ================================================================
# Always the repo's own script (this file is invoked from the repo), never one inside
# $TARGET — a stale or lenient copy in an old artifact must not override the verdict.
FM_RC=0; python3 "$(dirname "$0")/check-frontmatter.py" "$TARGET" >/dev/null 2>&1 || FM_RC=$?
if [ "$FM_RC" -eq 0 ]; then report "72" 1 "";
elif [ "$FM_RC" -eq 2 ]; then report "72" 0 "check-frontmatter.py could not run (PyYAML missing or no files) — run: python3 scripts/check-frontmatter.py $TARGET";
else report "72" 0 "frontmatter invalid — run: python3 scripts/check-frontmatter.py $TARGET"; fi
expect_file "72" "scripts/check-frontmatter.py"
expect_ge "72" "scripts/build-plugin.sh" "check-frontmatter.py" 1
expect_ge "72" "scripts/check-invariants.sh" "check-frontmatter.py" 1
expect_ge "72" "scripts/qa-mechanical.sh" "check-frontmatter.py" 1
expect_ge "72" "agents/qa-plugin.md" "Check 72" 1

# ================================================================
# Check 74 — Capability matching by default: role_matching / scope_preferences / cv_title_rules
# wired end-to-end (2026-10-19, per the user)
# ================================================================
expect_ge "74" "references/pipeline-preferences.json" "role_matching" 1
expect_ge "74" "references/pipeline-preferences.json" "scope_preferences" 1
expect_ge "74" "references/pipeline-preferences.json" "cv_title_rules" 1
for f in agents/source-open-roles.md skills/source-open-roles/SKILL.md agents/role-prioritizer.md skills/career-engine-intake/SKILL.md skills/career-engine-new-application/SKILL.md skills/career-engine-edit/SKILL.md; do
  expect_ge "74" "$f" "role_matching" 1
done
expect_ge "74" "skills/career-engine-new-application/SKILL.md" "MODE:" 1
expect_ge "74" "skills/career-engine-edit/SKILL.md" "MODE:" 1
expect_ge "74" "skills/source-open-roles/SKILL.md" "scope_preferences" 1
expect_ge "74" "agents/role-prioritizer.md" "scope_preferences" 1
expect_ge "74" "skills/career-coach/coach-analysis.md" "USER SCOPE PREFERENCES" 1
expect_ge "74" "skills/source-open-roles/SKILL.md" "Capabilities mode" 1
expect_ge "74" "agents/qa-plugin.md" "Check 74" 1

# Check 73 — Manifest version is bumped on every shipped build (2026-10-15)
# The CLI caches a marketplace plugin under <cache>/<marketplace>/<plugin>/<version>/.
# Two fixes shipped at version 1.0.0; `claude plugin update` kept serving the 1.0.0
# cache, so the user saw the duplicate-hooks error again after the fix had merged.
# Mechanical part: both manifests carry one identical version string. The bump itself
# (staged version semver-greater than origin/main's whenever shipped files are
# staged, read from the index) is asserted by the pre-commit hook,
# scripts/check-invariants.sh, which has the git context this artifact-side
# script does not.
# ================================================================
V_PLUGIN=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['version'])" "$TARGET/.claude-plugin/plugin.json" 2>/dev/null || echo "")
V_MARKET=$(python3 -c "import json,sys; print(next(p for p in json.load(open(sys.argv[1]))['plugins'] if p.get('name')=='career-engine')['version'])" "$TARGET/.claude-plugin/marketplace.json" 2>/dev/null || echo "")
if [ -n "$V_PLUGIN" ] && [ "$V_PLUGIN" = "$V_MARKET" ]; then report "73" 1 "";
else report "73" 0 "plugin.json version '$V_PLUGIN' != marketplace.json version '$V_MARKET' (or unreadable)"; fi
expect_ge "73" "scripts/check-invariants.sh" "version-bump" 1
expect_ge "73" "agents/qa-plugin.md" "Check 73" 1
expect_ge "73" "skills/plugin-builder/SKILL.md" "bump" 1

echo "qa-mechanical: $PASS passed, $FAIL failed"

# Relational layer (list parity, defined-term closure, spawn params, $PIPE closure)
# — driven by the sibling qa-parity.json manifest. Its PARITY lines follow the
# same contract as the CHECK lines above; a PARITY failure fails this script.
PARITY_RC=0
python3 "$(dirname "$0")/qa-parity.py" "$TARGET" || PARITY_RC=1

[ "$FAIL" -eq 0 ] && [ "$PARITY_RC" -eq 0 ]
