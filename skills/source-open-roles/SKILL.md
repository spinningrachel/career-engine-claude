---
name: source-open-roles
description: Logic for sourcing open roles across LinkedIn, remote-focused boards, startup boards, general job boards, and freelance platforms. Defines search modes, site-by-site fetch methods, scoring rubric, and deduplication rules. Load before running any source-open-roles search.
---

# Source Open Roles — Search Logic

> **Registry:** this pipeline is listed in the Pipeline Registry in `skills/career-engine/SKILL.md`. Actions owned by another pipeline's registry row are out of scope here — route to that pipeline instead of improvising.

---

## What This Skill Is For

Sourcing surfaces open roles that match the user's preferences — it is the top-of-funnel step that feeds the application pipeline. It does not research, coach, write, or score fit. Its job is to return a ranked list of roles that are (a) worth looking at and (b) not already in the pipeline.

---

## Preferences Schema

All sourcing preferences live in `${CAREER_DATA}/references/pipeline-preferences.json` — there is no separate local preferences store. The relevant keys:

```json
{
  "target_titles": ["Head of Marketing", "VP Marketing"],
  "title_variants": {"Head of Marketing": ["VP Marketing", "Marketing Director", "Head of Growth", "GTM Lead"]},
  "remote_preference": "remote only",
  "exclusion_patterns": ["junior", "intern", "contract"],
  "default_search_time_range": "last week",
  "location_compatibility": {"my_location": "City, Country"},
  "database_id": "<the Notion/tracker database id, or empty to disable deduplication>",
  "screening_answers": {"compensation_floor": "<minimum base, or empty for no minimum>"}
}
```

**Salary floor.** There is no separate `minSalary` field — the scoring rubric's salary signal reads `screening_answers.compensation_floor` directly. Leave it blank for no minimum.

**Database id.** Read `database_id` (legacy `notion_database_id`) from `pipeline-preferences.json` — the same single source the rest of the plugin uses. If it's empty, dedup is skipped and the agent notes it.

---

## Keyword Expansion

Target titles are searched as a **variant set**, not verbatim. The same role surfaces under many titles — "Product Marketing Manager," "Technical PMM Director," "Senior PMM," "GTM Enablement Lead," "Head of Marketing" — so a verbatim search for one misses the rest. Expanding at *search* time (not only fuzzy-matching at scoring time) is the single highest-payoff widener.

**The variant set:**
- **Source of truth:** the user's stored set in `${CAREER_DATA}/references/pipeline-preferences.json` → `title_variants`. Seeded once (Gate 1, on first run or the first run after upgrade), human-editable, auto-used every run, shown in the run header.
- **If no stored set exists:** derive on the fly from `target_titles` plus `USER_PROFESSION` and `USER_FUNCTION_SENIORITY_HIERARCHY` (`01-writing-rules.md` §8) — seniority variants (Lead / Manager / Director / Head / VP), phrasing variants (Product Marketing ↔ PMM, Go-to-Market ↔ GTM), and any adjacent-function variants the user flagged — then trigger Gate 1's seed so the set is stored for next time.
- **Capabilities mode (2026-10-19, `role_matching` absent or `capabilities`):** search terms also come from the capability profile's group lines (`${CAREER_DATA}/references/capability-profile.md`) (the discipline words, not titles) and `scope_preferences.want` — a role titled something new still surfaces when it asks for work the user does. Titles remain a search seed, never a gate. Under `titles` this widening does not apply.
- **Cap: ~6–8 variants per target title.** Stop there; search volume and noise stay manageable, and dedup + scoring absorb the overlap.

**Global search rule:** wherever a Site Catalog pattern below shows `[title]`, run it **once per variant** in the set (the LinkedIn `search_jobs` keywords and every `site:... "[title]"` WebSearch). Deduplication collapses the repeats; scoring ranks them.

---

## Search Selection Logic

**Before searching any built-in boards:** read `preferred_job_sites` and `local_job_sites` from `${CAREER_DATA}/references/pipeline-preferences.json`. Search these first, in order listed. User-specified sites always take priority over plugin-suggested boards. Only proceed to plugin defaults after exhausting the user's list. If the fields are empty arrays or absent, proceed directly to the tier system below.

Source selection is layered, not mode-based. Every run starts with the full Tier 1 core, then adds tiers based on preferences and career.

### Tier 1 — Always search (every run, no exceptions)

| Site | Category |
|---|---|
| LinkedIn Jobs | Core board (MCP) |
| Indeed | Core board |
| Glassdoor | Core board |
| BuiltIn | Core board |
| ChoppingBlock (AI jobs) | Core board — AI/ML-company roles, all functions |
| Crunchbase | Company intelligence |
| PitchBook | Company intelligence |
| Tracxn | Company intelligence |

### Tier 2 — Remote sites (when `remote_preference` includes "remote" or "remote only")

| Site |
|---|
| Remote.co |
| We Work Remotely |
| Remote OK |

### Tier 3 — Accelerator portfolio boards (every run — pick 2–3 most relevant)

Choose 2–3 from the list below. Selection criteria: portfolio overlap with the user's target company stage/sector, user's target function. Default when no signal: a16z + First Round.

a16z · First Round · Sequoia · Bessemer · NFX · Accel · Lightspeed · Index Ventures · General Catalyst

### Tier 4 — Career-specific boards (choose based on `USER_PROFESSION` and `USER_FUNCTION_SENIORITY_HIERARCHY`)

| Site | Relevant for |
|---|---|
| Product Marketing Alliance | Product marketing, PMM |
| Sharebird | Product marketing, PMM |
| Exit Five | Marketing broadly |
| Wellfound | Startup-focused roles, any function |
| Welcome to the Jungle | Startup-focused roles, any function |
| Y Combinator Jobs (Work at a Startup) | Startup-focused roles, any function |
| Techstars Jobs | Startup-focused roles, any function |

Read `USER_PROFESSION` and `USER_FUNCTION_SENIORITY_HIERARCHY` from `career-data` `01-writing-rules.md` §8 before selecting. Include all sites relevant to the user's function; include startup-focused sites when the user's target companies are predominantly early-stage.

### Tier 5 — Locale boards (the user's country)

The default catalog is US/global-remote-centric, which misses the boards that dominate a given country (e.g. Israel: Comeet ATS, Israeli VC portfolio boards). Source locale boards in this order:
1. **The user's configured boards first** — `preferred_job_sites` / `local_job_sites` from `pipeline-preferences.json` (already searched first per the top of Search Selection Logic).
2. **The locale starter catalog** — read `${CLAUDE_PLUGIN_ROOT}/references/locale-job-boards.md`, find the row for the user's country (from `location_compatibility.my_location`), and search the boards listed there that aren't already in the user's configured set. If no country row matches, use the generic/default row.

Locale boards run with the same Keyword Expansion (each variant) and feed the same dedup + scoring as every other tier.

### Explicit mode overrides

If the user specifies a mode keyword, apply it as an override on top of the tiers:

| Mode | Effect |
|---|---|
| `quick` | LinkedIn MCP only — skip all other sites including the rest of Tier 1 |
| `full` | All tiers + all career-specific sites + all accelerators |
| `contract` | Upwork + Fiverr (contract signals, not ranked roles) |

---

## Job-Sourcing MCP Registry

`${CLAUDE_PLUGIN_ROOT}/references/job-sourcing-mcp-registry.md` catalogs known MCP servers for job sourcing — which site each covers, how to connect it, its confirmed tool names, and whether it's wired into the Site Catalog below yet. Read it once per run, at Gate 2 (`agents/source-open-roles.md`), before any search begins.

**Wired-in status is the full four-part definition in `job-sourcing-mcp-registry.md`'s "Two statuses" — confirmed tool name, a recorded `Canary`, a Site Catalog gate below ("prefer MCP if connected, else fall back"), and that row's tools (including the canary) granted in the agent's own `tools:` frontmatter, all four.** A row missing any one of them isn't Wired-in yet, whatever its status cell says — a registry row and a Site Catalog gate alone can't call a tool the agent was never granted, and a confirmed name with no recorded canary leaves Gate 2 nothing to call. Gate 2 runs each Wired-in row's canary tool call once to determine connection state (see `agents/source-open-roles.md` Gate 2); Step 2 (Search) then uses that same result rather than re-checking per search.

**Candidate rows aren't granted in the agent's frontmatter** (whether or not their tool name happens to be confirmed), so their canary can't be called — they cannot be checked or suggested at runtime, and are informational only: a shortlist for the next person wiring one in. Never suggest a Candidate row in the run header.

For a **Wired-in** row relevant to this run's sources that the Gate 2 check found unconnected, add one line to the run header: `Also available: [server] — connect with '[command]' for structured [site] results.` Never block the run on this, never repeat it mid-run, and never suggest a server irrelevant to this run's tiers/sites.

## Site Catalog

### LinkedIn (MCP)

**Gate:** Requires `mcp__linkedin-mcp__search_jobs` to be connected. If unavailable, skip and report.

For each target title:
```
search_jobs(
  keywords = "[title]",
  location = location_compatibility.my_location,
  date_posted = [map: "last week"→"past_week", "2 weeks"→"past_month", "month"→"past_month"],
  work_type = [map: "remote only"→"remote", "hybrid"→"hybrid", "open to all"→null],
  sort_by = "date"
)
```
Collect all `job_ids`. Deduplicate across title searches. Fetch up to 30 job details via `get_job_details(job_id)`. A result is usable only if it contains role requirements or responsibilities — metadata-only responses (applicant stats only) are not usable.

**LinkedIn hiring posts (when the MCP is connected).** Recruiters and founders announce roles in the feed, not only the jobs board. Surface them: scan `get_feed` and `get_company_posts` for target companies, and run a `site:linkedin.com/posts "[title]" hiring` WebSearch per variant. Treat a hiring post as a lead — capture the company, the role, and the poster (a likely hiring-manager/recruiter contact) — and verify it against the company careers page before offering it for a database add. Skip this sub-source if the LinkedIn MCP is not connected and the WebSearch returns nothing usable.

---

### Remote-focused sites

All fetched via `WebSearch` using the pattern: `site:<domain> "[title]" [time signal]` where time signal is "posted this week" or "new" depending on the site. Extract all listings that contain at minimum a title, company, and apply URL or description.

**Tier 2 remote sites (search when `remote_preference` includes remote):**

| Site | Fetch method |
|---|---|
| Remote.co | `WebFetch("https://remote.co/remote-jobs/")` — filter by title. If sparse: `WebSearch("site:remote.co [title] remote job")` |
| We Work Remotely | `WebSearch("site:weworkremotely.com [title]")` — blocks direct fetch reliably; use WebSearch. |
| Remote OK | `WebSearch("site:remoteok.com [title]")` or `WebFetch("https://remoteok.com/remote-[title-slug]-jobs")` |
| Remotive | `WebFetch("https://remotive.com/remote-jobs/[category]")` — filter by title; fallback `WebSearch("site:remotive.com [title]")`. Curated remote board with strong coverage. |

**Additional remote boards:**

| Site | Fetch method |
|---|---|
| Working Nomads | `WebFetch("https://www.workingnomads.com/jobs?category=marketing&tag=[title-slug]")` |
| TrulyRemote | `WebSearch("site:trulyremote.co [title]")` |
| RemoteJobs.org | `WebSearch("site:remotejobs.org [title]")` |
| WeAreDistributed | `WebFetch("https://wearedistributed.org/remote-jobs/")` — parse listings on page |
| OpenToWorkRemote | `WebFetch("https://www.opentoworkremote.com/")` — WebSearch `site:opentoworkremote.com [title]` if direct fetch is sparse |
| WorkEW | `WebSearch("site:workew.com [title]")` |
| JobRack | `WebFetch("https://jobrack.eu/jobs?q=[title-urlencoded]")` |
| Jobgether | `WebFetch("https://jobgether.com/remote-jobs")` — parse listings, then `WebSearch("site:jobgether.com [title] remote")` for deeper coverage |
| PitchMeAI | `WebFetch("https://pitchmeai.com/jobs")` — filter by title after fetch |

---

### Startup / tech sites

| Site | Fetch method |
|---|---|
| startup.jobs | Prefer `mcp__startup-jobs__search_jobs` (keyword/role/country/remote/employment-type filters) + `mcp__startup-jobs__get_job` for full listing detail, if Gate 2's connection check found it connected (per `${CLAUDE_PLUGIN_ROOT}/references/job-sourcing-mcp-registry.md` — structured, no scraping; both tools are granted in this agent's own frontmatter). **Gate:** if not connected, fall back to `WebFetch("https://startup.jobs/?q=[title-urlencoded]&remote=true")` — the run header already noted the unconnected server at Gate 2, no need to repeat it here. |
| ChoppingBlock (Tier 1 — every run) | `WebFetch("https://www.choppingblock.ai/jobs?q=[title-urlencoded]")` — server-rendered, keyword search works (verified 2026-10-03, returns PMM listings). Optional filters: `&remote=`, `&country=`, `&seniority=`. Fallback `WebSearch("site:choppingblock.ai [title]")`. AI-native companies only. |
| MoaiJobs | `WebFetch("https://www.moaijobs.com/")` + `WebSearch("site:moaijobs.com [title]")` |
| CareerVault | `WebFetch("https://careervault.io/")` + `WebSearch("site:careervault.io [title]")` |

---

### General boards

| Site | Fetch method |
|---|---|
| Indeed | `WebSearch("site:indeed.com [title] [location or remote] job")` — do not attempt direct WebFetch (auth wall). If `mcp__140d3f8f-6ad4-4b39-9df9-84514cae0207__search_jobs` is connected, prefer it. |
| Glassdoor | `WebSearch("site:glassdoor.com/job-listing [title]")` — blocks direct WebFetch; use WebSearch only. |
| BuiltIn | `WebSearch("site:builtin.com [title] remote")` — blocks direct fetch; use WebSearch only. |
| ZipRecruiter | `WebSearch("site:ziprecruiter.com [title] remote")` |
| BeBee | `WebSearch("site:bebee.com [title]")` |
| Workable Jobs | `WebSearch("site:jobs.workable.com [title]")` |
| Hacker News Who's Hiring | WebSearch for `"Ask HN: Who is hiring?" site:news.ycombinator.com [current month] [current year]`. Fetch thread via `https://hacker-news.firebaseio.com/v0/item/{THREAD_ID}.json`. Fetch up to 100 comment items. Parse `text` field of each. Filter by title fuzzy-match. |
| Reddit hiring threads | WebSearch `site:reddit.com ("hiring" OR "who's hiring") "[title]"` and target the high-signal subreddits: `r/forhire`, `r/jobbit`, `r/remotejs`, plus the function/locale subreddits for the user's profession and country. Fetch a thread JSON via `https://www.reddit.com/<permalink>.json` and parse comments for company + role + apply link. Filter by variant fuzzy-match; verify against the company careers page before offering for a database add. |

---

### ATS / company career pages

Use these to surface roles posted directly on company career pages via their ATS. These often appear earlier than aggregators and are not always indexed on general boards.

**Native careers as a discovery source (not only verification).** For known target companies — `favorite_brands` from `pipeline-preferences.json`, and any companies surfaced during the run — fetch their own careers page directly (the rendering-capable extractor, or `site:<company-domain> "[title]"`) as a *discovery* step, per variant, not just to cross-check a board hit. A role can live on a company's careers page weeks before it reaches any aggregator.

| Site | Fetch method |
|---|---|
| Greenhouse | `WebSearch("site:boards.greenhouse.io [title]")` + `WebSearch("site:job-boards.greenhouse.io [title]")` |
| Lever | `WebSearch("site:jobs.lever.co [title]")` |
| Workday | `WebSearch("site:myworkdayjobs.com [title] remote")` |
| Ashby | `WebSearch("site:jobs.ashbyhq.com [title]")` |
| Rippling | `WebSearch("site:job.rippling.com [title]")` |

---

### AI / tech-specific sites

| Site | Fetch method |
|---|---|
| MoaiJobs | See Startup section |
| CareerVault | See Startup section |
| ChoppingBlock | See Startup section |
| PitchMeAI | See Remote section |
| TheirStack | Requires `mcp__theirstack__*` tools. Gate: if not connected, skip and note. |

---

### Accelerator portfolio boards (Tier 3)

Pick 2–3 per run based on portfolio fit. Fetch the board and filter by title; `WebSearch("site:[domain] [title]")` as fallback when direct fetch is blocked or sparse.

| Accelerator | Fetch method |
|---|---|
| a16z | `WebFetch("https://jobs.a16z.com/")` — filter by title |
| First Round | `WebFetch("https://jobs.firstround.com/")` — filter by title |
| Sequoia | `WebFetch("https://www.sequoiacap.com/jobs/")` or `WebSearch("site:sequoiacap.com jobs [title]")` |
| Bessemer | `WebFetch("https://www.bvp.com/jobs")` or `WebSearch("site:bvp.com jobs [title]")` |
| NFX | `WebFetch("https://www.nfx.com/jobs")` or `WebSearch("site:nfx.com jobs [title]")` |
| Accel | `WebFetch("https://jobs.accel.com/")` — filter by title |
| Lightspeed | `WebFetch("https://jobs.lsvp.com/")` — filter by title |
| Index Ventures | `WebFetch("https://jobs.indexventures.com/")` — filter by title |
| General Catalyst | `WebFetch("https://www.generalcatalyst.com/jobs")` or `WebSearch("site:generalcatalyst.com jobs [title]")` |

---

### Career-specific boards (Tier 4)

Select based on `USER_PROFESSION` / `USER_FUNCTION_SENIORITY_HIERARCHY`.

| Site | Fetch method |
|---|---|
| Product Marketing Alliance | `WebFetch("https://productmarketingalliance.com/jobs")` — filter by title. Fallback: `WebSearch("site:productmarketingalliance.com jobs [title]")` |
| Sharebird | `WebSearch("site:sharebird.com jobs [title]")` |
| Exit Five | `WebFetch("https://jobs.exitfive.com/")` or `WebSearch("site:exitfive.com jobs [title]")` |
| Wellfound | `WebFetch("https://wellfound.com/jobs?query=[title-urlencoded]&remote=true")` or `WebSearch("site:wellfound.com [title]")` |
| Welcome to the Jungle | `WebFetch("https://www.welcometothejungle.com/en/jobs?query=[title-urlencoded]")` or `WebSearch("site:welcometothejungle.com [title]")` |
| Y Combinator Jobs | `WebFetch("https://www.workatastartup.com/jobs?query=[title-urlencoded]")` or `WebSearch("site:workatastartup.com [title]")` |
| Techstars Jobs | `WebFetch("https://www.techstars.com/job-board")` — filter by title. Fallback: `WebSearch("site:techstars.com job-board [title]")` |

---

### Company intelligence boards (Tier 1 — last three)

These surfaces list roles at funded/tracked companies not always indexed on general boards. Fetch the jobs or portfolio section and filter by title.

| Site | Fetch method |
|---|---|
| Crunchbase | `WebSearch("site:crunchbase.com [title] jobs")` — direct fetch requires login; use WebSearch for role-level results. Also surface as company research context (funding stage, team size) for scored results. |
| PitchBook | `WebSearch("site:pitchbook.com [title] jobs")` — primarily company intelligence; use to enrich context for discovered roles. |
| Tracxn | `WebSearch("site:tracxn.com [title] jobs")` — similar to PitchBook; use for company context enrichment. |

**Note on company intelligence sites:** These are less reliable as direct role sources and more useful as enrichment for roles found elsewhere. If a WebSearch returns direct apply links or job pages, add them to the ranked list. If results are company profiles only, use them to enrich the Company field (funding stage, investor list, headcount) for roles discovered via other sites — especially when scoring and building context for the user.

---

### Contract / freelance

| Site | Fetch method |
|---|---|
| Upwork | Requires `mcp__1cb44f76-c627-45b2-8050-35e78e7f15c8__upwork_search_freelancers`. **Note:** Upwork searches for freelancers, not job postings — results represent active demand for this skill type, not open positions. Surface as "Contract signals" in a separate section, not as ranked roles. |
| Fiverr | `WebSearch("site:fiverr.com [title] OR [skill-category]")` — surfaces active buyer demand (Fiverr Pro projects, service categories). **Note:** Like Upwork, Fiverr results represent demand signals, not open positions. Surface as "Contract signals" alongside Upwork results, not as ranked roles. |

---

## Deduplication

Before scoring and displaying results, filter out any role that already exists in the database.

**Resolve the database id from the main config — one place to configure it.** Use `database_id` (legacy `notion_database_id`) from `${CAREER_DATA}/references/pipeline-preferences.json` — the same source every other pipeline reads. Everywhere below, the database id means this resolved value.

**How to check:** Query **every row, whatever its Status — closed rows included (2026-10-15, per the user: dedup "should include" closed roles)** via the **Notion adapter** (`${CLAUDE_PLUGIN_ROOT}/skills/database-notion/SKILL.md` → §2 read ladder, loaded when `database_backend` is `notion`) **in its all-rows mode (`target status = ALL`, defined in §2)**: Paths A1/A2 run with no Status filter; Path B resolves, through §3 view discovery, a view with no Status filter (one named "All", "All Applications", or similar) — a view whose saved filter hides `Closed` rows, such as an "active applications" view, is not acceptable for this step, since a closed role that is re-posted would come back as a new suggestion. If the adapter returns `all-rows unavailable` (Path B, no unfiltered view in the tracker), skip dedup for this run with the existing warning plus one line naming the fix: "add a view with no Status filter, e.g. 'All Applications', to enable deduplication." — never halt the sourcing run over it. Capture each row's `Status` alongside `Company` + `Position`. Extract the `Company` + `Position` pairs from the result — but if the returned table is misaligned (row/column counts don't match, cells empty where neighbours are not), do not parse it: log a warning, skip dedup for this run, and note in the results that duplicates were not filtered. A skipped dedup is recoverable; a mispaired Company/Position exclusion silently hides a real role. Extract all `Company` + `Position` pairs. For each search result: if `(company name, role title)` matches any existing pair (case-insensitive, substring match on title), exclude it from results — a match on a `Closed` (or `Position Closed`/`Role Closed`) row is excluded the same way, counted separately as "previously closed", so the report shows how many re-posts of closed roles were seen without re-surfacing them. Log both counts.

If no database id resolves, skip dedup and display a warning: "Deduplication skipped — no database ID configured. Run /career-engine:setup to configure."

---

## Scoring Rubric

Score every result (0–100) after deduplication.

| Signal | Points |
|---|---|
| Title — exact match to a target title | 20 |
| Title — partial / fuzzy match | 10 |
| Posted ≤ 3 days ago | 8 |
| Posted 4–7 days ago | 4 |
| Remote match (matches `remote_preference` exactly) | 10 |
| Salary meets or exceeds `screening_answers.compensation_floor` (only when listed) | 10 |
| Salary listed (any amount) | 5 |
| Applicant count < 50 (LinkedIn only) | 8 |
| Hiring manager identified (LinkedIn only) | 15 |
| Easy Apply available (LinkedIn only) | 4 |
| Apply URL present (non-LinkedIn sources) | 6 |
| Screening conflict — a populated `screening_answers` field contradicts a stated JD requirement | −15 (down-rank, never exclude; attach a visible label) |

Cap at 100. Sort descending. Under `titles` mode, roles without a title match should not appear unless no matches exist.

### Capabilities mode (default; `role_matching` absent or `capabilities`) — 2026-10-19

Per the user: "the coach needs to be savvy enough to identify what the user knows how to do, what they're aiming for in terms of scope of responsiblities and/or what they want and don't want to do, and then find relevant roles accordingly ... including but not limited to role titles." The title signal shrinks to a nudge and the "no title match → hidden" rule does not apply. Coverage is scored only for the opened shortlist (agent Step 4, pass 2): items = the posting's responsibilities and requirements; coverage = items a profile line covers (capability underneath the label, any vocabulary) ÷ all items.

| Signal | Points |
|---|---|
| Responsibility coverage ≥ 80% | +30 |
| Responsibility coverage 60–79% | +20 |
| Responsibility coverage 40–59% | +10 |
| `scope_preferences.want` hit on a responsibility | +5 (cap +10 total) |
| `scope_preferences.avoid` hit on a core responsibility | −15 + visible label `⚠ scope: avoid — [item]` (down-rank, never exclude) |
| Title exact / partial match (replaces the 20 / 10 rows above) | +8 / +4 |

The other rows (recency, remote, salary, applicants, hiring manager, Easy Apply, apply URL, screening conflict) apply unchanged. `exclusion_patterns` stays a title-substring exclusion in both modes. Profile missing under `capabilities` → the title rubric above plus the header notice; never a stop.

**Standing screening answers (`screening_answers` from `${CAREER_DATA}/references/pipeline-preferences.json`).** If present, compare each *populated* field (travel / relocation / security_clearance / compensation_floor / availability) against the JD. A hard conflict (e.g. role explicitly requires relocation while `relocation` = "no") applies the −15 down-rank above **and** attaches a visible reason label to the row (`⚠ screening: relocation required vs your "no"`) so the user sees exactly why it ranked lower. **Never silently exclude on a screening conflict** — down-rank + label only, and log it in the run output. If `screening_answers` is absent or empty, skip this entirely (no labels, no down-ranks).

---

## Verification Pass (mandatory before output)

Run on the ranked list after scoring — every result that will be displayed or offered for Notion add. Full verification applies to the top 20 by score; below that, run only item 2 on text already in hand (no extra fetches).

**1. Careers-page cross-check.** Locate the role on the company's own careers page (ATS fetch methods above, or `site:<company-domain>` search). Outcomes:
- **Listed** — capture any detail the board listing lacks (location nuance, salary, team, reporting line) and merge it into the result.
- **Not listed** — the role may be filled or pulled. Do not drop it; flag `[Not on careers page — verify before applying]`.
- **Listed with different terms** — the careers-page version wins; note the discrepancy.
While there, capture staleness signals: original posting date and re-post indicators (e.g. hiring posts months older than the board date). Flag roles open or re-posted 90+ days.

**2. Location deep-scan.** Location truth is rarely confined to the location field — clues hide in the full text and metadata and get overlooked. Scan the complete listing text plus metadata (structured data, board location tags, the careers-page entry, visible hiring posts) for: stated location or timezone requirements, the REASON given for them, work-authorization language, and operational clues (an EOR provider such as Deel or Oyster in the application flow, postings in multiple countries, distributed-team statements). Record what was found and where.

**3. Remote-geography rule.** A role advertised as remote is NEVER excluded for a geographic restriction found in its text (e.g. "US only", "primarily EST timezone"). Surface it in the ranked list and include it in the Notion-add offer regardless of score, with a one-line note carrying: the restriction as written, its stated reason, and any exception-path evidence from the deep-scan (EOR in place, hires outside the stated country, a timezone rationale the user's location satisfies as well or better). The user decides; the engine never silently hides a remote role over geography. Remote restrictions are often softer than written — this protects any user hunting remote roles from outside the restricted country.

---

## Exclusion Rules

**Geography is never an exclusion for remote roles.** A geographic restriction in a remote-advertised role's text is handled by the Verification Pass remote-geography rule above — noted, never excluded.

**A screening conflict is never an exclusion either.** A populated `screening_answers` field contradicting the JD is handled by the Scoring Rubric — down-ranked and labeled, never dropped. The user decides.

Exclude any result where:
- The title contains any `exclusion_patterns` value (case-insensitive substring match)
- The role is already in the database (see Deduplication)
- The role was already surfaced in a previous search session saved to `{{OUTPUT_FOLDER}}/sourcing/` (check saved search files from the last 14 days — skip roles that appeared with the same company + title)

**Sources deliberately not searched (echo aggregators).** Do **not** add Lensa, Metaintro, Work Whisper, or Remote Rocketship to the catalog. They re-publish roles already surfaced by the boards and ATS sources above, so they add deduplication load, not new openings. Skip them by default; do not reintroduce them as "more coverage."

---

## What Is Not a Role

Do not surface:
- Aggregator "job alert" pages (no actual company or description)
- Roles with no company name
- Roles where the only content is a stub or redirect
- Upwork listings (surface separately as contract signals, never as ranked roles)
