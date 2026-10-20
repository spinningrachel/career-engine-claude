# Writer Craft — [CV] CV Rules (§5, §5b, §5c, §6, §6b)

> Moved verbatim from `skills/writer-craft/SKILL.md` on 2026-07-22 (context-diet split). Section numbers (§) are preserved from the consolidated doctrine; `SKILL.md` is now the routing file. No rule was changed or removed in the move.

## [CV] §5 — CV Document Shape (correctness, not style) — Detailed

These define what a passing CV even is. Cutting them changes correctness, not polish. **This section describes the Detailed CV Type only** — see §5b immediately below for the Brief variant, which diverges structurally (no RoleOverview, no Consulting split, different required-heading list).

**Required sections:** `## SUMMARY`, `## SKILLS` or `## SKILLS & EXPERTISE`, `## EXPERIENCE`, `## CONSULTING` (with an "Earlier:" line) when applicable.

**FORBIDDEN sections — hard stop, no exceptions:** `## EDUCATION`, `## LANGUAGES`, `## ADDITIONAL`. These are already in the Word template and formatted correctly — writing them here duplicates them in the final DOCX. The gatekeeper FAILs on any of these headings appearing.

**`## TOOLS` — optional.** Include only when the JD calls out tools or Role Type is Specialist/Builder and the JD discusses tooling. Omit for Leader/Scaler roles regardless of JD content. No tool or technology name of any kind belongs inside experience bullets, ever — not even one named in the JD, not even as illustration. Tool identity lives only in `## TOOLS`.

**`## PUBLICATIONS` — optional, rarely used.** Include only when `background-portfolio.md` documents 2+ published/bylined pieces or original-POV talks AND thought leadership is genuinely relevant to this role's positioning (visible in Role emphasis, the JD, or company culture signals — e.g. analyst-facing, evangelist, or community-facing roles). When in doubt, omit — most CVs never need this section, and the underlying content already works as cover-letter proof (§10) whether or not it appears here.

**`## SKILLS` content rules — a format contract is not a content contract.** Every item in this section must pass a three-way test:
- **Skill (belongs here):** a verb-backed capability she *does* — something she can perform, not something she merely knows about or has been called.
- **Knowledge (does NOT belong here):** a subject-matter area she knows *about* — a domain, a technology category, a regulatory area. Domain knowledge belongs in the Summary or in Role-emphasis framing (sourced from `03-framework.md` §Domain depth), never in `## SKILLS`. ✗ "Cybersecurity | Identity & access management (IAM/PAM) | Non-human identity (NHI)" is a domain-knowledge list, not a skills list.
- **Title/role label (does NOT belong here):** a job title or role descriptor is never a skill. ✗ "Founding Marketer" is a title, not a capability — cut it.

**Cap: 3 skill groups maximum.** Each item appears in exactly one group; groups must be conceptually distinct from each other — run a de-dup pass before returning a draft. ✗ "Cross-Functional Leadership" (Product-Marketing-Sales alignment | Sales enablement | Partner and channel enablement) sitting alongside "Product Marketing & Growth" (Cross-functional work with product, engineering, and data) is the same idea claimed twice under two headings — merge or cut one.

**ColorEmphasis annotation syntax and pandoc custom-style annotations** (RoleTitle, RoleOverview, RoleActivitiesList, RoleActivitySingle, SkillsHeading, Skills, Salutation, Signature Char) — apply exactly as documented in `skills/career-engine-export/SKILL.md`. Output without these annotations produces an unstyled DOCX.

**"Earlier:" line placement.** `## CONSULTING` always comes AFTER the "Earlier:" aggregation line, never before it. Document order: named full-time roles → "Earlier:" line → `## CONSULTING`.

**RoleOverview mandatory for every named role** except the "Earlier:" line — a one-sentence company-context + scope line in italic immediately under RoleTitle. Count RoleTitles and RoleOverviews before returning a draft; they must match.

**Detailed length limits (2026-10-20, per the user: "limit role overview length (for detailed only) to max 120 chars"; "limit role titles (detailed only) to max length 95 chars"; "cv length must be limited to max: 890 words (NOT counting education, and additional info - which users enter themselves)").** Three hard ceilings, Detailed only (Brief is held to one page by its own backstop, §5b):
- **RoleOverview ≤ 120 characters** — one short clause of company context + scope. Cut the funding/ownership recital first, scope second.
- **RoleTitle line ≤ 95 characters** — the rendered line a reader sees (`Title | Company | City | Dates`, annotation markup not counted). Shorten the title (drop the parenthetical function) before dropping the city.
- **Whole CV ≤ 890 words** — Summary + Skills + Experience + Consulting (+ Tools/Publications when present), counted as whitespace tokens containing a letter or digit (a `|` or bullet dash is not a word; annotation fences and comments are not counted). **Education, Languages and Additional are not counted** — they are the user's own content, appended at export and never in a draft. Run `pregate-lint.py` and fix every `CV-TOTAL-WORDCOUNT` hit before returning. To get under the ceiling use the trim order in §6 ("Cut priority order"), and use the role-tailoring plan's levers (§5c) before thinning proof: fewer bullets on older/less-relevant roles, a Fold for roles that answer nothing, a one-line entry for a role that answers little. A role the plan retitles keeps the bullets that make the title true (§5c); the cut falls on the roles the target role cares least about.

**Consulting-section placement and completeness.** Any consulting/fractional engagement flagged as requiring a standalone entry in `02-professional-background.md` must appear — never omit an entry flagged mandatory.

---

## [CV] §5b — CV Document Shape (correctness, not style) — Brief

The one-page, two-column condensed CV Type. Correctness rules for this shape only — for Detailed, see §5 above. Content rules (§6, below) are shared by both types.

**Required sections:** `## PROFILE SUMMARY`, `## SKILLS`, `## EXPERIENCE`. Note the summary banner is `## PROFILE SUMMARY`, not `## SUMMARY` — deliberately different text so "the Brief CV" is never confused with "the CV's summary paragraph" (see `CLAUDE.md` naming note for this feature).

**FORBIDDEN sections — hard stop, no exceptions, same as Detailed:** `## EDUCATION`, `## LANGUAGES`, `## ADDITIONAL` (from the shared `static-cv-footer.md` append). Also never produced for Brief specifically: `## CONSULTING`, `## TOOLS`, `## PUBLICATIONS` — there is no room for any of the three on a one-page format, regardless of how strong the qualifying content is, and Brief has no consulting/fractional split at all (see the flat Experience structure below).

**No RoleOverview — structural absence, not a shorter version.** Detailed's RoleOverview line (company context + scope, in italic under RoleTitle) does not exist in Brief at all. Do not write one. Do not run a RoleTitle/RoleOverview count-parity check against Brief output — there is nothing to count.

**Flat Experience structure, `Earlier:` line closes it out.** Brief's `## EXPERIENCE` is a single flat, reverse-chronological list — no separate Consulting section, no full-time/consulting split. The same `**Earlier:**` aggregation-line convention used in Detailed (§5, "Earlier: line placement") applies here too, but instead of preceding `## CONSULTING`, it is the **last line of `## EXPERIENCE` itself** — closing out the section once the most recent/relevant roles have had their individual entries. Document order: named roles (most recent/relevant first) → `**Earlier:**` line (if used) → end of section.

**One-page fit is a judgment call — this plugin never hardcodes how many roles get a full entry vs. fold into `Earlier:`.** It depends on the specific user's total career length, number of employers, and how much room her actual `.dotx` template has (read `cv_type.brief_has_photo` from `pipeline-preferences.json` if set — blank means assume no photo). This mirrors why the cover-letter opener is a principle and not a template (`CLAUDE.md` Key design decisions) — a fixed number here would fit one person's CV and misfit everyone else's. Order by relevance and recency exactly as Detailed does; give the most recent/relevant roles full treatment with tapering bullet density; fold everything beyond what the page can hold into one `Earlier:` line.

**Skills — one flat list, not Role-Type-categorized.** Detailed's Scaler/Specialist skills format uses multiple `SkillsHeading`/`Skills` category blocks (§ role-type-definitions.md). Brief always uses a single flat `## SKILLS` list regardless of Role Type — there isn't room for categorized sub-headings on one page.

**Mechanical backstop — one total-body word ceiling, not a per-section formula.** Matching how Detailed's own summary paragraph has a hard `≤120` word ceiling as a correctness backstop (not a style suggestion), Brief has a single generous total-body word-count ceiling covering the whole CV (Profile Summary + Skills + Experience combined), checked with `wc -w`. This exists to catch a CV that clearly won't fit one page — it is not a per-section formula, and it applies the same way regardless of any individual user's career length. **[Ceiling TBD — set against a real drafted example rather than guessed; do not invent a number here without one.]**

**Same annotation system as Detailed, with two Brief-specific differences.** `RoleTitle`, `RoleActivitySingle`, `ColorEmphasis`, and the flat `SkillsHeading`/`Skills` pair all apply exactly as documented in `skills/career-engine-export/SKILL.md`'s Brief annotation reference — just without `RoleOverview`, since Brief never uses it. Two differences from Detailed, both confirmed against the real `cv-template-brief-default.dotx` build: **(1) no `RoleActivitiesList` style exists for Brief** — every activity line, including every bullet of a multi-bullet role, is its own `RoleActivitySingle` div, never a bulleted list; **(2) `RoleTitle` omits the date** — Brief's `RoleTitle` line is `Title | Company | Location` only, with the date range as its own `RoleActivitySingle` div immediately after (see the annotation reference for the exact worked pattern, including why: the target table layout puts the date in its own narrow column, separate from the title). Output without these annotations produces an unstyled DOCX, same as Detailed.

**Approved bullets — read the Brief-labeled subsection, never derive from Detailed's.** `background-approved-bullets.md` carries adjacent `Detailed: Approved bullets` / `Brief: Approved bullets` subsections per company. Read only `Brief: Approved bullets` when drafting this CV Type. If that subsection is empty (not yet curated for this company), write fresh bullets from the role-facts files — same fabrication discipline as always, never lengthen or split a Detailed bullet into a "Brief version" as a substitute for reading the actual Brief-curated content.

**Bullet-writing doctrine — same rules as §6, shorter.** Brief reuses Detailed's outcomes-first, XYZ-formula content rules (§6, below) exactly — no new bullet philosophy, just tighter word budgets per bullet given the space constraint.

---

## [CV] §5c — Role Tailoring: titles, folded roles, level (applies to both Detailed and Brief)

Added 2026-09-17, per the user's direct instruction after peer feedback on a real application: "Each CV is tailored for the relevant role... For all roles with any related experience, the role title should be adjusted to match the role the person is applying to. All other roles should be skipped and/or should take up far less space in the CV... we do need to be careful to not cross the line from tailoring to lying or hiding."

**The premise.** The CV is an argument that this person has already done this job. Assume she has the right experience; the CV's work is to make that visible in ten seconds. A title that names a different function makes a recruiter stop reading before the bullets can prove anything.

**The role-tailoring plan governs.** During intake the coach writes a per-role plan to the `CV Titles` property (the user reviews and may edit it in her tracker; her standing title rules live in `pipeline-preferences.json` → `cv_title_rules` (2026-10-19; the per-role `CV Title Preferences` tracker field is a legacy read) — the legacy field and any of her ad-hoc wishes live in her own `CV Title Preferences` field). The pipeline hands both to you as `CV_TITLES_PATH`. **When a plan is present, execute it verbatim** — every title, every disposition, the stated level. Never re-derive, soften, or second-guess it: a plan the user has seen is hers. **When no plan is present** (a role researched before this feature, an inline run), derive one yourself with the test below and state it at the top of `cv-changes.md` or, on a draft, in your one-line summary.

**Matching mode (2026-10-19).** `cv-titles.md` opens with `MODE: capabilities|titles` (the config's `role_matching`). When no plan is on file and `MODE: titles`, Keep is the default for every employer (Fold still allowed); Retitle/Descriptor only from a preferences-block rule. `capabilities` (or no MODE line) keeps the Retitle default above.

**Four dispositions — one per employer in her record, every employer accounted for:**

| Disposition | When | What appears |
|---|---|---|
| **Retitle** — the default | Her role facts show the target function was real, substantial work in that role (a recurring responsibility with documented outputs, not a one-off) | The target role's title, or its nearest truthful variant, in place of the recorded title |
| **Descriptor** | Some documented work in the target function, but it was not the substance of the role — the usual career-shift case | The recorded title with the target function appended: `Recorded Title (Target Function)` |
| **Keep** | The recorded title already reads as the target function, or the user asked for it | The recorded title, unchanged. A Keep always carries a stated reason |
| **Fold** | No documented work that answers this role | No entry. The employer is named in the aggregation line (below) |

**Do not be timid.** Retitle is the default, not the exception. Titles are employer-assigned labels that vary wildly between companies for identical work; aligning one to the work she actually did is tailoring. Between Retitle and Descriptor, choose Retitle when the facts show the function as a standing part of the job. Between Descriptor and Fold, choose Descriptor when the role can supply even two bullets that answer the JD. Use everything around the title creatively as well: the RoleOverview line, bullet selection and order, the summary's first noun phrase (§6b).

**The line between tailoring and lying — four fixed limits, no exceptions:**
1. **Never above her real level.** A retitle may match or sit below the seniority of the recorded title, never above it. Manager never becomes Director; an IC never becomes Head of.
2. **Employer names and dates never change.** Not rounded, not merged, not stretched to close a gap.
3. **A title must describe work the role facts document.** If the only support is an inference, it is a Descriptor at most. If there is none, it is a Fold. Creativity lives in framing, never in the facts.
4. **Nothing is hidden.** Every employer in her record appears, as an entry or by name in the aggregation line. Dropping an employer silently is hiding; folding it by name with a pointer to the full history is not. An entry her career-data flags as mandatory stays mandatory (§5).

**Level — write down to the role, never up.** The plan's `Level:` line names the level the target role reads at. When that is below her record, the whole CV drops to it: titles lowered to the target level where a Retitle applies, execution bullets first, and leadership scope (team size, budget, board exposure, function-building, org design) suppressed unless it answers a named JD requirement. The summary speaks peer-to-team. An over-senior CV for a junior seat reads as a flight risk and loses the shortlist faster than an under-framed one.

**The aggregation line carries the folded roles.** One line, the existing `Earlier:` convention (§5, §5b), same position and styling. When every folded employer predates the oldest full entry, the bold prefix is `Earlier:`. When any folded employer is more recent than that, the prefix is `Additional experience:` instead, because "Earlier" would be false. Never both lines. The line names the folded employers, in whatever form her career-data already uses for her `Earlier:` line (employer alone, or recorded title and employer), and closes by pointing at the full history: "Full history on LinkedIn" when her career-data holds a LinkedIn profile, otherwise "Full history on request."

**Her own structure rules outrank this section.** Where her career-data states CV structure rules of its own — which roles earn a standalone slot, entries flagged mandatory, how a given employer may be placed, the form of her `Earlier:` line — those rules govern, and the plan is executed inside them.

**Bullets follow the same cut.** Inside a kept role, only work that answers this role survives (§6 Tailoring and dedupe discipline). A retitled role whose bullets still describe the old function contradicts its own title; the bullets are what make the title true.

---

## [CV] §6 — CV Content Rules (demonstrated failure modes — applies to both Detailed and Brief)

**The single-instance trap — most common summary failure.** A summary sentence implies a repeated pattern. If the CV shows the claim only once, the sentence overreaches. **Test, run on every summary sentence:** "Does this imply a repeated competency? How many times does the CV actually show it?" Once → move the specific detail to a bullet under that role; replace the summary sentence with the generalized capability claim. Twice or more across different roles → the pattern is real, the summary can claim it.

**Range language for peaks.** A single absolute number ("a 13-person team," "300% YoY growth") implies that was the sustained state. Use "up to X" when the number reflects a peak or single point in time. Example: "up to 13-person teams" not "a 13-person team," "up to 300% YoY growth" not "300% YoY growth."

**Abstract the roster; carry the scope.** Listing the specific sub-functions of a team ("editorial, technical writing, social, product marketing, field") is bullet-level detail — the summary carries the scale and unified outcome, not the org chart.

**Verb tally — no opening verb 3+ times.** Tally bullet-opening verbs before returning any draft. A real gatekeeper catch: "Built" used 5 times. No verb may repeat 3 or more times across all bullets in the document.

**No verbatim JD phrase-lifting.** Do not lift a 4+ word phrase verbatim from the JD into a bullet. Paraphrase the requirement in the user's documented language; exact-string ATS matching belongs in `## SKILLS`/`## SUMMARY` keyword placement, not in bullet prose copied from the posting.

**Fabrication rule.** Every claim traces to `01-writing-rules.md` and the `background-role-facts-*.md` files. If a claim can't be traced, it does not exist. Consulting/fractional scope must use the correct verb pattern (`01-writing-rules.md` §1) — never overclaim fractional work as full function ownership.

**Bullet formula (XYZ) — for new composition only, when no approved bullet maps to a JD requirement:**
> Accomplished [X — the outcome] as measured by [Y — the metric/proof] by doing [Z — the method].

X is always required. Y is optional when the outcome is specific without a number. Z is optional when the method is obvious. Lead with the outcome, not the action, where possible. Third person, no "I." One bullet, one job. No phrase repeats verbatim across bullets.

**Tailoring and dedupe discipline.** A tailored CV is not the master CV with keywords swapped in:
- Dedupe stats — the same metric earns its place once; if it appears in two bullets, keep the stronger placement and cut the other.
- Combine overlapping bullets describing the same initiative.
- Cut role-irrelevant bullets, even excellent ones, if they don't serve *this* role's mandate.
- Cut priority order when trimming for length: role-irrelevant bullets first, then duplicated stats, then the weaker of an overlapping pair, then wording — never cut the proof the role most needs.

---


---

## [CV] §6b — Compression and Dedup Rules (added 2026-07-22, from real delivered-CV edit forensics)

Every rule below traces to a real delivered CV the user had to hand-edit before sending. The
common disease: **items restate their own category and pad every noun.** These rules are shared
by both CV Types. The mechanical subset is also enforced by `skills/gatekeeper-checks/scripts/pregate-lint.py`
(run it before returning any draft) — but the rules bind whether or not the linter fires.

**Summary's first noun phrase mirrors the target job title.** The first words of the summary
name the function the JD is hiring for, not a hybrid the writer finds more complete.
✗ "Content and editorial leader…" for a Content Marketing Director JD → ✓ "Content marketing leader…"

**The skills heading owns the category word — items never repeat it.** Headings are 1–3 words,
never "&"-chained triples. If an item needs the heading's word to make sense, the item is
restating the category instead of naming a capability.
✗ Heading "Demand Generation & Growth" with items "Demand generation program development | Demand funnel analysis | Growth-focused demand plays"
✓ Heading "Demand Generation" with items "Program development | Funnel analysis | Lifecycle plays"

**Dedup at three levels — column, adjacent bullets, cross-section.**
- *Within a skills column:* if an item rephrases another item, delete one.
  ✗ "Team management and staff leadership" alongside "Managing direct reports and workflows" → ✓ "Team leadership"
- *Across adjacent bullets:* a fact stated in one bullet is not restated in the next.
  ✗ "…for an 8-person function." immediately before a bullet saying "8 direct reports" → drop one.
- *Across sections:* a qualifier already carried by the Summary is not repeated in Skills.
  If the Summary says "complex enterprise buying journeys," the skills item is "Journey mapping," not "Journey mapping across complex enterprise buying journeys."

**No noun doublets.** "X and Y" where Y restates X keeps only one: "workflows and systems" →
"workflows"; "positioning and messaging" (when used as one activity) → pick the one the JD uses.

**No parenthetical enumerations in skills items.** ✗ "Multi-channel production management
(email, paid, social, events, webinars)" → ✓ "Multi-channel production". The formats belong in
Experience bullets where they attach to outcomes, or nowhere.

**No padded modifiers.** A modifier that adds no information is cut: "KPI-driven optimization"
→ "optimization"; "AI-assisted reporting workflows" → "AI reporting workflows".

**Drop modifiers implied by role context.** Inside a marketing role's entry, "marketing budget"
is "budget"; "vendor ownership for the team" is "vendors"; "founded the product marketing
function" is "founded PMM function" when the audience reads the abbreviation natively.

**State outputs, not process language.** The bullet names what exists because of her, not the
alchemy that produced it. ✗ "translating research insight directly into the assets sales teams
use" → ✓ "creating assets sales teams use".

**Concrete specifics over vague cadence.** ✗ "(annual)" → ✓ "(2023)". A year, a count, a named
framework — never a frequency adverb standing in for one.

**Terse by default; length only when specificity earns it.** These rules compress noise, not
signal. An item that carries real differentiating information keeps its length — "enablement
content for analyst relations" survives; "content excellence across the content lifecycle" does not.

**User style exemplars override defaults.** If the user's `career-data` contains a
`cv-style-exemplars` reference (before/after pairs from CVs the user hand-edited), load it and
treat the user's "after" versions as the governing register for skills sections and bullet
compression — the user's own edits outrank any default example in this file.
