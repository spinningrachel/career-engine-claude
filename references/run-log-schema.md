# Run log — default schema

*(2026-11-08, per the user: a user-chosen place to keep a record of what each run did, with a default schema offered at setup and the freedom to use their own.)*

The run log is where a finished run is recorded: what was processed, which files exist, what was flagged. It lives in **one** place the user picks at setup (`run_records.destination` in `pipeline-preferences.json`): a Notion database, or an Excel workbook inside the `agent-data` folder. Reports (feedback, LinkedIn updates, run metrics) live flat in `agent-data` either way — no subdirectories.

## Two tables

**Runs** — one row per pipeline run (New Application, Edit, or Intake).

| Column | Type | Filled with |
|---|---|---|
| Run | title/text | `<mode> <YYYY-MM-DD>` (e.g. `New Application 2026-11-08`) — the row's unique key |
| Mode | select/text | `new-application`, `edit`, `intake` |
| Started | date | Date the run began |
| Ended | date | Date it finished |
| Roles processed | number | Mechanical count of `completed` entries (never recalled from memory) |
| Roles flagged | number | Count of flag-and-deliver roles |
| Summary | text | 2-4 plain sentences: what ran, what was delivered, what is open |
| Reports | text/files | File names of the run's reports in `agent-data` (e.g. `linkedin-updates-2026-11-08.md`) |
| Session link | url | Only when visible in context; never guessed |
| Cleanup | text | `done`, or `kept scratch: <reason>` |

**Applications** — one row per role processed in a run.

| Column | Type | Filled with |
|---|---|---|
| Company | text | Company name |
| Role | text | Role title |
| Run | text | The `Runs` key it belongs to |
| Action | select/text | `created`, `edited`, `researched` |
| Date | date | Date the role was processed |
| Status | text | `completed` or `flagged` |
| Flag reason | text | The unresolved violation, citing the cap clause (blank when clean) |
| CV file | text | DOCX file name (and folder) in the output folder |
| Cover letter file | text | DOCX file name |
| Tracker link | url | The role's tracker page, when the tracker is Notion |
| Feedback report | text | File name of the role's feedback report in `agent-data` |

The key of an Applications row is **Company + Role + Run**. A re-log of the same run updates the row instead of adding a duplicate.

## Storage choices

- **`workbook`** — one `.xlsx` in `agent-data` (default name `Applications Log.xlsx`) with sheets `Runs` and `Applications`, created from this schema at setup.
- **`notion`** — a Notion database (`run_records.notion_database_id`) with these properties. Properties only; never a page body.
- **`none`** — no log. Reports still go to `agent-data`.

## Schema mode

- **`default`** — write exactly the columns above.
- **`flexible`** — the user's workbook or database is the schema. **Every run, before planning any write, fetch the live schema** (workbook: read each sheet's header row, plus any cell comments or data-validation lists on it; Notion: fetch the database) and map the run's facts onto the columns that exist. Rules: never add, rename, or delete a column; leave a column blank when no fact fits it; never invent a fact to fill a column; use a select column's existing options only; say in the confirmation which columns were left blank and which facts had no column.
