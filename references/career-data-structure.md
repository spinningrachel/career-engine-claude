# career-data — Structure Contract (DO NOT CHANGE)

**Canonical structure spec for the `career-data` skill.** This file is the plugin's source of truth; at skill-creation the setup handoff ships a copy of it **inside** the user's `career-data` skill as `references/_STRUCTURE-DO-NOT-CHANGE.md`, so the contract is in front of Chat on every future edit.

**Read this before editing any reference file in `career-data`.**

The career-engine plugin's agents read these files by **exact section heading and exact filename**. You may freely edit, add, and update the **content inside** a section. You must **not** rename, renumber, reorder, or delete a section heading, and must not rename or remove a file. Restructuring breaks the writers silently — they look for a heading by name, don't find it, and produce a weaker document with no error.

**Two kinds of change:**
- **Content edits (safe, anytime):** update text within a section; add a new role entry, vertical, table row, testimonial, or Motivation Bank row; refresh values. Stay inside the existing headings.
- **Structural changes (NOT ad-hoc):** adding, removing, renaming, renumbering, or reordering a section or file, or changing the Motivation Bank table format. These go through the career-engine `update-refs` skill, which also updates the file index and the agents that load it. Delivered letters are managed only via the letter-writer agent's "Manage Letter Examples" option, never by hand.

If a requested edit would rename, renumber, reorder, or delete any heading or file below — **stop and tell the user it needs the `update-refs` skill instead of an ad-hoc edit.**

---

## Canonical files (never rename or remove; all integrity-checked in `career-data-marker.json`)

- `references/01-writing-rules.md`
- `references/02-professional-background.md` (router) + `references/background/background-motivation-bank.md`, `background-cv-summaries.md`, `background-approved-bullets.md`, `background-role-facts-*.md` (one per company), `background-testimonials.md`, `background-portfolio.md`, `background-cross-cutting-skills.md`
- `references/03-framework.md`
- `references/linkedin-profile.md`
- `references/pipeline-preferences.json` (optional matching keys `role_matching`, `scope_preferences`, `cv_title_rules`, 2026-10-19; also the single source of truth for job-search/sourcing preferences — target titles, title variants, remote preference, exclusion patterns, industry fit, company stage fit, employment type, coaching prioritization, screening answers — retired `job-preferences.md` folded in here). **`references/` is the ONLY correct location (2026-07-24):** a skill built from the pre-2026-07-24 handoff tree may have this file at the skill root — runtime reads fall back to root and flag a migration note, but the fix is moving the file into `references/` (and updating the marker manifest), not leaving it there.
- `references/templates/` — CV and cover letter `.dotx`/`.dotm` templates (filenames vary per user), plus `cover_letter_templates.md` (optional — corpus-derived template pair and shared invariants, calibration material never overriding the Motivation Bank)
- `references/delivered-letters/INDEX.md` (+ the `example-letter-NN-*.md` files; cap 6, managed via the letter-writer "Manage Letter Examples" option)
- `references/capability-profile.md` — the coach-derived, user-confirmed capability profile (2026-10-15): ≤30 title-free capability lines (≤25 for an early-career user) in ≤5 discipline groups, the Prioritization pipeline's function-fit input. **Conditional:** generated at setup Phase 4 for new users; legitimately absent on a career-data built earlier until the user asks the coach to "generate my capability profile" (the prioritizer falls back to the title-based read and says so). Never hand-edited beyond the user's own confirmation-time line edits — regenerated through the coach so the de-duplication and transferability tests run every time.
- `references/static-cv-footer.md` + `references/static-cv-footer-he.md` — the CV footer (Education/Languages) appended at export as `$CV_FOOTER`/`$CV_FOOTER_HE`. **Conditional:** required when `pipeline-preferences.json` → `cv_footer.inject` is `true` (the default); legitimately absent by design when the user set it to `false` (she manages that content herself outside the pipeline). These live at `references/` directly, not `references/templates/` — they are markdown, not `.dotx`.

A user's skill may also contain **additional files** added through `update-refs` (split-out framework narratives, a `voice-and-identity/` directory, `linkedin-post-strategy.md`, etc.). Those are equally load-bearing — do not rename or remove them either. Anything listed in `career-data-marker.json` → `expected_files` is required.

---

## Fixed section headings (rename / renumber / reorder / delete = breakage)

Add content and subsections within them; never change the headings themselves. Section numbers are intentionally non-sequential — do not "fix" them.

**01-writing-rules.md**
- `## Section 1 — Rules`
- `## Section 2 — Identity and Framing`
- `## Section 3 — Professional Frameworks and Philosophy`
- `## Section 4 — Domain Depth and Verticals`
- `## Section 5 — Voice and Source Material`
- `## Section 8 — Reference Details`

**02-professional-background.md** (v1.5.0+: router to `background/` sub-files)

This file is now a router — all content lives in `references/background/background-*.md` sub-files. The router contains a routing table; load the sub-file that matches your task. Sub-files are load-bearing by filename — never rename or remove them:
- `background-motivation-bank.md` — the Motivation Bank (`| Tags | Motivation |` table — format spec below)
- `background-cv-summaries.md` — approved CV summaries by domain
- `background-approved-bullets.md` — approved CV bullets
- `background-role-facts-*.md` — per-company role facts (one file per company/role group)
- `background-testimonials.md` — testimonials
- `background-portfolio.md` — portfolio and work samples
- `background-cross-cutting-skills.md` — cross-cutting skills

**03-framework.md** (top-level `#` sections — inline except where noted)
- `# Category and market frame`
- `# Voice and tone` → `## Voice fingerprint (quantitative)` and `## Voice samples` (the letter-writer calibrates voice against these — never rename or drop them)
- `# Core positioning statement`
- `# Value pillars`
- `# Professional methodology and POV` → routes to `references/framework/framework-*.md` sub-files (PLG, GTM, research/docs, growth/B2C, leadership/AI, experience/POV) — never rename or remove them
- `# Proof points bank`
- `# Ideal target opportunities (ICP)`
- `# Career-shift posture`
- `# Domain depth` (add verticals as `##` subsections)
- `# Messaging`
- `# Differentiators`
- `# Anti-positioning`

---

## Section 5 — Motivation Bank: format is load-bearing (DO NOT CHANGE)

The Motivation Bank is the letter-writer's **primary** content and voice source — it loads and uses this section first, ahead of any constructed alternative. Its format is fixed:

- It is a **two-column table** with exactly these headers: `| Tags | Motivation |`.
- **Verbatim rule:** every cell in the **Motivation** column is the user's own voice, kept **word-for-word**. Correct only grammar and spelling. **Never** rephrase, paraphrase, summarize, "clean up," or synthesize a smoother version. The exact wording is the asset — scrappy real beats polished.
- **Tags** are a comma-separated list describing where/when the entry applies in a cover letter — persona, theme, vertical, opener-vs-body, audience. The writer matches tags to the role, then uses the Motivation text verbatim or close to it.
- **There is NO separate "Promoted from Why I Want This Role" section.** Content promoted from the `Why I Want This Role` field is appended here as ordinary tagged verbatim rows, with a source suffix `*(Why I Want This Role — Company, YYYY-MM-DD)*`. Never create or recreate a "Promoted from Why I Want This Role" heading.
- **Growth:** add a new motivation as a **new row appended to the table**. Never merge, rewrite, reorder, or trim existing rows. Never convert this table to prose, bullets, or a different column layout.
