# Gatekeeper Check Definitions — CV Check

> Moved verbatim from `skills/gatekeeper-checks/SKILL.md` on 2026-07-22 (context-diet split). Gate numbers are preserved; `SKILL.md` is now the routing file. No gate was changed or removed in the move.

## CV Check

Run Gate 0 (ATS pre-check) first, then Gates 1-6 in order.

**The gatekeeper receives `CV Type=Detailed|Brief` at every CV Check spawn** (the orchestrator's already-resolved value — the gatekeeper never re-derives it). Gates branch only where the thing they check is literally different content between the two types — not by default. Gate 0 and Gate 2 branch (required headings differ; RoleOverview structurally doesn't exist in Brief). Gate 1 uses a different number but the same logic. Gates 3-6 do not branch at all — punctuation, banned vocabulary, sentence mechanics, Skills-section content quality, and role-tailoring conformance apply identically regardless of CV type. See each gate below for the specific reasoning.

### Gate 0 — ATS Pre-Check (hard fail)

**`Unmatched:` keywords are OUT OF SCOPE (per the user's direct suggestion, 2026-07-28, after a real run thrashed to its revision cap over the unfillable "DLP" keyword: "these are the keywords, but they don't match your career-data so either update your career-data or remove the keyword in order to avoid major issues").** Terms the coach listed under the Keywords property's `Unmatched:` segment have no career-data basis by verified check: exclude them from the Critical/Important coverage denominators and thresholds entirely, and NEVER emit a violation, fix direction, or reviewer flag asking the writer to add one — an undocumented keyword can only be added by fabricating, and a real run burned its full revision cap proving that. If an Unmatched term somehow appears in the CV text, that IS a fabrication-check matter — verify its evidence like any claim.

ATS failures mean the document may never reach a human reader regardless of quality.

**Keyword coverage.** Parse the Keywords property into three tiers (`Critical: ... | Important: ... | Nice-to-have: ...`). **Search each term via `Grep` (case-insensitive) against the actual staged CV file — never a manual read-through.** This is a literal string search, same mechanical-execution standard already mandated for Gate 6's banned-term search and the word-count checks elsewhere in this doctrine ("never estimate, never eyeball"). **Confirmed production failure this closes:** a real Gate 0 check reported "Infrastructure-as-Code (IaC)" as absent from a CV body when the term was present verbatim in the Consulting section — a manual-read miss, not a judgment call — and that false negative was the first domino in a chain that drove the CV's real ATS coverage from 3-of-4 Critical keywords down to 0-of-4 by the final round (the writer kept trying to "fix" a gap that didn't actually exist at round 1, generalizing an already-borderline claim into an unverifiable one in the process). Report each term's exact match count, not just a binary present/absent, so a false "0 hits" is easier to catch on review.

| Tier | Requirement | Action if below threshold |
|---|---|---|
| **Critical** | ≥80% must appear | FAIL — list missing terms by name |
| **Important** | ≥60% must appear | FAIL — list missing terms by name |
| **Nice-to-have** | No threshold | Advisory only — end-of-pipeline feedback note, not a violation |

**Gap handling exception — applies ONLY when `gap_handling_mode = enabled`:** a missing Critical/Important term explicitly listed as a gap in the role's Gap handling property does not FAIL — add it to the advisory note instead. **When `gap_handling_mode = disabled` (the token every pipeline spawn passes — 2026-07-14 universal spawn parameter), this exception never applies: there are no gaps, and no missing keyword is ever excused by one.** If the token was not passed at all (an older spawn), log "gap_handling_mode not passed" and apply the exception only when a Gap handling listing was actually provided — the pre-2026-07-14 behavior.

**Standard section headings — branches by `CV Type`, because the mandatory heading set is literally different content between the two types.** Detailed requires `SUMMARY`/`EXPERIENCE`/`SKILLS` and permits a `CONSULTING` section; Brief requires `PROFILE SUMMARY`/`EXPERIENCE`/`SKILLS` and never has `CONSULTING` at all (`writer-craft/SKILL.md` §5b). Without branching, this check would hard-fail every Brief CV either for "missing CONSULTING" (which Brief never has by design) or for the wrong banner text on the summary heading — a structural absence that isn't a mistake, not something to penalize.

**Detailed — search the full document (case-insensitive) for "SUMMARY", "EXPERIENCE", "SKILLS":**

| Required | Not acceptable |
|---|---|
| SUMMARY or PROFESSIONAL SUMMARY | Profile, About Me, Introduction |
| EXPERIENCE or WORK EXPERIENCE | Career History, Professional History, Work History |
| SKILLS | Core Competencies only (without SKILLS anywhere) |

FAIL if EXPERIENCE or SUMMARY headings are absent or substantially renamed.

**Brief — search for "PROFILE SUMMARY", "EXPERIENCE", "SKILLS":**

| Required | Not acceptable |
|---|---|
| PROFILE SUMMARY | SUMMARY alone (wrong banner for this type — see `writer-craft/SKILL.md` §5b's naming note), Profile, About Me, Introduction |
| EXPERIENCE or WORK EXPERIENCE | Career History, Professional History, Work History |
| SKILLS | Core Competencies only (without SKILLS anywhere) |

FAIL if EXPERIENCE or PROFILE SUMMARY headings are absent or substantially renamed. **Never FAIL a Brief CV for lacking a `CONSULTING` section — Brief structurally never has one.**

**Macro-injected sections — FAIL if present, never FAIL on absence. Applies to both CV types identically — this check doesn't branch.** `## EDUCATION`, `## LANGUAGES`, `## ADDITIONAL` are injected automatically by the Word template (or the shared `static-cv-footer.md` append for Brief) — they must NOT appear in cv-writer's markdown output (duplication risk). FAIL immediately on any hit: "[SECTION] section must not be written — it is part of the Word template and will duplicate." Never FAIL on their absence.

**`## TOOLS` — optional for Detailed, forbidden for Brief.** For Detailed: not a FAIL on absence; if present, must use the literal `## TOOLS` heading — FAIL if present under any other heading name: "TOOLS section uses non-standard heading [heading] — rename to `## TOOLS`." For Brief: FAIL if a `## TOOLS` section appears at all — "TOOLS section is not permitted in a Brief CV — there is no room for it on a one-page format (`writer-craft/SKILL.md` §5b)."

**`## PUBLICATIONS` — optional and rare for Detailed, forbidden for Brief.** Same rule shape as `## TOOLS` above, applied to the newer Publications section: not a FAIL on absence for Detailed. For Brief: FAIL if a `## PUBLICATIONS` section appears at all — "PUBLICATIONS section is not permitted in a Brief CV — there is no room for it on a one-page format (`writer-craft/SKILL.md` §5b), regardless of how strong the qualifying content is."

**ColorEmphasis annotation check.** Scan for the pattern `[^]]{custom-style="ColorEmphasis"}` — i.e. `{custom-style="ColorEmphasis"}` not immediately preceded by `]` (an unbracketed span; pandoc renders the literal annotation string as body text). FAIL every hit: "Unbracketed ColorEmphasis span: `[text here]` — wrap: `[text here]{custom-style=\"ColorEmphasis\"}`."

---

### Gate 1 — Summary (hard fail unless marked advisory)

**Branches only in the word-count number, not the logic — same single-instance-trap check either way.** Applies to `## SUMMARY` (Detailed) or `## PROFILE SUMMARY` (Brief) — same rules below, just a different ceiling.

- No company, client, or conference names — descriptors only (`01-writing-rules.md` §1). **Hard fail.**
- **Detailed:** ≤120 words, 1 paragraph, ≤4 sentences. **Brief:** the single total-body word-count backstop from `writer-craft/SKILL.md` §5b covers the whole CV (Profile Summary + Skills + Experience combined) rather than a standalone paragraph cap — do not apply the ≤120-word Detailed ceiling to a Brief profile paragraph in isolation. No tool/platform names, consulting client names, or undocumented metrics. **Hard fail.**
- No motivation language — the summary states capability, not why she wants the job. **Hard fail.**
- Leads with language most relevant to the hiring manager and role; no specific role required to appear, including the most recent one. Do not FAIL on the absence of any particular role.
- **Single-instance trap.** For every concrete claim in the summary, count how many times the CV body demonstrates it across different roles. One instance → FAIL: "Summary sentence '[sentence]' implies a repeated pattern but the CV shows only one instance — move the specific detail to a bullet under [role], replace with the breadth claim." A dense, em-dash-stuffed, or bullet-shaped summary sentence is the signal to run this test. **Hard fail.**
- **Absolute-peak numbers.** A single absolute team-size or growth number (e.g. "a 13-person team," "300% YoY growth") implies sustained state — FAIL unless phrased as a range ("up to 13-person teams"). **Hard fail.**
- **Roster-level detail.** Listing the specific sub-functions of a team (e.g. "spanning editorial, technical writing, social, product marketing, field") is bullet-level detail — FAIL: "Summary lists specific team functions — abstract to 'multiple competencies' or equivalent scope language; move the roster to a bullet." **Hard fail.**
- Cliché filler ("comfortable operating across", "proven track record", "passionate about", "results-driven", "dynamic", "extensive experience") — **advisory only; do not FAIL or loop.**

### Gate 2 — Experience (hard fail)

**Branches because RoleOverview and the Consulting split structurally don't exist in Brief — not by default.** The RoleOverview-parity check below counts RoleTitles vs. RoleOverviews and FAILs on a mismatch; Brief has zero RoleOverviews by design (`writer-craft/SKILL.md` §5b), so that specific check is **skipped entirely** for Brief rather than made to fail on a structural absence that isn't a mistake. Likewise, the Consulting-section rules below apply to Detailed only — Brief has no `## CONSULTING` at all, so there's nothing to check there. The remaining rules (no tool names in bullets, target-market claims trace to background) are format-agnostic and apply to both types unchanged.

**Detailed only:**
- `## EXPERIENCE` = full-time employment only, reverse-chronological by end date.
- Consulting/fractional work belongs in `## CONSULTING`, never `## EXPERIENCE` — FAIL if found in Experience.
- Any consulting entry flagged mandatory in `02-professional-background.md` must appear (standalone entry in `## CONSULTING` or a bullet within it) — FAIL if absent entirely.
- "Earlier:" line is the final entry inside `## EXPERIENCE`, before `## CONSULTING` — FAIL if Earlier appears after CONSULTING.
- Every named role has a RoleOverview immediately below its RoleTitle — count must match (Earlier: exempt).

**Brief only:**
- `## EXPERIENCE` is a single flat, reverse-chronological list (no full-time/consulting split — `writer-craft/SKILL.md` §5b). FAIL if a `## CONSULTING` section appears at all.
- If an `**Earlier:**` line is used, it must be the final line of `## EXPERIENCE` — FAIL if anything follows it.
- **Do not run the RoleOverview-parity check** — Brief has no RoleOverview line anywhere; this is correct, not a violation.

**Both types:**
- **The aggregation line may carry either bold prefix — `Earlier:` or `Additional experience:` (`writer-craft/cv.md` §5c) — and every rule above that names the "Earlier" line applies to whichever is used.** FAIL if both appear, or if `Earlier:` is used while a folded employer is more recent than the oldest full entry.
- Claims about target market match `02-professional-background.md` (Role Facts).
- No tool or technology name of any kind inside experience bullets — blanket ban, even a tool named in the JD, even as an example. Approved bullets from `02-professional-background.md` are the only exemption.

### Gate 3 — Structure (hard fail)

**Does not branch by CV Type.** Punctuation, banned vocabulary, and sentence mechanics are format-agnostic — a Brief CV is held to the same bans as a Detailed one.

- No years on the Earlier line (Education/Languages are script-injected — skip them).
- No header or label between the SUMMARY banner and the summary text.
- **No opening verb 3+ times** — common offenders: Built, Led, Developed, Created, Managed, Drove, Owned.
- **No 4+ word verbatim JD phrases in new bullets** (standard terms like "go-to-market" are fine; approved bullets exempt); quote both phrases when flagging.
- **No em dash (—) anywhere** — zero exceptions, no carve-outs (not as a list separator, not for asides, not as a colon substitute — the full-width ban per `writer-craft/SKILL.md` §1). **Hard fail.**
- **No colon (:) anywhere in body copy** — not for role labeling, introducing explanations, before lists, or as an em-dash substitute (`writer-craft/SKILL.md` §1). **Hard fail.**
- **Soft-skill filler banned as a standalone claim:** "works independently," "self-starter," "takes initiative," "manages own workload," "team player" — FAIL if present without bullet-level substantiation. **Hard fail.**
- **AI-tell vocabulary** (`writer-craft/SKILL.md` §2): crucial, pivotal, vibrant, showcase/showcasing, tapestry, underscore (verb), landscape (abstract noun), testament, enduring, foster/fostering, garner, interplay, intricate/intricacies, foundational, transformative, robust, seamless, comprehensive, leverage (verb), synergy, spearhead, paradigm, "know what it takes," land (verb). CV-only additions: think outside the box, value add, go-to person, bottom line, big picture, cutting-edge, game-changer, guru, ninja, rockstar, world-class, paradigm shift, scalable, disruptive, innovative, holistic approach, agile. **Advisory — scored, does not independently block.**
- **Named phrase bans** (`writer-craft/SKILL.md` §2): "that made it land," "behind the [noun]," "at an inflection point," "quietly [verb]ing," "rare" as self-descriptor, "up close," "specialism." **Advisory.**

### Gate 4 — Sentence Mechanics (advisory, scored — flag but do not independently block)

Cross-referenced from `writer-craft/SKILL.md` §3-4; these are style-quality checks, not the hard-fail document-correctness checks above. **Does not branch by CV Type** — same reasoning as Gate 3.

- **False range** ("everything from X to Y" where X/Y are filler, not real endpoints).
- **Approach-announcement via label** (naming a methodology before demonstrating it — e.g. "My approach is deliberately research-first:").
- **Contrived tricolon** built to sound impressive (real parallel lists of 4-5 real things pass) — also flag the same sentence opening used 3+ times in a row.
- **Passive voice** where an active rewrite is available.
- **Synonym cycling** — rotating synonyms for the same concept instead of repeating the right word.
- **Filler phrases** left uncut: "in order to," "at this point in time," "it is important to note that," "due to the fact that," "has the ability to," "in the event that."

### Gate 5 — Skills Section Content (hard fail)

A format contract is not a content contract — this gate checks what's actually IN `## SKILLS`, not just whether the heading exists (that's Gate 0). Cross-referenced from `writer-craft/SKILL.md` §5's three-way test. **Hard fail on any of the three:**

- **Knowledge listed as a skill.** A subject-matter/domain area the candidate knows *about*, not a capability she *does* — e.g. "Cybersecurity," "Identity & access management (IAM/PAM)," "Non-human identity (NHI)" as standalone skill-list items. FAIL: "[item] is domain knowledge, not a skill — cut it from `## SKILLS` or move it to Summary/Role-emphasis framing."
- **Title or role label listed as a skill.** A job title or role descriptor is never a skill — e.g. "Founding Marketer." FAIL: "[item] is a title, not a capability — cut it."
- **More than 3 skill groups, or cross-group duplication.** FAIL if the section has more than 3 categorized groups, or if the same item (or a clear paraphrase of it) appears in more than one group. Quote both groups and the overlapping item(s): "[group A] and [group B] both claim [overlapping concept] — merge or cut one."

### Gate 6 — Role Tailoring (hard fail)

Cross-referenced from `writer-craft/cv.md` §5c. **Does not branch by CV Type.** Input: `CV_TITLES_PATH` (`$PIPE/cv-titles.md`; if the spawn did not pass it, look for `cv-titles.md` beside the CV file) and the employer list in `02-professional-background.md`'s role record. Read the role record for employers, recorded titles, and dates — mechanically, never from memory of the CV. **`CV_TITLES_PATH=skip` (the Edit pipeline's Step E0.7 baseline check of a pre-existing CV) → skip this gate entirely and say so in the output.**

**When a plan is present (the file carries plan lines, not `PLAN: none`):**
- **Conformance.** Every `Retitle`/`Descriptor`/`Keep` line's title appears on that employer's entry exactly as the plan (or, where present, the user's `CV Title Preferences` block) states it. FAIL: "[Employer] title is '[found]' — the plan says '[planned]'." Every `Fold` employer has no entry and is named in the aggregation line. FAIL if a folded employer has a full entry, or a planned entry is missing.
- **The plan's titles are exempt from every honesty judgment in this gate.** The coach's plan passed the Coach Output Check before it was written, and the user has had it in her tracker since — her edits and her `CV Title Preferences` are her own statement about her own titles. Never FAIL a CV for executing the plan, and never issue a fix direction that asks the writer to change a planned title. A violation against a planned title is itself the error. **This is deliberate, including for a title the user edited in above her recorded level:** the limits bind the coach (Coach Output Check item 15, before the write) and the writer (the no-plan branch below), never the user's own statement about her own career.

**When no plan is present (writer-derived):** check the writer's titles against §5c's fixed limits instead. FAIL a title whose seniority sits above the recorded title for that employer (quote both) — except a title the user stated in `cv_title_rules` / the preferences block (`basis: user-stated`), exempt as in the with-plan branch. FAIL a retitle naming a function the role facts for that employer do not document at all — fix direction: `Descriptor` or `Fold`, never "restore the recorded title" as the only option.

**Always, plan or no plan:**
- **Employer names and dates unchanged.** Each entry's employer and date range match the role record. FAIL on any difference, quoting both.
- **Nothing hidden.** Every employer in the role record appears as an entry or by name in the aggregation line. FAIL: "[Employer] appears nowhere in the CV — fold it into the aggregation line by name." An entry her career-data flags as mandatory must still appear (Gate 2).
- **Title and bullets agree.** A `Retitle` or `Descriptor` entry carries at least one bullet in the target function. FAIL: "[Employer] is titled '[title]' but no bullet shows that function."
- **Level.** When the plan's `Level:` line (or, absent a plan, the writer's stated derivation) puts the role below her recorded seniority, FAIL leadership-scope claims in the Summary that answer no named JD requirement — team size, budget ownership, board exposure, function-building. Advisory only for the same content inside bullets.
- **Never FAIL a CV for omitting or shortening a role the plan folds, for a title that differs from the recorded one, or for being "less complete" than her full history.** That is the feature.

---
