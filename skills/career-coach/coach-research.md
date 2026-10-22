# Career Coach — Research Phase

Load this file first for every coach invocation that requires role research (Option 2 intake, Option 1 inline). It covers the research dimensions, screening fit, the location deep-scan, JD signal analysis, and the post-research self-check.

---

## Research Phase

**Research standard:** Research comprehensively — the output is distilled but the research itself must be thorough. The bar: if a competent human recruiter spending 20 minutes on LinkedIn and Google could have found it, you should find it. Surface what materially changes the fit assessment, strategy, or risk picture — but do not stop researching before you have genuinely checked.

**⛔ Effort floor — a negative answer is a claim of exhaustion, not of first failure (2026-07-23, from a real pattern the user confirmed: "almost every single time, I find the information that it couldn't, and it doesn't prove to take much time either").** The recurring lazy negatives: team existence unchecked, hiring manager "no idea," `First Advertised` unknown, JD "unfetchable." Each of these values has a defined ladder in this file or `coach-analysis.md`; you may return the negative ONLY after every rung of that ladder actually ran. `Unfetchable` in particular: the same role routinely appears on multiple boards — the mirror search rungs (careers page, board mirrors, exact-title search) must each run before that word is permitted. The internal record of what you tried belongs in the Research confidence check block only.

**⛔ Terse negatives — the bare value, never the story (2026-07-23, per the user: "'not identifiable' is enough — WHY do I need the whole story?").** In every returned property value, a negative result is the bare value: `Not identifiable`, `Unknown`, `None found`. No search narrative, no bracketed process notes, no "despite checking X, Y and Z," no hedging clause. The Research confidence check block is the only sanctioned place to enumerate what was attempted. This also caps the note-and-bracket habit generally: brackets in property values are reserved for the defined `[HIGH]`/`[LOW]` tags where a property's own format specifies them — nothing else.

**Research principles:**
- Keep research objective and evidence-led. Conclusions must be traceable to a named source. Do not interpolate, speculate, or fill gaps with assumptions.
- Use OSINT (Open Source Intelligence) techniques: company websites, LinkedIn, Crunchbase, press releases, job boards, Glassdoor, GitHub, regulatory filings, news archives. Prefer primary sources over aggregators.
- Market conditions change. Do not rely on cached knowledge about a company's status, funding, or headcount — verify against the most recent available source and flag the date of the evidence.

### Six research dimensions

**1. What the company actually does today — and how it goes to market**
Product portfolio, current positioning, recent pivots or launches. Look for 2025–2026 press coverage and product pages. For stealth companies, infer from the JD and parent company thesis.

**Go-to-market and business model — research this explicitly; never assume it from the category.** How does the company actually acquire users or customers and make money *today*? Name the motion (sales-led / product-led / community- or UGC-driven), the buyer relationship (self-serve vs. enterprise contract), and the revenue engine (ad-supported, subscription, transactional, platform/take-rate). Then check the one thing the JD will never tell you: **has the model changed recently?** A monetization motion can move to a parent or acquirer, a company can pivot enterprise→self-serve, and a product can run on a different revenue engine than its public category implies. The published category is the floor, not the operating model.

*Worked example (generic):* a consumer mapping app whose ad-monetization was absorbed into its acquirer no longer hires GTM leaders to sell ads — it hires them to drive consumer adoption, community, and localization. The title on the JD would not reveal this; the GTM research does. **This dimension governs `Role emphasis` — the real mandate follows the real GTM model, not the title.** Capture the finding as a one-line "GTM reality" note you will use in the JD-vs-reality reconciliation (Part 1b).

**2. Corporate structure**
Ownership (independent / PE-backed / acquired / public), parent company if any, total funding and most recent round, employee headcount, notable M&A.

**3. Market position**
Enterprise, mid-market, or SMB? Primary target buyer?

**4. Competitive landscape**
Exactly 5 competitors:
- **Prioritize {{USER_COUNTRY}}-present competitors first.** Fill as many of the 5 slots as possible with companies that have offices in {{USER_COUNTRY}} or are {{USER_COUNTRY}}-founded. Only fill remaining slots with non-{{USER_COUNTRY}} competitors if there aren't 5 {{USER_COUNTRY}}-present options at the same market tier.
- Match the hiring company's actual market tier. SMB company → list SMB competitors, not enterprise players that happen to overlap.
- Real, known brands only. No obscure or invented names.
- For each: name, one-line description, {{USER_COUNTRY}} office (Yes / No).

**5. What this role actually means in context**
IC vs. team lead, reporting chain if findable, what the key JD phrases mean for *this* company specifically. The same title at a 10-person stealth startup means something entirely different than at a 300-person company — founding role vs. inheriting a team and process. Translate the JD into what the person will actually spend their time doing.

**6. Fit/gap for the user**
Draw ONLY from `02-professional-background.md` (Role Facts) and `03-framework.md` §Domain depth (per-vertical narratives). These are the only authoritative sources. Do not infer, extrapolate, or invent.

- **Strongest credential:** The single most relevant, specific thing the user has done that maps to what this role needs. Must name a real company from the relevant `background-role-facts-*.md` file and a documented outcome. If you cannot find a direct credential in the role-facts files or `03-framework.md` §Domain depth, write "No direct credential documented for this requirement" — never invent one.
- **Gap to prep:** One honest, specific gap or angle to prepare for, traceable to what the JD requires vs. what is documented. If there is a hard disqualifier (e.g., US residency required, domain not documented in `03-framework.md` §Domain depth), flag it clearly.

**Anti-fabrication rule:** If the strongest credential you can name is not traceable to a named company and documented outcome in `02-professional-background.md` (Role Facts), do not write it. This rule is absolute.

**Understanding a domain ≠ experience in it.** These are two different claims and only one of them needs to be true to use it. Demonstrating that the user *understands* a market, buyer, vertical, or geography — its dynamics, what good looks like, why it is hard — is allowed and is part of strategic framing. Asserting she has *worked in* it when Role Facts does not show it is fabrication. Keep them separate: the coach may note "she can speak to [domain] credibly from [adjacent documented work]," but must never state documented experience in a domain or market Role Facts does not contain. When a JD leans hard on a market the user has not worked, route it through `Gap handling` as an understanding/transfer angle, never as a credential.

**7. Company and org dynamics**
How does this company actually operate beyond what the JD says? Research in this order — all four sources are mandatory, not a pick-one list:
1. **Company Careers and About Us pages** — team structure, stated values, leadership listed by name. Read the actual page, not a summary.
2. **LinkedIn company profile** — `get_company_profile(company_name, sections="posts,jobs")` if the MCP is connected. Founder/leadership tone, recent posts, what they actually promote vs. what they claim.
3. **Glassdoor** — WebSearch `site:glassdoor.com "<company name>" reviews`. Read actual review excerpts: management style, work-life balance signals, burn-out flags, what employees say they value vs. what leadership says.
4. **Reddit** — WebSearch `site:reddit.com "<company name>" culture OR "working at" OR "interview"`. Candid employee and candidate observations not filtered through corporate comms.

**Sub-unit / division / newly-acquired roles — research the parent; do not return [LOW] and stop.** When the hiring entity is a division, business unit, or a newly-consolidated/acquired unit inside a larger company, thin *unit-specific* signal is expected — it is NOT a reason to give up. Research the **parent / owning company** (its Glassdoor, news, leadership, sector norms, operating culture) and apply it, noting explicitly which signal is the parent's and that the unit is new. "No Glassdoor/Reddit specific to [unit] found [LOW]" is a lazy result when the parent is a large, well-documented company — surface the parent's culture and the sector norms, and reserve [LOW] for genuinely unknowable unit-specific detail. The employer is still the parent; act like it.

Synthesise into 2–3 specific, sourced observations. Name the source inline (e.g. "Glassdoor: ..."). This feeds `Culture` (a dedicated Notion property — see Output Format) and `Role emphasis`.

**8. Recruitment criteria**
What do they actually look for when hiring for this type of role? Check: Glassdoor interview reviews, public hiring posts or LinkedIn content from the hiring manager, patterns across their open roles. Aim for 2–3 specific criteria beyond what the JD states explicitly.

**9. Company operating locations (2026-07-23 — replaces the retired Career Path dimension, per the user: "Landscape is business only" / "go figure out how and where the company operates").**
Where does this company actually operate? Offices and HQ (company site footer, About page, LinkedIn company page Locations), where its team members actually sit (LinkedIn People tab country distribution), and its hiring pattern (do its other open roles carry consistent location tags?). Cheap, always available, and it is the mandatory fallback before `Location` is ever reported as unclear: a role whose own posting is location-ambiguous inherits a working hypothesis from where the company demonstrably operates. Feeds the Location & eligibility deep-scan and, when the role's location remains genuinely unresolved after it, the `## Location Hypotheses` section of `Landscape` (the one sanctioned non-business Landscape section — see `coach-output.md`).

**10. Hiring manager and team research**

The LinkedIn MCP is the strongest tool for this step, but its absence is **not** a reason to skip — it is a reason to fall back. Never emit a bare "HM research skipped." Use the connected path when available; otherwise run the web-OSINT fallback and tag confidence down.

**If the LinkedIn MCP is connected:**

1. Identify the hiring manager: check the JD for a named contact, the company's LinkedIn Jobs page via `get_company_profile(company_name, sections="jobs")`, or the company About/Team page.
2. If a hiring manager is found, run `get_person_profile(linkedin_username, sections="experience,education,posts")`. Extract: current title, tenure at this company, background before this company, any recent posts about hiring priorities or team direction.
3. Run `get_company_employees(company_name, keywords="[relevant function keyword for the role]")`. Skim demographics — team size, seniority distribution, recent hires.
4. Produce a 3–5 line Hiring Manager and Team snapshot. Include: HM background relevance, tenure signal (new HM = flux; long-tenure = established culture), any public statements about what they value, team composition signal.
5. This snapshot feeds directly into `Role emphasis` and the Letter Outline, and informs the `Strategy` letter-type selection.

**If the LinkedIn MCP is not connected — web-OSINT fallback (run it; do not skip):**

1. Identify the hiring manager with the non-LinkedIn ladder already specified under the `Hiring Manager's Name` property: JD reporting language → company About/Team page → Google `"[title]" [company]` → B2B intelligence platforms (theorg.com, Crunchbase, ZoomInfo public pages). Public LinkedIn profile previews surfaced by Google count here even without the MCP.
2. For any named HM found, read what is publicly reachable without login: their company-blog posts, conference bios, published interviews, an indexed LinkedIn preview. Extract the same signals the MCP path would (background relevance, tenure, stated priorities).
3. For team composition, use the company Team/About page and Google rather than `get_company_employees`. Note whatever is visible; do not assert headcount you cannot see.
4. Produce the same 3–5 line snapshot, but tag every inferred element `[LOW]` and name the source inline. Note explicitly: "LinkedIn MCP not connected — HM/team snapshot built from web OSINT; reachability unverified."

Either path produces a snapshot. The only acceptable empty result is "no named HM identifiable after the full ladder" — and that is a finding to flag in `Patterns`, not a skipped step.

**11. User Voice**

What do customers and users actually say about this product? Check G2, Capterra, and Reddit (use the most relevant subreddits for the domain). Look for: what users praise, what they complain about, and how they compare the product to alternatives. Goal is 2–3 specific observations — direct quotes or paraphrased findings, each sourced inline (e.g. "G2: ..."). Skip this dimension if no public reviews are found (common for newer or stealth products); do not manufacture observations.

**12. Outreach contacts**

Goal: identify the 2–3 people most worth contacting at this company, decide what action to take for each, and produce a structured decision map the user can act on immediately. Do not produce a raw list of names — produce a decision.

**The LinkedIn MCP is the best tool here, but its absence is not a reason to skip.** A bare "outreach map skipped" is the failure mode this step exists to prevent. When the MCP is connected, run the full priority ladder and research steps below. When it is **not** connected, run the web-OSINT fallback: identify the HM via the non-LinkedIn ladder (dimension 10 fallback), find one plausible internal advocate from the company Team/About page or a Google search for the adjacent function, and produce the same decision map — but set the action to "Find on LinkedIn and connect" (reachability and degree-of-connection cannot be verified without the MCP), tag every row `[LOW]`, and add the line "LinkedIn MCP not connected — contacts identified via web OSINT; verify reachability before outreach." Only skip the outreach map when the role is a triage exit (Priority 5–6) or was flagged `ROLE MAY BE CLOSED` — never skip it solely because the MCP is absent.

**Priority ladder (work top to bottom; stop when you have 1 confirmed HM candidate + 1 internal advocate):**

1. **Hiring Manager candidate** — already identified in dimension 10. Confirm they are reachable on LinkedIn (public profile, accepts connections). Action: Connect + short note.
2. **One internal advocate** — someone in a role adjacent to the function being hired for, based in the same country as the user, 2nd-degree connection preferred. This is the person who can forward a profile internally or validate the user to the HM. Action: Connect + note. Selection criteria in priority order: (a) 2nd degree with mutual connections; (b) same country as the user (`my_location` from `pipeline-preferences.json`); (c) active on LinkedIn (recent posts or activity visible); (d) function adjacent to the role (PMM for PM roles; BI/Analytics for data roles; etc.).
3. **Skip everything else** — 3rd-degree contacts with no mutual path, global functional heads with no hiring relationship to this role, or anyone whose reach would require cold outreach to a connection with no clear reason to engage. One skipped row in the table is enough; do not list every excluded person.

**Research steps:**

1. Use `search_people` to find employees at the company in the function adjacent to the role (e.g. `search_people(keywords="[function keyword]", company="[company name]")`).
2. For each candidate advocate: check degree of connection, mutual count, country, and recent activity via `get_person_profile`.
3. For the HM (already profiled in dimension 10): verify LinkedIn reachability (public profile present, no InMail-only restriction signal).
4. For each actionable contact (HM candidate + selected advocate only): identify ONE specific engagement hook — something genuine from their profile, their company's recent direction, or the user's actual background that gives them a reason to engage — for the table's `Why` column. Specific enough to write a 2-sentence LinkedIn note from; skip generic observations ("we both care about marketing"). **(2026-07-23, per the user: "I ONLY want the table with recommended people and the relevant data there" — the hook lives in the table's `Why` cell; there is no separate Note-angles section and no Email/WhatsApp section anymore.)**

**Confidence labels:**
- `[HIGH]` — named, profile confirmed, degree and mutuals verified
- `[MEDIUM]` — identified by title/org but profile not fully confirmed or degree unclear
- `[LOW]` — hypothesis only (e.g. "this title likely exists at this company but wasn't found in search")

**What to skip:** Do not research contacts at companies where the role is already in the "open application" or speculative category (Priority 5–6), or where Step 2c flagged the role as `ROLE MAY BE CLOSED`. In those cases, note: "Outreach map skipped — role status unconfirmed."

---

### Location Compatibility — RETIRED (2026-07-23, per the user's direct instruction: "I'd like to completely cancel and remove the useless Israel Compatibility property")

The per-install location-compatibility verdict property (`location_compatibility.database_property`, legacy `notion_property` — e.g. "Israel Compatibility") is retired: the coach no longer produces a Yes/Remote-maybe/No compatibility verdict and intake no longer writes any such property. `location_compatibility.my_location` **survives** — it still feeds the Location & eligibility deep-scan below, the outreach advocate selection, and `source-open-roles` sourcing. The deep-scan's location findings still flow into Priority scoring (Part 0's remote-geography weighting) and the `Location` property; they just no longer produce a separate compatibility verdict field.

---

### Screening-fit check (standing answers)

Read `screening_answers` from `${CAREER_DATA}/references/pipeline-preferences.json`. **If the block is absent or every field is empty: skip this check entirely** — no output, no noise. For each *populated* field, compare the user's standing answer to what the JD states about that dimension:

- `travel` vs. the JD's travel expectation; `relocation` vs. any relocation requirement; `security_clearance` vs. a clearance requirement; `compensation_floor` vs. a stated salary/band; `availability` vs. a start-date/notice expectation.

**Output: one Patterns line per role, only when the JD actually addresses a dimension the user answered.** The check is **bidirectional and flag-only**:
- **Match** → a brief confirming note: `Screening fit — Elbit: frequent intl travel matches your stated "open to frequent travel".`
- **Conflict** → a brief flag: `Screening conflict — Elbit: JD expects frequent intl travel; your stated answer is "prefer minimal travel" → confirm before applying.`

**Hard rules:**
- This is **document framing / advisory only.** It NEVER drops the role, NEVER changes `Priority`, and NEVER gates the run — a role in the queue is a decision already made. It only surfaces the fact so the user can decide.
- The answer reflects what the *user wrote* — never invent or assume a cap/limit she did not state. If she wrote nothing for a dimension, that dimension is silent.
- Skip dimensions the JD does not mention — do not manufacture a flag from silence.
- Writes to `Patterns` only; no new database property.

---

### Location & eligibility deep-scan (Priority 1–4 roles only)

Runs during full research. Not run for Priority 5–6 triage-exit roles.

Location truth is rarely confined to the location field — and different sources contradict each other. **A single site, or a single version of the posting, is never sufficient to set the location result.** Check at minimum three sources, AND at least two independent versions of the same posting (the original board plus one other board or the company's own page), then synthesize across them:

- The JD itself (location field + full text for timezone/auth language)
- **A second independent version of the same posting** — the same role mirrored on another board or, best, the company's own ATS/careers listing. The location field frequently differs between versions of one posting; the discrepancy is itself the signal.
- The company's own careers page (may show other open roles with location patterns, EOR footer links)
- LinkedIn company page (team member locations visible on the People tab — do any show `my_location` or neighboring countries?)
- One web search: `"[company name]" remote hiring "[my_location]"` or `"[company name]" Deel OR Remote.com OR Oyster` to surface EOR signals

**Two failure modes a single source cannot catch — both require cross-version reading:**

- **Forced-location-field false positive (looks restricted, is remote).** Many boards refuse to publish a listing without a city, so they stamp one on (HQ city, "United States", the recruiter's city) even when the role is genuinely remote. A location field alone is therefore *not* evidence of an on-site or geographic requirement. Before downgrading on a stated city, confirm against the body text and a second version: if the JD body says remote / distributed / work-from-anywhere and another version omits or contradicts the city, treat the city as a board artifact, not a restriction.
- **Hidden-restriction false negative (looks remote, is restricted).** A board labelled "Remote" is not confirmation of *worldwide* remote. The real limit often lives in the fine print of the full body ("must be authorized to work in the US", "within 3 hours of CET") or appears only on another version of the posting. Never accept a one-word "Remote" label as worldwide-open without scanning the full body of at least two versions for an authorization/timezone/residency lock.

Sources often say different things, and the disagreement is the most useful data you have. Synthesize: a LinkedIn page showing 3 Israel-based employees and a careers page saying "Remote" outweighs a JD location field that says "New York"; equally, a single "Remote" tag is overridden the moment any version's body text states a residency or work-authorization lock.

1. **Scan for restriction signals across all sources:** stated location requirements, timezone mandates, work-authorization language, and crucially the REASON given for any restriction. "Primarily EST timezone for healthy overlap with European business hours" restricts very differently than "must hold US work authorization": the first is a rationale the user's location may satisfy better than the stated geography does; the second is structural.
2. **Check exception paths** when a restriction signal exists: does the company hire through an EOR (Deel, Remote.com, Oyster)? Does it already hire in `my_location` or nearby? Does the stated rationale actually hold against `my_location`?
3. **Output a Location block** in the research findings: sources and versions checked (name each, and say explicitly whether a second independent version was found), restriction signal found (or "none"), exception-path evidence (or "none found"), a confidence tag — `[HIGH]` only when ≥2 independent versions/sources agree; `[LOW]` when only one version was reachable or sources conflict and the conflict could not be resolved — and, when a restriction exists with a plausible path, a suggested ask-first action: a 2-line note to the named recruiter or People contact. A `[LOW]` location result is a "confirm before relying on it" flag, not a fit downgrade. This block feeds Priority scoring (Part 0).
4. **"Unclear" is not a permitted terminal answer without dimension 9 (2026-07-23, per the user: "even if the role itself isn't clear — go figure out how and where the company operates").** Before reporting the role's location as unclear/ambiguous, run research dimension 9 (company operating locations) and derive a working hypothesis from where the company demonstrably operates. If the posting itself stays ambiguous: write the best supported value to `Location` when one source pattern clearly dominates, or write `Unknown` to `Location` AND return a `## Location Hypotheses` section for `Landscape` (see `coach-output.md`) carrying the operating-footprint-derived hypotheses. Never return a bare "location unclear" with no hypotheses.

---

### JD Signal Analysis (Red and Green Flags)

After completing all research dimensions, analyse the JD text itself for non-obvious signals. This is separate from fit/gap analysis — it assesses the quality and health of the opportunity itself.

**Red flag patterns (language signals):**
- "Wear many hats", "rockstar", "ninja", "self-starter in a fast-paced environment", "work hard play hard" — indicators of unclear scope or burn-out culture
- "Results-driven" with no metrics anywhere in the JD — performance expectations undefined
- Constant hiring for the same role type — check if the same role appeared multiple times in 12 months on LinkedIn; if so, flag it
- No salary range — negotiating leverage gap
- Vague responsibilities with over-complicated requirements — misaligned expectation vs. actual budget
- "Family-like atmosphere" — culture warning label

**Green flag patterns:**
- Essential vs. preferred requirements clearly distinguished
- Specific measurable goals in the JD ("build X, achieve Y in first 90 days")
- Transparent hiring process described (number of stages, timeline)
- Long-tenured employees visible on LinkedIn
- Hiring manager has been in role 2+ years (stability signal)
- Company blog or HM posts show substantive thinking about the domain

**Output:** Include a "Signals" block in the research output:

```
**Signals:**
- Red: [list any, or "None identified"]
- Green: [list any, or "None identified"]
- Net: [Proceed with caution | Neutral | Positive signals]
```

This feeds into Priority scoring and `Role emphasis`.

---

### Job URL verification (backstop only)

Step 0.5's fetch ladder already runs before you ever see this role, and it already captures a `Working URL` when the original Job URL failed and a fallback rung succeeded on a different URL. **This is a backstop for what that ladder didn't catch, not a repeat of it** — do not re-run the fetch ladder yourself.

If, during your own research above, you independently notice that the original Job URL is stale, dead, or points at a materially different version of the role (e.g. a since-edited posting, a redirect to a generic careers page, or a listing that has clearly moved), **and** your research turned up a different URL you can confirm is the same role at the same company (matched on title and company, same standard the fetch ladder itself requires) — return it as `Corrected Job URL`. Omit this field when the original URL was fine, or when you have no confirmed match for the same role; do not guess or substitute a similar-but-different posting.

**Broadened standard (2026-07-23, per the user: "when the coach does need to fetch from a different URL, then the coach should remove the existing Job URL and add in the one that works").** "Genuinely broken" is no longer the bar. Whenever the JD you actually worked from was obtained at a URL *different* from the saved `Job URL` — whether the ladder fell through, the original was auth-walled, or your own research surfaced the working version — return that working URL as `Corrected Job URL`. Same-role confirmation (title + company match) still required; intake remains the sole writer. The point: the tracked link must be the one agents can actually fetch, so every later pipeline event starts from a working URL.

**An official URL is never traded for a mirror (2026-10-22):** never return a job-board, aggregator or investor-board mirror (Jobify, Built In, a VC board, …) as `Corrected Job URL` for a saved URL on the company's own domain or its ATS (Comeet, Greenhouse, Lever, …). A 404/410 or board-root redirect on an ATS page is a closure (`skills/database/SKILL.md` closure evidence, ATS rule), not something to correct.

**⛔ Liveness is a precondition, not an assumption — run the same liveness check intake's Step 0.5 defines (2026-08-12).** Never return a `Corrected Job URL` you have not resolved **this run** with a non-caching fetcher. Confirm two things: the final URL after redirects is still that posting's URL, and the page you land on is the posting — not a careers index, a site root, or a 404. Rendering-capable extractors (Exa, Tavily, any crawl tool) and search snippets serve their own cache and will return a posting that was pulled months ago; that proves it existed, never that it is live. A URL that redirects away is worse than an empty field, because it looks checked.

**⛔ And do not explain a dead posting away.** When a role's direct URL redirects to a careers index and the live index does not list the role, the supported reading is that **the posting was pulled** — flag the role as possibly closed and say the JD you worked from is historical. "Off-index hiring," "unlisted but live," and "de-indexed but still open" are readings that require the direct URL to actually serve the posting; they are prohibited when it doesn't. Enforced by Coach Output Check item 14. **Confirmed production failure (Anecdotes, 2026-08-11):** an entire analysis was built on an extractor's cache of a pulled posting, the dead URL was returned as a correction onto a previously empty field, and the role's absence from the careers index was written up as evidence of referral hiring.

### Post-research self-check

Run before writing any strategic properties. Answer all four questions. Record as a visible block in your output between research findings and strategic properties.

**1. Gap inventory — what didn't I find?**
Name anything you searched for and couldn't confirm: hiring manager not identified, funding round not found, Glassdoor absent, date first advertised unknown. These are [LOW] by definition.

**2. Thin evidence — where am I tagging [HIGH] without a primary source?**
Review every [HIGH] tag. If the source is a news article quoting a press release, a LinkedIn profile you're inferring from, or a second-hand mention — downgrade to [LOW]. [HIGH] means directly stated on an official company page, the JD itself, or LinkedIn with a confirmed match.

**3. Inference substituted for source — where did I write a conclusion without naming the evidence?**
Check for: "The company appears to value X," "Culture signals suggest Y," "The hiring manager is likely Z." Every such claim must name its source or be downgraded.

**4. Red flags surfaced or buried?**
If research found anything risk-relevant — leadership churn, hiring freeze just ended, a round 18+ months old with no follow-on, a role open 90+ days — it must appear in `Landscape` (`## Market Signals`) or Patterns.

**5. Org depth checked?**
Did you scan LinkedIn for ALL {{USER_PROFESSION}} team members at this company, not just the most senior person? If there is any {{USER_PROFESSION}} leader between the top title and this role, it must be named in `Hiring Manager's Name` and flagged in `Patterns`. Leaving this unresolved costs the user time she cannot get back.

```
### Research confidence check — <Company> — <Role Title>
- Not found: <list, or "nothing material missing">
- Thin evidence downgraded to [LOW]: <list, or "none">
- Inference without named source: <list, or "none">
- Red flags: <list, or "none surfaced">
- Org depth: <"Scanned all {{USER_PROFESSION}} titles on LinkedIn — [finding]" or "Could not access LinkedIn profiles for this company">
```

**When this check is complete, load `coach-analysis.md` and proceed to Analysis.**
