---
name: job-sourcing-mcp-registry
description: How agents discover any connected job-search connector, plus a suggestion list of free / no-login-for-search job connectors with connect instructions. Public server data only — no personal data.
---

# Job-Sourcing Connector Registry

**Any connected job-search connector works** (2026-11-03, per the user: "there are now a bazillion official connectors for job searching available on llm platforms"). This file is not a gate. Agents do not need a connector to be listed here to use it; the list below exists to *suggest* connectors to a user who has none, and to record each one's quirks.

## Discovery (used by `source-open-roles` Gate 2 and by the JD ladder's connector rung in intake, the coach, the prioritizer and edit)

1. `ToolSearch` with keywords `search jobs`, `job search`, `get job`, `job details`, `jobs`, `remote jobs`. Load the schemas of every hit.
2. Keep a tool only if it returns real job postings, identified by its **server name/description** — never by the bare tool name (unrelated servers also expose `search_jobs`). Exclude acting tools: apply, submit, save/track, alert-subscribe, reminders, messaging, profile/resume edits.
3. Search tools take keyword/title + location/remote/date filters (names differ per connector — read each schema); detail tools take the connector's own job id from a search result. Never pass a job key taken from a third-party URL.
4. **Be pedantic about access.** One failed call, an empty result, or an absent tool name does not mean "no access." Before marking a connector unavailable: re-run `ToolSearch` for it by server name and purpose, call it once with a minimal query (one title, no filters), retry once with alternate parameters, read the error (authorization needed vs. no results vs. bad parameters). Authorization needed is reported as "needs authorization" naming the server — not as "unavailable". Record what was tried.
5. No job connector found at all → say so once (never blocking) and suggest up to 3 rows from the list below, chosen for the user's location and function.

## Suggested connectors (free for job seekers; search needs no sign-in unless noted)

"Login for search" is what the vendor's own listing/instructions state; `unverified` means the listing does not say — check on first connect and correct the row. Connect via Customize → Connectors (search the name) or the command shown.

| Connector | Strong for | Login for search | Connect |
|---|---|---|---|
| workfinds.app | Jobs pulled from company career sites and ATSs, filter by country/arrangement/type/date | none (listing: "All data is public; no sign-in") | Connectors directory → "workfinds" |
| startup.jobs | Startup / tech roles, 8 read-only tools incl. `search_jobs`, `get_job` (vendor docs `https://startup.jobs/mcp`) | none stated | `claude mcp add --transport http startup-jobs https://api.startup.jobs/mcp` |
| Curaiz Remote Jobs | Fresh remote jobs (≤30 days), matched by role description + applicant location | unverified | `claude mcp add --transport http curaiz https://www.curaiz.com/mcp` |
| RVC Jobs | Digital roles in US, EMEA, worldwide remote; salary and language filters | none for search (applying on RVC needs sign-in) | `claude mcp add --transport http rvc https://app.rvc.global/mcp/claude` |
| Relomote | Remote jobs by the user's country; relocation / visa-sponsorship roles | unverified | `claude mcp add --transport http relomote https://relomote.com/mcp` |
| ZipRecruiter | General board, broad US coverage | unverified | `claude mcp add --transport http ziprecruiter https://api.ziprecruiter.com/mcp` |
| JobDataLake | 1M+ enriched listings from 40+ ATS platforms, hourly | free tier (500 calls/day) with an API key from jobdatalake.com | Connectors directory → "JobDataLake" |
| emprego.com | Portuguese-language / Portugal market | unverified | Connectors directory → "emprego" |
| Indeed (directory connector) | General board, worldwide | unverified | Connectors directory → "Indeed" |
| JobsPipe | 30+ boards, public employment services, career sites; also company hiring intelligence | account with plan credits (free allowance varies) | `claude mcp add --transport http jobspipe https://mcp.jobspipe.dev/mcp` |

**Not suggested by default** (need an account or are not seeker-oriented): TheirStack (credits), FoundRole and Wobo (account/OAuth, they also write to the user's profile and tracker), Greenhouse/Remote/Darwinbox (employer-side tools).

## Maintaining this list

A row belongs here only if it is a real MCP endpoint for job search. Record the connect command as a user would run it and the Login-for-search value exactly as the vendor states it — do not guess. Tool names are not recorded: discovery reads them from the connected server, so a vendor renaming a tool breaks nothing. The server name a user gives `claude mcp add` determines the `mcp__<server-name>__*` tool prefix; discovery handles any name.
