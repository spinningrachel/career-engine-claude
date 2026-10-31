# Connectors

## How tool references work

Plugin agents reference external services by MCP tool calls. This file documents which services this plugin connects to, what category each serves, and what alternatives exist in each category.

## Plugin path convention

Agents and skills in this plugin reference internal files using `${CLAUDE_PLUGIN_ROOT}` rather than hardcoded absolute paths. Claude Code resolves this variable to the plugin's installation root at runtime, so paths survive session ID changes, reinstalls, and moving the plugin folder.

- Reference files: `${CLAUDE_PLUGIN_ROOT}/references/`
- Skills: `${CLAUDE_PLUGIN_ROOT}/skills/`

Do not hardcode the full absolute path (e.g., `/Users/.../local-agent-mode-sessions/.../rpm/plugin_.../`) in any agent or skill file. If you add a new agent or skill that needs to read reference files, use `${CLAUDE_PLUGIN_ROOT}/references/` and point to `REFERENCES.md` as the index.

## Connectors for this plugin

| Category | In use | Included in .mcp.json | Alternatives |
|---|---|---|---|
| Job tracking | Notion | Yes | CSV/Google Sheets (setup agent configures either) |
| File storage | iCloud (local path via Desktop Commander) | n/a — filesystem access, not MCP | Any local folder; setup agent sets the output path |
| File system | Desktop Commander | Yes | MacOS-MCP |
| Job search | Indeed, Dice, ZipRecruiter | Yes | — |
| Document conversion | pandoc (CLI tool) | n/a — not an MCP server | — |
| Startup-board job search | startup.jobs MCP | No (user-installed) | WebFetch scraping (default fallback) |

### startup.jobs MCP — Optional

When connected, `source-open-roles` prefers this over scraping `startup.jobs` for structured, reliable results. Full catalog entry (confirmed tool names, canary check): `references/job-sourcing-mcp-registry.md`.

**Install:**
```bash
claude mcp add --transport http startup-jobs https://api.startup.jobs/mcp
```

**Configure with server name `startup-jobs`** (the name above — required so the resulting tool names match what the plugin expects). Gives the agent access to:
- `mcp__startup-jobs__search_jobs` — filter listings by keyword, role, country, remote status, employment type
- `mcp__startup-jobs__get_job` — full listing detail
- `mcp__startup-jobs__list_countries` — used only as a cheap connection check

Free tier: last 14 days of listings, 20 requests/minute, no API key required. `source-open-roles` falls back to `WebFetch` scraping if this MCP is not connected.

### LinkedIn — not accessed

LinkedIn is not accessed by this plugin: no MCP, no fetching of linkedin.com pages, no guest endpoint. LinkedIn's [User Agreement](https://www.linkedin.com/legal/user-agreement) (§8.2.2, §8.2.13) bars scrapers, bots and automated access, and its [prohibited-software page](https://www.linkedin.com/help/linkedin/answer/a1341387) warns that accounts using such tools can be restricted or shut down. A LinkedIn job link in your tracker is read as text only; the role is found through the company's careers page, job-board mirrors and search. If no public copy exists, `JD Fetch Status` is `LinkedIn-blocked`. Research contacts are built from web sources and marked `[LOW]`; connect with them on LinkedIn yourself.

**If you installed `linkedin-mcp` earlier:** the plugin no longer calls it. You can uninstall it and delete its saved login/profile folder.

## Notion setup

The plugin expects a specific database schema. The fastest way to get started:

**[Duplicate the Notion template →](https://abounding-trouser-bce.notion.site/13a6d072845047c0a99cfeb6b201091b?v=843875fd750c4a9d884b298748a4d331&pvs=143)**

**Prefer not to duplicate a shared page?** `references/job-applications-template.csv` is a superset of the schema as a CSV — every column the pipeline reads or writes, plus a few optional contact/referral-tracking columns — import it with Notion's **Import → CSV**, set the column types Notion cannot infer from a CSV (Status, the Select and Multi-select columns, URL and Date columns — the setup skill lists them), and delete the ten fictional example rows. The pipeline reads your database's schema at run start, so both routes end up identical.

After duplicating (or importing):
1. Copy the database ID from the URL (`notion.so/<workspace>/<DATABASE_ID>?v=...`)
2. Run `/career-engine:setup` — it will ask for the ID and write it to the plugin config

## CSV / Google Sheets alternative

If you don't use Notion, the setup agent can configure a CSV-based job tracking workflow instead. During setup, choose "CSV / spreadsheet" when prompted and provide the file path or Google Sheets URL. The pipeline will read from and write to the spreadsheet instead of Notion.
