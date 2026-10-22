# Career Coach — Output Format and Rules

Load this file when you are ready to format and return your analysis. It covers the output format template and output rules (what to return and how).

---

## Output Protocol — Intake Pipeline (R-41)

**When spawned by intake (Option 2) with a `$PIPE` path:** write the full analysis to `$PIPE/coach-output.md` and return this single line only:

`COACH: <N> roles analysed → $PIPE/coach-output.md`

Do not return the analysis inline — the file persists through context compression; inline returns do not. For all other options (1, 3, 4, 5, 6) where no `$PIPE` path is provided, return the analysis inline per the Output Format below.

---

## Output Format

Return findings in this exact structure for every role received.

```
## Career Coach Analysis — <date>

### Priority scores
[Omit roles where Priority was pre-set AND confirmed unchanged]
- **<Company> — <Role Title>** — Page ID: <id>
  - Priority: <value> — generated | confirmed | revised
  - Priority Reason: <one tight sentence — key factor(s) that drove the score>
  - Triage exit: <Yes — full research skipped | No — full research completed>

### Patterns and notes for the user
- <observation about the batch>

### Writing guidance

#### Batch analysis
- Common gaps across the queue: <what the user's background doesn't fully cover for this batch>
- Shared keywords: <terms appearing across 3+ JDs>

#### Base CV recommendation
<which shared sections to draft once before branching>

#### Per-role focus
1. **<Company> — <Role Title>:** <primary focus> / <secondary focus>

### Strategic properties

#### <Company> — <Role Title>
- **Role emphasis:** (exactly two labeled parts, each a bullet list, ≤100 words total — `coach-analysis.md` is the authority; no capability mapping, no de-emphasis, no confidence tags, no strategy, no CV type, no company facts beyond the operating-model translation, no rank commentary, ever)
  - **Emphasis:** then 3–4 bullets, most important first — each ONE job to be done (verb + the result the business hires this role to produce), JD vocabulary, ambiguous terms translated through the company's real operating model in generic discipline vocabulary (PLG, B2D, ABM...)
  - **Likely KPIs:** then 3–5 bullets — one metric or tight metric group each; target-model set for a transition
- **CV Type:** <Detailed | Brief — one-line rationale> — **only when `CV_TYPE_MODE == "Variant"`; omit entirely otherwise.** Its own property (2026-07-23): intake writes it to the user's per-role `CV Type` select, write-only-to-empty — never a line inside `Role emphasis`.
- **CV Titles:** (the role-tailoring plan — `coach-analysis.md` is the authority; a `Level:` line, then one disposition line per employer in her record, nothing else)
  - Level: <the level the target role reads at>
  - <Employer>: Retitle → <title> | basis: <role fact, ≤15 words>
  - <Employer>: Descriptor → <recorded title> (<target function>) | basis: <role fact, ≤15 words>
  - <Employer>: Keep → <recorded title> | reason: <≤15 words>
  - <Employer>: Fold
- **JD proof:** "<verbatim quote>"
- **Keywords:** Critical: <terms> | Important: <terms> | Nice-to-have: <terms> | Unmatched: <only terms with no career-data basis, with the update-or-accept note — omit the segment when all terms matched (2026-07-28)>
- **Strategy:** `IC` | `Strategic` | `Hybrid`
- **Company Stage:** <stage> [HIGH/LOW]
- **Role Type:** <types>
- **Relationship type:** <type>
- **Gap handling:** <[Gap]: [handling] — one line per gap, or N/A; omitted when gap handling is disabled> <PLUS, in BOTH modes (2026-07-28): `Keyword gap: [term] — no career-data basis; update career-data and re-run intake, or expect this at screen.` — one line per Unmatched keyword, omitted when all keywords matched>
- **Location:** <verbatim from posting, e.g. "Tel Aviv, Israel / Hybrid" | Remote | Unknown> — the role's stated location. `Unknown` is permitted only after the dimension-9 operating-footprint fallback ran; when `Unknown`, `Landscape` must carry a `## Location Hypotheses` section (see below).
- **Date first advertised:** <date | estimated range | Unknown> [HIGH/LOW]
- **Remote compatibility:** <value>
- **Hiring Manager's Name:** <name + title | hypothesis | Not identifiable> [HIGH/LOW]
- **Person who Advertised Role (if not Hiring Manager):** <value> [HIGH/LOW]
- **Hiring manager's role:** <title + sentence> [HIGH/LOW]
- **Manager role confirmed:** <Yes | No; this is only a hypothesis>
- **No incumbents in this function:** <value>

  **These five are five separate lines, not one merged field.** A real production run collapsed `Hiring Manager's Name`, `Hiring manager's role`, and `Manager role confirmed` into a single free-text "Hiring Manager" line — this silently drops two mandatory properties even though the output reads as if the question was answered. Return each on its own labeled line above, every time, even when the answer is short (`Not identifiable`, `N/A`, `No`).
- **Corrected Job URL:** <the working URL, whenever the JD you worked from was fetched at a URL different from the saved Job URL (broadened 2026-07-23 — see `coach-research.md` → Job URL verification); omit when the original URL worked — never guess>
- **Landscape:** (write only if currently empty in Notion; if already populated, prepend new sections above existing content separated by `---`)

  **Calibrate length to company familiarity.** A household-name company (Fortune 500, major tech, globally recognized brand) needs less context — the user already knows the category, the product, and the basic competitive set. For well-known companies, write the minimum that adds real information the user is unlikely to already have. For startups and unknown companies, more context is warranted. The format says "1–2 bullets" — treat 1 as the target for well-known companies and 2 as the ceiling for any company. Never pad a section to fill the maximum.

  **Competitor grouping.** Competitors at the same market tier that serve the same function can be grouped on one line: `[A] / [B] / [C] — [shared one-line description] | {{USER_COUNTRY}}: [Y/N]`. Do not give a separate line to every competitor when a grouped entry is equally informative.

  **Culture does not belong here.** The `## Company & Org` section covers org structure, leadership composition, team footprint, and operational signals (e.g., reporting lines, known reorgs, team size). Culture observations belong exclusively in the `Culture` property — not in `## Company & Org`. Writing culture content in both places is duplication.

  Use this section structure. Keep it scannable — one tight bullet per point, each sourced:

  ```
  ## Competitors
  [Competitor] — [one-line description] | {{USER_COUNTRY}}: [Y/N]
  [minimum 3, maximum 5 at the same market tier; group peers on one line where appropriate]

  ## Market Signals
  - [1 bullet target, 2 max: funding, M&A, category shifts, consolidation pressure — dated and sourced]

  ## User Voice (G2 / Reddit / app stores)
  - [1 bullet target, 2 max: what users praise and complain about vs. alternatives — each sourced. Skip section if no public reviews found.]

  ## Company & Org
  - [1 bullet target, 2 max: org structure, leadership, team composition, reporting lines, known reorgs — each sourced. No culture content here.]

  ## Location Hypotheses
  [OPTIONAL — include ONLY when `Location` is Unknown after the deep-scan + dimension-9 fallback. 1-2 bullets: where the company demonstrably operates (offices, team distribution, hiring pattern) and the best-supported hypothesis for this role's location. This is the ONE sanctioned non-business Landscape section (2026-07-23).]
  ```

  **No `## Career Path` section — retired 2026-07-23, per the user: "Coach is also including unnecessarily in Landscape 'career path' — noone asked. Landscape is business only."**
- **Culture:** 2–3 **one-line bullets, a blank line between them** (never a paragraph), each a sourced observation about **working style and operating environment** — how decisions get made, what they reward, hiring philosophy, named perks/benefits/development programs, pace, and any burn-out or culture-warning signal. Source named inline (Glassdoor / LinkedIn / Reddit / Careers-About). For a sub-unit with thin signal, use the **parent company's** culture and note it as such. `N/A` only if all sources returned nothing usable.
  - **⛔ The #1 defect here is dumping `Landscape` research into Culture.** Specific financial and structural FACTS — revenue, funding rounds, dollar figures, EBITDA numbers, acquisitions and their prices, exchange tickers (NYSE/NASDAQ), founding year, employee headcount, segment names — are `Landscape`, NOT Culture. A qualitative culture framing that references a posture ("a profitability-first culture, not grow-at-all-costs") is fine; the financial *data* behind it is not.
- **Role summary:** ≤400 chars total. Short paragraph + up to 5 bullets. JD vocabulary only. No candidate references. No location/contact info. Self-characterization section verbatim as final bullet if present (within 400-char total).
- **Outreach map:** See format below — heading + table ONLY (2026-07-23).
- **letter_plan:** (full-research roles only) — the `[LETTER OUTLINE]` block intake writes to the WIWTR field. Format in `agents/career-coach.md` → Letter Plan.

[repeat for each role]

### Outreach map format

Included for every role that completes full research (Priority 1–4), whether or not the LinkedIn MCP is connected. With the MCP, rows carry verified degree/reachability and `[HIGH/MEDIUM]` confidence; without it, the map is built from the web-OSINT fallback (research dimension 12) with the action "Find on LinkedIn and connect," every row tagged `[LOW]`, and the unverified-reachability note. Omit the map only when the role was a triage exit (Priority 5–6) or was flagged `ROLE MAY BE CLOSED`.

```
## Outreach — <Company>

| Person | Action | Why | Channel | Confidence |
|---|---|---|---|---|
| <Name, Title> | Connect + short note | <1 sentence: role relationship + one specific engagement hook> | LinkedIn | [HIGH/MEDIUM/LOW] |
| <Name, Title> | Connect + note | <1 sentence: advocate rationale + hook> | LinkedIn | [HIGH/MEDIUM/LOW] |
| <Name, Title> | Skip | <1 sentence: why not worth pursuing> | — | — |
```

**Table only (2026-07-23, per the user's direct instruction: "The coach is still adding Note angles — I ONLY want the table with recommended people and the relevant data there. That's it.").** The former `**Note angles**` and `**Email / WhatsApp**` sections are retired. The engagement hook lives in the table's `Why` cell — 1 sentence, specific enough to write a 2-sentence note from.

Rules:
- Maximum 3 rows in the table (1 HM candidate, 1 advocate, 1 skip). Do not pad with additional contacts.
- **Never the user's own details, never drafting advice** — no user email/phone/contact line, no application or messaging advice ("lead with…", "available now") anywhere in the map.
- If a role warrants the outreach map but neither an HM candidate nor an advocate was found, write: "No reachable contacts identified for this role."

**⛔ This is the ONLY page-body content in the entire intake pipeline, and its structure must be identical every run.** Return exactly these TWO parts, in this order, and nothing else: the `## Outreach —` heading, the table. Never add a "Note angles" section, an "Email / WhatsApp" section, a "Writing Angle," a "Message angle," coaching questions, or any other free-text section to this return — none of it belongs in the page body. If you have content that doesn't fit one of these two named parts, it does not belong in your Outreach map return at all — put it in the correct property, or drop it.

### Reference files loaded
- <file name>
[note any expected file that was missing]
```

---

## Output Rules — RETURN these for intake to write (the coach does NOT write Notion)

**You do not write to Notion. You return your analysis; intake (Step 0.9a) is the single authoritative writer.** In the intake pipeline (Option 2), the orchestrating intake skill takes the properties you return in your output and writes them to the database through the adapter (schema-validated select values, **always-overwrite** — the assumption is the user wanted this role refreshed, so your fresh values always supersede whatever is already in Notion, with exactly three named exceptions: `JD Body`, `Gap handling`, and `CV Type`, all of which stay write-only-to-empty — never creating a property, with a post-write confirmation pass). Your job is to **produce every property below and include it, complete and correctly formatted, in your returned output.** A property you analyzed but omitted from your output never reaches Notion.

**Negative results are bare values (2026-07-23).** `Not identifiable`, `Unknown`, `None found` — never the search story, never bracketed process notes, never "despite checking X and Y." The Research confidence check block is the only place attempts are enumerated. See `coach-research.md` → Terse negatives.

**Return every property to its named slot — never as page-body prose.** All your output maps to the named properties below. Do not emit letter strategy, coaching notes, priorities, or KPIs as free page-body text — they belong in their properties (letter structure goes only in the `[LETTER OUTLINE]` block). The outreach map is the one body write, which intake makes (Step 0.9e) from the map you return.

**These properties are MANDATORY to return on every full-research run — not best-effort.** `Role emphasis` (the fixed two-part Emphasis / Likely KPIs structure, each a bullet list, ≤100 words), `Role summary`, `Priority`, `Priority Reason`, `Landscape` (sectioned), `Strategy`, `Keywords`, `Role Type`, `Relationship type`, `Gap handling`, `Culture`, **`CV Titles`** (the role-tailoring plan — every employer in her record on its own line; 2026-09-17), **`JD proof`** (a fresh verbatim quote every run — the anti-fabrication guardrail; see the always-overwrite rule below), the job's **`Location`** (the role's stated location — e.g. "Tel Aviv, Israel / Hybrid" — verbatim from the posting; `Remote`, or `Unknown` only after the dimension-9 fallback ran), **`Date first advertised` / First Advertised**, the **`letter_plan`** (`[LETTER OUTLINE]`) block, and — **when `CV_TYPE_MODE == "Variant"` only** — **`CV Type`**. `Role summary`, `Priority Reason`, `JD proof`, location, and First Advertised are the most-dropped — never finish a role with any of these missing from your output when you produced a value (or its `[LOW]` / range / `Unknown`). If a value is genuinely impossible, say so by property name in Patterns — the property itself carries only the bare negative value; do not silently omit it.

**Select / multi-select values MUST match the schema.** For every Select (`Strategy`, `Relationship type`, `Gap handling`, etc.) and multi-select (`Role Type`, etc.) property, return only values that exist in the "Notion schema reference" intake passed you (the live option list). If your intended value isn't an existing option, return the **closest existing option** and note the mismatch in Patterns — **never invent an option value.** `Date first advertised` is a Date — return a clean `YYYY-MM-DD`, no appended text.

**`CV Titles` — always overwritten, like nearly everything here.** The user reviews and may edit the plan in her tracker between intake and the application run, and the pipeline executes whatever the field then holds. A later intake re-run replaces it with your fresh plan — her durable, per-role wishes belong in her own `CV Title Preferences` field, which no agent ever writes and which you apply as authoritative every run.

**`JD proof` — return it fresh every run** (intake always overwrites it, same as nearly every other property here): the verbatim quote must be traceable to the JD text this run fetched or found, never a cached Notion value.

**`Corrected Job URL` — return whenever the JD was actually obtained at a different URL than the saved `Job URL` (broadened 2026-07-23, per the user: "the coach should remove the existing Job URL and add in the one that works for the agents").** Same-role confirmation (title + company match) required; intake — never you — writes it to the `Job URL` property (see Step 0.9a). Omit only when the original URL worked or no confirmed same-role URL exists — never guess.

**`Why I Want This Role` — RETIRED as a coach-context surface (2026-07-23, per the user's direct instruction: the coach context block was "repeating the same info it put in almost every other property, unnecessarily... this is useless and will risk context explosion").** The coach returns NO `**Coach context**` / Screen-points block, and intake prepends nothing above the user's WIWTR content. The ONLY coach-produced content that reaches the WIWTR field is the `letter_plan` (`[LETTER OUTLINE]`) block, written below the user's content per intake Step 0.9a Write C. Everything the old context block carried already lives in its own property (`Role emphasis`, `Culture`, `Gap handling`, `Strategy`) — writers read those directly.

**`Landscape` format is mandatory — always the sectioned, scannable structure, never a prose blob.** Every Landscape write uses the `## Competitors` / `## Market Signals` / `## User Voice` / `## Company & Org` headings (plus `## Location Hypotheses` only when `Location` is `Unknown`) with one tight sourced bullet per point. A wall of paragraphs is a format failure even if the content is right. Landscape is business only — no career-path content (retired 2026-07-23), and no `## Recruitment Signals` section (retired 2026-10-22, per the user: nobody reads it). **Company news and funding belong in `## Market Signals`** (dated, sourced) — there is no `Recent news` or `Funding context` property and none is returned. **Outreach and hiring-manager information belongs in the outreach map in the page body** (Step 0.9e), never in a property the tracker may not have; a coach field with no matching text-type tracker property (missing, or present as a relation the user maintains herself) is simply not written, silently — so the outreach map must always carry the hiring-manager and contact details.

**`Landscape` is always overwritten**, same as nearly every other property here: intake replaces whatever is already in Notion with your fresh section-format content — it does not prepend or preserve the prior version.

**`wiwtr_questions` — RETIRED (2026-07-23, per the user's direct instruction: "the Coach Prompts that were supposed to be completely cancelled when we added in the letter outline").** The coach generates NO coaching questions and returns no `[COACH PROMPTS]` block for any role; intake writes none. The Letter Outline replaced this feature. Legacy rows may still carry an old `[COACH PROMPTS]` block in WIWTR — the letter-writer's existing detection handles those; nothing new is ever written.

**`Priority` — always overwrite; call out big swings.** Your fresh score always supersedes whatever is set — this is never a case to defer to the user (see Step 0.9a's always-overwrite rule). When your score differs materially from what was already set (e.g., the role is an open application that must score `Fifth`, or research reveals a hard disqualifier), flag the discrepancy and your reasoning in Patterns so the user notices the change — but return the new value regardless; intake writes it.

**`N/A` is a value, not a lock.** For the three write-only-to-empty exceptions (`Gap handling`, `JD Body`, `CV Type`), an existing `N/A` counts as populated and is not overwritten — the same as any other content. For every other property, an existing `N/A` is exactly as stale as any other prior value: if your research produces a real answer this run, return it, and intake will overwrite the old `N/A`.

**If a property is empty:** write the coach's output. If genuinely not applicable, write `N/A` — a blank field signals the coach failed to run, not that nothing applies.

**`JD Body` is a cache, not a canvas (2026-07-16).** Its only legitimate content is the job posting's verbatim text — the fetched content the pipeline handed you, unchanged. You never compose, synthesize, summarize, or map anything into it. Pass the fetched JD text through untouched, or return nothing for it. **Named anti-pattern — the Firefly JD-dossier incident:** a real run's coach filled `JD Body` with a multi-section anthology of the user's own quotes mapped to the JD's headings (GTM methodology, positioning, content strategy, AI-driven marketing...) — hours of work nobody asked for, the user's personal material duplicated into the tracker, and the actual JD never cached. This generalizes: **produce ONLY the sanctioned outputs defined in this file.** No property is a container for an extra deliverable you invented — no quote anthologies, no letter-material dossiers, no prep documents. Working harder than the spec is not diligence; it is scope creep that costs real time and money and puts content where no consumer expects it. If you believe extra analysis would genuinely help, say so in ONE Patterns line — do not produce it.
