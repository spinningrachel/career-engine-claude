#!/usr/bin/env bash
set -euo pipefail
REPO=$(git rev-parse --show-toplevel)
ERRORS=()
fail() { ERRORS+=("$1"); }

# Contract: R-41 output protocol present in required agents
for agent in gatekeeper cv-writer letter-writer recruiter-reviewer humanizer; do
  grep -q "Output protocol (R-41)" "$REPO/agents/$agent.md" \
    || fail "R-41 marker missing from agents/$agent.md"
done

# Contract: Tier 1 / Tier 2 grading model exists in gatekeeper-checks skill (source of truth; replaced the retired Grade A-D table)
grep -q 'Tier 1' "$REPO/skills/gatekeeper-checks/SKILL.md" \
  || fail "Tier 1 grading section missing from skills/gatekeeper-checks/SKILL.md"
grep -q 'Tier 2' "$REPO/skills/gatekeeper-checks/SKILL.md" \
  || fail "Tier 2 grading section missing from skills/gatekeeper-checks/SKILL.md"

# Contract: gatekeeper agent has both PASS and FAIL cover letter output templates
grep -q 'PASS — cover letter' "$REPO/agents/gatekeeper.md" \
  || fail "PASS cover letter template missing from agents/gatekeeper.md"
grep -q 'FAIL — cover letter' "$REPO/agents/gatekeeper.md" \
  || fail "FAIL cover letter template missing from agents/gatekeeper.md"

# Contract: CAREER_DATA passed through in sub-pipeline skills (not entry skills like intake, which self-locate)
for skill in career-engine-new-application career-engine-edit; do
  grep -q 'CAREER_DATA=${CAREER_DATA}' "$REPO/skills/$skill/SKILL.md" \
    || fail "CAREER_DATA pass-through missing from skills/$skill/SKILL.md"
done

# Contract: gatekeeper option values present in agent
for opt in cv cover-letter coach-output; do
  grep -q "option=$opt" "$REPO/agents/gatekeeper.md" \
    || fail "option=$opt missing from agents/gatekeeper.md"
done

# Contract: key OUTPUT_PATH filenames present in new-application pipeline
# 2026-07-22: coach-letter-review.md removed from the pipeline (coach review replaced by Gate 5/9
# conformance per the user's instruction); coach-outline.md is the letter-plan file both paths produce.
for fname in 'gatekeeper-cv' 'gatekeeper-cl' 'recruiter-cv.md' 'coach-outline.md'; do
  grep -q "$fname" "$REPO/skills/career-engine-new-application/SKILL.md" \
    || fail "Pipeline file '$fname' missing from new-application SKILL.md"
done

# Frontmatter validity: every shipped .md that opens with --- parses as YAML (agents and
# skills must also open with the block and carry name/description) — what the installer parses (2026-10-15 — a bad description line blocked the whole install).
FM_RC=0; python3 "$REPO/scripts/check-frontmatter.py" "$REPO" >/dev/null 2>&1 || FM_RC=$?
if [ "$FM_RC" -eq 2 ]; then
  fail "check-frontmatter.py could not run — PyYAML is a maintainer dependency (pip install pyyaml)"
elif [ "$FM_RC" -ne 0 ]; then
  fail "frontmatter is not valid YAML — diagnose with: python3 scripts/check-frontmatter.py ."
fi

# Contract: version-bump on every shipped build (2026-10-15). The CLI caches a
# marketplace plugin by its manifest version; a rebuilt artifact at an unchanged
# version is never re-fetched by `claude plugin update` — the user kept getting
# the already-fixed duplicate-hooks error from the stale 1.0.0 cache. Versions are
# read from the INDEX (what the commit will carry), never the working tree — a
# bump left unstaged must not satisfy the gate. Trigger: any staged path that
# ships (the artifact, or agents/ skills/ references/ hooks/ scripts/
# .claude-plugin/), since the marketplace serves the repo tree itself. Then
# plugin.json's version must be semver-GREATER than origin/main's (skipped when
# origin/main is absent locally — fetch before committing so it is current).
ver_of() { python3 -c "
import json,sys
d=json.load(sys.stdin)
if 'plugins' in d:
    d=next(p for p in d['plugins'] if p.get('name')=='career-engine')
print(d['version'])" 2>/dev/null || echo ""; }
semver_gt() { python3 -c "
import sys
a=[int(x) for x in sys.argv[1].split('.')]; b=[int(x) for x in sys.argv[2].split('.')]
sys.exit(0 if a>b else 1)" "$1" "$2" 2>/dev/null; }
V_PLUGIN=$(git show :.claude-plugin/plugin.json 2>/dev/null | ver_of)
V_MARKET=$(git show :.claude-plugin/marketplace.json 2>/dev/null | ver_of)
[ -n "$V_PLUGIN" ] && [ "$V_PLUGIN" = "$V_MARKET" ] \
  || fail "staged manifest versions differ or are unreadable: plugin.json='$V_PLUGIN' marketplace.json='$V_MARKET' (stage both after a bump)"
if git diff --cached --name-only | grep -qE '^(career-engine\.plugin$|(agents|skills|references|hooks|scripts|\.claude-plugin)/)' \
   && git rev-parse --verify -q origin/main >/dev/null; then
  V_MAIN=$(git show origin/main:.claude-plugin/plugin.json 2>/dev/null | ver_of)
  if [ -n "$V_MAIN" ] && [ -n "$V_PLUGIN" ] && ! semver_gt "$V_PLUGIN" "$V_MAIN"; then
    fail "shipped files are staged but .claude-plugin/plugin.json version '$V_PLUGIN' is not greater than origin/main's '$V_MAIN' — bump both manifests and stage them, or the CLI serves the stale cache"
  fi
fi

# Relational layer: list parity, defined-term closure, spawn params, $PIPE closure
# (scripts/qa-parity.py + qa-parity.json). Fast (<1s), so it runs on every commit —
# this is what forces the consumer sweep when a fix touches one list but not its siblings.
if ! python3 "$REPO/scripts/qa-parity.py" "$REPO" >/dev/null 2>&1; then
  fail "qa-parity relational checks failed — diagnose with: python3 scripts/qa-parity.py ."
fi

# Personal-data guard (second of three layers; the PreToolUse hook is the first and
# the QA agent's scan is the third). Scans the staged set plus the whole working tree
# for stray personal output files. This is the layer that catches a personal value
# written by something the hook does not see — a shell heredoc, a script, a git mv.
if ! bash "$REPO/scripts/scan-personal-data.sh" --staged >/dev/null 2>&1; then
  fail "personal data detected in staged files — diagnose with: bash scripts/scan-personal-data.sh --staged"
fi
if ! bash "$REPO/scripts/scan-personal-data.sh" >/dev/null 2>&1; then
  fail "personal data detected in the working tree — diagnose with: bash scripts/scan-personal-data.sh"
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "❌ Invariant check failed — fix before committing:"
  printf '  - %s\n' "${ERRORS[@]}"
  echo ""
  echo "Run: bash scripts/check-invariants.sh to diagnose"
  exit 1
fi

echo "✓ Invariants OK"
