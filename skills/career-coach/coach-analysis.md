# Career Coach — Analysis (Priority, Strategy, Properties)

Load this file after `coach-research.md` is complete and you are ready to analyze. It covers priority scoring, writing guidance, JD decoding, strategic property definitions, and patterns. When analysis is complete, load `coach-output.md` to format and return your output.

---

## Notion invocation context

The career-coach is always invoked by the intake pipeline after intake has queried the Notion database to build the Needs Research queue. The coach does not query Notion for its input list — that is intake's responsibility. This section documents the query protocol intake uses so the coach understands what state the database was in and what the ladder guarantees.

**How intake surfaces roles for the coach:** intake queries the database through the **Notion adapter** (`skills/database-notion/SKILL.md` → §2 read ladder, A1 → A2 → B, when `database_backend` is `notion`) and passes the coach fully-resolved rows. The coach does not need the mechanics — only the guarantees: rows arrive filtered to the target status with full per-page properties (Path B is discovery-only → per-page `notion-fetch`, never a parsed rendered table — R-1); and if every rung fails intake stops and reports rather than treating it as an empty queue or improvising `notion-search` (R-39).

**What the coach receives:** a list of roles with Page IDs, company names, position titles, Job URLs, and full Notion row content already resolved. The coach processes from that point forward; it does not re-query Notion for the role list.

---

## Analysis

### Settings pre-flight

Before any analysis, determine the gap handling mode in this order:

1. **Spawn prompt** — when invoked by a pipeline, the orchestrating skill passes `gap_handling_mode` in your prompt. Use it; skip the rest of this pre-flight.
2. **Career-data config** — otherwise (standalone), Read `${CAREER_DATA}/references/pipeline-preferences.json` (Read tool — you do not have Bash) and use its `gap_handling` value. **This is the user's real config and the authority** — resolve `${CAREER_DATA}` first (per the R-37 data-root block in the root SKILL.md) if it is not already set.
3. **Last-resort fallback** — only if career-data is unreachable: `~/.claude/settings.json`, then `${CLAUDE_PLUGIN_ROOT}/references/pipeline-preferences.json` (the **blank template**, which always ships the default — never the authority).
4. **Default** — if no source yields a value, use `enabled`.

- If the value is `"disabled"` (or the key is absent and you were invoked with "no gap handling" in the prompt): set a session flag `GAP_HANDLING = disabled`. **Disabling gap handling kills the gap-analysis behavior EVERYWHERE — not just the `Gap handling` property.** Specifically: skip all gap analysis in Part 2; do NOT populate the `Gap handling` property with gap-handling content (do not write `N/A`) — **the ONE sanctioned exception, in both modes (per the user's direct instruction, 2026-07-28: "even when gap handling = false we should actually put this info in the Gap Handling property. It stands out there, and it's most logical... it's related to gap handling, but in a way that anyone/everyone should care"): the labeled `Keyword gap:` warning line(s) from the Keywords career-data match check, which is data hygiene addressed to the USER (update career-data or accept the screen gap), never candidate-gap framing, and never letter/CV content;** and **no other output — the Letter Outline, `Patterns` — may enumerate gaps, name "the X real gaps," catalog what she lacks, or do any gap framing.** A disabled feature that still parks gap analysis somewhere else has leaked — that is the seam this rule closes. The Letter Outline may still carry the affirmative credibility-of-transfer argument ("her [X] transfers because [Y]"), but never a gap inventory.
- If the value is `"enabled"` or the key is absent (default): set `GAP_HANDLING = enabled`. Proceed normally.
- A per-role override always wins: if the user included "no gap handling" in their prompt for this run, treat as disabled for this run only.

**Same pre-flight, same order, for `cv_type_mode`:** when invoked by intake, the spawn prompt passes `cv_type_mode` (read from `pipeline-preferences.json` → `cv_type.mode`). Use it directly; do not re-read the config file yourself. If it is missing from the spawn prompt (standalone invocation), Read `pipeline-preferences.json` yourself via the same career-data resolution as above, and default to `"Detailed"` if the key is absent. Set a session flag `CV_TYPE_MODE = <value>`. This flag governs whether the standalone `CV Type` property is returned (Part 2 below) — only when `CV_TYPE_MODE == "Variant"`.

### Part 0 — Priority scoring (full research roles)

This step runs only for roles that reached full research (Priority 1–4 from triage, pre-scored roles, or `--full-research` runs). For Priority 5–6 triage-exit roles, Priority and Priority Reason were already written in Step 2c and are final.

Apply the Priority Framework in `01-writing-rules.md` Section 1, now with full research context:

**Step 1 — Open Application check (run this before everything else):**
Is this role an open application, unsolicited application, or speculative application — i.e., the user is applying without a specific open listing? If yes: the priority is `Fifth`. Stop. Do not apply domain fit or any other criterion. Write `Fifth` and the reason: "Open application — hard floor override." This is non-negotiable regardless of domain fit, seniority match, company stage, or any other factor.

**Step 2 — Standard scoring (only if Step 1 did not apply):**
1. Apply the Priority Framework criteria in order, now informed by the full research (location deep-scan, company signals, HM research, competitive landscape, JD decoding).

   **Requirements-coverage scoring — title/function mismatch never floors a score (intake-only, 2026-07-29, per the user's direct instruction).** The user's `01-writing-rules.md` §1 carries a requirements-coverage subsection; apply it whenever a role's function or title sits outside the user's usual target scope. The generic principle, for any user of this plugin:
   - **The role being in the tracker is the intent signal.** A user deliberately adds roles outside her usual function because a career shift is an option. The framework's job is fit *measurement*, never scope *policing* — "this isn't a [target-function] role" is not, by itself, a demotion.
   - **Split the JD's requirements into hard MUSTs vs. everything else.** Hard MUSTs are explicit: "must have," mandatory years-in-X, named certifications, languages, clearance, work authorization.
   - **A hard MUST genuinely absent from the user's documented background caps the tier:** one missing peripheral MUST → cap at Fourth; a missing MUST central to the role, or multiple missing → Fifth. `Priority Reason` names the missing MUST explicitly. Missing MUSTs are never silently averaged into the coverage percentage.
   - **Score the remaining requirements as coverage** of the user's documented background (`02` and its background files — documented evidence only, the fabrication rules apply to scoring as much as to writing): roughly ≥80% covered → Second or better, 60–79% → Third, 40–59% → Fourth, <40% → Fifth.
   - **Scope preferences (2026-10-19).** When `queue.md` carries a `USER SCOPE PREFERENCES` section (the config's `scope_preferences`) and `role_matching` is not `titles`: a core responsibility of the role that hits `avoid` is named in `Priority Reason` and caps the tier like a missing peripheral MUST (cap Fourth); a `want` hit is noted in `Priority Reason` and may lift the tier one step within the coverage band's ceiling. Both are the user's own standing words, applied as written.
   - **Domain fit and geography adjust the coverage tier by at most one tier in either direction.** The framework's hard floors (open application, crypto, structural geography) are unchanged and still absolute.
   - This methodology is **intake-only**: the Prioritization pipeline applies the base framework without it (no background read there) — scoring function fit as coverage of the JD's items against the user's `capability-profile.md` instead (2026-10-15) — and its provisional score is always overwritten here.
2. **Apply favorite-brand boost** — read `favorite_brands` from `pipeline-preferences.json`. If the company matches any entry (case-insensitive), apply +1 boost: final priority = scored priority − 1, minimum 1. Append "(+1 favorite brand)" to `Priority Reason`. Open-application roles are exempt — the Fifth override from Step 1 is absolute.
3. Write a tight one-sentence **`Priority Reason`** grounded in the user's documented background and the JD, including the brand boost note if applied. This is the final `Priority Reason` for Notion.
4. Mark as `confirmed` if a prior value existed and your score agrees, `revised` if your research produces a different score, or `new` if no prior value existed.
5. If the final Priority differs from the preliminary triage score, note both in Patterns.

Also factor in advertised date: a very recent role with strong fit may be more urgent than an older one with similar fit, but stronger fit generally outweighs recency.

**Remote-geography weighting:** when the role is advertised remote and the only blocker is a geographic restriction in its text, do not score it as a hard exclusion on that basis alone. Consult the Location & eligibility deep-scan first. If an exception path was found (EOR in place, existing out-of-country hires, a stated rationale `my_location` satisfies), score on the remaining criteria, discount at most one priority tier for the geography risk, and flag `ask-first` with the suggested 2-line outreach from the Location block. Score Fifth on geography only when the restriction is structural (legal residency, citizenship, security clearance, payroll-stated-no-exceptions) AND the deep-scan found no exception path. A remote role is never silently dropped over geography — if it reached the coach, it gets scored and its location note travels with it.

---

### Part 1 — Writing guidance

**Batch analysis:** 1 sentence on common gaps, 1 sentence on shared keywords. No more.

**Base CV recommendation:** If 3+ roles share the same Role Type or seniority level, name the sections to draft once. 1 sentence.

**Structural framing:** Name any framing trigger from `01-writing-rules.md` Section 1 that applies to this batch. 1 sentence.

**Per-role focus:** One line per role — primary emphasis only.

---

### Part 1b — JD decoding

Before setting any strategic property, decode the job posting. JDs are written by committee, filtered through HR templates, and often describe the role they wish they could afford rather than the one they're actually filling. Your job is to read past the surface layer.

**JD Reality Filter — apply this before reading anything else.**

A job posting is a wish list. No one will do everything on it. The real hire is driven by 1–3 macro business problems: the specific thing that broke, the gap that costs revenue, the function that doesn't exist yet. Every other requirement is noise that HR added because no one removed it.

Your job is to extract the 20% that actually drove the headcount request. Do not treat the JD as an equal-weight checklist. Do not inventory every requirement. Find the business problem, name it in `Role emphasis`, and let everything else serve that framing.

The signal is almost never in the responsibilities list. It is in Layer 3 (outcomes), Layer 4 (seniority signals), and Layer 5 (culture and compensation signals) — where the company reveals what it is actually trying to solve.

**Break the JD into layers and read each deliberately:**

**Layer 1 — Core responsibilities (what you will actually do)**
Tasks at the top or repeated frequently are the real priorities. Map the day-in-the-life against the user's documented experience. Ignore the generic HR filler ("collaborate cross-functionally", "drive results") — focus on the specific, named activities.

**Layer 2 — Qualifications (must-haves vs. nice-to-haves)**
"Must / required / expect" = hard requirements. "Ideally / preferred / bonus" = nice-to-haves — these are NOT gaps if the candidate doesn't have them. A "preferred" degree signals openness to equivalent experience. Vague soft skills (e.g., "team player", "strong communicator") carry no analytical weight — ignore them. Hard skills, named tools, specific domain experience: these matter.

**Layer 3 — Outcomes (what success looks like)**
Why does this role exist? What breaks if it goes unfilled? What does the hire need to accomplish in the first 6–12 months? Look for quantifiable output signals: closing deals, reducing churn, building a function, shipping product. This frames the strategy and role emphasis.

**Layer 4 — Seniority signals (what level this role actually is)**
Titles are unreliable. Read seniority from: required years of experience, whether the role owns budget, has direct reports, sets strategy vs. executes it, reports to C-suite vs. middle management. A "Senior Manager" with no direct reports and execution-heavy responsibilities is an IC role with a flattering title. A "Specialist" who owns P&L and presents to board is a leadership role. Identify the real level — it governs how the CV and letter are framed.

**Step-down identification — critical:** If the role's actual level is materially below the user's documented seniority (e.g., an IC execution role when she has been a VP, or a manager role when she has led functions), name it in `Patterns` as `Step-down: [reason — e.g., execution IC role vs. her VP-level background]` and let it shape the Letter Outline's paragraph subjects. **It is never written as a line inside `Role emphasis`** (2026-07-23 — rank/step commentary is banned there; `Role Type` carries the shape; the writers read career-data themselves and derive the framing from the role-vs-record comparison). Do not obscure or soften the detection itself — naming it in Patterns is how the documents get framed correctly.

**Operating-model transition identification — run this alongside step-down detection; it is a separate axis.** Compare the operating model this role sits in (from dimension 1 — GTM and business model) against the operating model(s) the user's record sits in (`02-professional-background.md` Role Facts, `03-framework.md` §Domain depth). If they differ on the **B2B ↔ B2C / enterprise ↔ consumer / sales-led ↔ product-led** axis, this is an operating-model transition — *even when the function and the seniority match*.

This is not a step-down and not a function shift. Do not collapse it into either — the handling is different:
- **Name it** in `Patterns`: `Operating-model transition: [from] → [to] — [the axis that differs]` (e.g., `enterprise B2B → mass-market B2C`). Never as a line inside `Role emphasis` (rank/transition commentary is banned there, 2026-07-23) — the transition instead shapes `Role emphasis` implicitly, through the Emphasis line's operating-model translation and the target-model `Likely KPIs`.
- **Name the KPI shift.** The metric set changes with the model: adoption, activation, usage, retention, virality for consumer; pipeline, ACV, win-rate, sales-cycle for enterprise. State the target model's KPIs in `Likely KPIs` so the writers frame toward them and not toward the model the user is leaving.
- **Mine for transferable, model-correct evidence.** Actively pull from `02`/`03` any genuinely consumer/audience-facing work — DTC or app products, marketplaces, freelance/creator surfaces, consumer segmentation, community, localization, channel-fit by cohort or market — and surface it in `Gap handling` (when enabled) and the Letter Outline as the credibility-of-transfer proof. Reframe real evidence; never invent it (see the understanding-vs-experience rule in research dimension 6).
- **Flag the wrong-model competence** so the writers do not lead with it: enterprise pipeline/ACV proof buried lower for a consumer role, and vice versa.

**Layer 5 — Compensation and culture signals**
Salary range signals the real budget and seniority expectation. Language like "fast-paced", "wear many hats", "startup environment" signals a generalist/execution context. "Cross-functional stakeholder management" signals internal politics and matrix orgs. These inform `Role emphasis` and the `Strategy` letter-type selection.

**Force-cite any non-generic, unusual, or behaviorally-revealing language verbatim.** Never paraphrase it. Never discard it. A phrase like "we're looking for someone with a sense of humor" or "you'll be comfortable with ambiguity" or "we move fast and don't always have clean answers" is not throwaway HR copy — it is a behavioral signal about culture expectations, team dynamics, or what past hires got wrong. Quote it exactly in `Culture` and surface it in Patterns. Decode what it signals: what kind of person thrives here, what kind fails, and what this phrasing reveals about the team's current pain. If you read it and thought "interesting" but did not quote it, you have failed this step.

**Layer 6 — Nice-to-haves and advantages are exactly that**
If the user has a "nice-to-have" or "advantage" qualification: call it out in JD proof — it is a differentiator. If she doesn't have it: it is NOT a gap. Never flag a preferred/bonus requirement as a gap unless it is genuinely screening-critical in context. Write `satisfied via [Y] — [X] is additive` or simply omit it from Gap handling.

**JD-vs-reality reconciliation — produce this before writing `Role emphasis`.**

The JD title and responsibilities describe the role the company *advertised*. The GTM-reality note from research dimension 1 describes the role it is *actually* filling. Reconcile the two explicitly — this is the bridge into `Role emphasis`:

- **Title/JD implies:** what a reader would assume the role owns, from the title and the responsibilities list.
- **GTM reality says it really owns:** what the role actually drives, given how the company makes money and goes to market today.
- **Does NOT own:** the scope the title implies but the reality excludes — the thing the candidate would wrongly position toward without this reconciliation.

Where the two diverge, the **reality governs** `Role emphasis` and the Letter Outline. This is document framing only — it shapes what the materials lead with, nothing beyond the document stage.

*Worked example (generic):* a "Head of GTM" title at a consumer app implies pipeline and revenue ownership; the GTM reality (consumer adoption and community, monetization owned elsewhere) means the role really owns audience growth and retention and does NOT own an enterprise sales motion. A letter that leads with ACV and pipeline answers the wrong brief. When the title and the reality agree, say so in one line and move on — the reconciliation is cheap and is run for every role.

**Application instructions**
If the JD specifies an unusual application instruction (e.g., "include a cover letter with your answer to X"), flag it in Patterns so the user sees it before applying.

**Organizational Mandate Type — set for director/VP/C-suite roles; also set for senior IC roles where mandate-type signals are strong.**

After reading all six layers, classify the role into one of three mandate types. This classification governs `Role emphasis` framing, the coaching questions you generate, and what the letter-writer must lead with.

| Type | JD signals | The reality | What the hire must prove |
|---|---|---|---|
| **Builder** | "scale," "pioneer," "build from scratch," "accelerate," "first hire," "0→1" | Company has runway/opportunity but lacks infrastructure. Hire loves messy execution and building playbooks. | Zero-to-one frameworks, prior hiring and playbook-building, scale metrics from prior growth cycles |
| **Fixer** | "optimize," "streamline," "turn around," "drive efficiencies," "evaluate existing architecture," "reduce churn" | Something is broken — margins down, churn high, tech debt crushing, or function never established cleanly. Hire is the surgical corrective force. | Diagnostic skills, cutting waste, managing change resistance, rapid stabilization, proof of turning around a broken function |
| **Maintainer** | "govern," "sustain," "protect market share," "standardize," "mature," "harden," "scale what works" | The business engine works well but is getting too big for current infrastructure. No cowboy needed — steady hand to harden and scale reliably. | Risk management, governance, operational maturity models, long-term sustainable yield |

Surface the mandate type in `Patterns` (one line: `Mandate type: Builder / Fixer / Maintainer — [one-line reason]`) and let it inform the Emphasis read and the Letter Outline. It is never a line inside `Role emphasis` (2026-07-23 — the property carries the emphasis read itself, not classification labels).

**Jargon Decoder — corporate phrases and their operational reality.** When any of these phrases appear in the JD, decode them before proceeding to `Role emphasis`. Surface the decoded reality in `Culture` and `Patterns`.

| JD says | Operational reality | Strategic use |
|---|---|---|
| "Thrives in ambiguity" / "Self-starter" | Zero documentation, no onboarding process, goalposts move frequently | Ask: has the user built structure out of chaos before? That proof leads. |
| "Wear many hats" | Team is understaffed; hire will do tasks both above and below their pay grade | Flag resource-allocation risk in Patterns; if Priority ≥ 3, call it out |
| "Fast-paced environment" | High volume, tight turnaround, burnout risk if boundaries aren't set | Surface in Culture; flag as Fixer/Builder signal |
| "We are like a family" | Blurred work-life boundaries; expectation of overtime and emotional investment | High-attrition risk; flag in Culture |
| "Matrixed environment" | Multiple stakeholders with competing priorities; no direct authority | Proof of aligning disagreeing stakeholders belongs in the letter |
| "Results-driven" with no JD metrics | Performance expectations undefined; negotiating leverage gap | Flag in Signals as a Red flag |
| Constant re-posting (same role 3× in 12 months) | Attrition in the role; expectation mismatch | Flag in Signals as a hard Red flag |

---

### Part 2 — Strategic properties

These properties are owned exclusively by the career-coach. Set them based on your expert reading of the JD and the user's documented fit — not on what the CV says, which comes later.

**Read between the lines — this is the most important analytical discipline here.** JDs are written by committee and filtered through HR templates. What the JD says explicitly is the floor, not the ceiling. For `Role emphasis` and the `Strategy` letter-type selection in particular:

- What problem is the company actually trying to solve by hiring for this role? What does the org structure, stage, or competitive position imply that the JD doesn't say?
- What kind of person succeeds here vs. fails? What does the "preferred" list reveal about who they've tried before?
- What is the subtext of the must-haves? "5+ years in B2B SaaS" alongside "fast-paced environment" and "wear many hats" signals something different from the same phrase alongside "cross-functional stakeholder management."
- If the Landscape property is already populated for this role — **read it carefully before writing `Role emphasis` and selecting `Strategy`.** The company's market position, competitive pressures, and known challenges should shape the framing. A company defending an established position needs a different hire than one building a function from scratch. Let the intelligence inform the framing.

Surface this reading in `Role emphasis`, and let it guide the `Strategy` letter-type selection. Do not repeat what the JD says — translate what it means for this specific company in this specific moment.

### Property reference — what each coach-owned property is for

| Property | What it is |
|---|---|
| `Priority` | Numeric urgency/fit rank (1 = highest). The sort handle; the *why* lives in `Priority Reason`. |
| `Priority Reason` | One sentence justifying the score — name the driver(s) and any reason it isn't higher. |
| `Role emphasis` | A paraphrased and/or directly quoted summary of what's most important in the role (with the operating-model translation of any ambiguous term, in generic discipline vocabulary) plus the likely KPIs. Exactly two labeled lines, ≤100 words. Never strategy, capability mapping, de-emphasis, CV type, company facts, confidence tags, or rank commentary. |
| `CV Type` | Variant mode only — the coach's Detailed/Brief call for this role, written by intake to the user's per-role `CV Type` select (write-only-to-empty; the user's hand-set value always wins). |
| `CV Titles` | The role-tailoring plan — one line naming the level the target role reads at, then one disposition line per employer in her record (Retitle / Descriptor / Keep / Fold). The cv-writer executes it verbatim; the user reviews and may edit it in her tracker. |
| `Role summary` | The plain-language "what the job is in practice" — scope, stage, ownership areas, constraints (solo, budget), business timing. The version you'd tell a friend. ≤400 chars. |
| `Landscape` | A structured market + company + product brief: snapshot (location, size, founders), product (what it is, how it works), buyers/personas, GTM motion, funding/stage, org context, competitive frame. |
| `Keywords` | A prioritized requirements map from the JD — Critical / Important / Nice-to-have, hard-capped. For ATS targeting, proof-point selection, and go/no-go on a missing "Critical". |
| `Strategy` | Letter-type Select — `IC` / `Strategic` / `Hybrid`. Sets the cover-letter structure only. |
| `Company Stage` | Maturity label — Seed / Series A–C / Public / PE-backed / Stealth / Other. |
| `Role Type` | Multi-select shape — Builder (0→1, first hire) / Scaler (growth, existing motion) / Leader (team/org ownership) / Specialist (narrow lane). |
| `Relationship type` | Full time / Part time / Temporary / Fractional. |
| `Gap handling` | The material gaps and how to handle each (max 3), or `N/A`. |
| `Culture` | A concise, sourced hypothesis about working style and operating environment. |
| `Hiring Manager's Name` | Best-inferred HM name (confirmed from JD/LinkedIn/site, or marked inferred/uncertain). |
| `Hiring manager's role` | HM's inferred title + functional context, including who likely runs the process vs. who the role reports to. |
| `Person who Advertised Role (if not Hiring Manager)` | The poster/recruiter when different from the HM. |
| `Manager role confirmed` | `Yes` or `No; this is only a hypothesis`. |
| `No incumbents in this function` | Whether the function is already staffed. |
| `Recent news` | One sentence, or "None found in last 6 months". |
| `Funding context` | Most recent round, amount, date, investors. |
| `First Advertised` | Earliest corroborated posting date (YYYY-MM-DD). |
| `JD proof` | A short verbatim JD sentence that proves the `Role emphasis` read. No writing agent reads it. |
| `JD Body` | The full verbatim JD text, persisted so later runs need not re-fetch. |
| `JD Fetch Status` | The fetch outcome — Fetched / LinkedIn-blocked / Unfetchable / Manual-entry. |

---

**Required — must be populated for every role that passes the pre-flight check:**
`Role emphasis` · `JD proof` · `Keywords` · `Strategy` · `Role Type` · `Relationship type` · `Gap handling` · `Landscape`

All eight fields are non-negotiable when gap handling is enabled (seven when disabled — `Gap handling` drops out entirely). The cv-writer and letter-writer cannot run without them. If you cannot produce a confident value, produce a [LOW]-tagged best estimate — do not leave any field blank.

If `GAP_HANDLING = disabled` (set in the Settings pre-flight), leave `Gap handling` unpopulated and skip all gap analysis — do not write `N/A`. If gap handling is enabled and there are no material gaps, write `N/A` — when enabled, an empty field signals an error, not a clean match.

---

**⛔ KEYSTONE — analysis properties describe the ROLE and the COMPANY, never the candidate — no exceptions (restored 2026-07-24; the short-lived `Capability match` exception was retired with that section, per the user: "it should NOT cite mapping to user's capabilities").** `Role emphasis`, `Landscape`, `Culture`, `Role summary`, `Company Stage`, and every research-derived property answer *"what is this role / company / market?"* — objectively, as a recruiter-grade intelligence brief. They must NOT name the candidate, reference "her letter," describe what she must do, or carry letter strategy. **(One further, differently-shaped property names her record: `CV Titles`, the role-tailoring plan, added 2026-09-17 per the user's direct instruction — a CV instruction listing her employers and titles, never a fit judgment, and never analysis of the role. It is not an exception to this keystone for any other property.)** **Candidate-facing framing lives in exactly three places: `Gap handling`, the `Strategy` select, and the Letter Outline — nowhere else.** If you catch yourself writing the candidate's name or "the letter" inside any role/company property, you have leaked framing into the wrong field: cut it.

---

**⛔ KEYSTONE — returned values are scannable briefs, not essays.** Every text property the coach produces must be **formatted to scan AND tight.** This is mandatory, not cosmetic.
- **Format (mirror the `Landscape` sectioned style):** use **bold labels**, a **blank line between distinct topics**, and **bullets** for any list. Never a single dense paragraph.
- **Brevity:** say it in the fewest words that carry the signal — cut throat-clearing, hedges, qualifiers, and restatement.
- **Hard caps:** `Role emphasis` → exactly the two labeled parts (**Emphasis**: 3–4 JTBD bullets; **Likely KPIs**: 3–5 bullets), blank line between them, ≤100 words total; `Culture` → 2–3 one-line bullets, blank-line-separated; `Keywords` → ≤9 total (Critical ≤4 / Important ≤3 / Nice-to-have ≤2); `Priority Reason` → one sentence; `Role summary` → ≤400 chars; each `Landscape` bullet → one line. When in doubt, cut.

---

**Likely KPIs (always produced — a required part of the `Role emphasis` property).** State, as bullets (3–5, one per metric or tight group), the metric set this role is actually measured on — for **every** role, **including when the JD names no targets at all.** When the JD is silent, do not skip it: infer the KPIs from the role's scope, the company's GTM and business model (research dimension 1), and market research. A consumer-adoption role is measured on activation, usage, retention, and engagement; an enterprise GTM role on pipeline, ACV, win-rate, and sales-cycle; a community/UGC role adds contribution and active-contributor metrics. For an operating-model transition, give the **target-model** KPIs, not the model the user is leaving. Never leave it blank — and never tag it: confidence tags do not appear anywhere in `Role emphasis` (2026-07-23); an inferred KPI set is simply stated (research is hypothesis by nature).

---

**`Role emphasis`** — **restructured again 2026-07-24, per the user's direct instruction: "the emphasis should literally only be a paraphrased and/or directly quoted summary of what's most important in the role... In reality it should have: Emphasis: / Likely KPIs: / And that's it. And the length should be max 100 words."**

**Load `${CLAUDE_PLUGIN_ROOT}/references/discipline-emphasis-signals.md` before writing this property** — it maps common disciplines to the signals that reveal what a JD actually weights, so the emphasis read is anchored instead of improvised.

**Fixed structure — identical every run, exactly these TWO labeled parts, each a bullet list, blank line between them, ≤100 words total (count before returning). Bullets added 2026-10-20, per the user: the prior single run-on Emphasis sentence ("Make a widening monetization platform understandable and useful to developers and multiple business personas; own product-area positioning and launches, then convert awareness into sustained self-serve adoption...") was not clear enough — the fix is to align it specifically with the role's JTBD (jobs to be done) and format it as bullets:**
```
**Emphasis:**
- <JTBD 1 — the single most important job this role exists to get done>
- <JTBD 2>
- <JTBD 3>

**Likely KPIs:**
- <KPI or KPI group 1>
- <KPI or KPI group 2>
- <KPI or KPI group 3>
```

**Emphasis = the role's jobs to be done, ranked.** 3–4 bullets (never more), each ONE job phrased as outcome-led work — a verb plus the result the business hires this role to produce ("Turn a widening monetization platform into something developers and business personas each understand and adopt", "Own product-area positioning and launches through to self-serve adoption"). Order by importance: bullet 1 is the job the JD weights most heavily (title, first-listed responsibilities, repeated themes, the hiring manager's function — see `discipline-emphasis-signals.md`); a job the JD merely lists does not outrank one it stresses. Paraphrase or quote the JD's own vocabulary; one bullet = one job, never a stacked sentence of three. No bold, no sub-bullets, no tags.

**Likely KPIs = bullets, one per metric or tight metric group** (3–5), most decision-relevant first. Each bullet names what is measured, not a task ("Self-serve activation and retention", "Pipeline sourced from launches"). Where a bullet's KPI belongs to a specific Emphasis job, keep them in matching order so a reader can pair them by position.

**The operating-model translation lives INSIDE the Emphasis line, in generic discipline terms — it is role description, not candidate mapping.** The user's own kept example of what belongs: *"Xata is a product-led, developer-bought Postgres/AI-infrastructure tool → 'demand gen' here means organic developer growth (content, SEO/AI-search, community, launches)."* Name the motion in standard discipline vocabulary — PLG, B2D, ABM, enterprise sales-led, community-led — so any user's writers (which read that user's career-data) can map it to their own background. That naming is the ENTIRE bridge to the candidate: this property never mentions the user, her capabilities, or what "maps to" her — the writers do that mapping themselves.

**⛔ NEVER in this property (2026-07-23 bans, tightened 2026-07-24):** letter strategy or any strategy content ("It should NEVER include strategy. NEVER."); a `De-emphasized`/non-emphasis line ("it should NOT cite... non-emphasis"); any capability mapping or candidate reference of any kind ("it should NOT cite mapping to user's capabilities" — the 2026-07-23 `Capability match` section is retired); a CV Type recommendation (its own property); company facts beyond the one-clause operating-model translation (`Landscape` owns them); confidence ratings; step-up/step-down/rank commentary (step-down/transition findings route to `Patterns`, `Gap handling` when enabled, and the Letter Outline — never here). Never restate the JD's responsibilities as a task list — summarize what is MOST important, which is a selection, not an inventory.

For Specialist / practitioner roles (IC contributor, no direct reports), the reporting line / founding-vs-established context / ownership scope belong in the Emphasis summary only when the JD itself makes them central — woven in, never appended as extra sections, always within the 100 words.

**`CV Type`** — **its own returned property, only when `CV_TYPE_MODE == "Variant"` (2026-07-23, per the user: "coach isn't updating CV Type at all — very bad — so every CV is still always the original default, long version but that's not always the right choice" / "that has its own Select property").** Return:

```
CV Type: Detailed | Brief — [one-line rationale]
```

Intake writes it to the user's per-role `CV Type` select — **write-only-to-empty: the user's own hand-set value always wins and is never overwritten.** When `CV_TYPE_MODE` is `"Detailed"` or `"Brief"`, omit this property entirely. Never place a CV-type recommendation inside `Role emphasis` or any other property.

**`CV Titles`** — **the role-tailoring plan, returned for every full-research role (2026-09-17, per the user's direct instruction after peer feedback on a real application: "For all roles with any related experience, the role title should be adjusted to match the role the person is applying to. All other roles should be skipped and/or should take up far less space in the CV... we do need to be careful to not cross the line from tailoring to lying or hiding." / "some of this work should be offloaded during intake maybe to ensure the coach is monitoring").** You read her role record anyway to score coverage (Part 0); this property turns that read into the plan the cv-writer executes. Return exactly:

```
CV Titles:
Level: <the level the target role reads at, in plain words — e.g. "Senior IC, no reports" / "Director, small team">
<Employer>: Retitle → <title as it should appear> | basis: <one role fact, ≤15 words>
<Employer>: Descriptor → <recorded title> (<target function>) | basis: <one role fact, ≤15 words>
<Employer>: Keep → <recorded title> | reason: <≤15 words>
<Employer>: Fold
```

One line per employer in her role record (`02-professional-background.md` and its `background-role-facts-*.md` files), every employer accounted for, in the record's own order. Nothing else — no commentary, no strategy, no summary advice (Hyper Focus).

**The four dispositions:**
**Matching mode (2026-10-19).** `queue.md`'s `MATCHING MODE` section carries `role_matching`. Under `titles` (the user chose rigid, official-titles-only), **Keep is the default and needs no reason**; Fold still applies (it is about space, not titles); Retitle and Descriptor are emitted only for an employer with a user-stated rule in `USER CV TITLE PREFERENCES`. Under `capabilities` (default, or section absent) the dispositions work as below.

- **Retitle — the default.** Her role facts show the target function was real, substantial work in that role: a standing responsibility with documented outputs, not a one-off. The title becomes the target role's title or its nearest truthful variant.
- **Descriptor.** Some documented work in the target function, but it was not the substance of the role — the usual career-shift case. The recorded title stays and the target function is appended in parentheses.
- **Keep.** The recorded title already reads as the target function, or the user asked for it. Always carries a reason.
- **Fold.** No documented work that answers this role. The cv-writer names the employer in the aggregation line and gives it no entry.

**Do not be timid.** Titles are employer-assigned labels that differ between companies for identical work; aligning one to the work she actually did is tailoring, and the user has explicitly asked not to be protected from it ("I don't want the coach to be overly careful either"). Between Retitle and Descriptor, choose Retitle whenever the facts show the function as a standing part of the job. Between Descriptor and Fold, choose Descriptor whenever the role can supply even two bullets that answer this JD. A `Keep` with no reason, or a plan that is mostly `Keep`, is the over-caution defect.

**The fixed limits — where tailoring would become lying or hiding:**
1. **Never above her recorded level.** A retitle matches or sits below the recorded title's seniority. When the target role is junior to her record, retitles drop to the target level — state that level on the `Level:` line and write every retitle at it. The user's instruction: "if the role is more junior than I am, then dumb down the CV as much as possible."
2. **Employer names and dates are never touched** — they are not part of this property at all.
3. **Every `basis:` is a fact from her role record.** If the only support is inference, the disposition is Descriptor at most; if there is none, Fold. For a career shift, put the creativity into which documented work you surface as the basis — never into the facts themselves. When nothing supports more, fall back to what her career-data says.
4. **Every employer appears on a line.** A missing employer is a hidden employer.

**The user's standing title rules (`cv_title_rules` in `pipeline-preferences.json`) and the legacy per-role `CV Title Preferences` field are authoritative.** When `queue.md` carries a `USER CV TITLE PREFERENCES` section for the role (rules first, then the legacy field, labelled), apply it as written — a title she states for an employer is that employer's line, marked `| basis: user-stated`, exempt from the limits above (it is her statement about her own title). Standing preferences in her career-data (`01-writing-rules.md`) apply the same way.

**Her own CV structure rules outrank the plan.** Where her career-data states structure rules of its own (roles that always get a standalone slot, entries flagged mandatory, how a given employer may be placed), never `Fold` against them.

**This is a CV instruction, never a fit judgment.** No gap language, no "she lacks", no fit verdicts — a Fold says nothing about her, only about this CV's space.

**CV Type judgment principle (2026-07-23 — replaces the retired CV Type Recommendation Matrix, per the user: "that looks like a highly personalized matrix which couldn't possibly be relevant for any user").** The matrix was a geography × seniority × vertical lookup table whose rows were admittedly unsourced guesses arranged around one user's scenario — the same failure the Brief CV's `Earlier:` cutoff decision (`CLAUDE.md` → Key design decisions) already names: shared plugin doctrine gets a judgment principle, never a fixed table pretending to be world knowledge. Reason it out per role, in this order:

1. **The user's own stated norms win.** Read `cv_type.market_norms` from `pipeline-preferences.json` (optional free-text, e.g. "Israeli tech: Brief unless C-suite; US roles: Detailed"). When present and it covers this role's market, it is authoritative — the recommendation applies it and the rationale cites it.
2. **Otherwise, the target market's screening norms as researched for THIS role** — not recalled generalities. What do this market's and function's recruiters actually screen from? Evidence available in the run: the JD's own length/format cues, the company's other postings, anything research dimension 7/8 surfaced about their hiring process. If the research gives no real signal, say so in the rationale rather than inventing a norm — and since the `CV Type` return is still mandatory under Variant mode, recommend `Detailed` in that no-signal case (the pipeline's own empty-field default, so the recommendation never invents a norm the honest answer is "unknown" for).
3. **ATS keyword density and seniority adjust within the format, never against the market norm.** A keyword-heavy vertical is handled by denser writing inside the market-appropriate format — density is never a reason to escape to the longer format; seniority nuance never overrides a clear market norm.
4. **Unknown location defaults to the user's own market** (`location_compatibility.my_location`), never to a speculative foreign market. A real run reasoned "location unconfirmed (possibly US, where cyber CVs run longer) → Detailed" for a user whose own market favors Brief — that inversion is exactly what this rule prohibits.

Mapping to the plugin's binary system: a one-page norm → **Brief**; a multi-page norm → **Detailed**. The rationale line names which rule (1–4) decided it.

**`JD proof`** — The single most revealing sentence from the JD that proves your Role emphasis interpretation. Direct quote, verbatim. For the user's reference only — no writing agent reads this field.

---

**`Keywords`** — a tight, prioritized requirements map from the JD. **Hard-capped — too many keywords muddies ATS targeting and bloats downstream context.** Three tiers plus a warning segment, format `Critical: [terms] | Important: [terms] | Nice-to-have: [terms] | Unmatched: [term] (no career-data basis — update career-data and re-run intake, or expect this gap at screen)`.

**Career-data match check — run before returning Keywords (per the user's direct suggestion, 2026-07-28, after a real run thrashed to its revision cap over the unfillable "DLP" keyword: "these are the keywords, but they don't match your career-data so either update your career-data or remove the keyword in order to avoid major issues").** For every Critical and Important term, verify a documented basis exists in career-data (`02` role facts / approved bullets, `03` §Domain depth) — a capability the CV could honestly evidence, not necessarily the verbatim term. A term with NO documented basis is NEVER listed under Critical or Important: move it to the `Unmatched:` segment (outside the ≤9 cap; keep it short) and add a Patterns line naming it: `Keyword gap — [Company]: [term] gates this screen but has no basis in career-data — update career-data (then re-run intake) or leave it; the pipeline will not chase Unmatched terms.` This is the user's review point: she either enriches career-data (a re-run then reclassifies the term into its real tier) or knowingly applies with the gap. **Dual surface (per the user's direct instruction, 2026-07-28: "even when gap handling = false we should actually put this info in the Gap Handling property. It stands out there, and it's most logical... it's related to gap handling, but in a way that anyone/everyone should care"): also return the same warning as a labeled line for the `Gap handling` property — `Keyword gap: [term] — no career-data basis; update career-data and re-run intake, or expect this at screen.` — written in BOTH gap-handling modes.** The Keywords `Unmatched:` segment stays the machine-read anchor (Gate 0 keys off it); the `Gap handling` line is the human-read surface. The pipeline side is enforced at Gate 0: Unmatched terms are excluded from ATS coverage thresholds and no agent may direct a writer to add one — chasing an undocumented keyword is fabrication pressure, the exact thrash this closes.

**Hard caps — count before writing, never exceed:** Critical ≤4 · Important ≤3 · Nice-to-have ≤2 (**total ≤9**). Keep only the terms that actually gate the screen; drop the rest. Each term is an exact phrase from, or directly derivable from, the JD — never a paraphrase, never padding.

- **Critical** — terms in required qualifications, repeated multiple times, or likely hard ATS filters. cv-writer must include ≥80% of this group.
- **Important** — terms in preferred qualifications or appearing 1–2 times. cv-writer should include ≥60% of this group.
- **Nice-to-have** — terms appearing once, implied by domain context, or adjacencies. Best effort; absence is advisory only, not a revision trigger.

Keywords are for CV text only — they do not set the agenda for the cover letter.

---

**`Strategy`** — Select field. Write exactly one of three values: `IC`, `Strategic`, or `Hybrid`. This is the letter-type signal for the letter-writer — it sets the cover letter's structural type, nothing more.

- **IC** — the role's mandate is primarily individual execution, deliverable ownership, or technical/domain depth. The hiring manager evaluates whether the candidate can do the work.
- **Strategic** — the role's mandate is organizational leadership, function ownership, or cross-functional strategic direction. The hiring manager evaluates leadership altitude, not primarily execution capability.
- **Hybrid** — the role requires both organizational leadership AND specific IC execution. A Director who also does the work, a senior founding hire with both strategic and craft mandates.

**Calibration — owning a function is never `IC`, even when solo (the DualBird error).** A founding or solo "Head of / VP / Director of [function]" still **owns the function** — they set its strategy, not merely execute deliverables someone else scoped — so they are **`Strategic`**, or **`Hybrid`** when the role visibly requires hands-on building alongside ownership (the usual case for a founding solo leader at a startup). `IC` is reserved for a mandate that executes *within* a function someone else owns. When the title is Head / VP / Director / Chief, default to `Strategic` or `Hybrid`, and justify any `IC` choice explicitly against the JD.

Strategy is always written. It is not subject to the write-only-to-empty rule — always set it, even if a value already exists.

**Weighted prioritization model:**

When scoring priority across multiple roles, weight: Company culture and stage fit (40%) + the user's documented credential match (40%) + role level and growth trajectory (20%). A role that scores high on culture and credentials but offers a lateral move ranks above a role with a step up but culture misalignment or credential stretch.

---

**`Company Stage`** — One of: `Seed`, `Series A`, `Series B`, `Series C`, `Public`, `PE-backed`. Use funding research as the primary source. Omit rather than guess if genuinely unknown.

---

**`Role Type`** — Multi-select. Choose all that apply: `Builder`, `Scaler`, `Specialist`, `Leader`.

---

**`Relationship type`** — Select one: `Full time`, `Part time`, `Temporary`, `Fractional/Consulting/Freelance`.

---

**`Gap handling`** — One line per genuine, material gap. Maximum 3 gaps — prioritize the most screening-critical. For each gap: state what it is and the recommended handling.

Format: `[Gap]: [handling]`

Handling options:
- `surface [X] instead` — a documented experience addresses the gap if reframed; name what to surface
- `letter addresses via [angle]` — the CV cannot carry this, but the cover letter can address it with context or framing; name the angle
- `ignore — not a screening risk` — the gap exists but won't cost the user a first call
- `satisfied via [Y] — [X] is additive` — for preferred requirements where she satisfies one alternative

**What are NOT gaps:** Adjacent experience, transferable skills, and credible adjacent verticals are not gaps — they are the story. Do not manufacture gap handling for something that is genuinely a match.

**Never flag "works independently" as a gap or callout.** The ability to work autonomously is implied for any experienced professional. For a junior user this could appear only as gap handling if the JD makes it genuinely screening-critical — but for an experienced candidate it is never flagged, noted, or addressed. The same applies to equivalent soft-skill filler phrases ("self-starter", "takes initiative", "manages own workload").

**"Preferred" requirements with alternatives.** When a JD says "X or Y experience preferred" and the user satisfies at least one alternative, she satisfies the requirement. The unsatisfied alternative is additive, not a gap. Write `satisfied via [Y] — [X] is additive`, or omit it.

Check `02-professional-background.md` (Role Facts) to determine which AI product categories the user's documented experience maps to. Use only what is documented there.

If the specific AI category (e.g., conversational AI, NLP, voice agents) is not documented in the user's background, name it as a product-category gap separately from any domain/vertical gap.

**Domain gap vs. product-category gap are distinct.** A company can require both domain experience (e.g., healthcare) and product-category experience (e.g., conversational AI). Flag each separately. Do not collapse them.

**If no material gaps exist:** write `N/A`.

---

**`Date first advertised`** — When was this role *first* posted? **One site is not enough.** Boards reset the displayed date on every re-post or syndication, so the same role routinely shows "2 days ago" on one site and "6 weeks ago" on another — and the *earliest* credible date is the true one. Procedure:

1. Gather a date from at least two independent sources: LinkedIn "posted X days ago" (calculate the actual calendar date), the original job-board timestamp, the company's own ATS/careers listing, URL date parameters, and any other version surfaced during the JD-mirror search.
2. **Take the earliest credible date** across all sources — not the date on the URL you happened to start from.
3. Confidence: `[HIGH]` only when a primary source (the company's own ATS/careers page) gives the date, OR when ≥2 independent sources agree. `[LOW]` when only one source was reachable, or sources disagree and none is primary — in that case record a range (`earliest seen – latest seen`) rather than a single date, and note which sources gave which.
4. If the role has been open >60 days (measured from the earliest date), flag it prominently. If no date is findable on any source, write `Unknown [LOW]` — never guess or approximate a single date.
5. **Mechanical effort floor (2026-07-29 — a real audit found ~40% of researched roles blank, alongside the confirmed lazy-negative pattern):** if ANY source seen this run displayed a posting age of any kind — LinkedIn "posted X days/weeks ago", a board timestamp, a URL date parameter — `Unknown` is prohibited: compute the calendar date and return it `[LOW]`. `Unknown` is only permitted when every source consulted showed no date signal at all, and the Research confidence check block names those sources.
6. Intake merges your value **earliest-wins** against the existing property (`career-engine-intake/SKILL.md` Step 0.9a): a populated date is never cleared and never moved later, and an empty field falls back to the row's creation date. Your job is only this run's earliest credible candidate — never return a value shaped to "correct" a prior date to something later.

**`Remote compatibility`** — "Remote" does not mean the same thing everywhere, and misreading it wastes significant effort. Classify against `USER_LOCATION_COUNTRY` (`01-writing-rules.md` §8):

- **NOT compatible:** `Remote(<country abbr>)`, `Remote – <country>`, `Remote (<country abbr> only)`, "Must be authorized to work in <country>" when that country isn't `USER_LOCATION_COUNTRY`; remote with a specific country qualifier that excludes it; any role requiring work authorization in a country the user isn't authorized to work in.
- **Confirmed worldwide:** "Remote (Worldwide)", "Work from anywhere", "Open to candidates globally", "No timezone restrictions"; remote with no country qualifier AND the company's other open roles consistently show no country qualifier either; "Remote + [region that includes `USER_LOCATION_COUNTRY`]"; a company About page that explicitly states a distributed global team.
- **Ambiguous — requires research:** remote with no qualifier on this role but other roles at the same company carry country-specific qualifiers (treat as NOT compatible unless confirmed otherwise); remote with no qualifier and an unclear company hiring pattern (flag ambiguous, state what was checked); hybrid or remote-first language with no geographic scope stated (research the company's hiring page).

**When in doubt, classify `Ambiguous` rather than worldwide-compatible** — a false positive here wastes more effort than a false negative. Output: `Confirmed worldwide` | `Confirmed region-restricted ([region])` | `Ambiguous — [reason and what was checked]`.

**`Hiring Manager's Name`** — Name + title [HIGH], or hypothesis [LOW], or "Not identifiable."

**How to identify — do not shortcut this. Work through every step before marking "Not identifiable."**

1. **Read the JD text.** Check the byline, "reports to" language, and any named title in the reporting structure. If the JD names a reporting title (e.g., "reports to the CMO"), that title + company is your next search query — go to step 3 immediately.
2. **Read the company About Us / Team page.** This is mandatory — not optional. Open the page and read it. Note any {{USER_PROFESSION}} function leaders by name and title.
3. **Google `"[title]" [company name]`** — e.g., `"CMO" Northwind` or `"VP Marketing" Acme Corp`. This often surfaces the person's name directly in search snippet text, press mentions, or LinkedIn previews without requiring a login. Read the first page of results.
4. **Search LinkedIn for the company** and scan **all** people with {{USER_PROFESSION}} titles — not just the most senior one. Map the org layer by layer using {{USER_FUNCTION_SENIORITY_HIERARCHY}} as the reference for title tiers. The most senior {{USER_PROFESSION}} leader is often NOT the hiring manager.
5. **Check B2B intelligence platforms.** Search theorg.com, Crunchbase, and ZoomInfo for the company. A Google search for `[company name] theorg` or `[company name] site:theorg.com` is a fast entry point.
6. **Apply org-layer logic.** If both a top-tier and a mid-tier {{USER_PROFESSION}} leader are visible, the mid-tier leader is the likely hiring manager for any role below the top tier. Do not default to the most senior title.
7. **If a name is found, check their digital footprint.** Review their LinkedIn posts, company blog articles, X/Twitter if public, and any published interviews — this surfaces culture signals, priorities, and framing that feeds `Role emphasis`.
8. Flag explicitly in `Patterns` if there is a layer between the most senior {{USER_PROFESSION}} leader and this role.

**`Person who Advertised Role (if not Hiring Manager)`** — Name + title | Same as hiring manager | Not identifiable. [HIGH/LOW]

**How to identify:** Check the JD posting on the source job board for a poster name or recruiter byline. Search LinkedIn for the company's recruiter or talent team — cross-reference any name visible on the job posting.

**`Hiring manager's role`** — Title + 1 sentence on what their org position implies for the user's seniority and accountability. Hypothesis flag if not confirmed. [HIGH/LOW]

**`Manager role confirmed`** — `Yes` or `No; this is only a hypothesis`.

**`No incumbents in this function`** — `No incumbent in this function` or `Function is already staffed`.

**`Recent news`** — One sentence, or "None found in last 6 months."

**`Funding context`** — Most recent round, amount, date, investors — or "No recent funding news found."

**`Role summary`** — A compressed summary of the JD itself. Not about the user. This property serves as the JD proxy for all downstream agents — they read this instead of the full JD body.

**⛔ The #1 defect here is bleeding fit/gap/title analysis into this field.** Role summary describes the **job only**. If a sentence mentions the candidate, her fit, her seniority or title, a title she "hasn't held," a gap, or the word "transferable," it does not belong here — it belongs in `Priority Reason`.

**Hard limit: 400 characters total including spaces.** Count before writing.

Write from the JD body only. Structure: one short paragraph (what the role is, key context) followed by up to 5 short bullets (the most critical requirements or signals).

Rules:
- Use the JD's own vocabulary where possible
- Simple, clear, concise language — no verbosity, no repetition
- Never reference the candidate by name, candidate fit, or anything not in the JD
- Never include contact information or location
- If the JD is empty of content: write exactly `No content`
- If the JD contains a self-characterization section ("you'll thrive here if", "good fit / not a good fit") — include it as the final bullet, labeled `Self-characterization:` followed by the verbatim text (within the 400-char total)

---

### Part 3 — Patterns

Surface patterns the user should think about: clusters of similar roles, missing data, roles that look unusually strong, track mismatches, anything worth flagging before the pipeline runs.

**When analysis is complete, load `coach-output.md` to format and return your output.**
