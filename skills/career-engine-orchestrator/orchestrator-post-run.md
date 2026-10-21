# Orchestrator — Post-Run (Steps 8–9, Final Delivery)

**Load this file after all per-role pipeline steps complete, OR when the per-role loop stops early due to a hard external blocker** (rate/spend limit, connection loss, or any non-retryable error unrelated to letter/CV quality) **— run every step below scoped to whatever roles actually completed, never skip this sequence because the run didn't reach the full queue.** It covers post-run validation, the LinkedIn updates file, revision log, bullet approval, run metrics, and final chat delivery. Every "all roles" reference below means "all roles that completed this run," not the original queue size, whenever the run was interrupted.

**Every file read or write in this document (Step 8b's CV markdown reads, Step 8c's `linkedin-updates` write, Step 9's revision log write, Step 9c's `run-metrics` write) routes through whichever access path (A or B) `orchestrator-queue.md`'s *Mandatory path verification* already confirmed for this run — never re-verify or default to a raw `cat`/`awk` bash heredoc if this run is on Path B.** On Path B, perform these same reads and writes through the host filesystem tool discovered at preflight, targeting the same output-folder paths shown below — the `bash`/`awk` snippets in this file illustrate the Path A form only.

---

## Wrap-up — release unfinished claims (2026-10-21)

Before anything else here, set `Agent Status = No Status` on every role claimed at Step O3 that did not reach Step 7c (interrupted run, skipped role). Never touch a role this run did not claim.

---

## Post-Run Validation

Validate at least 2 CV + cover letter pairs from this run — the first role produced and one other chosen at random. If fewer than 2 roles were produced, validate all of them. This step is not optional. A self-reporting cv-writer or letter-writer is not validation.

Full validation checklists (CV — 6 checks; cover letter — 8 checks; pandoc commands; results-appending instructions) are in `references/orchestrator-post-run-check.md`. Load it and follow it exactly.

---

## Step 8 — LinkedIn Updates File

Run after all roles complete. Inline — no agent spawn. Produces one file per run (not per role): `linkedin-updates-<YYYY-MM-DD>.md`, saved to the output folder alongside the per-role files.

**Purpose:** Surface what the run's collective intelligence implies for the user's permanent LinkedIn profile — specifically, which keywords and framing choices recur across multiple JDs in this session, making them stronger signals than anything optimized for a single application.

**Framework primacy.** `03-framework.md` is the primary source of truth about the user's goals and positioning; LinkedIn is a tool the plugin helps her improve, never a source of truth about her. Treat the framework as background guidance for every recommendation. The profile is permanent and serves her whole positioning: this run's roles — including any role that represents a career shift — must not pull recommendations toward themselves unless the change also strengthens her overall positioning. Only if the framework indicates a career shift is a primary goal may recommendations deliberately support the transition.

### Step 8-pre — Load the LinkedIn profile reference

Read `${CAREER_DATA}/references/linkedin-profile.md`.

- **Profile available** (file exists and its content does not still contain the characters `{{` and `}}`): run Steps 8a–8c in **gap-analysis mode** — every recommendation is grounded in what the profile actually says today.
- **Profile not provided** (file missing or still templated): run Steps 8a–8c in **fallback mode** — keyword aggregation without profile comparison. Open the output file with the note: "No LinkedIn profile on file — these are raw market signals, not a profile analysis. Provide a LinkedIn PDF export (say 'update my references') to get recommendations based on your actual profile."

### Step 8a — Aggregate keywords

The coach returned a tiered `Keywords` string for each role processed this run (format: `Critical: ... | Important: ... | Nice-to-have: ...`). Read each role's value from `$QUEUE_PIPE/role-properties.md` (the queue-level file written in Step O1 — the same source Step O2's readiness check reads from) rather than from an in-memory return, matching how the rest of this pipeline threads properties through disk instead of context. Collect all of them.

For each role, split on `|` to extract the three tier strings, then split each tier on `,` to get individual terms. Normalize each term: trim whitespace, preserve original casing. Pool all terms across all tiers into a single frequency map — record how many roles each term appeared in and which companies. Terms from Critical and Important tiers carry more signal weight than Nice-to-have, but all feed the frequency map.

**Threshold logic:**
- 3+ roles → **high signal** — likely a permanent LinkedIn gap
- 2 roles → **medium signal** — worth considering
- 1 role → omit — JD-specific, not a profile signal

Note: With a 5-role cap per run, "2 roles" = 40% of the batch. That is a meaningful pattern, not noise.

**Gap-analysis mode (profile available):** after building the frequency map, check every high- and medium-signal term against the actual profile content — headline, About, Skills list, and experience entries. Sort each term into:
- **Already covered** — the term (or a direct equivalent) appears in the profile. Report where it appears; no action needed. Do not recommend adding what is already there.
- **Genuinely missing** — the term appears nowhere in the profile. Recommend it, and name the specific profile section where it would do the most work (headline, About, Skills, or a specific experience entry).
- **Present but buried** — the term appears only deep in an old experience entry while the JDs treat it as central. Recommend surfacing it (e.g., into the headline, About, or Skills).

### Step 8b — Extract summary phrases

For each completed role, read the saved CV markdown from the output folder. **The heading to extract after depends on this role's CV Type** (from `run-metrics`'s `cv_type` field, or re-read `$PIPE/cv-type.txt` if the role's `$PIPE` still exists): Detailed uses `## SUMMARY`; Brief uses `## PROFILE SUMMARY`.

```bash
# CV markdowns are saved in the role's company subdirectory alongside the DOCX files
# Detailed:
cat "<output_dir>/<company_dir>/<cv_filename>.md" | awk '/^## SUMMARY/{found=1; next} found && /^[^#]/ && NF{print; exit}'
# Brief:
cat "<output_dir>/<company_dir>/<cv_filename>.md" | awk '/^## PROFILE SUMMARY/{found=1; next} found && /^[^#]/ && NF{print; exit}'
```

This extracts the first non-empty paragraph after the summary heading — which is the summary paragraph. Store it paired with company name and role title.

If a markdown file is missing (role used a different path or failed), skip that role's summary and note it. **If the file exists but the expected heading (per this role's CV Type) isn't found** — the `awk` command returns nothing rather than erroring — treat this the same as a missing file: skip that role's summary and note it by name, rather than silently omitting it with no indication anything went wrong.

**Gap-analysis mode (profile available):** compare each extracted summary phrase against the profile's actual About section and headline. Only surface a phrase as a recommendation when it says something the About section doesn't already say, or says it meaningfully better — and state which existing About sentence it would strengthen or replace. Phrases that merely restate the current About are dropped, not listed.

### Step 8c — Write the file

```bash
cat > "<output_dir>/linkedin-updates-<YYYY-MM-DD>.md" << 'MARKDOWN_EOF'
<full file content>
MARKDOWN_EOF
```

**File format:**

```markdown
# LinkedIn Updates — <YYYY-MM-DD> — <N> roles

*Accumulated across <N> roles this session, analysed against your LinkedIn profile snapshot of <profile snapshot date>. Terms appearing in multiple JDs are profile signals — they indicate what recruiters in your current target market are searching for.*
*(Fallback mode: replace the line above with the no-profile note from Step 8-pre and use the raw signal lists without the profile-comparison columns.)*

---

## Keywords

### Genuinely missing from your profile — add these

- **<term>** — <N> roles: <Company A>, <Company B> → add to: <specific profile section>
- ...

### Present but buried — surface these

- **<term>** — <N> roles — currently only in <where it appears> → surface in: <headline / About / Skills>
- ...

### Already covered — no action

- **<term>** — appears in <profile section>
- ...

*Career-shift guard: a term is only recommended if adding it strengthens the overall positioning per `03-framework.md` — not because a single role this run pointed at it.*

---

## About section — phrase upgrades

Tailored summary phrases from this run that say something your current About section doesn't — each paired with the existing About sentence it would strengthen or replace. Phrases that merely restate your About are omitted.

**<Company> — <Role Title>:**
> <phrase>
*vs. your current:* "<existing About sentence>" — <one line on why the new phrasing is stronger>

---

## Experience bullets — review manually

The CVs produced this run contain tailored bullet versions for each experience entry. Compare the saved CV markdown files to your current LinkedIn experience entries and update where the tailored version is meaningfully stronger.

Saved CV markdowns this run:
<list of cv_filename.md files from this run>
```

**Failure handling:** If the file write fails, retry once. If it still fails, surface the error in final delivery and include the full file content as plain text in chat so it is not lost. The LinkedIn updates file is a required output of every New Applications run — treat a failed write as a blocking issue, not a skip.

**Skip condition:** If only one role was processed this run (no cross-role signal possible), still write the file but note in the keywords section: "Only one role processed this session — no cross-run frequency signal. Review keywords for the single role in the CV directly."

---

## Step 9 — Run-level revision log

After all roles complete and after Step 8 (LinkedIn updates), write a single run-level revision log to the output folder:

**Filename:** `revision-log-<YYYY-MM-DD>.md`

```bash
cat > "<output_dir>/revision-log-<YYYY-MM-DD>.md" << 'MARKDOWN_EOF'
# Run Log — <YYYY-MM-DD> — <N> roles

## Cross-run decisions
<Any decision that affected all CVs or all roles. If none: "None.">

## Technical and orchestration issues
<Failures, fallbacks, writeback errors, and any unexpected or non-standard decisions made by any agent during the run. If none: "None.">
MARKDOWN_EOF
```

This file is non-blocking — if the write fails, log it in chat only.

---

## Step 9b — Bullet Approval Prompt

Run after Step 9 (revision log). For every role completed this run that produced a CV, ask once at the end of the full run — not per role:

> "New bullets were written for: **[Company A]**, **[Company B]**, **[Company C]**. Which of these should I add to your approved list? Approved bullets will be reused verbatim in future CVs for the same company. Reply with company names, 'all', or 'none'."

**Labeling — this is a non-blocking declaration, not a synchronous pause.** Post the question and proceed immediately to Step 9c and Final Chat Delivery in the same turn; do not hold the run open waiting for a reply. If the user answers in a later turn, apply the handling below at that time. This is distinct from the mid-run scope-check anti-pattern this file's sibling explicitly bans (`orchestrator-queue.md` Absolute Constraints) only in that it comes after all processing is already complete — it must never be moved earlier in the sequence or made to block any role's completion.

**If the user says 'all' or names specific companies:** For each approved company, append the bullets from the delivered CV into `${CAREER_DATA}/references/background/background-role-facts-<company>.md` under the heading `**Approved CV bullets:**`. Use the company name slug from the database record to identify the file (e.g. company "Acme Corp" → `background-role-facts-acme-corp.md`). If a bullets section already exists for that company, merge — do not duplicate bullets already present. This writes the personal data layer: in Code, write `${CAREER_DATA}` directly; in Cowork, stage the append to the output folder and emit the Appendix-A handoff (write path, §5.3) — never write a divergent copy.

**If the user says 'none' or does not respond:** Skip. Bullets remain as candidate status and will be rewritten fresh on the next run.

**Important:** Do not add approved bullets from old CVs the user submitted during setup. Only bullets the pipeline itself produced are candidates for approval.

---

## Step 9c — Run metrics

Run after Step 9b. Write a `run-metrics-<YYYY-MM-DD>.json` file to the run output folder. This file records structural metrics for the run. Actual token counts are appended by a Stop hook configured during setup — the hook writes to this same file when the session ends.

```bash
cat > "<output_dir>/run-metrics-$(date +%Y-%m-%d).json" << 'JSON_EOF'
{
  "run_date": "<YYYY-MM-DD>",
  "pipeline": "<New Applications|Edit|Intake>",
  "roles_processed": <N>,
  "roles_per_company": [
    {"company": "<name>", "track": "<cv|now>", "hebrew": <true|false>, "cv_type": "<Detailed|Brief>"}
  ],
  "agents_invoked": {
    "career_coach": <N>,
    "cv_writer_draft": <N>,
    "cv_writer_revision": <N>,
    "gatekeeper_cv": <N>,
    "recruiter_reviewer_cv": <N>,
    "letter_writer_draft": <N>,
    "letter_writer_revision": <N>,
    "gatekeeper_cl": <N>,
    "localization": <N>
  },
  "interrupted": <true|false, present only when the run stopped early — omit this key entirely on a clean run>,
  "interruption_reason": "<one-line cause, e.g. 'monthly spend limit reached' — omit when interrupted is false or absent>",
  "roles_not_started": ["<company>", "..."],
  "roles_halted": [
    {"company": "<name>", "track": "<cv|cover_letter>", "step": "<the pipeline step where the flag-and-deliver policy triggered, e.g. '5.2'>", "reason": "<one-line unresolved-violation summary>", "revision_log": "<path>", "delivered_files": ["<exported md and DOCX paths>"]}
  ],
  "token_counts": "pending — written by Stop hook at session end"
}
JSON_EOF
```

Fill all values from the run state. Set each agent count from the actual invocations this run. Leave `token_counts` as the literal string `"pending — written by Stop hook at session end"` — the hook replaces this value when the session closes. **`roles_processed` always means roles actually completed this run — never the original queue size on an interrupted run — and is derived by counting this run's `completed` entries in `state.json`, the same mechanical read-back discipline `roles_halted` already gets from `halted-roles.json`; never fill it from memory of the run.** Omit `interrupted`, `interruption_reason`, and `roles_not_started` entirely on a clean run rather than writing `false`/empty values — their presence is itself the signal that this run didn't reach the full queue. **`roles_halted` is populated by reading `$OUTPUT_DIR/halted-roles.json`** (key and file names are legacy — since 2026-07-14 they record FLAGGED roles, which DO ship deliverables per the flag-and-deliver policy; written incrementally by the pipeline steps at the moment each role is flagged — see `orchestrator-queue.md`'s Absolute Constraints for the append mechanism and entry shape) — copy its `roles` array in directly, do not re-derive it from memory of the run. Omit the `roles_halted` key entirely when that file doesn't exist (no role flagged this run). **This file is the structural record backing the Final Chat Delivery's mandatory flagged-role addendum below** — every entry in it must have a corresponding line in that chat message, and vice versa; both read from the same file, neither is reconstructed from conversational memory of a flag that may have happened many roles or turns earlier. A flagged role does NOT count toward `roles_processed` (that counts clean completions only — the flagged role's deliverables shipped, but it isn't done until the user resolves the flag), and its coach/writer/gatekeeper agent invocations still count in `agents_invoked`. **`cv_type`** is each role's resolved value from `$PIPE/cv-type.txt` (written at that role's Step 0.type) — carried into this schema so a run report can distinguish Detailed from Brief roles; omit this key entirely for `--now`-track roles if `$PIPE/cv-type.txt` was never written for them.

**Failure handling:** If the write fails, retry once. If it still fails on an interrupted run, the Final Chat Delivery hard gate below blocks on this file the same as it blocks on `linkedin-updates` — do not send the interrupted-run confirmation without it. On a clean run, a persistent failure is non-blocking: note it in the final chat delivery message and proceed (run-metrics is a structural record, not a deliverable the user is waiting on when everything else succeeded).

---

## Final Chat Delivery

**Hard gate — before sending the final confirmation, verify the files this run's completion form requires:**
- **Clean run:** `linkedin-updates-<YYYY-MM-DD>.md` exists in the output folder and is nonzero. If it is missing or zero bytes: run Step 8 now. If Step 8 fails on retry, include the full file content inline in chat with the note "LinkedIn updates file write failed — content follows."
- **Interrupted run:** all three of `linkedin-updates-<YYYY-MM-DD>.md`, `revision-log-<YYYY-MM-DD>.md`, and `run-metrics-<YYYY-MM-DD>.json` exist in the output folder and are nonzero (revision-log's own non-blocking rule at Step 9 and run-metrics's clean-run non-blocking rule at Step 9c are both superseded here — on an interrupted run all three block). For any that are missing: re-run that step now. If it still fails on retry, include its full content inline in chat with a "<file> write failed — content follows" note, matching the linkedin-updates handling above.

**Step 8 runs ONLY on new-application pipeline runs.** Do not produce a LinkedIn updates file for `--edit`, `--coach-skills`, `--now`, or any other mode.

After Step 9c completes and Step 8 is confirmed, deliver a single confirmation line in chat:

**Clean run (all queued roles either completed clean or delivered flagged per the Absolute Constraints' flag-and-deliver policy — no external blocker):**
`All N roles processed. Files are in your output folder and Notion rows are updated. LinkedIn updates file: linkedin-updates-<YYYY-MM-DD>.md`

**`N` is derived mechanically, never from conversational memory:** count the entries in this run's `state.json` marked `completed` (the same file each role's Step 7b append wrote at the moment it finished — the completion twin of the flagged-roles ledger `halted-roles.json`). A real run misreported its own role count in the final confirmation because the number was recalled from memory of a many-turn run instead of read back from the persisted record; the halted list already had this discipline, the completed count did not. If the `state.json` count disagrees with what you remember processing, the file wins — and the discrepancy itself is worth a line in the revision log.

**Mandatory flagged-role addendum — read directly from `$OUTPUT_DIR/halted-roles.json` (the same file `roles_halted` in run-metrics was populated from, above — do not reconstruct this list from memory), one line per entry, appended directly under either form above, never omitted when the file exists and is non-empty:**
`[Company] — [Role Title]: blocked, not delivered — [reason] — see [revision_log].`
A flagged role SHIPPED its md and DOCX AND advanced its Notion status exactly like a clean role (flag-and-deliver policy, 2026-07-17 amendment); this line — `[Company] — [Role Title]: ⚠ delivered with unresolved violations — [specific violation(s)] — review before sending; see <revision-log>` — plus the halted-roles.json entry and the feedback file's warning section are where its flagged state is reported, so it cannot be silently missed. If a role was flagged on the CV but its cover letter (or vice versa) passed cleanly, say so explicitly rather than reporting the whole role as flagged.

**Interrupted run (a hard external blocker stopped the loop early):** the confirmation may expand to name what completed, what didn't, and why — but only *after* Steps 8-9c have already run for the completed roles, never as a substitute for them. State plainly: which roles are fully done (files written, Notion updated), which roles were delivered flagged per the policy above, which role was mid-chain when the blocker hit (Notion left untouched, nothing half-written), which roles never started, and the concrete unblock step (e.g. "raise or reset the limit at claude.ai/settings/usage, then say 'continue the remaining roles'"). The run-metrics, revision-log, and linkedin-updates files for the completed roles must already exist in the output folder before this message is sent — confirm they do, the same way Step 8's hard gate above already requires.

Nothing else beyond one of these two forms plus two sanctioned addenda: the mandatory flagged-role addendum above, and the `⚙️ Config health` block (`orchestrator-queue.md` → Config-health notification) when `CONFIG_HEALTH` is non-empty — that block is emitted here, appended under either form, so the two contracts never conflict: the delivery forms stay rigid and the config-health notice still reaches the user at the end of every affected run. All other feedback, validation results, and decisions are in the revision log files in the output folder.

---

## Execution Rules

- Run roles sequentially unless the user explicitly asks for parallel execution.
- Narrate progress briefly between steps: "Role 3/5: recruiter review done, moving to CV revision."
- Do not deliver individual role outputs during processing — deliver everything together at the end.
- If any step fails, log it and move on. All failures are written to the run-level revision log (Step 9).
- The fabrication rule is absolute. Every claim in a CV or cover letter must trace to the candidate's documented background. Enforcement belongs to the writing subagents and gatekeeper — not the orchestrator.
