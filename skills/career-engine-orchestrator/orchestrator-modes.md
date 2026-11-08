# Orchestrator — Modes (--now, --status, Crash Recovery)

Load this file only when one of these specific modes is active. Do not load it at run start.

---

## --now Mode (Single-Role Fast Track)

Use when the user provides a URL or pastes a JD directly in chat and needs documents immediately, without going through the Notion queue. **No Notion interaction at all** — no reading, no writing.

### When to use
The user says something like: "Write my CV for this now", "/career-engine --now <url>", "I just found this job, do it", or pastes a JD with an urgent framing.

### Flow

**Step N1 — Determine input**

Check what the user provided:
- A URL → proceed to N2 with that URL
- Pasted JD text (no URL) → skip N2, treat the pasted text as the JD body and proceed to N3 directly

**Step N2 — Prepare JD content**

If the user provided a URL: pass it directly to the coach in Step N3. The coach fetches it as part of its pre-flight.

If the user pasted JD text (no URL): treat it as the JD body directly. Pass it to the coach in Step N3 — no fetch needed.

If the coach cannot access the URL: it will report the failure. Tell the user and stop — do not proceed without usable JD content.

**Step N3 — Career coach properties (required inline)**

The career coach is not spawned in `--now` mode. The user must provide the strategic properties inline in the `--now` invocation:

Required: `Role emphasis`, `Keywords`, `Strategy`
Also accepted: `Role Type`, `Relationship type`, `Gap handling`

If the user has NOT provided `Role emphasis`, `Keywords`, or `Strategy` inline, stop immediately:

> "Career coach properties required for `--now` mode. The career coach does not run in fast-track mode. Please provide `Role emphasis`, `Keywords`, and `Strategy` directly in your message, or run `/career-engine --coach-skills` on this URL first, add the role to Notion with Status = Interested, and run the standard pipeline."

If all three required properties are present, continue with them as the coach output for Step N4. No Notion writeback for coach properties in `--now` mode.

**Step N4 — Per-role pipeline**

Run `career-engine-new-application` Steps 1 through 7d exactly as in the standard pipeline. The only differences:
- **Why I Want This Role (before Step 5)** — no Notion row exists, so the field cannot be read. Ask the user in chat: "Why do you want this role? One or two sentences in your own words — this strengthens the letter's opener. Reply 'skip' to let the letter-writer work from your Motivation Bank instead." If she provides content, use it as the Why I Want This Role input for Step 5. If she replies "skip", declines, or provides nothing usable, **pass Why I Want This Role empty and spawn the letter-writer anyway** — its Sufficiency Gate writes the letter from the role-matched Motivation Bank entries, or returns a skip (deliver the CV only for this role) when neither Why I Want This Role nor the Bank has usable material. Do not pre-skip the letter.
- Step 6H (Hebrew localization) — skip entirely. No Notion row exists, so `Languages` cannot be read. `--now` mode does not support Hebrew output. If the user wants Hebrew, add the role to Notion and run normally.
- Step 7a (Draft Directory writeback) — skip entirely. No Notion row exists for this role.
- Step 7b (state.json) — write as normal to the output folder.
- Step 7c (Notion property writeback) — skip entirely.
- Step 7d (feedback file) — write as normal.

**Output folder:** same as all other runs:
`{{OUTPUT_FOLDER}}/${OUTPUT_DIR_PREFIX:-applications}-<YYYY-MM-DD>/`

Create the folder if it does not exist (same as normal).

**Step N5 — Final delivery**

Deliver the standard final summary. Append one note:

> "This role is not in your Notion database. If you want to track it, add it manually and set Status = Applied when you send."

When spawning reviewers, inject this note verbatim into the prompt:
> "Only flag something if it would cause a recruiter to decline before a first screening call. If the concern would only come up after the user is already in the room, it is not a flag. Any flag that cannot be closed by reframing, reordering, or surfacing something already documented in the skill reference files will be left unaddressed — cv-writer and letter-writer will NOT fabricate to satisfy your flag. Please flag anyway — honest identification of a real screening-risk gap is more useful than a papered-over document."

---

## State File

`state.json` is a crash-recovery file — not a run-history log. It records roles that reached Step 7b (post-DOCX, pre-Notion-writeback or later). A role that crashed before Step 7b will not appear in it at all.

**`state.json` is the authoritative source for crash recovery:**

If a `state.json` exists in the most recent run folder and a role is marked `completed` in it, **skip that role** — regardless of when the run was, regardless of the role's current Notion Status. The most recent `state.json` represents actual pipeline progress. Notion writeback may have failed without invalidating what is on disk.

**When to process from scratch:** If no `state.json` exists, or a role does not appear in it as `completed`, run the full pipeline for that role from the beginning. `Interested` roles not in `state.json` always run fresh.

`Needs Editing` → always run the editing pipeline using whatever is in the Notion entry. state.json is not used for the editing pipeline.

---

## --status Mode

Read-only. No agents. No Notion. Just reads the filesystem.

**Step S1 — Find the most recent run folder**

```bash
ls -1d "{{OUTPUT_FOLDER}}/${OUTPUT_DIR_PREFIX:-applications}-"* | sort | tail -1
```

If no run folder exists, report: "No pipeline runs found."

**Step S2 — Read state.json**

```bash
cat "<most-recent-folder>/state.json"
```

If state.json is missing, check the folder for scratch (`_pipeline*` directories). **None present:** the run finished and was cleaned up by its closing step (`skills/run-records/SKILL.md`, 2026-11-08) — report "No unfinished run in `<folder>`; completed runs are recorded in your run log and `agent-data` reports." and stop. **Scratch present:** report "state.json not found in `<folder>` — run may not have started or crashed before any role completed."

**Step S3 — Check files on disk**

For each role in state.json, verify the expected files exist. `cv_path` and `cover_letter_path` are relative to the run folder and already include the company subdirectory (e.g. `northwind/cv-<last-name>-...docx`). Hebrew file presence is detected from filenames — if any DOCX in the company subdirectory carries the `-he` suffix (derived from `cv_path`/`cover_letter_path` with `-he` inserted before `.docx`), treat the role as having Hebrew outputs and verify both Hebrew files exist.

```bash
ls "<most-recent-folder>/<cv_path>" 2>/dev/null && echo "✓" || echo "MISSING"
ls "<most-recent-folder>/<cover_letter_path>" 2>/dev/null && echo "✓" || echo "MISSING"
ls "<most-recent-folder>/<feedback_path>" 2>/dev/null && echo "✓" || echo "MISSING"
ls "<most-recent-folder>/<revision_log_path>" 2>/dev/null && echo "✓" || echo "MISSING"
# Hebrew files — derive expected filenames from cv_path/cover_letter_path with -he suffix; check only if a -he DOCX is present in the company subdirectory
```

**Step S4 — Print summary**

```
## Run status — <session_date>

Completed: N roles  ·  Files missing: M

| Company | Role | Track | CV | Cover letter | Hebrew CV | Hebrew CL | Feedback | Revision log |
|---|---|---|---|---|---|---|---|---|
| <company> | <title> | <track> | ✓/MISSING | ✓/MISSING | ✓/—/MISSING | ✓/—/MISSING | ✓/MISSING | ✓/MISSING |
...
Note: — means no Hebrew was produced for that role (Languages did not include Hebrew).

<if all files present for all roles>
All files accounted for. Notion writebacks happened during the run — check row Status in Notion to confirm.

<if any file MISSING>
Files marked MISSING exist in state.json but were not found on disk. See Crash Recovery below.
```

If any role's cover_letter_path is null or empty in state.json, note it: that role may have crashed before the cover letter completed.

---

## Crash Recovery

### What state.json captures — and doesn't

state.json records roles that **completed Step 7b** (all three files produced, state written). It does not capture:
- Roles that started but crashed before DOCX export
- Which step within a role's pipeline failed
- Whether Notion writeback (Steps 7a, 7c) succeeded after state was written

### Diagnosing where a run crashed

**If state.json has fewer roles than expected:** One or more roles crashed before completing. The crashed role will still have Status = `Interested` in Notion. Check the output folder for partial files (markdown backups from Steps 4 and 5.7 land there as `.md` files).

**If state.json has all expected roles but a file is MISSING on disk:** The state was written but the file copy failed or was deleted after the run. The markdown source file in `/tmp/` is gone; re-run that role.

**If state.json is complete and all files are present but Notion rows still show `Interested`:** Step 7c (Notion writeback) failed after state was written. The files are good. Manually update each Notion row: set Status to `CV Ready for Review` and write the Draft Directory URL to the `Draft Directory` property (construct it from the `draft_dir_url` field in state.json, or derive it from the formula using the run folder date and company directory name).

### Which steps are safe to re-run

All agent steps are stateless and safe to re-run. They produce the same class of output each time — a fresh draft, review, or revision — and overwrite the previous output intentionally.

| Step | Safe to re-run? | Notes |
|---|---|---|
| 0.5 — JD content prep | Yes | Idempotent; only writes if JD Body was empty |
| 0.8 — career coach | Yes | Fetches JDs + overwrites Notion properties ([HIGH] tags); [LOW] only fills empty |
| 1 — cv-writer draft | Yes | Overwrites previous draft |
| 1.5 / 4.5 / 5.2 / 5.95 — gatekeeper | Yes | Pure check, no side effects |
| 2 — recruiter-reviewer | Yes | Pure review, no side effects |
| 5.3 — strategic conformance (coach review removed 2026-07-22; enforced by Gates 5/9 in Step 5.2's gatekeeper check) | Yes | No spawn, no side effects |
| 4 — cv-writer revision | Yes | Overwrites draft; markdown backup re-saved |
| 5 — letter-writer draft | Yes | Overwrites previous draft |
| 6 — DOCX export | Yes | Overwrites existing DOCX files (harmless if content unchanged) |
| 7a — Draft Directory writeback | Yes | Idempotent; same URL written |
| 7b — state.json | **Caution** | Appends a new record; creates a duplicate if role already in state.json. Not harmful but makes --status output noisy. |
| 7c — Notion property writeback | Yes | Idempotent; same properties written |
| 7d — feedback file | Yes | Overwrites existing feedback file (harmless) |

### The most common crash scenario: good DOCX, no Notion writeback

If the pipeline produced both DOCX files and the feedback file but crashed before Step 7a or 7c:

1. Run `--status` to confirm the files are on disk.
2. In Notion, manually set the row's Status to `CV Ready for Review`.
3. Write the Draft Directory URL to the `Draft Directory` URL property. Construct it from the `draft_dir_url` field in state.json, or derive it using the formula:
   `$DRAFT_DIR_URL_BASE<date-folder>%2F<company_dir>%2F`
4. The role is done. Do not re-run it — the documents are good.
