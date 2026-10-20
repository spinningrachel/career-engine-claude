---
name: career-engine-new-application
description: 'Per-role pipeline for the career-engine orchestrator. Handles Step 0.10 (warm-up role selection) and Steps 1 through 7 for New Applications pipeline roles: CV draft, gatekeeper, recruiter review, CV revision, cover letter draft, cover letter gatekeeper, letter-plan conformance (Gates 5/9; coach review removed 2026-07-22), cover letter revision, final verification gate, DOCX export for both files, and Notion writeback. The structured JD for each role is already in memory from the queue pipeline — do not re-fetch. Load this skill as part of the career-engine pipeline, after career-engine-intake.'
---

# New Application — Per-Role Pipeline

> **Registry:** this pipeline is listed in the Pipeline Registry in `skills/career-engine/SKILL.md`. Actions owned by another pipeline's registry row are out of scope here — route to that pipeline instead of improvising.

This skill covers Step 0.10 and Steps 1 through 7 of the New Applications pipeline. Step 0.10 runs once before the per-role loop begins. Steps 1 through 7 repeat for each role in the processing queue. The structured JD was fetched in Step 0.5 and is in memory — pass it directly without re-fetching.

The pipeline produces two deliverables per role: a CV DOCX and a cover letter DOCX. The CV goes through: draft, gatekeeper, recruiter review, revision, gatekeeper (post-revision). The cover letter is written after the final CV, from exactly three content inputs — the final CV, `Role emphasis`, and Why I Want This Role (see Step 5's input contract). The recruiter review, including its interview-trigger gaps, is user-facing feedback surfaced in Step 7d's feedback file — it is never passed to the letter-writer.

> **`career-data` data root (R-37).** The personal-data files — `01-writing-rules.md`, `02-professional-background.md`, `03-framework.md`, `linkedin-profile.md`, `pipeline-preferences.json`, `delivered-letters/`, and the user's `.dotx` — load from `${CAREER_DATA}/references/`, the path the orchestrator resolves in its `career-data` discovery preflight. Every other file (self-checks, `REFERENCES.md`, skill docs, default `.dotx` templates) stays on `${CLAUDE_PLUGIN_ROOT}`. If `${CAREER_DATA}` is not set (direct or standalone invocation outside the orchestrator), locate the `career-data` skill yourself, confirm `career-data-marker.json`, and apply the orchestrator's healthy / damaged / absent outcomes before reading. A configured user's missing `career-data` is a hard stop — never silently fall back to blank templates.

> **Universal spawn parameter — `gap_handling_mode` (2026-07-14).** `$GAP_HANDLING_MODE` is resolved once per run (orchestrator config resolution: `pipeline-preferences.json` → `gap_handling`; `disabled` when the value is `disabled` or empty, `enabled` otherwise — an absent key on an older config means `enabled`). **Every subagent spawn in this pipeline passes `gap_handling_mode=$GAP_HANDLING_MODE`, exactly like `CAREER_DATA` — every agent, every round, every re-spawn and crash-recovery fallback, no exceptions.** When `disabled`, no agent may produce, request, or enforce gap framing anywhere: the coach's outline and review carry no gap directives, the recruiter asks no writer to address a gap in a document, the gatekeeper's Gate 0 gap-handling keyword exception never applies, and no document acknowledges a gap (the letter-side never-name-the-gap rule applies regardless of mode). This is a one-word routing token — for the letter-writer it rides inside its input contract's routing-token allowance, never as content.

---

## Step 0.10 — Warm-up role selection (for batch runs of 2 or more roles)

**Only applies when the processing queue contains 2 or more roles.**

Before processing the full queue, identify the warm-up role — the first role to process. **Process the warm-up role to completion (through Step 4.5) before starting any other role in the batch — this mechanism only works serially.** The warm-up role's gatekeeper violations will be extracted and injected as pre-warnings into the cv-writer prompt for all remaining roles, reducing loops across the batch; there is nothing to extract yet if other roles are already running in parallel with it.

**Warm-up role selection logic:**
1. If any role in the queue has priority `Highest` — use the first one.
2. Otherwise, use the first `First` priority role in the queue.
3. If no `Highest` or `First` exists — use the first role in the queue regardless of priority.
4. Among ties, prefer {{USER_CITY}}/{{USER_COUNTRY}} location over remote.

**After the warm-up role completes Steps 1 through 4.5 (draft → gatekeeper → recruiter review → revision → gatekeeper):**

Extract recurring failure patterns from the gatekeeper violation logs. Specifically:
- Any tool name found in bullets (e.g., "ZoomInfo found in VL bullets")
- Any role missing RoleOverview (e.g., "[Company] missing RoleOverview") — **Detailed only; skip this pattern if the warm-up role's `CV Type` was `Brief`, since Brief never has RoleOverview at all and "missing" it is correct, not a violation**
- Any verb used 3+ times (e.g., "'Built' appeared 4 times")
- Any summary violation that repeated across loops

**Tag every extracted pattern with the warm-up role's `CV Type`.** Under `cv_type.mode: Variant`, a batch can mix Detailed and Brief roles — a Detailed-derived pattern (e.g. RoleOverview presence, Consulting-section placement) is meaningless or actively wrong if injected into a Brief-type role's prompt, and vice versa (Brief has no equivalent concept for several Detailed-only checks). Build the `known_issues` note per CV Type and inject only the patterns matching each subsequent role's own resolved `CV Type`:

> "Pre-warnings from role 1 ([CV Type] CV) gatekeeper logs: [list violations applicable to this CV Type]. Check for these specifically before returning your draft."

If the warm-up role's CV Type differs from a later role's, and no same-type pattern set has been extracted yet, skip the pre-warning for that role entirely rather than injecting a mismatched one — this mechanism is a helpful optimization, not a required input.

This is the only inter-role learning mechanism. It does not require agents to share state — the orchestrator extracts and injects the patterns explicitly.

---

### Step 0.pipe — Create the per-role pipeline directory

Before Step 1, create `<output_dir>/<company_dir>/_pipeline/` (the run's scratch area for intermediate text artifacts — reviewer feedback, revision logs, gatekeeper violations). Call this path `$PIPE`. On Path A use `mkdir -p`; on Path B create it through the host file tool (R-30). Every subagent below is given an exact `$PIPE/<file>.md` path to write to, and returns only a short status plus that path — never its full output (R-41). The orchestrator branches on the short status and, when a later step needs prior content, passes the path so that step reads it from disk. `_pipeline/` is intermediate only — it is not a deliverable and is not written to Notion.

### Step 0.pipe.5 — Capability check: `$PIPE` filesystem availability (once per run)

**Run this once, on the first role of the run — not per role.** Every step below assumes both the orchestrator and each spawned subagent can read/write the same `$PIPE/<file>.md` path (R-41's file-based handoff convention). That assumption doesn't hold in every environment — confirmed in a real run where no shared filesystem existed between the orchestrator and its subagents, forcing manual content relay that silently dropped custom-style annotation markup along the way (see the Absolute Constraints' manual-relay rule).

Immediately after `$PIPE` is created above, write a canary file `$PIPE/pipe-canary.md` (fixed sentinel content, e.g. `PIPE-CANARY-OK`) via whichever path (A or B) the orchestrator's *Mandatory path verification* already confirmed for this run. Then prepend this line to Step 1's very first `cv-writer` spawn of the run only:

> "Before anything else, attempt to Read `$PIPE/pipe-canary.md`. Your first returned line must be exactly `PIPE-CANARY: reachable` if you could read it, or `PIPE-CANARY: unreachable — <short reason>` if not. If unreachable, do not attempt to write `$PIPE/cv-draft.md` — return your full draft inline instead, prefixed `FULL-DRAFT-INLINE:`, so the orchestrator can relay it manually."

Cache the result as `$PIPE_FILESYSTEM_AVAILABLE` (true/false) for the rest of the run — do not re-check per role.

- **If available:** every `$PIPE`-file-path spawn instruction below works exactly as documented — nothing else changes.
- **If unavailable:** post one non-blocking chat message before continuing the rest of role 1 (do not wait for a reply):
  > "⚠️ This environment can't share files between me and the writing sub-agents (no `$PIPE` access) — I'll relay each draft's exact text between steps manually instead of pointing sub-agents at a shared file. This carries more handoff risk than the normal path, especially for CV/letter formatting markup, so I'm running the extra verification checks this adds. Continuing the run."

  For the rest of the run, every step below that would normally pass a `$PIPE/<file>.md` path to a subagent must instead relay that prior subagent's exact returned text, copied byte-for-byte, into the next subagent's prompt — never retyped, cleaned, reformatted, or summarized, including pandoc `:::`/`custom-style=` markup (Absolute Constraints' manual-relay rule). Apply the same `custom-style=`-count self-check used at Step 1.5's inline hand-fixes to every relay point too: count occurrences in the outgoing text and in the composed next prompt; a mismatch means stop and re-copy verbatim before proceeding, never patch around it.

### Step 0.data — Write role properties to `$PIPE/role-properties.md`

Immediately after creating `$PIPE`, write the role's Notion-sourced properties to disk before spawning any subagent. This file is the single on-disk record of role metadata for this pipeline run — it survives context compression and is available to every subagent in this role's pipeline as `$PIPE/role-properties.md`.

**Content to write:**

````markdown
# Role Properties — <Company> — <Role Title>

**Company:** <company name>
**Role title:** <role title>
**Strategy:** <IC / Strategic / Hybrid>
**Relationship type:** <Full time / Part time / Temporary / Fractional>
**Keywords:** <keywords string — tiered: Critical: ... | Important: ... | Nice-to-have: ...>
**Gap handling:** <value, or "disabled (empty)">
**Role summary (JD proxy):**
<full Role summary content — the compressed JD proxy including role context, key requirements, and self-characterization section verbatim if present>
````

**Write mechanics:** On Path A use the `Write` tool or `cat >` to write the file directly. On Path B (host-bridge MCP), use Desktop Commander `write_file` to create it host-side — same R-30 pattern as other `$PIPE/` writes.

### Step 0.type — Resolve CV Type (single resolution point)

Immediately after Step 0.data, resolve which CV format this role gets. This is the **only** place this pipeline reads `cv_type` config or the database for it — every downstream spawn (Steps 1, 1.5, 4, 4.5, and Step 6 export) reads the resolved value from `$PIPE/cv-type.txt`, never re-deriving it.

1. Read `pipeline-preferences.json` → `cv_type.mode` (career-data first, plugin blank template as last-resort fallback — same R-37 resolution order as every other config key). **A present-but-invalid value** (anything other than exactly `Detailed`/`Brief`/`Variant`) is treated the same as missing: try the next source; invalid everywhere → default `Detailed`, noted in config-health.
2. **`--now` mode:** no Notion row exists for this run (Pre-Step 5). If `mode` resolved to `Variant`, there is no per-role database field to read — default directly to `Detailed` and skip step 4 entirely (step 3 already only applies to non-Variant mode, so it never applied here in the first place — step 4 is the one that would otherwise attempt a database read).
3. If `mode` is `Detailed` or `Brief`, that is the resolved value — **the database backend is never consulted.**
4. If `mode` is `Variant` (and not `--now` mode), read this role's own `CV Type` field from the configured database backend (a single targeted read on this role's Page ID — delegate to the backend adapter, e.g. `notion-fetch` on this role's page, never re-describe the mechanics inline). **Distinguish a genuine empty field from a failed read:** empty/absent field on a successfully-read page → resolved value defaults to `Detailed`. A read that errors or can't reach the page at all → stop and report for this role ("could not read `CV Type` for [Company] — [error]") rather than silently defaulting; do not treat a tool failure as equivalent to an empty field.
5. **If the resolved value is `Brief`:** confirm `$CV_TEMPLATE_BRIEF` (`${CAREER_DATA}/references/templates/cv-brief.dotx`) exists now, before any drafting begins — fail fast rather than discovering the missing template only at Step 6 export, after a full draft/gatekeeper/revision cycle has already run. Missing → stop and report: "career-data is missing `references/templates/cv-brief.dotx` — run `/career-engine:setup --phase 5` to add it, or set `cv_type.mode` to `Detailed` for this role."
6. Write the resolved value (`Detailed` or `Brief`) to `$PIPE/cv-type.txt`.

### Step 0.titles — Write the role-tailoring plan to `$PIPE/cv-titles.md` (single resolution point)

Same design as Step 0.type: this is the **only** place this pipeline reads the role's `CV Titles` and legacy `CV Title Preferences` properties and the config's `role_matching` / `cv_title_rules`. Read the properties from this role's section of `$QUEUE_PIPE/role-properties.md` (never a fresh database fetch), the config keys from `pipeline-preferences.json` (absent = `capabilities` / none), and write:

````markdown
# Role-tailoring plan — <Company> — <Role Title>

MODE: <role_matching — `capabilities` or `titles`>

## CV Title Preferences (the user's own — outranks the plan line for the same employer)
<`cv_title_rules` lines first, one per entry: `<employer> — <keep | retitle-as "<title>"> [— <note>]`; then the legacy per-role property verbatim under a line `(legacy tracker field)`; or "none">

## CV Titles (the coach's plan, as the tracker holds it now — including any edits the user made)
<verbatim, or "PLAN: none">
````

Write `PLAN: none` when the property is empty, absent from the schema, or this is `--now` mode — the cv-writer then derives the plan itself (`writer-craft/cv.md` §5c) and the gatekeeper checks its titles against §5c's fixed limits instead of against a plan. **Never compose, repair, or summarize a plan here** — this step copies. **Every `cv-writer`, `gatekeeper` CV Check, and `recruiter-reviewer` spawn for this role passes `CV_TITLES_PATH=$PIPE/cv-titles.md`** alongside `CV Type`.

---

## CV Steps (1 through 4.5)

> **Step numbering:** the CV stages are Steps 1, 1.5, 2, 4, and 4.5. There is no Step 3 — the numbering skips it intentionally; "Steps 1 through 4.5" is the full CV range.

### Step 1 — CV writer (draft)

Spawn `cv-writer` with `option=draft`, passing:
- `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`
- `CV Type=<value from $PIPE/cv-type.txt, resolved at Step 0.type>` — read the file, never re-derive
- `CV_TITLES_PATH=$PIPE/cv-titles.md` — the role-tailoring plan (Step 0.titles); the writer executes it verbatim
- `Role summary` (the compressed JD proxy — contains role context, key requirements, and self-characterization section)
- The coach's output for this role: `Role emphasis`, `Keywords`, `Strategy`, `Role Type`, `Relationship type`, `Gap handling`
- `CV_PATH=$PIPE/cv-draft.md` — the writer writes the draft there and returns the path (R-41).

**Note:** `Role summary`, `Strategy`, `Keywords`, `Relationship type`, and `Gap handling` are also written to `$PIPE/role-properties.md` (Step 0.data). Subagents that need a lightweight reference to role metadata may read from that file instead of receiving the full content inline in every spawn prompt — **except the letter-writer, which is prohibited from reading `$PIPE/role-properties.md` (or any `$PIPE` file not named in its own spawn) under the 2026-07-14 letter-writer input contract (Step 5).**

### Step 1.5 — Gatekeeper (CV draft check)

Spawn `gatekeeper` with `option=cv`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md`, the CV path `$PIPE/cv-draft.md` to read, `Role summary`, the coach's `Keywords` property, and `OUTPUT_PATH=$PIPE/gatekeeper-cv-<round>.md`. The gatekeeper's ATS pre-check parses Keywords into tiers (Critical / Important / Nice-to-have) to verify coverage. It returns `PASS`, or `FAIL: <n> violations → <path>` (R-41).

**If PASS:** proceed to Step 2.

**If FAIL:** read the violation file at the returned path. If all violations are mechanical and unambiguous (swap two words, remove one phrase, reorder paragraphs — no creative judgment required) **and none of them touch text inside or immediately adjacent to a `::: {custom-style=...}` div or span** — a violation touching custom-style-wrapped text is never eligible for an inline hand-fix, no matter how small the wording change looks; it always goes through the cv-writer re-spawn below instead — apply them inline to `$PIPE/cv-draft.md`. **After applying any inline fix, verify the annotation markup survived: `grep -c 'custom-style=' $PIPE/cv-draft.md` before and after the edit, run on Path A directly in the orchestrator's own context (not a spawned subagent's); on Path B (sandbox Bash cannot reach the host file), run this same count through the host process tool discovered at preflight, against the host-side copy of `$PIPE/cv-draft.md` — never against a sandbox-local copy, which may not reflect the edit that was actually applied to the file the export step will convert. If the count dropped, the edit stripped annotation markup that should have been preserved — revert the edit and re-spawn `cv-writer` with `option=revision` instead (below), rather than proceeding with a CV that will export without its Word formatting.** (See the Absolute Constraints' "condensed process" anti-pattern — this carve-out exists because a real production run's inline hand-fixes silently stripped custom-style markup from two CVs.) If any violation requires cv-writer judgment (rewriting a bullet, resolving a fabrication flag), spawn `cv-writer` with `option=revision`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md`, `CV_PATH=$PIPE/cv-draft.md` (read and overwrite), the gatekeeper violation path, and the fix-log path `$PIPE/fix-log.md` (read and append). Locked-fixes instruction (see the orchestrator's Absolute Constraints): reintroducing a previously fixed violation is itself a FAIL, and a writer that reverts to an older base is re-spawned with the regression named — never patched by hand. After fix, spawn `gatekeeper` again with `option=cv`, using the same parameters as the Step 1.5 spawn above, including `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE` and `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md` (new `OUTPUT_PATH` round). Repeat until PASS. Do not surface this loop to the user — log violation rounds internally.

**Cap: 3 revision passes — but confirm the mechanical locked-fix checklist (Absolute Constraints) was actually re-verified each round before treating the cap as genuinely exhausted, not just re-flagged.** If the gatekeeper still returns FAIL after pass 3, this role is flagged here — per the Absolute Constraints' flag-and-deliver policy. Log all remaining violations under a `## Gatekeeper — Unresolved Violations (Step 1.5)` section in the revision log. **Stop the CV revision loop for this role and continue the pipeline with the best current CV as the working draft — the recruiter review, the letter track, and export ALL still run; the CV delivers flagged (md + DOCX always reach the output folder). This role's Notion status still advances at the writeback step, exactly like a clean role's (flag-and-deliver policy, 2026-07-17 amendment — the flag lives in halted-roles.json, the feedback file, and the chat addendum, never in a withheld status; withholding it just requeued the same roles run after run).** Write an entry to `$OUTPUT_DIR/halted-roles.json` now (Absolute Constraints — append discipline, exact entry shape, including `delivered_files` once export completes). This is what makes the flagged role reportable in the final chat delivery and run-metrics; naming it in chat with no persisted entry is not sufficient and does not satisfy this step. Continue processing every other role in the run's queue normally.

### Step 2 — Recruiter review (CV)

Spawn `recruiter-reviewer` with `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md` (required — Brief's intentional structural absences must not be flagged as weaknesses; see the agent's own CV Type awareness section), `Role summary`, the CV path `$PIPE/cv-draft.md` to read, and `OUTPUT_PATH=$PIPE/recruiter-cv.md`. It writes its full review there and returns a 2-line status (R-41).

### Step 4 — CV writer (revision)

Spawn `cv-writer` with `option=revision`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md`, `CV_PATH=$PIPE/cv-final.md` (write), the draft path `$PIPE/cv-draft.md`, and the recruiter review path `$PIPE/recruiter-cv.md` to read. The writer also writes the CV CHANGES section to `$PIPE/cv-changes.md` and returns the paths (R-41). Step 7d reads `$PIPE/cv-changes.md` for the feedback file.

If any recruiter flag identifies a skill or credential gap the user does not have — do not address it. IT SHOULD BE COMPLETELY OMITTED. Reframing, surfacing, and reordering are permitted; fabrication and scope-hedging ARE ABSOLUTELY PROHIBITED.

**Immediately after Step 4 returns — stage the revised CV markdown and the revision log for export and crash recovery before spawning the gatekeeper.** Context compaction can interrupt between any two steps, and disk is the only reliable recovery path. The writer has already written `$PIPE/cv-final.md` and `$PIPE/cv-changes.md` (R-41); copy them into place:

```bash
# CV markdown that pandoc consumes in Step 6
cp "$PIPE/cv-final.md" /tmp/<cv_filename>.md
# crash-recovery backup in the company subdir
cp "$PIPE/cv-final.md" "<output_dir>/<company_dir>/<cv_filename>.md"

# revision log, built from the writer's CV CHANGES file
{ echo "# Revision Log — <Role Title> at <Company> — <YYYY-MM-DD>"; echo; echo "## CV Changes"; cat "$PIPE/cv-changes.md"; } \
  > "<output_dir>/<company_dir>/revision-log-<roletitle>-<company>-<monYYYY>.md"
```

### Step 4.5 — Gatekeeper (CV final check)

Spawn `gatekeeper` with `option=cv`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md`, the CV path `$PIPE/cv-final.md` to read, `Role summary`, the coach's `Keywords` property, and `OUTPUT_PATH=$PIPE/gatekeeper-cv-<round>.md`.

**If PASS:** proceed to Step 5.

**If FAIL:** spawn `cv-writer` with `option=revision`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md`, `CV_PATH=$PIPE/cv-final.md` (read and overwrite), the gatekeeper violation path, and the fix-log path `$PIPE/fix-log.md` (read and append). Locked-fixes instruction (see the orchestrator's Absolute Constraints): reintroducing a previously fixed violation is itself a FAIL, and a writer that reverts to an older base is re-spawned with the regression named — never patched by hand. After revision, re-copy `$PIPE/cv-final.md` to `/tmp/<cv_filename>.md` and the output backup path before spawning `gatekeeper` again with `option=cv`, using the same parameters as the Step 4.5 spawn above, including `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE` and `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md` (new `OUTPUT_PATH` round). Repeat until PASS. Log all violation rounds internally.

**Cap: 3 revision passes — but confirm the mechanical locked-fix checklist (Absolute Constraints) was actually re-verified each round before treating the cap as genuinely exhausted, not just re-flagged.** If the gatekeeper still returns FAIL after pass 3, this role is flagged here — per the Absolute Constraints' flag-and-deliver policy. Log all remaining violations under a `## Gatekeeper — Unresolved Violations (Step 4.5)` section in the revision log. **Stop the CV revision loop for this role and continue the pipeline with the best current CV as the final CV — the letter track and export ALL still run; the CV delivers flagged (md + DOCX always reach the output folder). This role's Notion status still advances at the writeback step, exactly like a clean role's (flag-and-deliver policy, 2026-07-17 amendment — the flag lives in halted-roles.json, the feedback file, and the chat addendum, never in a withheld status; withholding it just requeued the same roles run after run).** Write an entry to `$OUTPUT_DIR/halted-roles.json` now (Absolute Constraints — append discipline, exact entry shape, including `delivered_files` once export completes). This is what makes the flagged role reportable in the final chat delivery and run-metrics; naming it in chat with no persisted entry is not sufficient and does not satisfy this step. Continue processing every other role in the run's queue normally.

---

## Cover Letter Steps (5 through 5.95)

The cover letter receives the **final revised CV** as input. letter-writer uses it to ensure the letter and CV tell a coherent story and the letter adds something the CV cannot.

### Pre-Step 5 — Cover letter content inputs

**Skip in `--now` mode** — no Notion row exists.

Read the following from Notion for this role:

**Why I Want This Role property** — the user's written motivation for this role, filled in manually in Notion (it may also carry intake's `[LETTER OUTLINE` block — legacy rows: `[COACH LETTER PLAN` — Step 4.99 extracts and strips that block before any downstream use; "WIWTR content" everywhere below means the stripped text; rows intaken before 2026-07-23 may also carry a legacy coach-context or `[COACH PROMPTS` block, handled exactly as before). If populated, pass the full content to the letter-writer as the role-specific content input. **Why I Want This Role is NOT required to produce a letter** — the letter-writer's primary source is the Motivation Bank (`background/background-motivation-bank.md`), and the letter-writer itself decides whether it has enough to write.

**Always proceed to Step 5 and spawn the letter-writer for this role — whether or not Why I Want This Role is populated.** Pass the Why I Want This Role value if present; if empty, pass it empty and let the letter-writer's **Sufficiency Gate** decide (write from the role-matched Motivation Bank entries, or skip). **Do NOT pre-skip the letter on an empty Why I Want This Role** — that decision belongs to the letter-writer now.

**WIWTR is never a run blocker, in any state (2026-07-16, per the user's direct instruction — a real run stopped at role start to demand her answers to the coach's questions; it should not have).** A WIWTR that is empty, or that still contains unanswered `[COACH PROMPTS` questions, is a NORMAL, fully-supported input state — pass it through exactly as found and keep going. Do not stop to ask the user to answer the prompts, do not frame the run as "ready except for" WIWTR, and do not treat proceeding as a fabrication risk: anti-fabrication is preserved by the Motivation Bank path (her real, verbatim words), not by halting. The letter-writer's Option A pre-check already detects unanswered prompts and routes to the Bank. **This is by design, not a degraded mode:** the system's goal is for career-data to carry more of every letter over time — the Bank grows via the WIWTR promotion loop (Step 7f / edit E10.5) — so per-role user input becomes less necessary, not more. A run that produces a Bank-only letter she can react to beats a run that stops to assign her homework; she can always add WIWTR and re-run.

**If the letter-writer returns a skip status** (it judged there was no Why I Want This Role content and no role-relevant Motivation Bank material): this is not an error. Deliver the CV only for this role, log "Letter skipped — [reason returned by the writer]", and surface the writer's message to the user (it tells her to add Why I Want This Role or enrich the Motivation Bank). **This applies only to this role** — continue processing other roles normally.

---

### Step 4.9 — Voice calibration (resolve)

Read `${CAREER_DATA}/references/voice-calibration-coverletters.md` directly — no agent spawn.

- **If it exists:** copy its content to `$PIPE/voice-calibration.md`. Proceed to Step 5.
- **If it does not exist** (new user, or the user has not yet applied the update-prompt that delivers it): this is not an error — do not hard-stop. Proceed to Step 5 without creating `$PIPE/voice-calibration.md`. The letter-writer falls back to its standalone Voice Gate (read the delivered-letters archive directly, or `03-framework.md` §Voice and tone if the archive is also empty; the humanizer was retired 2026-07-26).

**Either way, the letter-writer ALSO reads real letters from the delivered-letters archive at its Voice Gate (restored 2026-07-16, per the user's direct instruction; the humanizer was retired 2026-07-26).** The calibration file is a supplement to the archive, never a substitute — do not describe it to any spawned agent as making the archive read unnecessary.

---

### Step 4.95 — Capability preflight (once per run)

**Run this once, on the first role of the run — not per role.** Check whether this environment can resume a sub-agent instance across multiple spawns (the mechanism Steps 5, 5.2, and 5.95 below rely on to keep talking to the same letter-writer — and the career-coach only on Step 4.99's legacy-WIWTR fallback — across a role's revision rounds instead of hiring a fresh one every round). Cache the result as `$SENDMESSAGE_AVAILABLE` (true/false) for the rest of the run — do not re-check per role or per revision round.

- **If available:** every "resume" instruction below (letter-writer and career-coach) reuses the same cached instance across all touchpoints for that role.
- **If unavailable:** log it plainly, once — "this environment can't reuse sub-agents; every revision spawns a fresh writer/coach with full context instead" — and every "resume" instruction below falls back to a fresh spawn with full accumulated context, for the rest of the run, without rediscovering the same fact on every role.

### Step 4.99 — Letter plan (from intake's Letter Outline; coach spawn is fallback only)

**Primary path — no coach spawn (2026-07-22, per the user's instruction: "during intake is when the coach should enter into WIWTR the actual outline + opener that is recommended ... This means the coach doesn't need to be in the application pipelines anymore").** Take the Why I Want This Role content from the Pre-Step 5 read and look for a `[LETTER OUTLINE` ... `[/LETTER OUTLINE]` block — or, on rows intaken before the 2026-07-23 rename, the legacy `[COACH LETTER PLAN` ... `[/COACH LETTER PLAN]` markers, handled identically — (written by intake Step 0.9a Write C; the user may have edited any line of it in Notion — **the user's edits are authoritative and are never second-guessed**). If present:

1. Write the block's `Template:` value to `$PIPE/template-selection.txt` — the single token, nothing else.
2. Write the block's `Opener:` line when present (2026-07-24 — the coach's verbatim bank-variant copy; older blocks lack it), followed by its `Para N:` outline lines, to `$PIPE/coach-outline.md`. **A legacy `Opener anchor:` line (blocks written 2026-07-22 → 2026-07-24, before the anchor's retirement) is DROPPED — never copied into `coach-outline.md` and never read for content** (retired 2026-07-24, per the user's direct instruction; it was the confirmed injection vector for coach-composed prose).
3. **Strip the block (markers included) from the WIWTR content.** Every downstream use of "Why I Want This Role content" in this pipeline — the letter-writer's content input, Gate 2 coverage, Step 7f promotion — means the STRIPPED version (the user's motivation text only). The plan block never reaches the letter-writer as motivation material.

**Fallback — legacy rows only:** if the WIWTR contains neither a `[LETTER OUTLINE` nor a legacy `[COACH LETTER PLAN` block (the role was intaken before 2026-07-22), spawn `career-coach` with **Option 4a — Pre-Draft Outline** (the agent dispatches by this literal heading name — never a slug-style `option=` value, unlike the gatekeeper), passing:
- `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`
- `Role summary`, `Strategy`, `Keywords` (from the coach's Step 0.8 output)
- Why I Want This Role content (from the Pre-Step 5 read) — pass verbatim
- `Gap handling` property
- Company name and role title
- The user's `references/templates/cover_letter_templates.md` if present (career-data path); note its absence explicitly if not

The coach writes `$PIPE/template-selection.txt` and `$PIPE/coach-outline.md` (first line `Opener: <...> (variant <n>)` per the Option 4a output contract — no `Opener anchor:` line, retired 2026-07-24) and returns `COACH-OUTLINE: template=<selection> → $PIPE/template-selection.txt, outline written → $PIPE/coach-outline.md` (R-41). Log in the role's delivery: "Letter plan generated in-pipeline (legacy WIWTR — re-run intake to move letter planning into Notion review)." When `$SENDMESSAGE_AVAILABLE`, capture the returned agent ID to `$PIPE/coach-agent-id.txt` (crash-recovery reuse only — the Step 5.3 coach review no longer exists).

Read `$PIPE/template-selection.txt` after this step — its value is threaded into the gatekeeper spawns at Steps 5.2 and 5.95 below as `Template selected=<value>`, for Gate 9. The letter plan `$PIPE/coach-outline.md` (Opener line + outline; no anchor since 2026-07-24) is likewise passed to those same gatekeeper spawns for the opener source check and Gate 9 outline conformance.

### Step 5 — Cover letter (draft)

**Before spawning letter-writer:** Read `${CAREER_DATA}/references/background/background-role-facts-<company>.md` for the user's role facts for this company — key proof points the letter-writer can draw from naturally rather than assembling pre-written paragraphs. Derive `<company>` from the company name in the Notion role record, slugified: lowercase, spaces and punctuation to hyphens (e.g., "Visit TLV" → `background-role-facts-visit-tlv.md`). If the file does not exist for this company, note it in the spawn context: "No pre-documented role facts file found for this company — letter-writer draws from the Motivation Bank, framework, and WIWTR only."

**Before spawning, pass the following for this role:**
- **Why I Want This Role property** — use the value retrieved in Pre-Step 5. Do not re-read from Notion.
- **Role emphasis** property — from the career coach (Step 0.8 output). The role's Mandate / Likely KPIs — the ONE piece of coach analysis the writer receives.
- **Strategy** property — from the career coach. A single routing token (`IC`/`Strategic`/`Hybrid`) governing letter type and word ceiling only — never content.

**Priority rule:** the **Motivation Bank** (`background/background-motivation-bank.md`, loaded by the letter-writer from career-data) is the primary content source; **Why I Want This Role** is the role-specific source on top of it **when present**. Strategy provides the letter type only — it does not govern content selection.

**⛔ Letter-writer input contract (2026-07-14) — three content inputs, nothing else.** The letter-writer receives exactly three content-bearing inputs: the **final CV**, **`Role emphasis`**, and **`Why I Want This Role`** — plus the coach's pre-draft outline `$PIPE/coach-outline.md` (structural spine — bare paragraph subjects, restored as writer input 2026-07-16 per the user's direct instruction; structure only, never a content source), company name + role title (identity), the `Strategy`, `gap_handling_mode`, and template-selection routing tokens, `$PIPE/voice-calibration.md` (her own career-data material), and on revision rounds the violation/review files about its own letter. It NEVER receives, under any framing: `Role summary`, `Landscape`, `Culture`, `Keywords`, `Gap handling` property content (the one-word `gap_handling_mode` token is routing, not content), `Relationship type`, `JD Body` or any JD text, the recruiter review, `$PIPE/coach-output.md`, or `$PIPE/role-properties.md`. This is a per-user directive after a real shipped batch recited pipeline research (org size, acquisition history, coach analysis) back at the reader — the writer aims with Role emphasis and writes from her material; everything else the pipeline knows stays out of its context.

**Include this verbatim at the front of the letter-writer prompt:**
> STRUCTURE IS NON-NEGOTIABLE. Regardless of any reviewer feedback you receive, the letter structure defined in `skills/letter-core/SKILL.md` must be observed in full — in particular the tone, voice, and content of the opening paragraph. Reviewer feedback informs what proof to include or emphasise; it does not change how the letter is structured or how the opening is written.

Spawn `letter-writer` with `option=cover-letter`, passing exactly the input contract above:
- `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`
- `LETTER_PATH=$PIPE/letter-draft.md` — the writer writes the draft there and returns the path (R-41)
- The **final revised CV** path `$PIPE/cv-final.md` to read (content input 1 — for CV/letter coherence and the no-repetition rule)
- **`Role emphasis`** from the coach's Step 0.8 output (content input 2 — the role's ranked jobs-to-be-done bullets and Likely KPIs bullets; the writer's only role-analysis input)
- **Why I Want This Role** from Notion (read above; content input 3) — include verbatim if populated (the letter-writer loads its primary source, the Motivation Bank, from career-data itself). If empty, pass it empty — the letter-writer's Sufficiency Gate decides write-or-skip.
- Company name and role title
- **Strategy** (routing token — letter type + word ceiling only)
- The coach's **template selection** (`$PIPE/template-selection.txt`) from Step 4.99 — a single token; the writer no longer chooses the template itself.
- The coach's **outline** (`$PIPE/coach-outline.md`) from Step 4.99 — the writer's structural spine (restored 2026-07-16); bare paragraph subjects, structure only.

**Do not pass anything else** — no `Role summary`, no `Gap handling` property content (the `gap_handling_mode` token is already in the list above), no `Relationship type`, no recruiter review (its "Interview-trigger gaps" section is user-facing interview-prep feedback surfaced in Step 7d's feedback file, not letter material). See the input contract above.

**Capture the returned agent ID** and write it to `$PIPE/letter-writer-agent-id.txt`. This is the one instance that gets resumed — never re-spawned fresh — for every subsequent letter-writer touch on this same letter (Steps 5.2, 5.3, 5.95 below). See the resume rule immediately below.

> **⛔ Resume, don't respawn — applies to every "spawn letter-writer with option=revision" instruction for this letter, anywhere below (Steps 5.2, 5.3, 5.95).** A fresh subagent has no memory of what it already tried or why — this is precisely how a real production run took 4 gatekeeper rounds on one letter: fixing "role in sentence 1" broke "subject-first," and a fresh, memoryless writer fixing *that* produced a banned cliché neither rule caught. Instead: read `$PIPE/letter-writer-agent-id.txt` and resume that exact instance (send it a new message; do not spawn a new one) with a prompt scoped to *only* the new feedback — "Gatekeeper/coach found these issues: [violations]. Fix only these — leave everything else exactly as it is." The resumed instance still retains its own R-41 output contract (write to `$PIPE`, return a 1-line status) — nothing about resuming changes what the orchestrator holds in its own context. **If `$PIPE/letter-writer-agent-id.txt` is missing or the resume fails** (e.g. crash-recovery restart): fall back to a fresh `option=revision` spawn — **"full context" means every input the original Step 5 draft spawn received (`CAREER_DATA`, the final CV path, `Role emphasis`, Why I Want This Role, company name + role title, `Strategy`, the template selection token AND the coach outline `$PIPE/coach-outline.md` from Step 4.99 — exactly the input contract above, nothing more) plus the current draft at `$PIPE/letter-draft.md` and every accumulated violation/feedback file (`$PIPE/fix-log.md` and any gatekeeper/coach review files produced so far) — not the draft and feedback alone**, since a fresh instance has none of the resumed instance's memory and must reconstruct the same grounding the original spawn had. A crash-recovery respawn never widens the contract — `Role summary`, `Gap handling`, and the recruiter review stay out here exactly as they do at Step 5 (the coach outline is IN — it is part of the Step 5 contract since 2026-07-16). Capture and overwrite the agent-ID file with the new instance.

### Step 5.2 — Gatekeeper (cover letter draft check)

Spawn `gatekeeper` with `option=cover-letter`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, the cover letter path `$PIPE/letter-draft.md` to read, `Role summary`, `Strategy` (the coach's Step 0.8 output — governs the word-count ceiling: 250 instead of 320 when `Strategic`), the user's Why I Want This Role content (from the Pre-Step 5 read), the final CV path `$PIPE/cv-final.md` to read (required for the CV-repetition check; if no CV exists for this role — including in `--now` mode where no CV pipeline ran — state that explicitly so the gatekeeper reports the skipped check by name; do not pass a path that doesn't exist), `$PIPE/opener-derivation.txt` to read if it exists (the letter-writer's opener-derivation record, for Gate 5's derivation check — the letter-writer writes it at drafting), `$PIPE/wiwtr-checklist.md` to read if it exists (the letter-writer's numbered [WIWTR-N] point list, for Gate 2's coverage check — omit this parameter entirely if the file wasn't written, i.e. Why I Want This Role was empty this run), `Template selected=<value read from $PIPE/template-selection.txt at Step 4.99, or omit if that file was absent>`, and `OUTPUT_PATH=$PIPE/gatekeeper-cl-<round>.md`. The Why I Want This Role content allows the gatekeeper to apply the personal-content exemption correctly — see the exemption rule at the top of Cover Letter Check in `gatekeeper-checks/SKILL.md`.

**If PASS:** proceed to Step 5.3. On round 2+ the gatekeeper's own reply may carry a Tier 2 deferred note — a normal round-aware PASS (Tier 1 clean, Tier 2 below 70% but no longer blocking past round 1), not an error; log the failing check types in the revision log and the role's feedback file (humanizer retired 2026-07-26 — these are user-visible notes now). When it carries that deferred note, log the failing Tier 2 check types (read from the gatekeeper's `OUTPUT_PATH`) under `## Gatekeeper — Tier 2 Deferred to Humanizer (Step 5.2)` in the revision log; the humanizer handles them from there.

**If FAIL — round 1:** **resume the letter-writer instance** (see the resume rule at Step 5 — do not spawn fresh), passing `LETTER_PATH=$PIPE/letter-draft.md` (read and overwrite), the gatekeeper violation path, and the fix-log path `$PIPE/fix-log.md` (read and append). Locked-fixes instruction (see the orchestrator's Absolute Constraints): reintroducing a previously fixed violation is itself a FAIL, and a writer that reverts to an older base is re-spawned with the regression named — never patched by hand. After revision, spawn `gatekeeper` again with `option=cover-letter` (same parameters as the Step 5.2 spawn above, including `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE` and `Strategy`; new `OUTPUT_PATH` round). Log all violation rounds internally.

**If FAIL — round 2+:** this only occurs when a Tier 1 check still fails (Tier 2 alone never blocks past round 1 — see the PASS case above). Loop as above. Hard/Tier 1 fails block every round.

**Cap: 3 revision passes on hard fails — but confirm the mechanical locked-fix checklist (Absolute Constraints) was actually re-verified each round before treating the cap as genuinely exhausted, not just re-flagged.** If the gatekeeper still returns hard-fail violations after pass 3, this role is flagged here — per the Absolute Constraints' flag-and-deliver policy. Log all remaining violations under a `## Gatekeeper — Unresolved Violations (Step 5.2)` section in the revision log. **Stop the revision loop for this role and skip the remaining quality steps — proceed DIRECTLY to this pipeline's export step with the best current text and deliver it flagged (the md and DOCX always reach the output folder). This role's Notion status still advances at the writeback step, exactly like a clean role's (flag-and-deliver policy, 2026-07-17 amendment — the flag lives in halted-roles.json, the feedback file, and the chat addendum, never in a withheld status; withholding it just requeued the same roles run after run).** Write an entry to `$OUTPUT_DIR/halted-roles.json` now (Absolute Constraints — append discipline, exact entry shape, including `delivered_files` once export completes). This is what makes the flagged role reportable in the final chat delivery and run-metrics; naming it in chat with no persisted entry is not sufficient and does not satisfy this step. Continue processing every other role in the run's queue normally — if this role already produced a passing CV, that CV's own delivery is unaffected; only the cover letter (and the role's overall "done") is blocked.

### Step 5.3 — Strategic conformance (coach review removed 2026-07-22)

The per-role coach review that ran here was removed per the user's instruction ("the coach doesn't need to be in the application pipelines anymore at all"). Strategic conformance is enforced by the gatekeeper's Cover Letter Check, which Step 5.2 already ran on this letter: the opener source check verifies the opener's derivation matches the plan's `Opener:` variant (or logs a substitution reason; the opener-anchor conformance check was retired with the anchor, 2026-07-24), and Gate 9 verifies the letter follows the plan's outline — the plan being user-approved at intake is a stronger authority than a mid-pipeline coach opinion was. **Spawn nothing here.**

Entry condition unchanged: this point is reached only after Step 5.2's genuine PASS. Step 5.2's cap-exhaustion path routes directly to Step 6 (the humanizer is retired) export, delivered flagged per the Absolute Constraints' flag-and-deliver policy.

After this step, copy `$PIPE/letter-draft.md` to `$PIPE/letter-final.md`, `/tmp/<cl_filename>.md`, and the output backup path:

```bash
cp "$PIPE/letter-draft.md" "$PIPE/letter-final.md"
cp "$PIPE/letter-draft.md" /tmp/<cl_filename>.md
cp "$PIPE/letter-draft.md" "<output_dir>/<company_dir>/<cl_filename>.md"
```

---

### Step 5.9 — Humanizer — RETIRED (per the user's direct instruction, 2026-07-26: "The only thing humanizer seems to actually effectively be doing is taking semi and/or non-slop and turning it into its own version of slop. Not helpful. give the gatekeeper the quantitative checks and get rid of humanizer")

**No humanizer pass runs. Ever.** The letter that passed Step 5.3 is the final text — no agent edits it after its last gatekeeper PASS. The humanizer's Quantitative Final Gate did not die with it: its checks are now **Gate 10 — Quantitative voice metrics** in the Cover Letter Check (`skills/gatekeeper-checks/letter-gates.md`), run mechanically by the gatekeeper in the Step 5.2 rounds, with violations routed to the letter-writer like any other Tier 2 item — her voice is fixed by the writer from her bank, never by a post-hoc editing agent. Copy `$PIPE/letter-final.md` to `/tmp/<cl_filename>.md` and the output backup path, then proceed to Step 5.95.

### Step 5.95 — Final verification on the exported bytes

With the humanizer retired (per the user's direct instruction, 2026-07-26: "The only thing humanizer seems to actually effectively be doing is taking semi and/or non-slop and turning it into its own version of slop. Not helpful. give the gatekeeper the quantitative checks and get rid of humanizer"), no agent has touched the text since its Step 5.3 gatekeeper PASS — so no fresh gatekeeper spawn is needed here. Run the mechanical pre-export checklist on the **exact saved markdown** that Step 6 will convert:

1. **Mechanical pre-export checklist** — run directly, no subagent, using Bash in the orchestrator's own context (not a spawned subagent's) on Path A. **On Path B (sandbox Bash cannot reach the host file), run these same checks — `wc -w`, and the grep batteries below — through the host process tool (e.g. `start_process`) discovered at preflight, against the host-side copy of `$PIPE/letter-final.md`, never against a sandbox-local copy that may not reflect the humanizer's actual edits.** The guarantee this step exists for (a mechanical count independent of subagent self-reporting) holds on either path only if the count runs against the real file the export step will actually convert. On the letter body (ignore pandoc fence lines starting `:::` and `{custom-style=...}` attributes):
   - Company name appears in the first body paragraph (stealth roles: the JD descriptor satisfies this).
   - Role title appears somewhere in the body.
   - Zero em dashes (`—`) and zero colons in body text.
   - Zero hits for the named banned patterns: "I know this", "that's where", "that's what", "that's the kind", "that exact", "exactly that", "this same", "serves as", "stands as", "acts as"; also grep "the same" — a hit fails only when it points at an agent-coined abstraction ("the same engine"), not in benign uses ("the same week").
   - **Word count ≤ 320, or ≤ 250 if this role's `Strategy = Strategic` — via `wc -w` on the body text, run here directly, not delegated.** A confirmed real production run had every gatekeeper-subagent round report no Bash tool available in that environment and substitute a hand-estimate instead — wrong by 10-45 words every time, shipping letters at 322 and 330 words despite the gatekeeper's own reported PASS. This orchestrator-level count is the guaranteed-mechanical enforcement of the cap; it does not defer to whatever the gatekeeper subagent already reported.
   - **Gate 6 Tier 1 banned-vocabulary/phrase/fit-declaration hit — run the same grep battery named in `skills/gatekeeper-checks/letter-gates.md` → Gate 6's Tier 1 section (curated cliché/vague-filler list, AI-vocabulary list, cover-letter-only phrase bans, fit-declaration family) directly against this exact text.** Apply the personal-voice exemption (`skills/writer-craft/SKILL.md` §2 — check the delivered-letters archive / `01-writing-rules.md` first) before treating any hit as real. A confirmed hit is a Tier 1 violation, handled the same as any other item in this checklist.
   - **Round-snapshot presence (2026-07-26 — a real run kept no per-round history, leaving the round-1 opener unrecoverable):** if any revision round ran for this letter (a round-2 gatekeeper file `gatekeeper-cl-2.md` exists in `_pipeline/`), at least one `letter-draft-round-<n>.md` snapshot must exist there too (Absolute Constraints, numbered-snapshot rule). Missing snapshots are logged as a process violation in the revision log — not a delivery blocker, but never silent.
   - **Opener verbatim check (2026-07-24 — a real run's gates ordered a rewrite of the user-reviewed `Opener:` line and the writer obeyed):** if `$PIPE/coach-outline.md` carries an `Opener:` line with no `{...}` placeholders remaining, mechanically confirm (normalized for whitespace and typographic quotes) that the letter's opening contains that text verbatim — unless `$PIPE/opener-derivation.txt` logs a `no-variant-because:` reason. A mismatch with no logged reason is a Tier 1 violation, handled like any other item here — the user reviewed that exact sentence in Notion; the pipeline does not ship a different one silently. **The pasted Opener span is EXCLUDED from every other item in this checklist** (the banned-pattern greps, the Gate 6 Tier 1 battery — a hit inside her reviewed sentence is exempt, per letter-gates' Opener precedence rule; the word count still covers the whole body).

**If all pass:** proceed to Step 6. **If any item fails** (would mean the Step 5.3 PASS was wrong, or the file on disk is not the passing text): **resume the letter-writer instance** (see the resume rule at Step 5 — do not spawn fresh) with the specific failures named, then re-run this step. Cap: 2 rounds. **After the cap:** this role is flagged — per the Absolute Constraints' flag-and-deliver policy. Log the failure, proceed DIRECTLY to export with the best current text and deliver it flagged (the md and DOCX always reach the output folder; Notion status still advances at writeback — the flag lives in `halted-roles.json`, the feedback file, and the chat addendum). Write the `$OUTPUT_DIR/halted-roles.json` entry now. Continue every other role normally.

**Sync the passing bytes to the export path — on EVERY exit from this step, before Step 6 runs.** Any retry edits `$PIPE/letter-final.md` in place, so re-copy the authoritative final letter to `/tmp/<cl_filename>.md` and the output backup after verification passes — Step 6 must convert exactly the verified bytes.

## Step 6 — Produce DOCX

**Before executing this step:** confirm `career-engine-export` is loaded. If it is not already in context, load it now — read `skills/career-engine-export/SKILL.md` before proceeding. Do not execute Step 6 without it.

Both the CV and the cover letter are now final markdown files saved to `/tmp/`. Convert both to `.docx` using pandoc with the `.dotx` reference templates. Run bash directly — no agent spawn needed. **On Path B (host-bridge MCP — see the orchestrator's Mandatory path verification, R-30), run these commands through the host process tool instead, with intermediate markdown written host-side rather than to sandbox `/tmp/`.**

**Read `$PIPE/cv-type.txt` (resolved at Step 0.type) before invoking the export protocol below — this is what the export skill's Step 6 conditional (`$CV_TEMPLATE` vs. `$CV_TEMPLATE_BRIEF`) branches on.** Per Step 0.type, Step 6 is one of the named downstream consumers of this file; it is not re-derived here.

Follow the `career-engine-export` skill's Step 6 production protocol exactly — it is the single authoritative source for pandoc commands, script paths, subtitle update, and verification. Do not substitute your own abbreviated steps. Both files must exist and be nonzero in the output folder before proceeding to Step 7.

**Subtitle argument:** Pass the exact role title from the JD as the subtitle argument to `update-subtitle.py` — the job title the user is applying for (e.g., "[Role Title from JD]"). This is the ONLY text that should appear in the subtitle slot under the user's name. Do not pass a generic descriptor, the user's background framing, or anything not directly taken from the JD role title field.

---

## Step 6H — Additional language localization (conditional)

**Skip in `--now` mode** — no Notion row exists, so there is no `Languages` property to read. Produce output in `$DEFAULT_LANGUAGE` only and proceed to Step 7.

**Language resolution rule — apply before deciding whether to run this step:**

1. Read the `Languages` property from this role's Notion row — the one the orchestrator/queue pipeline already fetched upstream and holds in memory. Do not re-fetch.
2. **If `Languages` is empty or not set:** produce output in `$DEFAULT_LANGUAGE` only. Skip this step entirely and proceed to Step 7.
3. **If `Languages` is populated:** produce output in every listed language. The `$DEFAULT_LANGUAGE` output has already been produced in Steps 1–5.95. This step handles all additional languages listed in `Languages` beyond the default.

**Hebrew localization — runs only if `Languages` explicitly includes `Hebrew`** (i.e. the `Languages` property is non-empty and `Hebrew` is one of its values). If `Hebrew` is not listed, skip Hebrew localization even if other non-default languages are listed.

**Guard — Hebrew CV export requires `CV Type=Detailed` for this role.** Hebrew CV export uses the fixed `$CV_TEMPLATE_HE` (`cvHe.dotm`) template, which is built for the Detailed CV's structure — no Brief-format Hebrew template exists yet. If `$PIPE/cv-type.txt` (resolved at Step 0.type) is `Brief` and this role's `Languages` includes `Hebrew`: **stop the CV-side Hebrew export for this role and report it** — "Hebrew export for [Company] skipped: Brief CV Type has no Hebrew template yet (`cvHe.dotm` is Detailed-only). English Brief CV proceeds normally; add a Hebrew Brief template to career-data to enable this, or set this role's CV Type to Detailed." The Hebrew **cover letter** is unaffected by this guard (its template, `he-letter.dotx`, doesn't vary by CV Type) and proceeds normally.

### 6H.1 — Spawn Hebrew localization agent

Spawn `localization` with:
- `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`
- The final English CV markdown (read from `$PIPE/cv-final.md`)
- The final English cover letter markdown (read from `$PIPE/letter-final.md`)
- The structured JD — the same in-memory JD the queue pipeline fetched in Step 0.5 and passed through Steps 1–5. On a crash-recovery resume where that in-memory JD is no longer available, omit it: the localization agent translates from the on-disk English markdown above (the authoritative source content) plus the role title below — the structured JD is supplementary context, not required.
- The exact role title from the JD — on a resume where the in-memory value is gone, recover it from the `<roletitle>` slug in the staged English filenames / `<company_dir>` (the same slug Step 4 wrote to disk).

The agent returns a Hebrew CV markdown block and a Hebrew cover letter markdown block.

### 6H.2 — Export Hebrew DOCX files

Write the Hebrew markdown files to `/tmp/` **and** copy them to the output folder:

```bash
cat > /tmp/he-<cv_filename>.md << 'MARKDOWN_EOF'
<Hebrew CV markdown from agent>
MARKDOWN_EOF

cat > /tmp/he-<cl_filename>.md << 'MARKDOWN_EOF'
<Hebrew cover letter markdown from agent>
MARKDOWN_EOF

# Copy Hebrew markdown files to output folder — required, same as English markdown files
cp /tmp/he-<cv_filename>.md "<output_dir>/"
cp /tmp/he-<cl_filename>.md "<output_dir>/"
```

**Hebrew template existence check — before any conversion.** `$CV_TEMPLATE_HE` (`cvHe.dotm`) and `$CL_TEMPLATE_HE` (`he-letter.dotx`) are fixed career-data paths, but a user whose `Languages` includes Hebrew may still never have supplied them. Confirm both exist (and, when `cv_footer.inject` is true, that `$CV_FOOTER_HE` exists). If any required file is missing: **skip Hebrew export for this role and report it** — "Hebrew export for [Company] skipped: career-data is missing `references/templates/cvHe.dotm` / `he-letter.dotx` (or `references/static-cv-footer-he.md`) — run `/career-engine:setup --phase 5` to add them." The English delivery for this role is unaffected; log the skip in the run-level revision log and continue. Never run pandoc against a missing `--reference-doc` and let the raw error surface as the report.

Convert using the Hebrew DOCX production protocol from `career-engine-export`:

```bash
# $CV_TEMPLATE_HE, $CL_TEMPLATE_HE, and $CV_FOOTER_HE already resolved (fixed career-data paths, no config key)
# $CV_FOOTER_HE is empty when cv_footer.inject is false -- skip the footer append entirely in that case

# Hebrew CV — concatenate with Hebrew footer (if injecting), then convert
if [ -n "$CV_FOOTER_HE" ]; then
  cat /tmp/he-<cv_filename>.md \
      "$CV_FOOTER_HE" \
      > /tmp/he-<cv_filename>-with-footer.md
else
  cp /tmp/he-<cv_filename>.md /tmp/he-<cv_filename>-with-footer.md
fi

pandoc /tmp/he-<cv_filename>-with-footer.md \
  --reference-doc="${CV_TEMPLATE_HE}" \
  -o "<output_dir>/<company_dir>/he-cv-<last-name>-<roletitle>-<company>-<monYYYY>.docx"

# Hebrew CV subtitle
python3 "${CLAUDE_PLUGIN_ROOT}/skills/career-engine-export/scripts/update-subtitle.py" \
  "<output_dir>/<company_dir>/he-cv-<last-name>-<roletitle>-<company>-<monYYYY>.docx" \
  "<role title>"

# Hebrew cover letter
pandoc /tmp/he-<cl_filename>.md \
  --reference-doc="${CL_TEMPLATE_HE}" \
  -o "<output_dir>/<company_dir>/he-coverletter-<last-name>-<roletitle>-<company>-<monYYYY>.docx"
```

Verify both files exist and are nonzero:

```bash
ls -lh "<output_dir>/<company_dir>/he-cv-<last-name>-<roletitle>-<company>-<monYYYY>.docx"
ls -lh "<output_dir>/<company_dir>/he-coverletter-<last-name>-<roletitle>-<company>-<monYYYY>.docx"
```

**If verification fails for either file (missing or zero bytes):** re-run that file's pandoc conversion once — same handling as the English DOCX verification in Step 6. If the retry also fails, log `[Company] — Hebrew DOCX production failed after retry — [error]` in the run-level revision log, flag it in the final delivery for manual export, and continue — the English files and this role's Notion writeback are unaffected; a Hebrew conversion failure never blocks or reverts the English delivery.

**Hebrew re-translation rule:** If either English document (CV or cover letter) is revised after Hebrew export, the corresponding Hebrew document MUST be fully re-translated from the updated English markdown — do not patch or edit the prior Hebrew text. If the English CV changes, re-translate the Hebrew CV. If the English cover letter changes, re-translate the Hebrew cover letter. Both change together only if both English documents changed. This applies regardless of how small the English edit is.

Hebrew files land in the same `<company_dir>` subdirectory as the English files. The `Draft Directory` URL (written in Step 7a) points to the whole directory and covers both English and Hebrew files — no separate Notion writeback for Hebrew filenames.

---

## Step 7 — Record file paths and write state

### Step 7a — DOCX existence gate + Draft Directory URL construction

**Hard gate — do not skip, do not proceed on failure.**

```bash
ls -lh "<output_dir>/<company_dir>/<cv_filename>.docx"
ls -lh "<output_dir>/<company_dir>/<cl_filename>.docx"
```

**If either file is missing or zero bytes: STOP.** Do not write anything to Notion. Do not mark the role complete. Report to the user: "DOCX export failed for [Company] — files not found on disk. Step 6 did not complete. Notion has not been updated." This is a declaration, not a question — do not wait for a reply; move directly to the next role in the queue.

**If both files exist and are nonzero:** construct the Draft Directory URL and store it in `$DRAFT_DIR_URL` for use in Steps 7b and 7c:

```
DRAFT_DIR_URL=$DRAFT_DIR_URL_BASE<date-folder>%2F<company_dir>%2F
```

If `$DRAFT_DIR_URL_BASE` is empty or the literal word `skip`, set `$DRAFT_DIR_URL` to an empty string. Step 7c will omit the `Draft Directory` property from the `notion-update-page` call in that case.

Then proceed to Step 7b.

### Step 7b — Write state file (crash-recovery)

Append this role's data to:
`$OUTPUT_DIR/state.json`

where `$OUTPUT_DIR` is the run directory resolved by the orchestrator (e.g. `{{OUTPUT_FOLDER}}/${OUTPUT_DIR_PREFIX:-applications}-<YYYY-MM-DD>/`). Create the file on the first role; append on subsequent ones. Use the `/tmp→output folder` copy protocol from `career-engine-export`. Use the shortened path format for all paths — `<run-dir-name>/<filename>` only, never the full output folder path.

**To append (role 2+):** Read the existing state.json, parse the `roles` array, push the new role object, and write the full updated JSON back. Do not use `cat >` on a file that already exists — that overwrites the file and loses all previous role entries.

```json
{
  "session_date": "<YYYY-MM-DD>",
  "roles": [
    {
      "notion_page_id": "<id | null for --now mode roles>",
      "company": "<company>",
      "company_dir": "<company_dir>",
      "title": "<title>",
      "track": "<cv | now>",
      "status": "completed",
      "cv_type": "<Detailed | Brief — the value resolved at Step 0.type, persisted here since $PIPE/cv-type.txt is deleted at Step 7g cleanup>",
      "cv_path": "<company_dir>/<cv_filename>.docx",
      "cover_letter_path": "<company_dir>/<cl_filename>.docx",
      "feedback_path": "<company_dir>/feedback-<roletitle>-<company>-<monYYYY>.md",
      "revision_log_path": "<company_dir>/revision-log-<roletitle>-<company>-<monYYYY>.md",
      "draft_dir_url": "$DRAFT_DIR_URL (the value constructed in Step 7a — empty string if $DRAFT_DIR_URL_BASE was skip/unset)",
      "role_emphasis": "<1-2 sentence real mandate interpretation>",
      "jd_proof": "<verbatim quote from JD>",
      "keywords": "Critical: <terms> | Important: <terms> | Nice-to-have: <terms>",
      "strategy": "<IC | Strategic | Hybrid>",
      "date_first_advertised": "<YYYY-MM-DD | estimated range | Unknown>",
      "remote_compatibility": "<Confirmed worldwide | Confirmed region-restricted ([region]) | Ambiguous — [reason]>"
    }
  ]
}
```

**Field notes:**
- `track` — `cv` for New Applications pipeline, `now` for --now mode
- `notion_page_id` — `null` for --now mode roles that were never in Notion
- `company_dir` — the kebab-case company directory name (same as used for the subdirectory)
- `date_first_advertised` / `remote_compatibility` — from the coach's research output; write `null` if not available (e.g., content-exists roles where coach skipped fetching)
- All paths are relative to the run folder (e.g., `company-name/cv-<last-name>-[role-title]-company-name-may2026.docx`). Hebrew files are not listed separately — they are in the same `company_dir` and accessible via the Draft Directory URL.

### Step 7c — Write pipeline outputs to Notion properties

Write the following properties using `notion-update-page`. All values are already in memory.

**Confirm every property name against the schema before writing.** The database-notion adapter's §1 schema read (the SQLite `CREATE TABLE` block — the authoritative list of property names and select-option values) was already done upstream and is in context; do not re-fetch it. Before the `notion-update-page` call, check each property name below against that schema. Per the adapter's writeback rule (`skills/database-notion/SKILL.md` §3), a property that is missing, renamed, or whose type doesn't match the schema must **not** be silently dropped and must **never** spawn a numbered variant ("Strategy 1") — omit only that property from the call and surface a named note in the final chat delivery: "Notion property `<name>` not found in the database schema for [Company] — renamed or removed; its value was not written. Update the property name or your `database_property` mapping." Write the properties that do match; one renamed property never blocks the others.

**Coach-owned properties** — write verbatim from the coach's output in Step 0.8. Do not rewrite or reinterpret.

| Property | Source |
|---|---|
| `Role emphasis` | Career coach output — verbatim |
| `JD proof` | Career coach output — verbatim |
| `Keywords` | Career coach output — verbatim |
| `Strategy` | Career coach output — Select value (`IC` / `Strategic` / `Hybrid`) |
| `Role Type` | Career coach output — verbatim |
| `Relationship type` | Career coach output — verbatim |
| `Gap handling` | Career coach output — verbatim. If the user edited this in Notion before the pipeline ran, her version is already there; do not overwrite it. |
| `Role summary` | Career coach output — verbatim. |
| `Person who Advertised Role (if not Hiring Manager)` | Career coach output — verbatim. |
| `Hiring manager's role` | Career coach output — verbatim. |
| `Manager role confirmed` | Career coach output — verbatim. |
| `No incumbents in this function` | Career coach output — verbatim. |

**Pipeline-derived properties**

| Property | What to write |
|---|---|
| `Hiring Manager's Name` | Hiring manager name and title from the coach's research. Write "Not identified" if none found. |
| `Last Pipeline Run` | Today's date in ISO format (YYYY-MM-DD). |
| `Status` | `CV Ready for Review` — set once DOCX export and writeback are confirmed complete. |
| `Draft Directory` | `$DRAFT_DIR_URL` (constructed in Step 7a). **Omit this property from the `notion-update-page` call entirely if `$DRAFT_DIR_URL` is empty** — do not write an empty string to the property. If `$DRAFT_DIR_URL` is empty, include a named note in the final chat delivery: "Draft Directory not written for [Company] — `draft_dir_url_base` not configured or empty. Run `/career-engine:setup --phase 5` to configure it." |

**Property discipline** — write only the properties listed above. Nothing else.

- Do NOT write CV text, cover letter text, revision logs, or reviewer feedback to Notion. Reviewer feedback goes to the feedback markdown file (Step 7d), not to Notion.
- Do NOT write to the `Note` field. It is the user's space.

If any writeback fails, log it and surface it in the final chat delivery. The state.json holds all data as a fallback.

### Step 7d — Save reviewer feedback file

Write a single markdown file to the output folder. This is the one file the user reads — it contains reviewer feedback from all review passes plus the cv-writer's change log, **all read from the role's `_pipeline/` files, not pasted from context (R-41).**

**Filename:** `feedback-<roletitle>-<company>-<monYYYY>.md`  
(Use the same slug format as the CV and cover letter files for this role.)

**File content:**

```markdown
# Feedback — <Role Title> at <Company> — <YYYY-MM-DD>

## CV Changes

<contents of `$PIPE/cv-changes.md` — read the file; if missing, write `_(not available)_`>

---

## Recruiter Review — CV

<contents of `$PIPE/recruiter-cv.md` — read the file; if missing, write `_(not available)_`>

---

## Letter Plan (followed by this letter)

<contents of `$PIPE/coach-outline.md` — read the file; if missing, write `_(not available)_`. Note the plan's source: "from intake (user-reviewed in Notion)" or "generated in-pipeline (legacy WIWTR)" per Step 4.99's path taken>
```

Build the file by reading each `$PIPE` section from disk (not from context — R-41; the reviewer text flows file→file and never re-enters the orchestrator's working set) and writing it to the company subdir using the same `/tmp → output folder` copy protocol as the DOCX files. On Path B, read the `$PIPE` files and run the copy through the host file/process tools (R-30):

```bash
cat > /tmp/<feedback_filename>.md << 'MARKDOWN_EOF'
<full feedback file content>
MARKDOWN_EOF

cp /tmp/<feedback_filename>.md "<output_dir>/<company_dir>/<feedback_filename>.md"
```

Verify the file exists and is nonzero. If the write fails, log it in the final chat delivery — it is not a blocking error; the pipeline has already completed.

### Step 7e — Note new bullets in role state

After Step 7d, record in state.json that this role produced new (unapproved) bullets this run:

```json
"bullets_status": "new"
```

This flag is read by the orchestrator's Step 9b (bullet approval prompt) at the end of the full run. Roles where bullets were already approved in a prior run and no new bullets were written do not need this flag set.

### Step 7f — Why I Want This Role promotion prompt

Runs for every role in the run whose `Why I Want This Role` field is populated — including roles where the letter track was skipped. This step is mechanical and must never block delivery: if it fails, log the failure and continue.

Write a file named `update-prompt-<company>-<monYYYY>.md` into the role's company subdirectory in the output folder using the structure below. The file has two parts: a fixed context block that never changes (copy it verbatim every time) and a variable content block specific to this role.

```
# career-data Update Prompt
<!-- This prompt is generated by the career-engine pipeline. Paste it into Claude Chat or Claude Code to update your career-data skill. -->

## Context for the receiving agent

You are updating a skill file called `career-data`. This is a `.skill` package installed in Claude Desktop that contains the user's personal career data — their background, voice, positioning, and motivation bank. The pipeline cannot run without it. The user's data stays local (never in the plugin) for privacy.

To find `career-data`: locate the directory containing `career-data-marker.json`. It will be at a path like:
`~/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/<workspace-id>/<user-id>/skills/career-data/`

If you are in Claude Code, you can also find it at `~/.claude/skills/career-data/` if a Code-side copy exists. **Important:** if the user runs both Chat and Code (or Cowork), they must apply this update twice — once in Chat and once in Code — because each environment maintains its own copy.

The file to update is: `references/background/background-motivation-bank.md`

Read that file in full before making any changes. Make only the additions described below. Do not rewrite, reorganise, or delete anything else in the file.

After updating the file, repackage the `career-data` directory as a `.skill` zip and provide it to the user to reinstall via Desktop app Settings → Capabilities → Skills. The `.skill` file is a standard zip archive with a `.skill` extension containing all the files in the `career-data/` directory.

## What to add

**Target location:** The `| Tags | Motivation |` table. Append new rows to it. There is **no** "Promoted from Why I Want This Role" subsection — promoted content is simply new rows in this table.

**Source content** (from Why I Want This Role — [Company], [Role Title], [YYYY-MM-DD]):
> [INSERT THE USER'S WHY I WANT THIS ROLE CONTENT HERE — VERBATIM, EXACTLY AS SHE WROTE IT. Do NOT correct grammar or spelling, do NOT polish, do NOT paraphrase. Scrappy English is fine and preferred over a cleaned-up version; the user fixes her own wording inside this prompt before sending if she wants.]

**Promotion rules:**
- Compare the source content against the entire file. Add only what is genuinely new: durable motivation themes, standing professional observations, reusable angles, or characteristic phrasings the user wrote.
- Exclude: anything already captured (even in different words), purely company- or role-specific reactions with no reuse value, and anything not in the user's own written words.
- **Verbatim, raw.** The Motivation cell is the user's exact words — never paraphrased, polished, or grammar-"fixed" by the agent. Quote what she wrote. The user may correct her own wording in this prompt before sending; the agent never does.
- **Entry format — append a new table row:** `| [suggested tags] | "[verbatim quote]" *(Why I Want This Role — [Company], [YYYY-MM-DD])* |`. Suggest the **tags** (comma-separated: where/when this applies in a cover letter — persona, theme, vertical, opener-vs-body, audience); the user can adjust them. The Motivation text stays raw verbatim regardless of the tags.
- Append-only. Never rewrite, merge, reorder, or delete existing rows; never change the table's column layout.
- If the content contains a new durable career fact (outcome, metric, deliverable, role detail) that belongs in the role-facts file for this company, do NOT write it there — it requires the user's explicit approval. Flag it instead: "New role fact found: '[quote]' — add to `background-role-facts-<company>.md` if accurate."
- If there is nothing new to add, say so explicitly: "No new content to promote from this entry."
```

**After the Motivation Bank promotion section, append a WIWTR-UNLOGGED section if applicable:** Collect every item the gatekeeper flagged as `[WIWTR-UNLOGGED]` during this run (from Steps 5.2, 5.3, and 5.95 violation reports). For each item, append to the update-prompt file:

```
## Role facts needing verification (WIWTR-UNLOGGED — from [Company] [Run Date])

The following claims appeared in your Why I Want This Role and were used in the letter,
but are not yet documented in your role-facts files. They are NOT fabrications —
they are your own first-person record. To make them available to future pipeline runs
without re-triggering this advisory, add them to `background-role-facts-[company].md`
for the relevant role, pending your verification that the facts are accurate.

For each item below: if accurate, add it as a role fact to the relevant
`background-role-facts-[company].md` file. If not accurate, remove it from your
Why I Want This Role before the next run.

[For each WIWTR-UNLOGGED item, one line:]
- **[Employer]** — "[verbatim claim from WIWTR]" *(flagged in [step] — not in background-role-facts-[company].md)*
```

If no [WIWTR-UNLOGGED] items were found, omit this section entirely.

Log in the final delivery per role: "Update prompt written to `<company_dir>/update-prompt-<company>-<monYYYY>.md` — paste into Chat or Code to complete the motivation bank promotion (do both if you use both environments)" or "No Why I Want This Role content and no WIWTR-UNLOGGED items — skipped."

### Step 7g — Clean up `_pipeline/` scratch directory

After Step 7f, remove the `_pipeline/` directory for this role. All content needed for delivery (feedback file, revision log) has already been written to the output folder in Step 7d and in the post-Step-4 and post-Step-5.3 staging blocks. The `_pipeline/` files are intermediate scratch — they are not deliverables and do not belong in the user's output folder.

- **Path A:** `rm -rf "$PIPE"`
- **Path B:** delete `$PIPE` through the host file tool (Desktop Commander `move_file`/delete or equivalent).

If the deletion fails, log it in the final delivery ("_pipeline cleanup failed for [Company] — delete manually") and continue. This step must never block delivery.

The output folder after cleanup contains only: final DOCX files, the feedback markdown, the revision log markdown, and (for Hebrew runs) the Hebrew DOCX files.
