---
name: run-records
description: "Closing procedure for the New Application, Edit, and Intake pipelines: file the run's reports flat in the user's agent-data folder, record the run in the user's chosen log (Notion database or Excel workbook, default or flexible schema), then delete the run's scratch files. Loaded by each pipeline's final step."
---

# Run Records and Cleanup

*(2026-11-08, per the user: "agents generate many related md files, reports, etc. ... I want to have all this stored in a more logical manner" and "the agents leave behind a massive amount of files that aren't necessary like batch verification, pipeline, state.json, edit-manifest, export-verification.json and the cv and cover letter md versions. the same is true for intake as well".)*

Runs in the main session after the last role is terminal, never in a subagent. Three jobs in order: **file the reports, record the run, clean up.** Cleanup never runs unless the first two are verified.

## 0. Resolve config (R-37)

Read `${CAREER_DATA}/references/pipeline-preferences.json`. Every key is optional; none blocks a run.

| Key | Default when absent |
|---|---|
| `agent_data_folder` | `<parent of output_folder>/agent-data` |
| `run_records.destination` | `none` (reports are filed, no log row is written) |
| `run_records.schema_mode` | `default` |
| `run_records.workbook_file` | `Applications Log.xlsx` |
| `run_records.notion_database_id` | none (required only when destination is `notion`; missing then means `none` plus a one-line note) |

Create `agent_data_folder` if missing. It is flat: **no subdirectories, ever.**

## 1. File the reports

Move (never copy-and-leave) each report the run produced into `agent_data_folder`, keeping the name unique with the date and company:

- per-role feedback report -> `feedback-<company>-<role>-<date>.md`
- per-role revision log, **only for a flagged role** (a clean role's is deleted in step 3) -> `revision-log-<company>-<date>.md`
- run-level `linkedin-updates-<date>.md` and `revision-log-<date>.md` (new-application runs). `run-metrics-<date>.json` is **not moved**: Step 9c writes it straight into `agent_data_folder` (the Stop hook finds it by that write path)

Confirm each moved file exists and is nonzero by listing the folder. A report that cannot be moved stays where it is and is named in the final message.

## 2. Record the run

Skip when destination is `none`. Otherwise:

1. **Get the schema.** `schema_mode = default`: use `references/run-log-schema.md`. `schema_mode = flexible`: fetch the live schema first (workbook: `python3 ${CLAUDE_PLUGIN_ROOT}/skills/run-records/scripts/xlsx_log.py headers <file>`; Notion: `notion-fetch` the database) and plan the mapping before writing anything. The rules for flexible mode are in `references/run-log-schema.md`.
2. **Derive each field from the run's persisted record**, never from memory: `state.json` for counts and file paths, `halted-roles.json` for flags, the feedback report names from step 1.
3. **Find the existing row** (Runs key: `<mode> <date>`; Applications key: company + role + run). Update it if present, else create it. One run never produces duplicates.
4. **Write.** Workbook: `python3 ${CLAUDE_PLUGIN_ROOT}/skills/run-records/scripts/xlsx_log.py upsert <file> <sheet> --key-cols "<col,col>" --row '<json>'` (one call per row; it creates a missing workbook with the default headers only when `schema_mode` is `default`). Notion: properties only, never a page body, through the database adapter (`skills/database-notion/SKILL.md`).
5. **Read back** the rows just written and check the counts match. A failed or unverified write blocks step 3 and is reported.

## 3. Clean up

**Preconditions, all required:** every role is completed clean or delivered flagged; step 1 reports exist in `agent_data_folder`; step 2 was verified (or destination is `none`); every role is terminal. Any precondition failing, or an **interrupted run** (state.json is the resume record): delete nothing, set the log's Cleanup cell to `kept scratch: <reason>`, and say so in the final message.

**Delete (this run's folders only):**
- every `_pipeline/`, `_intake_pipeline/`, `_edit_pipeline*/`, the queue scratch directory, and `career-data-staged/`
- in the run folder: `state.json`, `halted-roles.json`, any `*verification*`, `*manifest*`, and `*.json` scratch the run wrote
- in each role folder this run created or updated (an Edit run's `$EDIT_DIR` included): **every non-`.docx` file this run wrote** — files whose **modification** time is later than the run's start (the start is the birth time of its earliest scratch folder: `stat -f %B` on macOS, `stat -c %W` on Linux; a file's modification time is `stat -f %m` / `stat -c %Y`, so an older file this run overwrote still counts as written by this run). A file older than that belongs to an earlier run and is kept. (the CV and cover letter markdown copies, rounds, drafts). **Per role, per track:** delete that track's markdown only after its `.docx` is confirmed on disk by listing; where a DOCX could not be written (a flagged DOCX-write failure), keep that track's markdown so the user can convert it
- `/tmp` working copies this run created

**Keep:** the `.docx` files in their role folders, everything already filed in `agent_data_folder`, and anything the run did not create. Use an allowlist for role folders (only `.docx` survives among this run's files), never a blocklist of names. Delete only paths inside this run's folder; never a path outside it, never the output folder itself. A failed delete is logged and never blocks delivery.

Intake has no role folders: it files its reports (if any), deletes its `_intake_pipeline/`, and records the run.

## 4. Confirm

One line appended to the pipeline's final message: `Records: <destination> · reports in agent-data · cleanup <done|kept scratch: reason>`, plus `Left blank: <columns>` (flexible mode) or `Not filed: <files>` when relevant.
