---
name: cv-self-check
description: Mandatory pre-submission self-check for CV drafts and revisions. Run every item in order before returning any CV output. Covers ATS, summary, key achievements, experience, earlier line, header, and body word count.
---

# CV Pre-Submission Self-Check

Run every item in order before returning output. The gatekeeper runs the same checks — catching violations here prevents loops.

## Role emphasis — run this before ATS

- [ ] Re-read Role emphasis. In one sentence: what does the hiring manager actually need proven by this CV?
- [ ] Does the summary lead with the answer to that question?
- [ ] Are the most prominent bullets (first bullet of first two roles) the strongest evidence for what Role emphasis identified?
- [ ] If Role emphasis calls out a specific function (e.g., developer-facing, brand, team leadership, customer research) — is that function visibly present in the CV, not buried?

## ATS — run this first

- [ ] Keyword coverage: parse the Keywords property into Critical, Important, and Nice-to-have tiers; count coverage per tier (case-insensitive, summary + bullets + skills); Critical ≥80% and Important ≥60% required — incorporate missing terms naturally where possible without fabrication; Nice-to-have is best effort only; do not keyword-stuff
- [ ] SUMMARY and EXPERIENCE headings use standard names recognisable by ATS systems
- [ ] No tables, columns, or special-character bullet markers (✓, →, ◆) in the body

## Summary

- [ ] No company names, conference names, or named clients anywhere in the summary — descriptors only
- [ ] Paragraph 1 establishes the most recent role context with a descriptor, not a company name — acceptable descriptor signals are in `01-writing-rules.md` Section 1
- [ ] Word count is 120 words or fewer, counted explicitly
- [ ] Sentence count is 4 or fewer, counted explicitly
- [ ] Paragraph count is 1 (single paragraph only)
- [ ] No tool names, platform names, client names, or role-specific metrics in the summary
- [ ] None of these phrases appear: "comfortable operating across," "proven track record," "passionate about," "results-driven," "dynamic," "extensive experience"
- [ ] No section header or label sits between the `## SUMMARY` banner and the summary text
- [ ] **Single-instance trap:** For every concrete claim or named activity in the summary, count how many times it appears across the CV body. If a sentence implies a repeated pattern but the CV shows only one instance — that sentence is a bullet wearing a summary's clothes. Move the specific detail to a bullet under the relevant role; replace it with the breadth claim. A dense, em-dash-stuffed sentence in the summary is a structural signal to apply this check.

## Key Achievements block (when present)

- [ ] No two KA bullets reference the same outcome, metric, or achievement — scan for duplicate percentages, duplicate company-specific proof points, or duplicate event references; remove or consolidate any duplicates
- [ ] Each KA bullet is a distinct achievement — not a restatement of an experience bullet in the same document

## Experience

- [ ] `## EDUCATION`, `## LANGUAGES`, and `## ADDITIONAL` do NOT appear anywhere in the output — these sections are already inside {{USER_FIRST_NAME}}'s Word template; writing them here duplicates them in the final DOCX
- [ ] `## EXPERIENCE` contains full-time employment only, in reverse-chronological order per `01-writing-rules.md` Section 1 — consulting/fractional engagements must not appear here
- [ ] `## CONSULTING` section is present and contains the consulting/fractional track record
- [ ] Every named role has a RoleOverview immediately below its RoleTitle — count them; the numbers must match (applies to both EXPERIENCE and CONSULTING sections)
- [ ] No tool or app names inside any experience bullet (exemption: approved bullets from `background-approved-bullets.md` are pre-validated — do not alter them to satisfy this check)
- [ ] Each employer is described using only the approved target market from `01-writing-rules.md` Section 1
- [ ] No opening verb appears 3 or more times across all bullets — tally and fix before returning

## Role tailoring (`writer-craft/cv.md` §5c)

- [ ] `CV_TITLES_PATH` was read. Plan present: every title matches its plan line exactly (the user's standing `cv_title_rules` / legacy `CV Title Preferences` line wins for the same employer); every `Fold` employer has no entry. Plan absent: one disposition derived per employer (default Keep when `MODE: titles`) and stated in the summary line / `cv-changes.md`
- [ ] No title sits above the recorded title's seniority; no employer name or date differs from the role record
- [ ] Every employer in the role record appears as an entry or by name in the aggregation line — count them
- [ ] Every retitled or descriptor entry has at least one bullet showing the titled function
- [ ] When the plan's `Level:` is below her record: execution bullets lead, leadership scope is out of the Summary

## Tools section

- [ ] If the Role Type is Specialist or Builder AND the JD mentions tools or platform proficiency: `## TOOLS` section is present with a relevant selection from `01-writing-rules.md` Section 8
- [ ] If the Role Type is Leader or Scaler, OR the JD does not mention tools: `## TOOLS` section is absent

## Earlier

- [ ] No years on the Earlier line
- [ ] The aggregation line's bold prefix is `Earlier:` only when every folded employer predates the oldest full entry — otherwise `Additional experience:`; never both lines. It names every folded employer and closes with the full-history pointer (§5c)
- [ ] Earlier line appears as the last entry inside `## EXPERIENCE`, immediately before the `## CONSULTING` section header — not after CONSULTING

## Header

- [ ] Output markdown does NOT include `{custom-style="Name"}` or `{custom-style="ContactInfo"}` blocks
- [ ] **ColorEmphasis bracket check:** scan the output for any occurrence of `}{custom-style="ColorEmphasis"}` not preceded by `]`. Every ColorEmphasis span must be written as `[text]{custom-style="ColorEmphasis"}`. A missing opening bracket causes pandoc to render the literal annotation string into the DOCX. Fix any unbracketed spans before returning.

## Body word count

- [ ] Body word count (summary + experience bullets only, excluding banners/titles/dates/skills blocks) is 800 words or fewer — if over, cut the least-relevant bullets from lowest-priority roles before returning
