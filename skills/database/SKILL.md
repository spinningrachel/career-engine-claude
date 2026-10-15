---
name: database
description: Pipeline-level database vocabulary — Status values, Priority values, and property ownership rules. Backend-neutral: these concepts apply regardless of whether the tracker is Notion, Airtable, or anything else. Load this skill whenever you need to understand what status values mean, how priority ordering works, or which agent owns which field. For Notion-specific mechanics (query ladder, view discovery, writeback syntax), also load `database-notion`. For other backends, load the corresponding adapter.
---

# Database — Pipeline Concepts

Backend-neutral vocabulary for the job applications tracker. Any database backend implements the same concepts here. Field names, tool calls, and query mechanics are backend-specific — see the adapter skill for those.

**Backend adapters:**
- **Notion (default):** `skills/database-notion/SKILL.md` — read ladder, view discovery, writeback syntax, schema

---

## Status Values

Status is the single property that drives what the pipeline does with a role. The user sets and updates it; agents update it at pipeline completion only.

| Status | Who sets it | Meaning |
|---|---|---|
| `New` | user (manual add, or any future sourcing pipeline) | True entry point — where a role sits immediately after being added, before Prioritization has touched it. Not yet triaged: no JD fetch, no location read, no priority score. **This is what the Prioritization pipeline fetches by default.** |
| `Needs Research` | user, or Prioritization pipeline (on completion) | Being researched before a decision to apply. **NOT handled by the CV-writing pipeline.** Use the intake pipeline (`--coach-skills`) to research Needs Research roles. That pipeline runs the career coach, writes strategic properties, and promotes Needs Research roles to Researched. (Renamed from `Hold` — same meaning, same trigger, purely a label change.) |
| `Interested` | user | The user has decided to apply. **This is what the New Application pipeline fetches.** Move a role from Needs Research → Interested (or add directly as Interested) when a CV and cover letter need to be produced. Intake does not process Interested roles — it only processes Needs Research roles. |
| `Needs Editing` | user | Queued for the editing pipeline. Pipeline starts from existing outputs — does not run fresh. |
| `CV Ready for Review` | pipeline (on completion) | Pipeline finished; the user needs to review before sending. |
| `Applied` | user | Sent. |
| `Researched` | intake pipeline (on completion) | Coach has run market intelligence — competitive landscape, priority scoring, strategic properties. Role is ready for the user to decide whether to move to Interested. |
| `Closed` | Prioritization or intake (on confirmed closure), or the user | The posting is no longer open. Written automatically when the **closure evidence** rule below is met (2026-10-15, per the user: "if the position closed then that's the update. It should be automatic."). No pipeline queue reads this status. |

**Closure evidence (2026-10-15) — the one rule every pipeline uses to decide a posting is closed.** A role is *closed* when either: (a) the company's own careers page, its ATS page, or the posting page itself states the role is closed, filled, or no longer accepting applications; or (b) the posting URL returns 404/410 **and** the company's careers index, checked this run, does not list the role. Anything less — a redirect to a careers index with no second confirmation, an aggregator's "expired" tag, a LinkedIn auth wall, a cached copy — is *possibly closed*, which is a report line, never a Status write. **Writing `Closed`:** read the tracker's Status option list from the schema; write the option that matches `Closed`, `Position Closed`, or `Role Closed` case-insensitively, using its exact stored string; when no such option exists, leave Status untouched and say in the run report that adding a `Closed` option to Status enables the automatic write. A closed role is never scored, never sent to the coach, and never promoted.

**Pipeline reads:** Prioritization reads `New` (default) or `Needs Research` (on explicit request, e.g. to refresh a stale Priority before running full intake). Intake reads `Needs Research` (renamed from `Hold`). New Application reads `Interested`. Editing reads `Needs Editing`. All other statuses — including `Researched` and `Closed` — are ignored by those pipelines.

**The upstream pipelines are separate:**
- Prioritization → cheap triage of **New** roles (optionally **Needs Research** roles on request) → sets Status to **Needs Research**
- Intake → researches **Needs Research** roles → sets Status to **Researched**
- New Application → fetches **Interested** roles directly → feeds the CV writing pipeline

---

## Priority Values

`Priority` is the sole queue ordering signal. Set by the career coach during intake — that is where scoring happens. The New Application pipeline never scores: it reads the `Priority` intake already wrote and uses it purely for queue order. An unscored role still processes, ordered last.

| Label | Tracker value | Meaning |
|---|---|---|
| `Highest` | `1` | Urgent — drop everything, run this role first |
| `First` | `2` | Excellent fit — strong domain, right seniority, right stage, no red flags |
| `Second` | `3` | Strong fit — domain or seniority match is clear; minor friction elsewhere |
| `Third` | `4` | Reasonable fit — worth applying but the cover letter has work to do |
| `Fourth` | `5` | Weaker fit — possible if the user wants to stretch |
| `Fifth` | `6` | Weakest fit in this batch. Also the hard floor for Open Application entries regardless of any other criterion. |

**Always write the numeric tracker value (1–6) when setting Priority** via the database adapter. The label names are internal shorthand — the tracker rejects them as select values.

Roles with `Priority` already set are always selected into the queue before unscored roles, ordered 1 → 6. In the New Application pipeline the coach is **not** spawned to score them (R-42 — the coach runs only in standalone intake); an unscored role is still processed, and `Priority` affects ordering only.

**Open Application hard floor:** Roles identifiable as open/speculative/unsolicited applications must always sort and be treated as `6` (Fifth) in the queue, regardless of any Priority value in the tracker. The coach will write `6` during intake (Step 0.8). If the coach is skipped (all coach-complete), verify any open application entry is set to `6` before queue ordering — correct it inline if not.

---

## Property Ownership

Each property in the job applications database has a single designated owner. Agents write each piece of information once, to the correct field, and must not duplicate content across properties.

**Role prioritizer owns provisionally, for `New`-status roles only:**
`Role Summary`, `Location`, `Priority`, `JD Fetch Status`, `JD Body`. These are cheap, JD-only values meant to inform which roles reach full intake next — not a substitute for the career coach's research-informed versions. **The career coach always overwrites `Role Summary`, `Location`, `Priority`, and `JD Fetch Status` when a role reaches full intake** — the coach redoes them from scratch using full research and never treats Prioritization's values as a starting point to confirm or correct. This is intake's general default (see the cross-file-contract row in `CLAUDE.md` and `career-engine-intake/SKILL.md` Step 0.9a): every coach-owned property is always-overwrite except three named exceptions (`JD Body`, `Gap handling`, and `CV Type` — the `wiwtr_questions` append was retired 2026-07-23 with the coaching-prompts feature). `JD Body` stays write-only-to-empty for the coach too, same as any other role's — Prioritization's fetched JD is reused, not re-fetched, when already present.

**Career coach owns exclusively:**

*Written for all roles (triage-exit and full-research):*
`Priority`, `Priority Reason`, `JD Body`, `JD Fetch Status`, `Role Type`, and `Relationship type`. (The location-compatibility property was retired 2026-07-23, per the user's direct instruction: "I'd like to completely cancel and remove the useless Israel Compatibility property." No agent writes any compatibility verdict anymore; `location_compatibility.my_location` survives in config for sourcing and the location deep-scan.)

*Written for full-research roles only (Priority 1–4, pre-scored, or `--full-research`):*
`Role emphasis`, `CV Titles`, `JD proof`, `Keywords`, `Strategy`, `Gap handling`, `Role summary`, `Company Stage`, `Culture`, `Landscape`, `Person who Advertised Role (if not Hiring Manager)`, `Hiring Manager's Name`, `Hiring manager's role`, `Manager role confirmed`, `No incumbents in this function`, `First Advertised`, `Recent news`, `Funding context`, and conditionally `Job URL`.

**`CV Type` recommendation moved out of `Role emphasis` (2026-07-23, per the user's direct instruction).** When `pipeline-preferences.json` → `cv_type.mode` is `"Variant"`, the coach returns a standalone `CV Type` value (Detailed or Brief, with a one-line rationale — see `skills/career-coach/coach-analysis.md`'s CV Type judgment principle), and intake writes it to the per-role `CV Type` select **write-only-to-empty** — the user's own hand-set value is never overwritten. `Role emphasis` never carries a CV-type clause anymore; when `cv_type.mode` is `Detailed` or `Brief`, no `CV Type` value is returned or written at all. The recommendation itself comes from the CV Type judgment principle in `skills/career-coach/coach-analysis.md` (the geography lookup matrix was retired same-day, per the user: "couldn't possibly be relevant for any user"), with the user's own optional `cv_type.market_norms` config as the authoritative first source.

No other agent rewrites or second-guesses any of these. **`Gap handling` is the exception to the carry-forward rule — if the user has edited it in the tracker, the pipeline reads her version as authoritative. The write-only-to-empty rule enforces this: if the field is non-empty, the coach skips writing. This exception only applies when `gap_handling_mode` is not `disabled` — see config.**

**`Job URL` is written whenever the JD was actually obtained at a different URL than the saved one (broadened 2026-07-23, per the user's direct instruction), never as a routine write.** The coach never writes Notion directly (same as every other property here) — it returns `Corrected Job URL` whenever the URL it worked from differs from the saved one and is confirmed same-role (`coach-research.md` → Job URL verification); intake (Step 0.9a) is still the sole writer (preferring the coach's value over Step 0.5's `Working URL` capture when both exist for the same role). A role whose saved URL worked never touches this property.

**Mandatory value rule:** Every coach-owned property the coach returns (and intake writes) must receive an explicit value — `N/A` when genuinely inapplicable. A blank field signals agent failure, not inapplicability. This applies to `Company Stage` and `Role Type` in particular. **Prerequisite:** `N/A` must be present as a valid option in the tracker's select fields for `Company Stage` and `Role Type`.

**Triage-exit roles** (Priority 5–6, non-`--full-research`): only the first group of properties above is written. Full-research properties are skipped.

**`Why I Want This Role`** is set manually by the user. The ONE agent write it ever receives is intake Step 0.9a's Write C: the `[LETTER OUTLINE]` block appended below her content (replace-own-block on re-runs; legacy `[COACH LETTER PLAN` blocks recognized). Her own content above the block is never touched, and no other agent writes to this field (the coach context block and `[COACH PROMPTS]` writes were retired 2026-07-23). If it is empty when the pipeline runs, the letter-writer still runs and writes from the **Motivation Bank** (its primary source); it skips the letter for that role (CV only) only when neither `Why I Want This Role` nor any role-relevant Motivation Bank entry has usable material — that decision belongs to the letter-writer's Sufficiency Gate.

**The `Note` field is the user's space. Agents never write to it.**

**`CV Titles`** (text, coach-owned, always-overwrite — 2026-09-17) holds the role-tailoring plan: a `Level:` line and one disposition line per employer in the user's record (Retitle / Descriptor / Keep / Fold — `skills/career-coach/coach-analysis.md`). Intake writes it; the New Application and Edit pipelines read it once per role (Step 0.titles / E0.titles) and hand it to the cv-writer, which executes it verbatim. The user may edit it in the tracker between intake and the application run — the pipeline executes whatever the field holds.

**`CV Title Preferences`** (text, optional) is the user's space, like `Note` — her own per-role wishes for how her titles read on this CV. **No agent ever writes it.** Intake passes it to the coach as authoritative input to the `CV Titles` plan, and the application pipelines pass it to the cv-writer, where it outranks the coach's line for the same employer. Both field names are fixed (setup tells the user to add them); a tracker without them still runs — the cv-writer derives the plan itself.

**`CV Type`** (select: `Detailed`/`Brief`) is user-owned, per role — a fixed field name (setup instructs the user to add it directly). Agents read it only when `pipeline-preferences.json` → `cv_type.mode` is `"Variant"`, to decide which CV format to produce for that role. **Since 2026-07-23 (per the user's direct instruction), the coach fills it when empty under Variant mode** — intake writes the coach's returned `CV Type` value write-only-to-empty, so the user's own hand-set value always wins and a hand-cleared field gets a fresh recommendation on the next coach run. Empty (never coached, or cleared) defaults to `Detailed` at pipeline time. See `skills/career-coach/coach-analysis.md` for the CV Type judgment principle.

---

## Role Type Definitions

See `references/role-type-definitions.md`. Loaded by the career coach (sets the value) and the cv-writer (uses it to select CV structure).
