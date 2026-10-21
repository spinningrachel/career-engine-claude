---
name: database-notion
description: The Notion adapter — the complete mechanics for every database operation the pipeline performs against a Notion tracker (schema read, the A1→A2→B query ladder, view discovery, and property/page-body writeback). MANDATORY load whenever `database_backend` is `notion` (the default) and a skill needs to read from or write to the database. The pipeline skills speak in generic operations (query the queue, fetch a record, write a field, resolve a view); this skill is the only place those operations are spelled out in Notion-specific tool calls.
---

# Database adapter — Notion

This is the **Notion adapter**. It owns every Notion-specific mechanic in one place, so the pipeline skills can speak in backend-neutral operations and a future backend can be added as a sibling adapter without touching them.

**When to load (mandatory, conditional):** any time a pipeline skill needs to read from or write to the database **and** `database_backend` resolves to `notion` (the default; from `${CAREER_DATA}/references/pipeline-preferences.json`). The caller names the generic operation and the parameters (target status, properties to read, fields to write); this skill provides the *how*. If `database_backend` is ever something else, the caller loads that backend's adapter instead — never this one.

**Database ID:** `$NOTION_DATABASE_ID`, resolved from config (`database_id`, legacy `notion_database_id`) by the calling skill. Any `{{NOTION_DATABASE_ID}}` token in plugin text is a literal placeholder, not a value. `$NOTION_DATABASE_ID`/`$NOTION_NEEDS_EDITING_VIEW_URL` are this adapter's internal variable names.

**Generic operation → Notion mechanic:**

| Generic operation (what callers say) | Notion mechanic (below) |
|---|---|
| Read the schema reference | §1 Schema read |
| Query the queue for `Status = <target>` | §2 Read ladder (A1 → A2 → B) |
| Resolve a view by name | §3 View discovery |
| Fetch a record's full properties | §1/§2 per-page `notion-fetch` |
| Write a field / write-if-empty | §4 Writeback |
| Write the page body | §4 Page-body write |

---

## §1 — Schema read (always first)

**⛔ STOP — check this before running the fetch below.** §1's fetch below is needed once per run for the property/select-option schema reference — that use is never skipped. But if the caller's need right now is *only* view discovery (resolving a view URL for §2 Path B or §3), and the caller already has a non-empty, non-stale fast-path view URL from config (`database_edit_view_url`, `database_interested_view_url`, `database_hold_view_url`, `database_researched_view_url`, `database_cv_ready_view_url`, `database_new_view_url`), **skip straight to §2 Path B step 2** (`notion-query-database-view` with that URL) — do not run the full schema fetch just to discover a view you already have the URL for. Two independent live runs ran this ~60-65KB fetch anyway despite already holding a populated fast-path URL in context, and both hit context exhaustion shortly after. Only run the fetch below when you actually need the schema reference (property names / select options for a write) or when no fast-path URL is available for the view you need.

Run `notion-fetch` on the configured database ID:

```
notion-fetch id="{{NOTION_DATABASE_ID}}"
```

If the fetch fails (tool error, empty response) or the response contains no `CREATE TABLE` block, **stop and report** — do not proceed without a schema and do not improvise one.

**If the result is a persisted-output stub, not inline JSON** (the tool reports something like "Output too large (NN KB) — saved to <path>"): **do NOT `Read` or otherwise re-ingest that file in full.** A full re-read of a 60KB+ persisted schema file has been the single largest context injection in multiple live runs and immediately preceded auto-compaction each time — it defeats the entire point of the persist-to-stub mechanism. Instead, extract only what you need via a scoped shell command against the file path (`python3`/`jq`/`grep`) — the `CREATE TABLE` block for the schema reference, and/or the `<views>`/`<data-sources>` blocks if you need view discovery — and discard the rest. This is the same projection discipline Path A1 already uses to avoid bulk payloads (below); apply it here too.

Extract the SQLite `CREATE TABLE` block: this is the **schema reference** for the run — the authoritative list of property names and valid select-option values. Keep it in context.

**Use it for every write.** When writing a select field, look up the valid options in the SQLite comment for that column (e.g. `-- one of ["Yes", "Remote-maybe", "No"]`) and write the exact string from the schema. Never hardcode select-option values. If an agent returns a value that doesn't match a schema option, map it to the closest option using the schema as the authority. Pass the SQLite block to any spawned agent that writes select values (e.g. the career coach) as a "Notion schema reference" section.

This same `notion-fetch` response also carries the `<data-sources>` and `<views>` blocks used in §2/§3.

---

## §2 — Read ladder: query the queue (A1 → A2 → B)

The caller supplies the **target status** (e.g. `New`, `Needs Research`, `Needs Editing`) and the properties it needs. Use **Path A1** (`ntn` CLI) when its gate passes; fall to **Path A2** (`notionApi`) when A1 is unavailable; use **Path B** (standard connector) when both A rungs are absent or unusable. **Falling down the ladder is sanctioned routing, never a reportable failure.**

**All-rows mode (2026-10-15, per the user — sourcing deduplication must see closed roles too).** A caller may instead supply `target status = ALL`. Then: Paths A1 and A2 run their query with the Status filter omitted entirely; Path B resolves (§3) a view whose saved filter does not restrict Status — one named "All", "All Applications", or the like — and never an "active applications" view, since a view that hides `Closed` rows defeats the purpose; and the "process only rows matching the target status" rule below does not apply — every live row is a result, with its `Status` captured alongside the properties the caller asked for. The archived/trashed exclusion still applies. The only sanctioned caller today is `source-open-roles`' Deduplication step; queue pipelines never use this mode. **When no unfiltered view exists on Path B** (§3 finds nothing named "All"/"All Applications" or equivalent, and every view carries a Status filter), all-rows mode cannot run there: return that outcome to the caller as `all-rows unavailable` rather than the ladder's usual stop-and-report — the caller decides (sourcing skips dedup for the run with its existing warning and names the missing view, since a skipped dedup is recoverable and a halted sourcing run is not).

### Path A1 — `ntn` CLI structured query (preferred where available)

The official Notion CLI returns the same structured JSON as the API, through Bash — so the result is trimmed in the shell and only the needed fields enter context. The **gate**, not the environment label, decides. The gate never installs the CLI and never prompts for credentials mid-run. In headless/sandboxed shells auth comes from `NOTION_API_TOKEN` (or `NOTION_KEYRING=0` file auth); if neither is present `ntn whoami` fails — the gate working as designed.

Gate (both must pass):
```bash
command -v ntn >/dev/null 2>&1 && ntn whoami >/dev/null 2>&1 && echo "Path A1 available"
```

Resolve the data-source ID once, then query:
```bash
ntn api /v1/databases/{{NOTION_DATABASE_ID}}   # read data_sources[0].id from the response
ntn datasources query <data-source-id> \
  --filter '{"property":"Status","status":{"equals":"<target status>"}}' \
  --limit 100 --json
```

Trim the JSON in the shell (`python3`/`jq`) to each row's page `id` plus the named properties — always by property name, never column position. If `has_more` is true, continue with `--start-cursor` until exhausted. `ntn pages get <page_id>` returns a full single row (properties + page body markdown) in one call.

Project at the source so bulk payloads never arrive: repeat `filter_properties==<property_id>` on a direct query call —
```bash
ntn api /v1/data_sources/<data-source-id>/query 'filter_properties==title' 'filter_properties==<property_id>' \
  -X POST -d '{"filter": {...}, "page_size": 100}'
```
— returns only the named properties (~3KB projected vs ~120KB unprojected). `filter_properties` takes property **IDs** read from the schema, not names.

`ntn api` is httpie-style: path given directly, no verb words (`ntn api /v1/pages/<page_id>`; method inferred, override `-X PATCH -d '{...}'`); query params are `name==value`. Verify rather than guess: `ntn api ls`, `ntn api <path> --docs`, `ntn api <path> --spec`.

If an A1 call errors after the gate passed (auth revoked, network), fall to A2 for the rest of the run.

### Path A2 — `notionApi` structured query

`notionApi` returns structured JSON keyed by property name — no column alignment to get wrong.

The `notionApi` tools are deferred; load the schema first:
```
ToolSearch query="select:notionApi__API-query-data-source"
```
If ToolSearch returns a schema, proceed. If nothing, try the full name `mcp__notionApi__API-query-data-source` directly (deferred tools are callable by full name). If the direct call returns **tool-not-found**, the server isn't connected — **execute Path B immediately**. If it returns **any other error** (401, Enterprise-gated, malformed, timeout), treat the server as unusable — **execute Path B immediately**. Neither is a reportable failure. Do NOT attempt `notion-search`, `notion-fetch` on a view URL, or any improvised route — the next action is always `notion-fetch id="$NOTION_DATABASE_ID"` (Path B step 1).

Call `API-query-data-source` (full name `mcp__notionApi__API-query-data-source`) with: database ID `$NOTION_DATABASE_ID`; filter `{"property": "Status", "status": {"equals": "<target status>"}}`; page_size 100. Returns a JSON array of page objects, each with `id` and a named `properties` object — read by name, not position. **Paginate:** when the response carries `has_more: true`, call again with `start_cursor` = the returned `next_cursor` until it is false — a queue rarely exceeds 100 rows, but all-rows mode (§2) regularly does, and a silently truncated list re-suggests every duplicate past row 100.

### Path B — connector view query for discovery, per-page fetch for properties

Only when the `notionApi` server is absent or unusable. **Start with step 1 — `notion-fetch id="$NOTION_DATABASE_ID"` first.** Do not call `notion-fetch` on any other URL, do not call `notion-search`, and complete steps 1–4 in order. `notion-query-database-view` runs a *view's own saved filter/sort* and returns a *rendered table*. **Two hard constraints (R-39):** it accepts **no ad-hoc `filter`** (any filter is silently ignored) and requires a real **view URL** (`https://www.notion.so/<DB_ID>?v=<VIEW_ID>`), never the bare database URL. The rendered table is also prone to column misalignment (R-1: 17 companies, 16 status tags) and shows only visible columns, so it is **discovery only**; property values are always read per page. **A misaligned rendered table must never be parsed** — and in Path B no rendered table is ever parsed for property values, aligned or not.

**⛔ Steps 2–3 (the view-query call itself) must be delegated, never run directly in the calling pipeline's own context.** Doctrine has always said "discovery only... read no property value from the rendered table," but that describes what the *caller* does with the result — it does not stop `notion-query-database-view` itself from returning full property data for every row in the view. A live traced session confirmed exactly this: 28 queued roles returned 40,158 raw characters of full property data into the orchestrator's own context from this one call, with no persist-to-stub and no extraction step — the same context-exhaustion failure shape as the per-page fetch loop in step 4 (below), just one call earlier in the sequence. **Spawn a lightweight subagent** (general-purpose / Task tool) to run steps 2–3: pass it the resolved view URL from step 1. Instruct it exactly: *"Call `notion-query-database-view` with `view_url`=<url> and no other arguments. From the result, extract only the page IDs (and links, if present) — read no property value from the table. Return a plain list of page IDs only, one per line. Return nothing else — no commentary, no property data, no partial table."* The subagent returns text only (page IDs) — the calling pipeline receives that bounded list and proceeds to step 4 (which is itself already delegated per the per-page fetch pattern below). This keeps the full property dump out of the calling pipeline's context at both steps, not just the per-page one.

1. **Resolve the view URL by name — ONE fetch is enough** (verified against the live `notion-fetch`, 2026-06). Call `notion-fetch id="$NOTION_DATABASE_ID"`. **This single response contains BOTH:** a `<data-sources>` block (each `<data-source url="{{collection://UUID}}">` is the data-source id used by `API-query-data-source`) **and** a `<views>` block listing every view as `<view url="{{view://UUID-with-dashes}}">` with config JSON including `"name":"<view name>"`.
   - **Find the view in that same response:** scan `<views>` for the one whose JSON `"name"` matches the target; strip the `{{...}}` wrapper (all URLs are wrapped) to get `view://<UUID-with-dashes>`.
   - **Do NOT fetch the `collection://` URL to find views** — a `notion-fetch` on a `collection://` returns **only** the data-source schema (properties + SQLite table), with **no `<views>` block**. Views live only in the database fetch. (Fetching `collection://` is for reading the schema.)
   - **Build the query URL:** take the view UUID, **remove all dashes**, construct `https://www.notion.so/<DB_ID_NO_DASHES>?v=<VIEW_ID_NO_DASHES>`. View IDs change when views are reorganised, so the by-name lookup is always the source of truth.
2. Call `notion-query-database-view` with `view_url` = that URL and **no other arguments**, via the delegated subagent above. The view already restricts to the target status (in all-rows mode, to nothing — the §3-resolved view has no Status filter); do not construct a filter.
3. **Discovery only.** The subagent extracts page IDs/links from the result (unambiguous even in a misaligned table) and returns only those. Read no property value from the rendered table.
4. **Fetch full properties per page (in all-rows mode, keep every live page — the Status discard below does not apply):** `notion-fetch id="<page_id>"` on each candidate page; read its complete property set from the structured response. Discard pages whose Status doesn't match. Every downstream read uses these per-page property sets, never the rendered table. **This step is also delegated** — see each consumer's own per-page-fetch delegation instructions (e.g. intake Step 0b, orchestrator Step O1, edit Step E0) for the exact subagent contract; the principle is identical to steps 2–3 above: bound the return, write it to disk in one call, never accumulate raw results turn-by-turn in the calling pipeline's own context.

---

## §3 — View discovery (resolve a view by name)

**⛔ STOP — is a fast-path URL already non-empty from config? Check this before anything else in this section.** The calling skill passes its pre-resolved view URL (e.g. `$NOTION_INTERESTED_VIEW_URL`, `$NOTION_HOLD_VIEW_URL`, `$NOTION_NEEDS_EDITING_VIEW_URL`, `$NOTION_NEW_VIEW_URL`, etc., resolved from `pipeline-preferences.json`). **If that URL is non-empty and not known to be stale: skip straight to §2 Path B step 2** (`notion-query-database-view` with that URL, no filter) — do not run the DB-discovery fetch below at all. This is not a minor optimization; skipping it wastes a ~60-65KB fetch that has caused early context exhaustion in production runs. Only fall through to the by-name lookup below when the fast-path URL is empty, is known to be stale, or the query against it fails.

This is Path B step 1 above, also used wherever a skill needs a view URL: one `notion-fetch` on the DB id → read the `<views>` block → match `"name"` → strip `{{...}}` → dash-remove → `?v=` URL. When the URL is empty, stale, or the query fails, fall back to this by-name lookup — it is always the fallback because saved URLs break when views are reorganised. **Never fetch the `collection://` URL to find a view.**

---

## §4 — Writeback (write a field / write-if-empty / page body)

**Write to the EXISTING property of that exact name — never create a property or a numbered variant** (the "Strategy 1" bug: an agent that couldn't write `Strategy` cleanly made a duplicate). If a target property is missing, rejects the write, or its type doesn't match the schema (§1), **stop and report** — never invent a field.

**Both write-only-to-empty and always-overwrite are supported per property — the caller specifies which applies to each, and this adapter has no opinion on which should be the default.** Write-only-to-empty: read the current value first; if populated (including `N/A`), skip — do not overwrite. Always-overwrite: write the coach's/caller's fresh value regardless of what's currently there. Pipelines differ on which is the default: intake's Step 0.9a, for example, defaults every coach-owned property to always-overwrite with three named write-only-to-empty exceptions (`JD Body`, `Gap handling`, `CV Type`) — see `career-engine-intake/SKILL.md`. Follow whatever the calling skill specifies per property, not an assumption carried over from a different pipeline.

**Mechanism:**
- On Path A1 (the `ntn` gate passed), writes may go through `ntn api /v1/pages/<page_id> -X PATCH -d '{"properties": {...}}'` — same per-property write-only-to-empty / always-overwrite rule, same parallelism.
- Otherwise use the connector: `notion-update-page`, properties keyed by exact name, select values exactly matching the schema options.

  **Exact required call shape — do not guess this.** The tool requires `command` and `page_id` as top-level arguments, NOT the bare `{"id": ..., "properties": {...}}` shape that seems natural by analogy to other Notion tools:
  ```json
  {
    "page_id": "<page_id>",
    "command": "update_properties",
    "properties": { "<Property Name>": <value in the shape that property type expects> }
  }
  ```
  A call using `{"id": ...}` instead of `{"page_id": ..., "command": "update_properties", ...}` fails with `MCP error -32602: Invalid arguments` for every property, costing a full failed round-trip. This has been independently discovered by trial in multiple production runs — do not re-derive it by trial again.

**Write to properties, not the page body**, except where a caller explicitly sanctions a page-body block (e.g. the intake outreach map). For a sanctioned page-body write: use `notion-update-page`; prepend above existing content separated by `---`; never delete existing content.

---

## Rules for all paths

- **`Agent Status` claim (2026-10-21):** the claim, skip, and release rules live in `skills/database/SKILL.md` → Agent Status. Mechanics here: it is a select property; claim and release are single-page `notion-update-page` / `API-patch-page` property writes, validated against the §1 schema like any select (a missing property means skip the claim and emit the config-health notice, never an error); the per-page fetch already returns it, so filtering needs no extra call.

- **Archived/trashed rows are never queue members (2026-07-23).** Depending on the tool surface, a status query can return pages that are archived or in the trash — a real run's `New`-status query surfaced two archived pages, which were then written to and promoted like live rows. On every path, check each candidate row's archived/in-trash indicator (`archived`/`in_trash` in structured responses on A1/A2; the per-page fetch on Path B) before treating it as a queue member — drop archived rows and name them in the run report, same as non-matching-status rows.
- **Never write to an archived/trashed page (§4 side of the same rule).** Immediately before writing a page, the caller must have seen it alive in a fetch from this run showing `archived`/`in_trash` false. A write to an archived page skips silently on some tool surfaces (success response, no effect) — a success response is not proof the page was live. Skip the role's writes, report it as `skipped — page archived/trashed`, and never unarchive a page to make a write land.
- **User automations can archive a page the moment you write it — batch trigger-prone writes, and treat post-write archival as a sanctioned outcome (2026-07-23).** Notion databases can carry user-defined automations with no delay option (all-or-nothing), e.g. "archive when Priority ≥ 4" — so a multi-call writeback that sets `Priority` early can have the page archived out from under its remaining calls, which then silently no-op and confuse the run. Two rules: (1) **batch each page's writes into ONE update call** wherever the tool supports multiple properties per call — all property values AND the Status change together — so any automation fires after the full payload lands; when a single call is impossible, write the trigger-prone fields (`Priority`, `Status`) LAST. (2) **A page found archived AFTER this run's own successful write to it is not an error and not a liveness-rule violation** — report it as `archived post-write (user automation)` and move on; do not retry, do not unarchive, and do not treat the role's writeback as failed.
- **Never create, update, or modify Notion views.** Do not call `create-database-view`, `update-database-view`, or any equivalent — not as a workaround, not to filter, not to fix misalignment.
- **On Paths A2 and B, do not Bash/Grep the query result** — process it from the tool response in context. On Path A1 the result arrives through the shell and trimming it there (`python3`/`jq`) is the sanctioned mechanism.
- Process only rows matching the target status; discard non-matching in memory and log a warning. (Not in all-rows mode — see §2 — where every live row is kept with its `Status`.)
- **All paths fail → stop and report.** Never treat a failed query as zero results, and **never fall back to `notion-search` or any semantic/keyword search to enumerate queue rows (R-39)** — it is relevance-ranked and capped, cannot enumerate the queue, and silently misses roles, producing a false "no roles" when roles exist.
