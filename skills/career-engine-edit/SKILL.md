---
name: career-engine-edit
description: Editing pipeline for the career-engine plugin. Triggers when the user says "edit CVs", "run CV edits", "process the Needs Editing queue", or any similar phrase. Retrieves all Job Applications rows with Status = Needs Editing, runs the career coach first to verify and update its owned properties, then routes each role through the appropriate pipeline agents to improve existing outputs — not to start from scratch. Agents in this pipeline are explicitly informed they are refining existing work, not generating from zero.
---

# New Application — Editing Pipeline

> **Registry:** this pipeline is listed in the Pipeline Registry in `skills/career-engine/SKILL.md`. Actions owned by another pipeline's registry row are out of scope here — route to that pipeline instead of improvising.

This skill handles the editing pipeline for roles the user has flagged as needing revision. It runs separately from the main pipeline and is triggered by Status = `Needs Editing` in the Job Applications database.

The key difference from the main pipeline: **agents are not starting from scratch.** Existing CV text, cover letter text, coach properties, and reviewer feedback are all in the Notion row. The goal is to improve what exists, informed by what is already documented there.

**`Needs Editing` always means edit from the Notion entry.** Every role with Status = `Needs Editing` uses whatever is already inside its Notion row as the starting point — existing CV text, cover letter, coach properties, reviewer notes. Nothing is discarded. This rule holds regardless of what state.json says. state.json is crash recovery only (see State file section below).

> **`career-data` data root (R-37).** The personal-data files — `01-writing-rules.md`, `02-professional-background.md`, `03-framework.md`, `linkedin-profile.md`, `pipeline-preferences.json`, `delivered-letters/`, and the user's `.dotx` — load from `${CAREER_DATA}/references/`, the path the orchestrator resolves in its `career-data` discovery preflight. Every other file (self-checks, `REFERENCES.md`, skill docs, default `.dotx` templates) stays on `${CLAUDE_PLUGIN_ROOT}`. If `${CAREER_DATA}` is not set (direct or standalone invocation outside the orchestrator), locate the `career-data` skill yourself, confirm `career-data-marker.json`, and apply the orchestrator's healthy / damaged / absent outcomes before reading. A configured user's missing `career-data` is a hard stop — never silently fall back to blank templates.

> **Universal spawn parameter — `gap_handling_mode` (2026-07-14).** Resolve `$GAP_HANDLING_MODE` once at run start from `${CAREER_DATA}/references/pipeline-preferences.json` → `gap_handling` (`disabled` when the value is `disabled` or empty, `enabled` otherwise — an absent key on an older config means `enabled`). **Every subagent spawn in this pipeline passes `gap_handling_mode=$GAP_HANDLING_MODE`, exactly like `CAREER_DATA` — every agent, every round, every re-spawn and crash-recovery fallback, no exceptions.** When `disabled`, no agent may produce, request, or enforce gap framing anywhere (see the identical rule in `career-engine-new-application/SKILL.md` for the per-agent meaning). A one-word routing token — for the letter-writer it rides inside its input contract's routing-token allowance, never as content.

## Preflight

**Outputs go to the configured output folder — never to a session scratchpad.**

The only valid output destination is:
`{{OUTPUT_FOLDER}}/applications-<YYYY-MM-DD>/`

Do not create a local output directory inside a session path (`local_*/outputs/` or similar). Files written there do not sync and are not findable.

Before starting, verify output access using the two-path ladder (R-30 — full definition in the orchestrator's Mandatory path verification):

**Path A — direct filesystem:**

```bash
ls "{{OUTPUT_FOLDER}}/" 2>/dev/null && echo "Output path confirmed (Path A)."
```

**Path B — host-bridge MCP:** if Path A fails (sandboxed environment — an environment limitation, not a missing folder), discover host filesystem tools via ToolSearch (`Desktop Commander`, `read_file`, `write_file`, `create_directory`, `start_process`, or equivalent) and verify access by listing `{{OUTPUT_FOLDER}}` through the strongest available tool. If confirmed, proceed — and route ALL of this run's file operations through those tools: reading the existing CV/letter DOCX files, the pandoc text extractions (E0.7 baseline, existing letter text), every conversion, and every write back to the run folder (pandoc runs via the host process tool; intermediate markdown is written through the host tool, not sandbox `/tmp/`).

**Both paths fail → stop the run immediately** and report to the user: the run needs either the output folder connected to the session or a host filesystem tool (e.g. Desktop Commander) enabled.

**The no-scratchpad rule applies on both paths.** Do not use `./outputs/`, relative paths, or any path containing "local-agent-mode-sessions" or "Application Support". If host access is lost mid-run, retry once; if still unreachable, deliver the remaining file contents in chat flagged for manual save and log the failure — never write to a substitute location.

Then confirm:
1. Output folder for each role is the run folder from the original run date. **How to identify it:** search for `state.json` files across all run folders under the output root — check both `applications-<YYYY-MM-DD>/` (current naming) and `cv-campaign-YYYY-MM-DD/` (legacy naming used by earlier pipeline runs). For each state.json found, look for an entry matching this role's `notion_page_id`. The run folder is the directory containing that state.json. If no state.json entry exists for this role (e.g., it was added to Notion after the original run), use today's date as the run folder (`applications-<YYYY-MM-DD>/`) and create it if needed.
2. File format is DOCX — same as the main pipeline.
3. `career-engine-export` skill is loaded.
4. All career-engine skills this pipeline actually reads are loaded before Step E0 runs — not a vague "all skills," but specifically: `database` (Status/Priority/property-ownership rules), `database-notion` (or the configured backend's adapter, mandatory whenever `database_backend` is `notion`), `career-engine-export` (already confirmed at item 3 above), and `${CAREER_DATA}/references/01-writing-rules.md` (the fabrication rule and attribution constraints the gatekeeper enforces at every check below — resolved per R-37, same ordering as the orchestrator's own writing-rules load).

## Step E0-pre — Resolve per-install config (R-38)

The edit pipeline is its own entry (no orchestrator), so resolve config yourself. After the `career-data` discovery, run the **career-data health check** before proceeding:
1. Count files in `${CAREER_DATA}/references/delivered-letters/` (excluding `INDEX.md`). If count = 0: **stop** — "career-data has no delivered letters — voice calibration will fail. Add at least one sent letter, then re-run."
2. **Config keys — required hard-stop; everything else optional.** Read `pipeline-preferences.json`. **Required (stop if missing or empty):** `output_folder`, and — when a database backend is configured (`database_backend`; default `notion`) — `database_id`. Stop with: "career-data config is incomplete — run `/career-engine:setup --phase 5` to fill in: [required keys missing]." **All other keys are optional — never stop on them;** collect any absent (older config) or empty into `CONFIG_HEALTH` and emit the same end-of-run `⚙️ Config health` block the orchestrator defines. **Backward compatibility:** accept legacy `notion_database_id` (→ `database_id`), `notion_needs_editing_view_url` (→ `database_edit_view_url`), `location_compatibility.notion_property` (→ `database_property`); prefer the `database_*` names and flag any legacy name in `CONFIG_HEALTH`.
3. (Code sessions) If `~/.claude/skills/career-data/` is absent or differs from `${CAREER_DATA}`, warn: "career-data may be out of sync with the Desktop app — re-install the .skill file if you recently updated it in Chat. Continuing on the resolved path."

**Schema read (2026-10-15) — run once per run, right after config resolution, so Step E0.5's `Closed` write can be validated.** Load the database adapter (`${CLAUDE_PLUGIN_ROOT}/skills/database-notion/SKILL.md`) and run its §1 Schema read; keep the Status option list in context for the rest of the run, exactly as intake Step 0a and the prioritizer's Step 0 item 3 do. This is the only place the Edit pipeline learns whether the tracker has a `Closed`/`Position Closed`/`Role Closed` option.

Then read `${CAREER_DATA}/references/pipeline-preferences.json` and set `$NOTION_DATABASE_ID` (← `database_id`, legacy `notion_database_id`), `$NOTION_NEEDS_EDITING_VIEW_URL` (← `database_edit_view_url`, legacy `notion_needs_editing_view_url`), `$NOTION_INTERESTED_VIEW_URL` (← `database_interested_view_url`), `$NOTION_HOLD_VIEW_URL` (← `database_hold_view_url`), `$NOTION_RESEARCHED_VIEW_URL` (← `database_researched_view_url`), `$NOTION_CV_READY_VIEW_URL` (← `database_cv_ready_view_url`), `$OUTPUT_FOLDER`, and `$DRAFT_DIR_URL_BASE` (used by the queries and exports below; the `$NOTION_*` var names are the Notion adapter's internal names and are unchanged). Wherever this skill shows `{{NOTION_DATABASE_ID}}` or `{{NOTION_NEEDS_EDITING_VIEW_URL}}`, use the resolved values. Stop if `database_id` or `output_folder` is missing: "career-data is missing a required config key — run `/career-engine:setup --phase 5`." Optional: `draft_dir_url_base` absent or `skip` → Draft Directory writeback is skipped (log it in the final delivery as "Draft Directory not written — `draft_dir_url_base` not configured"). The plugin keeps these placeholders literal (single build).

**Template resolution — fixed filenames, no config key (2026-07-04 fix).** `cv_template` and `word_templates_path` are no longer config keys. Set `$CV_TEMPLATE` = `${CAREER_DATA}/references/templates/cv.dotx`, `$CV_TEMPLATE_BRIEF` = `${CAREER_DATA}/references/templates/cv-brief.dotx` (Brief CV Type — required only for a role whose resolved CV Type is `Brief`, see Step E0.type below), `$CL_TEMPLATE` = `${CAREER_DATA}/references/templates/cover-letter-template.dotx`, `$CV_TEMPLATE_HE` = `${CAREER_DATA}/references/templates/cvHe.dotm`, `$CL_TEMPLATE_HE` = `${CAREER_DATA}/references/templates/he-letter.dotx` — always these fixed relative paths, never an external OS path, never a config lookup. `$CV_TEMPLATE`/`$CL_TEMPLATE` are required for any export used by this pipeline — if either doesn't exist, stop with: "career-data is missing `references/<filename>` — run `/career-engine:setup --phase 5` to restore the default templates." `$CV_TEMPLATE_BRIEF` follows the same required-when-needed rule as the Hebrew templates: missing when actually needed for a `Brief`-type role is a stop, never a silent fallback to `$CV_TEMPLATE`. `$CV_TEMPLATE_HE`/`$CL_TEMPLATE_HE` are optional — if any is missing, Hebrew export for that document type is unavailable (collect into `CONFIG_HEALTH`).

**`$CV_FOOTER`/`$CV_FOOTER_HE` resolution is conditional on `cv_footer.inject` (2026-07-12 fix) — read this key from `pipeline-preferences.json` (default `true` when absent, for configs written before this feature existed).** If `true` (the default): set `$CV_FOOTER` = `${CAREER_DATA}/references/static-cv-footer.md` and `$CV_FOOTER_HE` = `${CAREER_DATA}/references/static-cv-footer-he.md`, exactly as before, and `$CV_FOOTER` becomes required for any export — if missing, stop with the same "career-data is missing `references/<filename>`" message. **`$CV_FOOTER` (2026-07-09 fix)** replaces the plugin's own `skills/career-engine-export/static-cv-footer.md`, which `convert-cv.sh` previously hardcoded for every CV export — confirmed in the shipped repo to have accumulated one real user's actual Education/Languages content, meaning every installation was silently appending someone else's real degree/university info onto every exported CV. **If `cv_footer.inject` is `false`:** set `$CV_FOOTER=""` and `$CV_FOOTER_HE=""` — neither file is required to exist, neither is checked, and the empty string passes through unchanged to every downstream spawn and script call. This is for a user who manages Education/Languages herself outside the pipeline (e.g. her own Word macro run after export) — the same "not this pipeline's job" treatment the CV's optional `## ADDITIONAL` section has always had. `$CV_FOOTER_HE` stays optional (Hebrew export unavailable if missing, collect into `CONFIG_HEALTH`) whenever `cv_footer.inject` is true.

## Step E0 — Fetch roles for editing

**Guard — resolve the database ID from the career-data config (R-38).** The plugin keeps `{{NOTION_DATABASE_ID}}` literal by design — do not treat the literal placeholder as unconfigured. Use `$NOTION_DATABASE_ID` resolved in Step E0-pre from the career-data config. **Stop only if that config value is missing or empty**, and tell the user:

> "Your career-data config has no `database_id` (or legacy `notion_database_id`). Run `/career-engine:setup --phase 5` to add it."

---

**Establish a run-scoped `$RUN_PIPE` before the fetch below** — mirrors the intake pipeline's Step 0a.5 pattern (`skills/career-engine-intake/SKILL.md`) and the orchestrator's Step O1 pattern (`orchestrator-queue.md`). This is distinct from the per-role `$PIPE` created later at Step E0.pipe — that one doesn't exist yet at this point. Set `$RUN_PIPE` = `$OUTPUT_FOLDER/_edit_pipeline/<run-timestamp>/` (timestamped so a concurrent or immediately-prior run never collides; `$OUTPUT_FOLDER` is already resolved from Step E0-pre). Create it via `mkdir -p` (Path A) or the host file tool (Path B, R-30). `_edit_pipeline/` is intermediate only — never a deliverable, never written to Notion; remove it once Step E0.5 has consumed its content into each role's per-role `$PIPE`.

**Career-data reachability verification (staging fallback) — run once here, immediately after `$RUN_PIPE` is established, before the queue fetch below.** The self-locate this pipeline runs per the R-37 data root note above (this file has no orchestrator to inherit a resolution from — "locate the career-data skill yourself") may have found `career-data` using a broader search or a different tool surface than the one every spawned subagent actually has. **Confirmed in a real run:** the resolving agent's own `Read` tool failed on the exact path its own broader-search tool had just confirmed present, with the error "is a VM path... Read tool runs on the host filesystem" — and a `cv-writer` subagent spawned moments later, given only that same unreachable path, correctly hard-stopped rather than fabricate a CV. Every subagent this pipeline spawns is guaranteed to have `Read` regardless of what else it does or doesn't have, so `Read` is the correct universal test — cheap, and it changes nothing when it passes.

1. Attempt `Read` on `${CAREER_DATA}/career-data-marker.json`.
2. **Succeeds:** `${CAREER_DATA}` is confirmed reachable by the tool surface subagents actually have. Nothing else changes — every spawn in this pipeline continues to pass `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE` exactly as already documented.
3. **Fails with a reachability error** (e.g. "is a VM path," "outside connected folders," or any error indicating the file exists but this specific tool can't reach it — distinct from a genuine not-found, already handled in Step E0-pre's own career-data health check): stage the content instead of letting every subsequent subagent spawn fail the same way one at a time.
   - Create `$RUN_PIPE/career-data-staged/` using whichever tool succeeded at the original discovery (the one that can actually reach the real location).
   - Copy only the files subagents read directly — never the `.dotx`/`.dotm` templates, which only this pipeline's own `pandoc` call touches, never a subagent (`career-engine-export/SKILL.md`: "None of these templates should be read into context. Use them only as pandoc `--reference-doc` arguments."): `pipeline-preferences.json`, `01-writing-rules.md`, `02-professional-background.md`, every file under `background/`, `03-framework.md`, every file under `framework/`, `linkedin-profile.md`, `voice-calibration-coverletters.md`, every file under `delivered-letters/`, and `templates/cover_letter_templates.md` if present (optional — `letter-writer`, `gatekeeper`, and `career-coach` each read it directly when it exists; skip it silently when it doesn't, same as those agents already do).
   - **Reassign `${CAREER_DATA}` to `$RUN_PIPE/career-data-staged/` for the rest of this run.** Every spawn in this pipeline already just interpolates `${CAREER_DATA}` — no spawn instruction anywhere needs to change.
   - Add one line to this run's `⚙️ Config health` notification: "career-data staged locally for this run — the resolved path wasn't reachable by the tool surface subagents use in this environment (`<brief reason>`). Using a staged copy; your actual career-data files are untouched."
4. **Fails with a genuine not-found:** already covered by the R-37 data root note's Absent outcome above — do not re-diagnose here.

This does not extend to `${CLAUDE_PLUGIN_ROOT}` paths (plugin doctrine files) — the confirmed failure was specific to the external `career-data` skill mount, not the plugin's own files.

**Query the Needs-Editing queue via the database adapter.** Following `${CLAUDE_PLUGIN_ROOT}/skills/database-notion/SKILL.md` (the Notion adapter; loaded when `database_backend` is `notion`) → **§2 read ladder**, query the queue for **`Status = Needs Editing`** (A1 → A2 → B; falling down the ladder is sanctioned routing). For Path B, the configured edit view is the fast path — pass `{{NOTION_NEEDS_EDITING_VIEW_URL}}` (resolved from `database_edit_view_url`, legacy `notion_needs_editing_view_url`) as the `view_url`; if it is empty, stale, or fails, fall back to the adapter's **§3 view discovery** to resolve the "Needs Editing" view by name. **On Path B, the view-query call itself (§2 Path B steps 2–3) is delegated by the adapter — never run it directly in this pipeline's own context; see the adapter for the subagent contract.** A live traced run confirmed this call returning tens of thousands of raw characters of full property data directly into this pipeline's own context when run inline — the same context-exhaustion failure shape as an undelegated per-page fetch. This step is discovery only — page IDs, company, position, priority. Do not fetch full per-page properties here; that is the next paragraph's job, delegated.

**⛔ Delegate the per-page property fetch — do not run it directly in this pipeline's own context.** This mirrors the orchestrator's Step O1 fix and the intake pipeline's Step 0b fix for the identical failure mode: running several raw `notion-fetch` calls in this context and holding every result inline has caused premature context exhaustion in production. **Spawn a lightweight subagent** (general-purpose / Task tool), passing it: the list of page IDs from the view-discovery step above, and the full property list needed — Page ID, Company name, Position title, Job URL, `Edit type`, `Edit notes`, `JD Body`, `Role summary`, `Role emphasis`, `JD proof`, `Keywords`, `Strategy`, `Role Type`, `Relationship type`, `Gap handling`, `Why I Want This Role`, `CV File Name`, `Letter File Name` (if present), `Note`, `Priority`, `CV Titles` and `CV Title Preferences` (the role-tailoring plan and the user's own title wishes — Step E0.titles reads both), `CV Type` (the user-owned per-role field — only relevant when `cv_type.mode` is `Variant`, but always fetched so it's never silently missed under an "any other populated fields" catch-all), and any other populated fields, plus any reviewer feedback or notes already on the row. Instruct it exactly: *"For each page ID, call `notion-fetch` and capture its full property set. Do this for all N pages. If a page's fetch fails or errors, do not stop — skip that page, continue with the rest, and add one line for it under a final `## FAILED` section naming the page ID and the error. Return your response as one block, using this exact format, one section per role: `## ROLE — <Company> — <Position>` followed by `**Page ID:** <id>` and then every property as a labeled line, plus the `## FAILED` section if any page errored. Return nothing else — no commentary, no partial returns per page."* The subagent returns text only — it does not write `$RUN_PIPE` itself (sandboxed subagents cannot reach the real filesystem). **If the returned block's `## FAILED` section lists any page:** log each by page ID in the run-level revision log and exclude that role from the queue, never silently.

**Receive that one returned block and write it to `$RUN_PIPE/needs-editing-role-properties.md` in a single `Write` call, then drop the returned text from working memory immediately.** The bulk of the property/JD text arrives as one bounded return and is flushed to disk in one action, rather than accumulating turn-by-turn across several raw inline `notion-fetch` results. If the page count is large enough that the subagent's own return risks being oversized (rough guide: more than ~8-10 roles), split the page-ID list across two or more subagent spawns and append each returned block to `$RUN_PIPE/needs-editing-role-properties.md` in turn — still never running the per-page fetches in this pipeline's own context. **If the subagent cannot access `notion-fetch`** (check its return — it will say so or return an empty/error result): fall back to running the per-page fetches directly here, but still write each result to `$RUN_PIPE/needs-editing-role-properties.md` before fetching the next page, and log in the revision log that the delegation didn't fire this run.

**Read `$RUN_PIPE/needs-editing-role-properties.md`** to obtain the full row payload for every role — never a rendered table, never held from an earlier in-memory fetch. (Step E0.5 below reads this same file again for its own JD-extraction pass — that is a separate, expected read, not a contradiction of anything said here.) If every rung of the read ladder failed instead, stop and report — never treat it as zero results, and never improvise `notion-search` to enumerate the queue (R-39).

**Edit type is mandatory. It controls everything.** After reading `$RUN_PIPE/needs-editing-role-properties.md`, immediately inspect the `Edit type` value for every role before any other work begins — before spawning the coach, before loading JDs, before any pipeline step.

- **`Edit type` is empty or not one of `CV`, `Letter`, `Both`:** do not proceed with this role under any circumstances. Do not default to `Both`. Log the skip: "[Company] — [Role Title]: skipped — Edit type not set. Add CV, Letter, or Both to the Edit type field in Notion." No subagent is spawned for this role.
- **`Edit type` is `CV`, `Letter`, or `Both`:** proceed with that role using the routing below.

Report the count to the user: "Found N roles marked Needs Editing (M skipped — Edit type missing)." **When N ≥ 1 this report is a declaration, not a question — do not wait for a response; proceed immediately** (same labeling as the intake pipeline's Step 0b count report, so a report-then-silently-wait stall can't happen here either). If the count after skipping is 0, **stop immediately and report that.** Do not continue the pipeline.

**Queue cap — maximum 5 roles per run.** If more than 5 roles remain after skipping, select the top 5 by Priority field: First > Second > Third > Fourth > Fifth. Ties at the same Priority level are broken randomly. Report which roles are deferred: "Deferring N roles — re-run edit to process them." Proceed only with the selected 5.

**Routing by Edit type — hard gate, checked again before each subagent spawn:**
- `CV` — run CV editing steps only (E0.7 content check, E3–E5.5, CV DOCX export). Skip ALL cover letter steps. Do not spawn letter-writer, do not run cover letter gatekeeper.
- `Letter` — run cover letter editing steps only (E0.7 cover letter check, E7–E8.5, cover letter DOCX export). Skip ALL CV steps. Do not spawn cv-writer, do not run CV gatekeeper.
- `Both` — run all steps.

## Step E0.5 — Prepare JD content from Notion rows

For each role fetched in Step E0, extract the structured JD from `$RUN_PIPE/needs-editing-role-properties.md` (read once here, not re-read per step). The `JD Body` property was already captured in Step E0 as part of the full row payload written to that file. After this step has extracted what each role needs into working memory, `$RUN_PIPE` may be cleaned up (Path A: `rm -rf`; Path B: host file tool delete — non-blocking if removal fails).

For each role:
1. **`JD Body` is populated** — mark `content-exists`. Use this as the structured JD for all downstream steps (coach, gatekeeper, cv-writer, letter-writer). Do not re-fetch from the Job URL.
2. **`JD Body` is empty** — **first apply intake Step 0.45's user-note precedence gate:** read the row's user-authored free-text properties and page body; if any says the role is unadvertised, referral-only, or has no job description, do **not** fetch and do **not** hard-drop — proceed with her stated facts as the role data (the empty `JD Body` is correct and expected for that role, not a defect). Otherwise, attempt to fetch from the Job URL directly (use the full fetch ladder from `career-engine-intake` Step 0.5 — its LinkedIn branch (job ID in any URL form, guest endpoint, LinkedIn MCP) and Indeed branch included, not only the rendering-capable extraction rung — **including its liveness check — a `url-dead-cached-jd` result is an extractor's cache of a pulled posting, is not usable JD text, and never populates `JD Body`**). If the fetch succeeds, populate `JD Body` in memory and proceed. **Closure check before any drop (2026-10-15, per the user: "if the position closed then that's the update. It should be automatic.").** If the fetch's failure meets the **closure evidence** rule (`skills/database/SKILL.md` → Status Values: the company's own careers/ATS/posting page states closed, filled, or no longer accepting; or 404/410 plus the role's absence from the careers index checked this run — a bare redirect is only possibly closed), tag the role `url-dead-cached-jd (closed-confirmed)`, write `Status = <the tracker's Closed option>` through the adapter now (matched against the Status option list from E0-pre's schema read — `Closed`/`Position Closed`/`Role Closed`, case-insensitive, exact stored string; no such option → leave Status and add one line to the Final Chat Delivery: "[Company] — [Role Title] is closed but your tracker has no `Closed` Status option — add one to enable the automatic write"), log "Closed — [Company] — [Role Title]: <evidence>", and remove it from all subsequent steps. A closed role is never edited and never left at `Needs Editing`. Otherwise, if the URL is unreachable and `JD Body` remains empty, **hard-drop this role from the editing queue**: log "Dropped — JD unavailable: [Company] — [Role Title]: URL unreachable and JD Body empty. Paste the JD into Notion before re-running edit." Remove from all subsequent steps (E0.7 onward). Do not proceed with a role that has no JD.

Hold all structured JD data in memory. All subsequent steps that reference "the structured JD from Step E0.5" draw from here.

## Step E0.7 — Baseline check

**Create each role's per-role `$PIPE` now, before running any checks below.** Both baseline-check spawns write to `$PIPE/gatekeeper-baseline-*.md`, but the per-role pipeline directory is otherwise first described at Step E0.pipe, later in this file, inside the per-role loop — which runs *after* this step. Create `<output_dir>/<company_dir>/_pipeline/` for every role now (Path A: `mkdir -p`; Path B: host file tool), one per role, as part of this step's own "for each role" fan-out — do not wait for Step E0.pipe. (`mkdir -p` is idempotent, so Step E0.pipe running again later for the same role is harmless — it's a confirmation at that point, not a first creation.)

**Capability check: `$PIPE` filesystem availability — run once, immediately after the FIRST role's `$PIPE` is created above, before that role's (or any role's) baseline gatekeeper spawns below.** This must run before the two baseline gatekeeper spawns below, not after them — both spawns already depend on `$PIPE` being reachable/writable, so checking afterward would mean the run's first `$PIPE`-dependent spawns get none of the benefit of this check. Write a canary file `$PIPE/pipe-canary.md` (fixed sentinel content) via whichever path (A or B) the orchestrator's Mandatory path verification already confirmed. Prepend to the first baseline `gatekeeper` spawn below: *"Before anything else, attempt to Read `$PIPE/pipe-canary.md`. Your first returned line must be exactly `PIPE-CANARY: reachable` or `PIPE-CANARY: unreachable — <short reason>`. If unreachable, return your full content inline instead, prefixed `FULL-DRAFT-INLINE:`."* Cache the result as `$PIPE_FILESYSTEM_AVAILABLE` (true/false) for the rest of the run — do not re-check per role.

If unavailable: post one non-blocking chat message before continuing (do not wait for a reply): "⚠️ This environment can't share files between me and the writing sub-agents (no `$PIPE` access) — I'll relay each draft's exact text between steps manually instead of pointing sub-agents at a shared file. This carries more handoff risk than the normal path, especially for CV/letter formatting markup, so I'm running the extra verification checks this adds. Continuing the run." Then, for the rest of the run (both this role's baseline checks and every later per-role step, including E0.pipe.5's own trigger point below), relay every subagent's returned text byte-for-byte between spawns — never retyped, cleaned, reformatted, or summarized, including pandoc `:::`/`custom-style=` markup — with the same `custom-style=`-count self-check used elsewhere in this doctrine (`orchestrator-queue.md`'s manual-relay rule): a mismatch means stop and re-copy verbatim before proceeding.

**Role 1's baseline spawn(s) carry the capability-check canary prepend above and must be dispatched and resolved before any other role's baseline spawns fire** — otherwise roles 2+ could fire before `$PIPE_FILESYSTEM_AVAILABLE` is even known, defeating the point of checking it first. Dispatch role 1's baseline check(s) alone; once that result resolves (and the chat disclosure above has posted, if applicable), dispatch every other role's baseline checks in parallel as a normal batch. This sequencing only applies to role 1 of the run — every role after that already has a cached, known value and batches normally. Run the gatekeeper on all existing outputs in parallel (subject to that one-time role-1-first sequencing). The goal is a complete picture of what's already broken before any editing begins. All violation lists travel forward to the coach (E1) and cv-writer (E3) as context.

**Do not skip this step because the letter or CV will be substantially rewritten anyway.** A real production run skipped baseline checks for all 5 roles on that reasoning — the letters were all being rewritten from scratch, so the run judged the existing-content diagnostic as moot. That reasoning is wrong: the baseline violation list is what tells the writer *what specifically was broken* about the existing draft, which is signal for what NOT to reproduce in the rewrite, independent of how much surviving text there is. The only valid reasons to skip are the two named below (no JD, cover letter file not locatable) — "it's getting rewritten" is never one of them.

**Baseline runs only for roles with a JD.** If E0.5 hard-dropped a role (URL unreachable and `JD Body` empty), no baseline check runs for it at all. For every role whose `JD Body` is populated (from the row or fetched in E0.5), run the baseline check now.

**Content check:** Run only if Edit type is `CV` or `Both`. **This is a different question from Step E0.type below, not a duplicate of it — E0.7 asks "what type IS the existing CV" (diagnostic, for picking which gate rules apply to the old document); E0.type asks "what type SHOULD this run's output be" (prescriptive, for the new draft).** They deliberately use *different* read mechanisms, not the same one — this is intentional, not an inconsistency: E0.7 reads the **cached** `Variant`-mode value from the Step E0 row payload (already fetched for the whole batch, cheap to reuse, and "close enough" is fine for a diagnostic-only read), while E0.type does a **live, targeted** per-role read (line 151) because it's the authoritative value the actual output depends on, and a stale cached value there could produce the wrong CV. E0.type remains the single resolution point for what this run *produces* — E0.7's read here never feeds `$PIPE/cv-type.txt` or any downstream spawn. Resolve the existing CV's diagnosed type inline: `pipeline-preferences.json` → `cv_type.mode`; if `Detailed`/`Brief`, use directly; if `Variant`, read this role's `CV Type` field from the Step E0 row payload (empty → `Detailed`). **Write this value to `$PIPE/existing-cv-type.txt`** (disk, not memory — consistent with this plugin's established `$PIPE`-file convention for anything a later step needs, same as `$PIPE/cv-type.txt` itself) — Step E3 reads it back and compares against E0.type's resolved value to detect a type change (see Step E3 below). Spawn `gatekeeper` with `option=cv`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<$EXISTING_CV_TYPE>`, `CV_TITLES_PATH=skip` (the role-tailoring plan is not resolved until Step E0.titles, and a CV written before the plan existed cannot conform to it — Gate 6 is skipped for this baseline; the mismatch is Step E3's revision item, never a baseline violation), the existing CV text, `Role summary` (from the Step E0 row payload — the JD proxy the gatekeeper reads), the role's `Keywords` property (from the Notion row — required for the ATS pre-check), and `OUTPUT_PATH=$PIPE/gatekeeper-baseline-cv.md`. Per the gatekeeper's R-41 protocol, it returns either `PASS` or `FAIL: <n> violations → $PIPE/gatekeeper-baseline-cv.md` — read the file for the violation list, never expect it inline.

**Cover letter check:** Run only if Edit type is `Letter` or `Both`. Locate the existing cover letter in this order: `Letter File Name` from the Notion row → state.json `cover_letter_path` → run-folder pattern search (`coverletter-*` / `cv-*` in the company subdirectory) → Draft Directory company subdirectory. If the file cannot be located by any of these methods, skip the cover letter baseline check entirely and log: "Cover letter baseline check skipped for [Company] — file not locatable (no prior pipeline run or file moved)." Otherwise spawn `gatekeeper` with `option=cover-letter`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, the existing cover letter text, `Role summary` (from the Step E0 row payload), `Strategy` (from the Step E0 row payload — governs the word-count ceiling: 250 instead of 320 when `Strategic`), and `OUTPUT_PATH=$PIPE/gatekeeper-baseline-cl.md`. Returns either `PASS` (or `PASS — cover letter [Tier 2: <n>%]`) or `FAIL: <n> violations → $PIPE/gatekeeper-baseline-cl.md` — read the file for the violation list, never expect it inline.

Run both in parallel. Collect results. Do not loop or fix anything yet — this step is diagnosis only.

**If either gatekeeper spawn errors, times out, or returns without a violation file at all** (distinct from a normal PASS/FAIL, both of which always resolve cleanly): do not treat this as a PASS and do not block the role. Log it in the run-level revision log — "[Company] — [Role Title]: baseline [CV|cover letter] check did not complete — [error/timeout detail]. Proceeding without baseline violation context for this document." — and proceed with that document's downstream steps (E1, E3) simply carrying no baseline violation list for it, the same as the two named skip conditions above (no JD, cover letter file not locatable). This is a diagnostic input, not a gate — a failed spawn here must never stop the role or be silently treated as "nothing was wrong."

## Step E1 — Coach properties gate

**The coach's full research/verification pass (Option 2) is never re-run from the edit pipeline.** Coach properties are set during intake (Needs Research → Researched) and are expected to be present when the editing pipeline runs. (Since 2026-07-22 the coach is normally not spawned here at all — Step E6.9 parses the intake-written Coach Letter Plan from WIWTR and spawns `career-coach` (Option 4a) only as the legacy-row fallback; the Step E7.4 review was removed per the user's instruction and replaced by Gate 5/9 conformance. The narrower-mode framing below is retained for that fallback pathegic Letter Review roles, which read the properties this gate verifies rather than re-deriving them.)

For each role in the editing queue, verify these **writer-needed fields** are populated (non-empty):
`Role summary`, `Role emphasis`, `Keywords`, `Strategy`.

`Role summary` is the **JD proxy** downstream checkers and the coach read instead of the full JD body (never the letter-writer — 2026-07-14 input contract) (see `skills/career-coach/SKILL.md` → `Role summary`). Steps E7.3/E7.7 and E8.5 pass it to the gatekeeper "from the coach properties verified in Step E1" with **no fallback**, so it must be gated here — exactly as the orchestrator's O2 readiness gate does (`skills/career-engine-orchestrator/SKILL.md` Step O2). This list must stay in parity with O2's writer-needed fields. `JD proof` is not checked — it is reference-only. `Gap handling` is not required when `gap_handling_mode = disabled`.

- **All four fields present** → role is ready; carry its existing coach values forward.
- **Any field missing** → **hard-drop this role from the queue**. Log: "Career coach properties missing for [Company] — [Role Title]: missing `<list>`. Run intake first (`/career-engine --coach-skills`), then re-run edit." Leave Status unchanged.

After the gate, confirm in chat: "Coach properties verified: N roles proceed, M excluded (missing coach properties)." This is a declaration, not a question — do not wait for a response; proceed immediately to the per-role loop.

## Per-role editing pipeline

Process roles sequentially. For each role, branch on the pipeline the user specified in chat (same logic as the main pipeline).

**Step E0.pipe — Confirm scratch directory**

`$PIPE` for this role was already created at Step E0.7, ahead of the baseline checks — this step just sets it as the variable in scope for the rest of the per-role loop and confirms it exists (mirrors the new-application `$PIPE` pattern):

```
$PIPE = <output_dir>/<company_dir>/_pipeline/
```

Path A (Bash): `mkdir -p "$PIPE"` (idempotent — a no-op if E0.7 already created it)
Path B (host-bridge MCP): confirm/create the directory through the host file tool.

Set `$PIPE` as a variable used throughout this role's steps. Remove it after Step E9.5 (same as the new-application Step 7g cleanup) — non-blocking if removal fails.

**Step E0.pipe.5 — `$PIPE` filesystem availability, already resolved**

`$PIPE_FILESYSTEM_AVAILABLE` was already determined once, at Step E0.7, immediately after the first role's `$PIPE` was created and before that role's baseline gatekeeper spawns — not here. This step is just a pointer: read the cached value for the rest of this role's steps below; do not re-run the canary check per role. If it resolved `false` at E0.7, every `$PIPE`-dependent step below (not just the baseline checks) follows the same byte-for-byte manual-relay rule described there.

**Step E0.type — Resolve CV Type (single resolution point for this run's output)**

Same design as the new-application pipeline's Step 0.type — this is the **only** place this pipeline resolves the CV Type this run will *produce*; every downstream spawn (Steps E3, E3.5, E5, E5.5, and the export step) reads the resolved value from `$PIPE/cv-type.txt`, never re-deriving it. (Step E0.7's inline read above answers a different, diagnostic-only question — see that step's note.)

1. Read `pipeline-preferences.json` → `cv_type.mode` (career-data first, plugin blank template as last-resort fallback — same R-37 resolution order as every other config key). **A present-but-invalid value** (anything other than exactly `Detailed`/`Brief`/`Variant`) is treated the same as missing: try the next source; invalid everywhere → default `Detailed`, noted in config-health.
2. If `mode` is `Detailed` or `Brief`, that is the resolved value — **the database backend is never consulted.**
3. If `mode` is `Variant`, read this role's own `CV Type` field from the configured database backend (a single targeted read on this role's Page ID — delegate to the backend adapter, never re-describe the mechanics inline). **Distinguish a genuine empty field from a failed read:** empty/absent field on a successfully-read page → resolved value defaults to `Detailed`. A read that errors or can't reach the page at all → stop and report for this role ("could not read `CV Type` for [Company] — [error]") rather than silently defaulting.
4. **If the resolved value is `Brief`:** confirm `$CV_TEMPLATE_BRIEF` exists now, before any revision work begins — fail fast rather than discovering the missing template only at export, after a full revision/gatekeeper cycle has already run. Missing → stop and report: "career-data is missing `references/templates/cv-brief.dotx` — run `/career-engine:setup --phase 5` to add it, or set `cv_type.mode` to `Detailed` for this role."
5. Write the resolved value (`Detailed` or `Brief`) to `$PIPE/cv-type.txt`.

**Step E0.titles — Write the role-tailoring plan to `$PIPE/cv-titles.md` (single resolution point)**

Same design as the new-application pipeline's Step 0.titles, same file format, including the `MODE: <role_matching>` header line (`capabilities` default, or `titles`, from `pipeline-preferences.json`) and the `## CV Title Preferences` block holding `cv_title_rules` lines first and the legacy property second labelled `(legacy tracker field)`, then the `## CV Titles` block, each verbatim or `none` / `PLAN: none` — read this role's `CV Titles` and legacy `CV Title Preferences` from the row payload captured at Step E0, never a fresh fetch, and never compose or repair a plan here. **A title wish in `Edit notes` counts as a `CV Title Preferences` entry** — copy that sentence into the preferences block verbatim. `PLAN: none` → the cv-writer derives the plan itself (`writer-craft/cv.md` §5c). **Every `cv-writer`, `gatekeeper` CV Check, and `recruiter-reviewer` spawn from Step E3 onward passes `CV_TITLES_PATH=$PIPE/cv-titles.md`** alongside `CV Type`. An existing CV written before this feature will usually not match the plan — that is a real revision item for Step E3, not a baseline defect.

### Pipeline `New Applications`

Agents in this track are explicitly informed they are improving existing work. Pass each agent:
- The structured JD from Step E0.5
- The existing CV text from the Notion row or the existing DOCX (whichever is available)
- The existing cover letter text (retrieved from the output run folder using the filename in `Letter File Name`; if the property is absent from the schema or empty, locate the file via the run-folder convention instead: state.json `cover_letter_path`/`cv_path`, or the Draft Directory company subdirectory with filename patterns `coverletter-*`/`cv-*` — extract text using `pandoc "<output_dir>/<letter-filename>.docx" -t plain` or read the `.md` sibling)
- The coach properties verified in Step E1
- Any reviewer feedback or notes already on the row

**Step E3 — CV writer (revision mode)**

Spawn `cv-writer` with `option=revision`. Pass:
- `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`
- `CV Type=<value from $PIPE/cv-type.txt, resolved at Step E0.type>` — read the file, never re-derive
- `CV_TITLES_PATH=$PIPE/cv-titles.md` — the role-tailoring plan (Step E0.titles); the writer executes it verbatim
- `CV_PATH=$PIPE/cv-final.md` (write) — **this is where the revised CV lands, and the explicit write that every later reference to `$PIPE/cv-final.md` (E3.25's comparison, E3.5/E5.5's gatekeeper reads, E5's read-and-overwrite, E7's "already at `$PIPE/cv-final.md`", E7.3's CV path) depends on.** The writer writes the full revised CV there and returns a 1-line status (R-41) — mirrors the new-application Step 4 convention exactly; no step downstream may assume this file exists unless this spawn (or a later overwrite of the same path) wrote it.
- The existing CV text as the draft (from the saved markdown backup at the output path, or extracted using `pandoc "<cv>.docx" -t markdown` if only the DOCX is available)
- The coach's verified properties as the strategic anchor
- The baseline content violation file path `$PIPE/gatekeeper-baseline-cv.md` from Step E0.7, if it returned FAIL — the cv-writer reads it directly (so it addresses pre-existing violations immediately, not after another loop). Omit this line entirely if Step E0.7 returned PASS (no file was written).
- Any recruiter or hiring manager feedback already on the row from the original pipeline run
- **`Edit notes` content** (from the Step E0 row payload) — if populated, include verbatim with the instruction: "Address these specific edit notes first, before applying general improvements: [content]". Omit if empty.

**Type-change check — read `$PIPE/existing-cv-type.txt` (written at Step E0.7) and compare against the value just resolved at Step E0.type.** If they're the same, this is an ordinary revision — proceed as below. **If they differ** (e.g. the existing CV is `Detailed` but this run's resolved CV Type is now `Brief`, or vice versa), this is not an incremental edit — the document's whole structure changes (section list, RoleOverview presence, Consulting split). Tell cv-writer explicitly: "This role's CV Type has changed from `<value from $PIPE/existing-cv-type.txt>` to `<new value>` since the existing draft was produced. Do not incrementally revise the existing text — restructure fully per the new CV Type's rules (`agents/cv-writer.md` Section Scope / Brief-Specific Rules), using the existing draft only as a source of role facts and proof points to carry forward, not as a structural base."

The cv-writer is improving the existing CV — not drafting a new one (except under the type-change case above, where a structural rewrite is expected and correct).

**Quality requirement — include this verbatim in the cv-writer prompt:**
> For every section you touch, return a before/after comparison stating specifically what changed and why the revision is stronger. If you leave a section unchanged, say so explicitly. If you cannot improve a section beyond rule-compliance — same structure, same sentences, minor word swaps — say "no quality improvement possible here" rather than returning near-identical text. Rule-compliant-but-equivalent output is a failure, not a revision.

**Step E3.25 — Quality comparison gate**

Before passing the revised CV to the gatekeeper, compare the old and new versions on four dimensions (this is the edit pipeline's own comparison step — it runs standalone with no orchestrator, unlike the New Application pipeline this step's wording was originally adapted from):

1. **Summary strength** — did it change substantively, or just swap words?
2. **Bullet specificity** — did bullets become more specific, quantified, or better targeted to this JD?
3. **Structural fit** — **applies only to a type-change role** (see the check above); does the new structure actually match the target CV Type's rules, not just carry over the old shape with new words? **For an ordinary revision where CV Type did not change, this dimension does not apply — exclude it from the count entirely, do not treat it as automatically met or automatically failed.**
4. **No regressions** — is any section weaker than before (vaguer, less specific, or missing a proof point)?

**The revision must be stronger than the original on at least 2 of the *applicable* dimensions, with zero regressions on dimension 4.** For a type-change role, that's 2 of 4 (dimension 3 counts). For an ordinary revision, that's 2 of the remaining 3 (dimensions 1, 2, 4 — dimension 3 is excluded, not counted as a pass). Either way, a revision that scores well elsewhere but weakens any section on dimension 4 still fails this gate. **The "stronger"/"weaker" judgment on each dimension is deliberately qualitative, not a numeric or word-count threshold** — matching this plugin's established design principle (see CLAUDE.md's "Why the opener rule is a principle, not a template" and the Brief CV `Earlier:` cutoff decision) that content-quality calls like this don't generalize to a fixed number across every user's writing and every role's content; the count (2 of N) is the only hard threshold here, applied to a per-dimension judgment call, not a formula.

**If it doesn't meet that bar:** Return to `cv-writer` with `option=revision`, quoting the specific weak section verbatim and instructing: "This section is not improved. Rewrite it — new structure, stronger framing, more targeted language. Do not return text that is substantively the same as the input." Max 2 loops. If no quality improvement is achieved after 2 loops, flag in the final delivery: "[Role] — CV section [X]: no quality improvement achieved after 2 rounds."

**If output is demonstrably stronger:** proceed to Step E3.5.

**Step E3.5 — Gatekeeper (content check)**

Spawn `gatekeeper` with `option=cv`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md`, the revised CV path `$PIPE/cv-final.md` to read (written by the Step E3 spawn), `Role summary` (from the coach properties verified in Step E1 — the JD proxy the gatekeeper reads), the role's `Keywords` property (from the coach properties verified in Step E1 — required for the ATS pre-check), and `OUTPUT_PATH=$PIPE/gatekeeper-cv-<round>.md` (R-41 — read the file for the violation list, never expect it inline).

**If PASS:** proceed to Step E4.

**If FAIL:** spawn `cv-writer` with `option=revision`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md`, the revised CV and the gatekeeper's full violation list. Pass the accumulated fix log from all prior rounds with the locked-fixes instruction (see the orchestrator's Absolute Constraints): reintroducing a previously fixed violation is itself a FAIL; a writer that reverts to an older base is re-spawned with the regression named — never patched by hand; also re-verify the FULL mechanical locked-fix checklist (Absolute Constraints), not just the newly flagged item. After revision, spawn `gatekeeper` again. Repeat until PASS. **Cap: 3 revision passes. After the third FAIL, this role is flagged here — per the Absolute Constraints' flag-and-deliver policy. Log the unresolved violations, then CONTINUE the edit flow with the best current CV — the letter track (Edit type `Both`) and export ALL still run; the CV delivers flagged (md + DOCX always reach the output folder). This role's Notion status still advances at the writeback step, exactly like a clean role's (flag-and-deliver policy, 2026-07-17 amendment — the flag lives in halted-roles.json, the feedback file, and the chat addendum, never in a withheld status; withholding it just requeued the same roles run after run).** Write an entry to `$OUTPUT_DIR/halted-roles.json` now (Absolute Constraints — append discipline, exact entry shape) — this is what makes the role reportable in the final chat delivery and run-metrics, not the round-by-round loop itself (which stays internal, not surfaced to the user). Log all violation rounds internally, continue processing every other role in the queue.

**Step E4 — Recruiter review**

Spawn `recruiter-reviewer` with `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md` (required — Brief's intentional structural absences must not be flagged as weaknesses; see the agent's own CV Type awareness section), the structured JD, the revised CV, and `OUTPUT_PATH=$PIPE/recruiter-review.md`. The reviewer writes its full review to that file and returns only a 2-line status (R-41 protocol). The reviewer is aware this is a revision, not a first draft.

**Step E5 — CV writer (final revision)**

Read recruiter feedback from `$PIPE/recruiter-review.md`. Spawn `cv-writer` with `option=revision`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md`, `CV_PATH=$PIPE/cv-final.md` (read and overwrite — the Step E3 output is the base; the final CV lands at this same path), and the recruiter review path `$PIPE/recruiter-review.md` to read. The writer overwrites `$PIPE/cv-final.md` in place and returns a 1-line status (R-41) — same convention as the new-application Step 4 spawn.

**Step E5.5 — Gatekeeper (content check)**

Spawn `gatekeeper` with `option=cv`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md`, the final CV path `$PIPE/cv-final.md` to read (overwritten by the Step E5 spawn), `Role summary` (from the coach properties verified in Step E1), the role's `Keywords` property, and `OUTPUT_PATH=$PIPE/gatekeeper-cv-<round>.md` (R-41 — read the file for the violation list, never expect it inline).

**If PASS:** proceed to Step E7.

**If FAIL:** spawn `cv-writer` with `option=revision`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, `CV Type=<value from $PIPE/cv-type.txt>`, `CV_TITLES_PATH=$PIPE/cv-titles.md`, the final CV and the gatekeeper's full violation list. Pass the accumulated fix log from all prior rounds with the locked-fixes instruction (see the orchestrator's Absolute Constraints): reintroducing a previously fixed violation is itself a FAIL; a writer that reverts to an older base is re-spawned with the regression named — never patched by hand; also re-verify the FULL mechanical locked-fix checklist (Absolute Constraints), not just the newly flagged item. After revision, spawn `gatekeeper` again. Repeat until PASS. **Cap: 3 revision passes. After the third FAIL, this role is flagged here — per the Absolute Constraints' flag-and-deliver policy. Log the unresolved violations, then CONTINUE the edit flow with the best current CV — the letter track (Edit type `Both`) and export ALL still run; the CV delivers flagged (md + DOCX always reach the output folder). This role's Notion status still advances at the writeback step, exactly like a clean role's (flag-and-deliver policy, 2026-07-17 amendment — the flag lives in halted-roles.json, the feedback file, and the chat addendum, never in a withheld status; withholding it just requeued the same roles run after run).** Write an entry to `$OUTPUT_DIR/halted-roles.json` now (Absolute Constraints — append discipline, exact entry shape, including `delivered_files` once export completes). This is what makes the flagged role reportable in the final chat delivery and run-metrics; naming it in chat with no persisted entry is not sufficient and does not satisfy this step. Log all violation rounds internally, continue processing every other role in the queue.

**Step E6.8 — Voice calibration (resolve)**

Read `${CAREER_DATA}/references/voice-calibration-coverletters.md` directly — no agent spawn.

- **If it exists:** copy its content to `$PIPE/voice-calibration.md`. Proceed to Step E7.
- **If it does not exist** (new user, or the user has not yet applied the update-prompt that delivers it): this is not an error — do not hard-stop. Proceed to Step E7 without creating `$PIPE/voice-calibration.md`. The letter-writer falls back to its standalone Voice Gate (read the delivered-letters archive directly, or `03-framework.md` §Voice and tone if the archive is also empty; the humanizer was retired 2026-07-26).

**Either way, the letter-writer ALSO reads real letters from the delivered-letters archive at its Voice Gate (restored 2026-07-16, per the user's direct instruction).** The calibration file is a supplement to the archive, never a substitute — do not describe it to any spawned agent as making the archive read unnecessary.

**Step E6.85 — Capability preflight (once per run)**

**Run this once, on the first role of the run — not per role, and regardless of that first role's `Edit type`.** Unlike E6.9 immediately below (which genuinely skips for Edit type `CV`, since there's no letter track to outline), this step is a pure environment capability test with no dependency on any one role's content — it doesn't matter whether the first role in the queue happens to be `CV`-only; run it anyway, on schedule, so the cached value is ready the moment any later role in the batch reaches a letter track. **Do not inherit E6.9's `Edit type = CV` skip here** — that would defer this check to the first `Letter`/`Both` role in the queue instead of the literal first role, breaking "once, on the first role" for any batch that opens with one or more `CV`-only roles. Check whether this environment can resume a sub-agent instance across multiple spawns (the mechanism Step E7 and its revision loops rely on to keep talking to the same letter-writer, and now the same career-coach, across a role's revision rounds instead of hiring a fresh one every round). **The concrete test:** search available tools for `SendMessage` (e.g. `ToolSearch query="select:SendMessage"` or equivalent for this environment) — if it resolves to a usable tool, resume is available; if the search returns nothing, it isn't. Cache the result as `$SENDMESSAGE_AVAILABLE` (true/false) for the rest of the run — do not re-check per role or per revision round.

- **If available:** every "resume" instruction below (letter-writer and career-coach) reuses the same cached instance across all touchpoints for that role.
- **If unavailable:** log it plainly, once — "this environment can't reuse sub-agents; every revision spawns a fresh writer/coach with full context instead" — and every "resume" instruction below falls back to a fresh spawn with full accumulated context, for the rest of the run, without rediscovering the same fact on every role.

**Step E6.9 — Letter plan (from intake's Letter Outline; coach spawn is fallback only)**

**Skip this entire step if Edit type = `CV`** — there is no letter track for this role, so there is nothing to plan. Only run this step for Edit type `Letter` or `Both`, matching the same gate every other letter-only step in this pipeline observes.

**Primary path — no coach spawn (2026-07-22, per the user's instruction: "during intake is when the coach should enter into WIWTR the actual outline + opener that is recommended ... cuts the coach's role and necessary effort for application pipelines (edit and new of course)").** Take the Why I Want This Role content from the Step E0 row payload and look for a `[LETTER OUTLINE` ... `[/LETTER OUTLINE]` block — or, on rows intaken before the 2026-07-23 rename, the legacy `[COACH LETTER PLAN` ... `[/COACH LETTER PLAN]` markers, handled identically — (written by intake Step 0.9a Write C; user edits in Notion are authoritative). If present:

1. Write the block's `Template:` value to `$PIPE/template-selection.txt` — the single token, nothing else.
2. Write the block's `Opener:` line when present (2026-07-24 — the coach's verbatim bank-variant copy; older blocks lack it), followed by its `Para N:` outline lines, to `$PIPE/coach-outline.md`. **A legacy `Opener anchor:` line (blocks written 2026-07-22 → 2026-07-24, before the anchor's retirement) is DROPPED — never copied into `coach-outline.md` and never read for content** (retired 2026-07-24, per the user's direct instruction; it was the confirmed injection vector for coach-composed prose).
3. **Strip the block (markers included) from the WIWTR content** — every downstream use of "Why I Want This Role content" in this pipeline means the stripped text (the user's motivation only).

**Fallback — legacy rows only:** if the WIWTR contains neither a `[LETTER OUTLINE` nor a legacy `[COACH LETTER PLAN` block, spawn `career-coach` with **Option 4a — Pre-Draft Outline** (the agent dispatches by this literal heading name — never a slug-style `option=` value, unlike the gatekeeper), passing:
- `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`
- `Role summary`, `Strategy`, `Keywords` (from the coach properties verified in Step E1)
- Why I Want This Role content (from the Step E0 row payload) — pass verbatim if populated, empty if not
- `Gap handling` (from the Step E1 coach properties)
- Company name and role title
- The user's `references/templates/cover_letter_templates.md` if present (career-data path); note its absence explicitly if not

The coach writes `$PIPE/template-selection.txt` and `$PIPE/coach-outline.md` (first line `Opener: <...> (variant <n>)` per the Option 4a output contract — no `Opener anchor:` line, retired 2026-07-24) and returns `COACH-OUTLINE: template=<selection> → $PIPE/template-selection.txt, outline written → $PIPE/coach-outline.md` (R-41). Log in the role's delivery: "Letter plan generated in-pipeline (legacy WIWTR — re-run intake to move letter planning into Notion review)." When `$SENDMESSAGE_AVAILABLE`, capture the returned agent ID to `$PIPE/coach-agent-id.txt` (crash-recovery reuse only — the Step E7.4 coach review no longer exists).

Read `$PIPE/template-selection.txt` after this step — its value is threaded into the gatekeeper spawns at Steps E7.3 and E7.7 below as `Template selected=<value>`, for Gate 9. The letter plan `$PIPE/coach-outline.md` (Opener line + outline; no anchor since 2026-07-24) is likewise passed to those same gatekeeper spawns for the opener source check and Gate 9 outline conformance.

**Step E7 — Cover letter (initial revision)**

**Gate — always run the letter track for `Letter`/`Both`; the letter-writer decides write-or-skip.** Why I Want This Role is **no longer required** to edit a letter. Spawn the letter-writer whether or not `Why I Want This Role` is populated (pass it if present, empty if not). The letter-writer's **Sufficiency Gate** decides: it revises from the Motivation Bank (its primary source) plus Why I Want This Role when present, or — if there is no Why I Want This Role content **and** no role-relevant Motivation Bank material — returns a skip. **If the letter-writer returns a skip:** for Edit type `Both`, continue with the CV track only; for `Letter`, skip the role. Log and surface the writer's message (it tells the user to add Why I Want This Role or enrich the Motivation Bank). **Do NOT pre-skip on an empty Why I Want This Role** — that decision belongs to the letter-writer now. **And WIWTR is never a run blocker in any state (2026-07-16):** empty, or still carrying unanswered `[COACH PROMPTS` questions — pass it through as found and keep going; never stop to ask the user to answer the prompts mid-run (see the identical rule at `career-engine-new-application/SKILL.md` Step 4.9→5 for the full statement and the real incident).

**Before spawning letter-writer:** Read the following from the Notion row payload collected in Step E0 (all are part of the full row payload already in memory):
- **`Why I Want This Role` property** — the user's role-specific motivation; include the full content **if populated** (the letter-writer's primary source is the Motivation Bank, loaded from career-data). If empty, pass it empty — the Sufficiency Gate decides.

Spawn `letter-writer` with `option=revision`. Pass:
- `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`
- The existing cover letter (from the output run folder using the filename in `Letter File Name`; if the property is absent from the schema or empty, locate the file via the run-folder convention instead: state.json `cover_letter_path`/`cv_path`, or the Draft Directory company subdirectory with filename patterns `coverletter-*`/`cv-*`)
- The baseline cover letter violation file path `$PIPE/gatekeeper-baseline-cl.md` from Step E0.7, if it returned FAIL — the letter-writer reads it directly. Omit this line entirely if Step E0.7 returned PASS (no file was written).
- From the coach properties verified in Step E1: **`Role emphasis`** (content input — the role's Mandate / Likely KPIs, the writer's only role-analysis input) and **`Strategy`** (routing token — letter type + word ceiling only). **Do NOT pass `Keywords`, `Gap handling`, `Role summary`, `Relationship type`, `Culture`, or `Landscape`** — per the 2026-07-14 letter-writer input contract (same contract as New Application Step 5: exactly three content inputs — CV, `Role emphasis`, Why I Want This Role — plus the coach's outline `$PIPE/coach-outline.md` as structural spine (restored 2026-07-16), identity, and routing tokens, nothing else)
- **The CV (always required — for context).** If Edit type is `Both`, use the final revised CV from Steps E3–E5 (already at `$PIPE/cv-final.md`). If Edit type is `Letter`, read the existing CV from the output run folder using the filename in `CV File Name` from the Notion row (fallback: state.json `cv_path`, or the Draft Directory company subdirectory with filename pattern `cv-*`). Extract text via `pandoc "<cv-file>.docx" -t plain` and **write the extracted markdown to `$PIPE/cv-text.md`** (Path A: Bash directly; Path B: run pandoc via the host process tool and write through the host file tool, same routing as E8.5/E9/E9.5 — this extraction was previously the letter track's only Path A-only file operation) — this file is the CV reference for all subsequent cover letter gatekeeper spawns (Steps E7.3, E7.7, E8.5). If the CV file cannot be located, log a warning and skip the write (the gatekeeper spawns will report the repetition check skipped); proceed — but never omit this attempt silently. The letter-writer uses the CV to check first-person consistency, scope claims, and experience framing.
- **`Why I Want This Role` — when populated, pass the verbatim text as a quoted block, never paraphrased or distilled.** The letter-writer's instruction rules require working from the user's exact words, not thematic summaries of them. If the Edit notes reference this field as the content source, that is even more reason to pass it raw — the writer must receive the actual material, not the orchestrator's interpretation of it. If empty, pass it empty; the letter-writer falls back to the Motivation Bank (its primary source). (R-44)
- **`Edit notes` content** (from the Step E0 row payload) — if populated, include verbatim with the instruction: "Address these specific edit notes first, before applying general improvements: [content]". Omit if empty.
- **Do NOT pass the recruiter review** (`$PIPE/recruiter-review.md`) — its "Interview-trigger gaps" section is user-facing interview-prep feedback surfaced in the role's feedback file, never letter material (2026-07-14 input contract).
- The coach's **template selection** (`$PIPE/template-selection.txt`) from Step E6.9 — a single token; the writer no longer chooses the template itself.
- The coach's **outline** (`$PIPE/coach-outline.md`) from Step E6.9 — the writer's structural spine (restored 2026-07-16, per the user's direct instruction); bare paragraph subjects, structure only. Conformance to the same outline is checked by Gate 9 at Steps E7.3/E7.7 (the Step E7.4 coach review was removed 2026-07-22).
- `LETTER_PATH=$PIPE/letter-draft.md` — the writer writes its output to this file and returns only a 2-line status + path (R-41 protocol).

The letter-writer improves the existing letter — it does not start from scratch. **Exception:** if the Edit notes contain an explicit "write from scratch" instruction, spawn the letter-writer in fresh-draft mode and discard the existing letter as the starting point. **When "write from scratch" is present, this instruction applies to ALL language versions** — if the role's `Languages` property includes Hebrew or other languages, Step E9H must also regenerate those versions from scratch (do not carry the old localized text forward as a base; spawn localization with the new English letter as the source).

The cover letter is written to the DOCX file only. Do not write cover letter text to any Notion property.

**Capture the returned agent ID** and write it to `$PIPE/letter-writer-agent-id.txt`. This is the one instance that gets resumed — never re-spawned fresh — for every subsequent letter-writer touch on this same letter (the revision loops below, including E7.3, E7.7, E8.5, and the quality-comparison loop).

> **⛔ Resume, don't respawn — applies to every "spawn letter-writer with option=revision" instruction for this letter, anywhere below.** A fresh subagent has no memory of what it already tried or why — this is precisely how a real production run took 4 gatekeeper rounds on one letter: fixing "role in sentence 1" broke "subject-first," and a fresh, memoryless writer fixing *that* produced a banned cliché neither rule caught. Instead: read `$PIPE/letter-writer-agent-id.txt` and resume that exact instance (send it a new message; do not spawn a new one) with a prompt scoped to *only* the new feedback — "Gatekeeper/coach found these issues: [violations]. Fix only these — leave everything else exactly as it is." The resumed instance still retains its own R-41 output contract (write to `$PIPE`, return a 1-line status) — nothing about resuming changes what the orchestrator holds in its own context. **If `$PIPE/letter-writer-agent-id.txt` is missing or the resume fails** (e.g. crash-recovery restart): fall back to a fresh `option=revision` spawn — **"full context" means every input the original Step E7 spawn received (`CAREER_DATA`, the existing cover letter, `Role emphasis`, `Strategy`, the CV text, Why I Want This Role, `Edit notes`, the coach's template-selection token AND outline `$PIPE/coach-outline.md` from Step E6.9 — exactly the E7 input contract, nothing more) plus the current draft at `$PIPE/letter-draft.md` and every accumulated violation/feedback file (`$PIPE/fix-log.md` and any gatekeeper/coach review files produced so far) — not the draft and feedback alone**, since a fresh instance has none of the resumed instance's memory and must reconstruct the same grounding the original spawn had. A crash-recovery respawn never widens the contract — `Keywords`, `Gap handling`, `Role summary`, and the recruiter review stay out here exactly as they do at Step E7 (the coach outline is IN — part of the E7 contract since 2026-07-16). Capture and overwrite the agent-ID file with the new instance.

**Step E7.25 — Cover letter quality comparison gate**

Before passing the revised cover letter to the gatekeeper, compare the old and new versions on four dimensions:

1. **Opening strength** — does it pull the reader in immediately, or start with a generic frame?
2. **Specificity** — does it name concrete things about this company, this role, or this intersection of the user's background?
3. **Voice naturalness** — does it sound like a person talking, or like assembled copy?
4. **Closing force** — does it end with a reason to respond, or trail off?

**The new letter must be stronger than the old on at least 2 of these 4 dimensions.** As with Step E3.25's CV dimensions, this is a qualitative per-dimension judgment call, not a numeric or word-count formula — only the count (2 of 4) is a hard threshold.

**If it is not:** **Resume the letter-writer instance** (see the resume rule at Step E7 — do not spawn fresh), quoting the old letter's strongest lines verbatim and instructing: "The revision is not better. The original was stronger in [specific dimension]. Here are the lines that worked best in the original: [quoted lines]. Write a new letter that preserves this strength while fixing the identified problems." Max 2 loops. If no improvement after 2 loops, preserve the original letter and flag in the final delivery: "[Role] — cover letter: quality ceiling reached — the revision could not improve on 2 of 4 dimensions after 2 attempts. Original letter preserved. To get a different result, add specific Edit notes (e.g., 'rewrite paragraph 3 to strengthen the [X] angle') and re-run." **Then continue to Step E7.3 with the preserved original written to `$PIPE/letter-draft.md`** — the quality ceiling changes which text proceeds, never the remaining gate sequence; the original must still pass every downstream gate (and is flagged per the flag-and-deliver policy if it can't — delivered either way) before export.

**If it is stronger:** proceed to Step E7.3.

**Step E7.3 — Gatekeeper (cover letter check — initial)**

Spawn `gatekeeper` with `option=cover-letter`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, the cover letter (read from `$PIPE/letter-draft.md`), `Role summary` (from the coach properties verified in Step E1 — includes the Company self-characterization section), `Strategy` (from the coach properties verified in Step E1 — governs the word-count ceiling: 250 instead of 320 when `Strategic`), the user's Why I Want This Role content (retrieved in Step E7 from Notion), the CV path to read: `$PIPE/cv-final.md` for Edit type `Both`; `$PIPE/cv-text.md` for Edit type `Letter` (written from the pandoc extraction in Step E7); if the CV file does not exist (CV could not be located in Step E7), state that explicitly so the gatekeeper reports the skipped check by name — do not pass a path that doesn't exist; `$PIPE/opener-derivation.txt` to read if it exists (the letter-writer's opener-derivation record, for Gate 5's derivation check — the letter-writer writes it at drafting), `$PIPE/wiwtr-checklist.md` to read if it exists (the letter-writer's numbered [WIWTR-N] point list, for Gate 2's coverage check — omit this parameter entirely if the file wasn't written); and `Template selected=<value read from $PIPE/template-selection.txt at Step E6.9, or omit if that file was absent>`.

**If PASS:** proceed via Step E7.4 (a no-op conformance note since 2026-07-22) to Step E7.7. On round 2+ the gatekeeper's own reply may read `PASS — cover letter [Tier 2: <n>% — deferred to humanizer]` — this is a normal round-aware PASS (Tier 1 clean, Tier 2 below 70% but no longer blocking past round 1), not an error. When it carries that deferred note, log the failing Tier 2 check types (read from the gatekeeper's `OUTPUT_PATH`) under `## Gatekeeper — Tier 2 Deferred to Humanizer (Step E7.3)` in the revision log; the humanizer handles them from there.

**If FAIL — round 1:** **resume the letter-writer instance** (see the resume rule at Step E7 — do not spawn fresh), passing the cover letter and the gatekeeper's full violation list. Pass the accumulated fix log from all prior rounds with the locked-fixes instruction (see the orchestrator's Absolute Constraints): reintroducing a previously fixed violation is itself a FAIL; a writer that reverts to an older base is re-spawned with the regression named — never patched by hand. After revision, spawn `gatekeeper` again with `option=cover-letter` (same parameters as the Step E7.3 spawn above, including `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE` and `Strategy`). Log all violation rounds internally.

**If FAIL — round 2+:** this only occurs when a Tier 1 check still fails (Tier 2 alone never blocks past round 1 — see the PASS case above). Loop as above. Hard/Tier 1 fails block every round.

**Cap: 3 revision passes on hard fails — but confirm the mechanical locked-fix checklist (Absolute Constraints) was actually re-verified each round before treating the cap as genuinely exhausted, not just re-flagged.** After the third hard-fail FAIL, this role is flagged here — per the Absolute Constraints' flag-and-deliver policy. Log the unresolved violations. **Stop the revision loop for this role and skip the remaining quality steps — proceed DIRECTLY to this pipeline's export step with the best current text and deliver it flagged (the md and DOCX always reach the output folder). This role's Notion status still advances at the writeback step, exactly like a clean role's (flag-and-deliver policy, 2026-07-17 amendment — the flag lives in halted-roles.json, the feedback file, and the chat addendum, never in a withheld status; withholding it just requeued the same roles run after run).** Write an entry to `$OUTPUT_DIR/halted-roles.json` now (Absolute Constraints — append discipline, exact entry shape, including `delivered_files` once export completes). This is what makes the flagged role reportable in the final chat delivery and run-metrics; naming it in chat with no persisted entry is not sufficient and does not satisfy this step. Continue processing every other role in the queue normally — if this role already produced a passing CV, that CV's own delivery is unaffected; the cover letter delivers flagged, and only the role's clean "done" status is withheld.

**Step E7.4 — Strategic conformance (coach review removed 2026-07-22)**

The per-role coach review that ran here was removed per the user's instruction ("the coach doesn't need to be in the application pipelines anymore at all ... (edit and new of course)"). Strategic conformance is enforced by the gatekeeper's Cover Letter Check at Steps E7.3 and E7.7: the opener source check verifies the opener's derivation matches the plan's `Opener:` variant (or logs a substitution reason; the opener-anchor conformance check was retired with the anchor, 2026-07-24), and Gate 9 verifies the letter follows the plan's outline — the plan being user-approved at intake. **Spawn nothing here; proceed directly to Step E7.7.**

**Step E7.7 — Gatekeeper (cover letter check — final)**

Spawn `gatekeeper` with `option=cover-letter`, passing `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`, the final cover letter text, `Role summary` (from the coach properties verified in Step E1), `Strategy` (same as Step E7.3), the user's Why I Want This Role content, the final CV text (same as Step E7.3), `$PIPE/opener-derivation.txt` to read if it exists (the letter-writer's opener-derivation record, for Gate 5's derivation check — the letter-writer writes it at drafting), `$PIPE/wiwtr-checklist.md` to read if it exists (same as Step E7.3), and `Template selected=<same value passed at Step E7.3, or omit if that file was absent>`.

**If PASS:** proceed to E8.5 (Step E8 is retired). If the reply carries a Tier 2 deferred note, log the failing Tier 2 check types (read from the gatekeeper's `OUTPUT_PATH`) under `## Gatekeeper — Tier 2 Deferred (Step E7.7)` in the revision log and in the role's feedback file — with the humanizer retired (2026-07-26, per the user), deferred Tier 2 items are user-visible notes, not a later agent's queue.

**If FAIL (a Tier 1 check still failing):** **resume the letter-writer instance** (see the resume rule at Step E7 — do not spawn fresh), passing the final cover letter and the gatekeeper's full violation list. Pass the accumulated fix log from all prior rounds with the locked-fixes instruction (see the orchestrator's Absolute Constraints): reintroducing a previously fixed violation is itself a FAIL; a writer that reverts to an older base is re-spawned with the regression named — never patched by hand; also re-verify the FULL mechanical locked-fix checklist (Absolute Constraints), not just the newly flagged item. After revision, spawn `gatekeeper` again with `option=cover-letter` (same parameters as the Step E7.7 spawn above, including `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE` and `Strategy`). **Cap: 3 revision passes on hard fails. After the third FAIL, this role is flagged here — per the Absolute Constraints' flag-and-deliver policy.** Log the unresolved violations. **Stop the revision loop for this role and skip the remaining quality steps — proceed DIRECTLY to this pipeline's export step with the best current text and deliver it flagged (the md and DOCX always reach the output folder). This role's Notion status still advances at the writeback step, exactly like a clean role's (flag-and-deliver policy, 2026-07-17 amendment — the flag lives in halted-roles.json, the feedback file, and the chat addendum, never in a withheld status; withholding it just requeued the same roles run after run).** Write an entry to `$OUTPUT_DIR/halted-roles.json` now (Absolute Constraints — append discipline, exact entry shape, including `delivered_files` once export completes). This is what makes the flagged role reportable in the final chat delivery and run-metrics; naming it in chat with no persisted entry is not sufficient and does not satisfy this step. Log all violation rounds internally, continue processing every other role in the queue.

---

**Step E8 — Humanizer — RETIRED (per the user's direct instruction, 2026-07-26: "The only thing humanizer seems to actually effectively be doing is taking semi and/or non-slop and turning it into its own version of slop. Not helpful. give the gatekeeper the quantitative checks and get rid of humanizer")**

**No humanizer pass runs. Ever.** The letter that passed E7.7 is the final text — no agent edits it after its last gatekeeper PASS. The Quantitative Final Gate's checks now live in Gate 10 of the Cover Letter Check (mechanical, gatekeeper-run in the E7.3/E7.7 rounds; violations route to the letter-writer like any Tier 2 item). Proceed to E8.5.

**Step E8.5 — Final verification on the exported bytes**

With the humanizer retired, no agent has touched the text since its E7.7 gatekeeper PASS — no fresh gatekeeper spawn is needed here. Run the mechanical pre-export checklist directly (Bash in the orchestrator's own context on Path A; on Path B through the host process tool, against the host-side copy of `$PIPE/letter-draft.md`) — same checklist as the main pipeline's Step 5.95 (`skills/career-engine-new-application/SKILL.md`): company name in first body paragraph, role title in body, zero em dashes/colons in body text, the banned-pattern greps, word count ≤320 (≤250 when `Strategy = Strategic`) via `wc -w` run here directly (the guaranteed-mechanical enforcement of the cap, never delegated), the Gate 6 Tier 1 banned-vocabulary/phrase/fit-declaration grep battery (personal-voice exemption applied first), the Opener verbatim check (the pasted Opener span excluded from the grep batteries per letter-gates' Opener precedence rule), and the round-snapshot presence check (if `$PIPE/gatekeeper-cl-2.md` exists, at least one `letter-draft-round-<n>.md` must too — missing snapshots are logged as a process violation, never silent).

**If all pass:** proceed to E9. **If any item fails:** **resume the letter-writer instance** (see the resume rule at Step E7 — do not spawn fresh) with the specific failures named, then re-run this step. Cap: 2 rounds. **After the cap:** this role is flagged — flag-and-deliver policy: log the failure, proceed DIRECTLY to export with the best current text, deliver flagged (md + DOCX always reach the output folder; Notion status still advances at writeback; the flag lives in `halted-roles.json`, the feedback file, and the chat addendum). Write the `$OUTPUT_DIR/halted-roles.json` entry now. Continue every other role normally.

**Step E9 — Produce DOCX**

Follow the same pandoc production protocol as the main pipeline. See `career-engine-export` for the full protocol — including its CV-Type-conditional template selection (`$CV_TEMPLATE` vs `$CV_TEMPLATE_BRIEF`), which reads `$PIPE/cv-type.txt` (resolved at Step E0.type) exactly as the new-application pipeline does.

Derive `<company_dir>` from the Company name using the naming convention in `career-engine-export`. Convert using the original run folder as the temporary landing pad: write the final CV markdown and the final cover letter markdown (the E8.5-verified `$PIPE/letter-draft.md`) to a temporary location, convert with pandoc using the `.dotx` reference templates, update the CV Subtitle, and copy both files to `<output_dir>/<company_dir>/`. If a file with the same name already exists, overwrite it — this is an edit, not a new file.

**This step follows the same Path A/B routing established at E0-pre — it was previously the only file-producing step in this pipeline written as Path A-only, which made it unexecutable exactly where E0-pre's Path B detection had already said Bash can't reach the host filesystem:**
- **Path A (direct Bash):** write the markdown to `/tmp/`, run pandoc and `update-subtitle.py` via Bash, `cp` the DOCXs to `<output_dir>/<company_dir>/`.
- **Path B (host-bridge MCP):** write the intermediate markdown through the host file tool (host-side paths, never sandbox `/tmp/`), run pandoc and the subtitle script via the host process tool, and place the DOCXs in `<output_dir>/<company_dir>/` through the same tools — matching the routing E8.5's mechanical checklist and E9.5's move already use.

Verify the produced file(s) exist and are nonzero before proceeding to Step E9.5. (Only the file(s) for the active Edit type are produced here — the unedited companion file is handled in E9.5.) **If verification fails** (file missing or zero bytes): re-run the pandoc conversion once; if the retry also fails, stop this role, log "[Company] — [Role Title]: DOCX production failed after retry — [error]" in the run-level revision log, flag it in the final delivery for manual export, and continue to the next role in the queue rather than blocking the whole run.

**Step E9.5 — Move edited DOCXs to today's dated folder**

Regardless of what was edited (CV only, letter only, or both), move **both** DOCX files — CV and cover letter — from the original run folder to a new folder named with today's edit date. This keeps the original run folder clean and makes it immediately obvious which files are the most recently edited versions.

**The unedited file must travel too.** Step E9 only produces the file(s) for the active edit type — the other file was not re-converted. Before moving, locate the unedited file in the original run folder (`<output_dir>/<company_dir>/`):
- Edit type `CV`: locate the existing cover letter DOCX by filename (`Letter File Name` Notion property → state.json `cover_letter_path` → `coverletter-*` glob in the company subdirectory). It must move alongside the freshly produced CV.
- Edit type `Letter`: locate the existing CV DOCX (`CV File Name` → state.json `cv_path` → `cv-*` glob). It must move alongside the freshly produced cover letter.
- Edit type `Both`: both files were produced by E9; no special handling needed.

If the unedited file cannot be located, log the missing file and move what is available — do not block the move of the edited file.

```
$EDIT_DIR = $OUTPUT_FOLDER/${OUTPUT_DIR_PREFIX:-applications}-<YYYY-MM-DD-today>/<company_dir>/
```

Create `$EDIT_DIR` if it does not exist.

**Path A (direct Bash):**
```bash
mkdir -p "$EDIT_DIR"
# Move CV DOCX if it exists
CV_DOCX="<output_dir>/<company_dir>/<cv-filename>.docx"
[ -f "$CV_DOCX" ] && mv "$CV_DOCX" "$EDIT_DIR/"

# Move cover letter DOCX if it exists
CL_DOCX="<output_dir>/<company_dir>/<coverletter-filename>.docx"
[ -f "$CL_DOCX" ] && mv "$CL_DOCX" "$EDIT_DIR/"
```

**Path B (host-bridge MCP):** Use the host filesystem tool's move/rename capability for each file.

**If today's folder is the same as the original run folder** (i.e., the original pipeline ran today): skip the move — the files are already in the right place. Set `$EDIT_DIR = <output_dir>/<company_dir>/` and proceed.

**After the move, patch the original `state.json`:** Open the state.json in the original run folder, find the entry for this role's `notion_page_id`, and update `cv_path` and `cover_letter_path` to the new paths under `$EDIT_DIR`. **If this role's CV was produced under Step E3's type-change branch** (the resolved CV Type differed from the value in `$PIPE/existing-cv-type.txt`, read before `$PIPE` cleanup below), also update the entry's `cv_type` field to the new resolved value — otherwise leave it untouched. Leave all other fields untouched. This ensures a future edit run finds the files immediately rather than falling back to pattern-search.

Non-blocking: if the move or patch fails, log the failure and continue — the files remain in the original folder and the pipeline proceeds.

**`$PIPE` cleanup:** After the move, remove the `_pipeline/` scratch directory — but **only if Hebrew localization (Step E9H) is not running for this role** (i.e., `Languages` is empty or does not include `Hebrew`). If Hebrew localization will run, delay `$PIPE` cleanup until after Step E9H completes. Cleanup: Path A: `rm -rf "$PIPE"`; Path B: host file tool delete. Non-blocking — log and continue if removal fails. The output folder after cleanup contains only the moved DOCXs (in `$EDIT_DIR`) and the unchanged originals (state.json, feedback.md, revision logs).

**Step E9H — Additional language localization (conditional)**

**Language resolution rule:** If the `Languages` property from Step E0 is **empty or not set**, produce output in `$DEFAULT_LANGUAGE` only — skip this step entirely and proceed to Step E10. If `Languages` is populated, handle all listed languages beyond the default here.

**Hebrew localization — runs only if `Languages` explicitly includes `Hebrew`.** If `Hebrew` is not listed, skip even if other non-default languages are listed. If `Hebrew` is not present, skip this step entirely and proceed to Step E10. **After Step E9H completes (or is skipped), run the `$PIPE` cleanup described in Step E9.5 if it was deferred.**

**Guard — Hebrew CV export requires `CV Type=Detailed` for this role.** Hebrew CV export uses the fixed `$CV_TEMPLATE_HE` (`cvHe.dotm`) template, which is built for the Detailed CV's structure — no Brief-format Hebrew template exists yet. If `$PIPE/cv-type.txt` (resolved at Step E0.type) is `Brief`, Edit type is `CV` or `Both`, and this role's `Languages` includes `Hebrew`: **stop the CV-side Hebrew export for this role and report it** — "Hebrew export for [Company] skipped: Brief CV Type has no Hebrew template yet (`cvHe.dotm` is Detailed-only). English Brief CV proceeds normally; add a Hebrew Brief template to career-data to enable this, or set this role's CV Type to Detailed." The Hebrew **cover letter** is unaffected by this guard (its template, `he-letter.dotx`, doesn't vary by CV Type) and proceeds normally for Edit type `Letter` or `Both`.

Spawn `localization` with:
- `CAREER_DATA=${CAREER_DATA}`, `gap_handling_mode=$GAP_HANDLING_MODE`
- The final English CV markdown — for Edit type `Both`, the final revised CV from Step E5 (in memory); for Edit type `Letter`, extract from the existing CV DOCX (`CV File Name` → state.json `cv_path` → `cv-*` glob) via `pandoc "<cv-file>.docx" -t plain`
- The final English cover letter markdown (read from `$PIPE/letter-draft.md`)
- The structured JD from Step E0.5
- The exact role title from the JD

The agent returns a Hebrew CV markdown block and a Hebrew cover letter markdown block.

Write to `/tmp/` and convert:

```bash
cat > /tmp/he-<cv_filename>.md << 'MARKDOWN_EOF'
<Hebrew CV markdown from agent>
MARKDOWN_EOF

cat > /tmp/he-<cl_filename>.md << 'MARKDOWN_EOF'
<Hebrew cover letter markdown from agent>
MARKDOWN_EOF

# $CV_TEMPLATE_HE, $CL_TEMPLATE_HE, and $CV_FOOTER_HE already resolved above (fixed career-data paths, no config key)
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

python3 "${CLAUDE_PLUGIN_ROOT}/skills/career-engine-export/scripts/update-subtitle.py" \
  "<output_dir>/<company_dir>/he-cv-<last-name>-<roletitle>-<company>-<monYYYY>.docx" \
  "<role title>"

# Hebrew cover letter
pandoc /tmp/he-<cl_filename>.md \
  --reference-doc="${CL_TEMPLATE_HE}" \
  -o "<output_dir>/<company_dir>/he-coverletter-<last-name>-<roletitle>-<company>-<monYYYY>.docx"

ls -lh "<output_dir>/<company_dir>/he-cv-<last-name>-<roletitle>-<company>-<monYYYY>.docx"
ls -lh "<output_dir>/<company_dir>/he-coverletter-<last-name>-<roletitle>-<company>-<monYYYY>.docx"
```

If a Hebrew file with the same name already exists, overwrite it — this is an edit.

After conversion, move the Hebrew DOCX files to `$EDIT_DIR` (same destination as the English files in Step E9.5) using the same Path A/B logic. Non-blocking if the move fails.

**Step E10 — Notion writeback and state update**

1. Confirm both English DOCX files are saved in `$EDIT_DIR` (set in Step E9.5 — today's dated folder, or the original folder if today's run date matches).
2. Write the Draft Directory URL to the `Draft Directory` URL property on the Notion row, using the edit-date folder (today's date, from `$EDIT_DIR`):
   ```
   Draft Directory: $DRAFT_DIR_URL_BASE<today-date-folder>%2F<company_dir>%2F
   ```
   Use `$DRAFT_DIR_URL_BASE` — the value resolved from `pipeline-preferences.json` in Step E0-pre. If `$DRAFT_DIR_URL_BASE` is empty or `skip`, omit this property from the writeback entirely. Do not write an empty string or the literal word "skip" to the Notion property. If omitted, include a named note in the final chat delivery: "Draft Directory not written for [Company] — `draft_dir_url_base` not configured or empty. Run `/career-engine:setup --phase 5` to configure it."
   This always reflects where the DOCX files actually are after Step E9.5. Hebrew files (if produced in Step E9H) move to the same `$EDIT_DIR` — no separate Hebrew property writes needed.
3. Update Status from `Needs Editing` to `CV Ready for Review`. **If this write fails** (tool error, permission issue, property renamed/missing from the schema): do not silently drop it — log "[Company] — [Role Title]: Status write to `CV Ready for Review` failed — [error]. Update Status manually in Notion." in the run-level revision log and include it as a named line in the final chat delivery, the same way an omitted Draft Directory write is surfaced above. The DOCX files are already produced regardless — this is a writeback failure, not a pipeline failure, so continue to step 4 and the next role.
4. Append this role to the editing run's `state.json` (see State file section below) with `status: "completed"`.

Do not overwrite coach-owned properties here — those are set during intake and verified (read-only) in Step E1.

Do not write anything to the `Note` field unless the agent has genuinely additional context that the structured properties cannot carry.

**Step E10.5 — Why I Want This Role promotion prompt + WIWTR-UNLOGGED role facts**

Runs for every role in the run. This step is mechanical and must never block delivery: if it fails, log the failure and continue.

Write a file named `update-prompt-<company>-<monYYYY>.md` into the role's company subdirectory in the output folder. The file uses the structure defined in `skills/career-engine-new-application/SKILL.md` Step 7f. If the file already exists (generated by the new-application run), **append** the new sections rather than overwriting.

**Section 1 — Why I Want This Role promotion (if the field is populated):** Copy the fixed context block verbatim and fill in the variable content block with this role's Why I Want This Role content, company, role title, and date.

**Section 2 — WIWTR-UNLOGGED role facts (always check):** Collect every item the gatekeeper flagged as `[WIWTR-UNLOGGED]` during this run (from E7.3, E7.7, and E8.5 violation reports). For each item, append the following section to the update-prompt file:

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

If no [WIWTR-UNLOGGED] items were found in this run, omit Section 2 entirely.

Log in the final delivery per role: "Update prompt written/appended to `<company_dir>/update-prompt-<company>-<monYYYY>.md` — paste into Chat or Code (do both if you use both environments)" or "No Why I Want This Role content and no WIWTR-UNLOGGED items — skipped."

## State file (crash-recovery resilience)

After each role completes, append its data to the state.json in the role's run folder (identified in Preflight step 1). For new runs where the run folder is today's date, this is:
`{{OUTPUT_FOLDER}}/applications-<YYYY-MM-DD>/state.json`

Use the same format as the main pipeline (see career-engine-new-application Step 7b). The `session_date` field must reflect today's date.

**Purpose:** state.json is crash recovery only. If this editing pipeline is interrupted mid-run, the orchestrator can resume by checking state.json and skipping roles already marked `completed`. It is not a record of prior editing runs.

**At the start of an editing run, check per role — not one global "today's folder" check.** Each role's append target is its own run folder from Preflight step 1, which is the role's original application-run folder for a pre-existing role and only defaults to today's date for a role with no prior run at all — the two are frequently different folders within the same batch. For each `Needs Editing` role: identify its run folder (Preflight step 1), check that folder's `state.json` for an entry matching this role's `notion_page_id` that belongs to the run being resumed. If found and marked `completed`, skip it — it was processed before the crash. If no matching entry exists, or the entry belongs to a genuinely earlier editing run, process the role from scratch. **Checking only a single "today's run folder" instead of each role's own folder will silently miss the completed-marker for any role whose original run predates today — that role gets redundantly reprocessed on every resume.**

**"Belongs to the run being resumed" is run identity, not the calendar.** The `session_date` gate exists to distinguish this-run completions from stale prior-run completions — it was previously expressed as "matches today's date," which broke on the one boundary a multi-hour run actually crosses: a run that started before midnight and is resumed after it saw every completed entry carry yesterday's `session_date`, fail the today-check, and get fully reprocessed. The check is: the entry's `session_date` is today, **or** it is the calendar day the interrupted run started on when this run is an explicit resume of that run (the entry was written by the run being continued, not by a separate earlier session). An entry from a genuinely distinct prior editing run — a different run, not the one being resumed, regardless of how recent — still means process the role from scratch, exactly as before.

**`Needs Editing` always takes precedence over state.json.** A role's Notion Status is the source of truth for what mode to run. If a role is marked `Needs Editing`, it runs the editing pipeline using the Notion entry as source material — even if it also appears in state.json from an earlier session.

## Final chat delivery

Same format as the main pipeline (`skills/career-engine-orchestrator/orchestrator-post-run.md` → Final Chat Delivery):
- **Mandatory, one line per role flagged this run per the Absolute Constraints' flag-and-deliver policy** (E3.5, E5.5, E7.3, E7.7, or E8.5 — the E7.4 coach-directed cap existed until the coach review's 2026-07-22 removal) — never omitted when at least one role was flagged: `[Company] — [Role Title]: ⚠ delivered with unresolved violations — [specific violation(s) in one clause] — review before sending; see revision-log-<file>.` A flagged role ships its md and DOCX AND advances its Notion status like any other (2026-07-17 amendment); this addendum plus the halted-roles.json entry and the feedback file's warning section are where its flagged state is reported.
- Named list of any roles that failed for a different reason (e.g. DOCX production failure — company, title, failure step, reason)
- Any properties the coach updated and why (brief)
- Single confirmation line if nothing notable to report: "All N roles edited. Files updated in the output folder and Notion rows updated." **`N` is counted mechanically from this run's `completed` entries in `state.json` (the per-role appends from Step E10), never recalled from memory of the run** — the same read-back discipline the halted-roles addendum already has; a real run misstated its own completed-role count because the number came from conversational memory instead of the persisted record.

## Hard rules

- **No orchestrator-authored content.** Document text comes only from cv-writer, letter-writer, and the humanizer. The orchestrator never composes sentences, merges drafts, or assembles a final document from parts — writer regression is handled by re-spawning with the fix log, per the orchestrator's Absolute Constraints.

- **Agents are improving existing work, not starting from scratch.** Every agent in this pipeline receives the existing outputs as context. The instruction "improve what exists" must be explicit in every sub-agent spawn.
- **Coach properties are the anchor.** The cv-writer, reviewers, and other agents take the coach's verified properties as given. They do not reinterpret strategic positioning.
- **Property discipline.** Each property is written once, by its owner. Do not duplicate content across fields. The `Note` field is the user's space.
- **Fabrication rule is absolute.** See 01-writing-rules.md. Editing does not license invention.
- **Status update is the final step.** Only update Status to `CV Ready for Review` after the DOCX export and Notion writeback are confirmed complete.
- **Do not pause mid-run. This is an Absolute Constraint.** Process all roles in the selected queue automatically without stopping to ask the user about scope, workload, priorities, or session length. Mid-run observations (fabrication catches, data gaps, file issues) go into the final report — never into a blocking question. The only permitted stops are a hard failure (output folder unreachable, zero roles after skipping) and the end-of-run summary.

- **Reviewer spawns are never skipped. This is an Absolute Constraint.** Step E4 (recruiter review) runs for every role, every time, regardless of edit scope, prior review history, or inferred task description. (Step E7.4's coach strategic letter review was removed 2026-07-22 per the user's instruction — its conformance duty now runs inside the E7.3/E7.7 gatekeeper checks, Gates 5/9, which bind under this same constraint.) The only valid exception is an explicit per-session user instruction to skip them — "fabrication-only edit" or "these were already reviewed" are not grounds for skipping.
