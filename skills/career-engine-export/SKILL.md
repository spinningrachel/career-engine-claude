---
name: career-engine-export
description: DOCX production rules for the career-engine pipeline. Contains the pandoc conversion protocol, custom-style annotation reference, cover letter styles, and file naming conventions. Load this skill before any DOCX export step in the career-engine pipeline. Both the CV pipeline.
---

# New Application — DOCX Production

This skill governs all DOCX production in the career-engine pipeline. Load it before any DOCX export step. Output files are `.docx`, opened directly in Word. The user exports to PDF before sending.

> **`career-data` data root (R-37).** The personal-data files — `01-writing-rules.md`, `02-professional-background.md`, `03-framework.md`, `linkedin-profile.md`, `pipeline-preferences.json`, `delivered-letters/`, and the user's `.dotx` — load from `${CAREER_DATA}/references/`, the path the orchestrator resolves in its `career-data` discovery preflight. Every other file (self-checks, `REFERENCES.md`, skill docs, default `.dotx` templates) stays on `${CLAUDE_PLUGIN_ROOT}`. If `${CAREER_DATA}` is not set (direct or standalone invocation outside the orchestrator), locate the `career-data` skill yourself, confirm `career-data-marker.json`, and apply the orchestrator's healthy / damaged / absent outcomes before reading. A configured user's missing `career-data` is a hard stop — never silently fall back to blank templates.

**The templates own all fonts, sizes, and colors — never hand-set these.**

---

## How DOCX production works

cv-writer outputs **styled markdown** using pandoc's `custom-style` div and span syntax. The pipeline converts it to `.docx` at Step 6 using pandoc with the `.dotx` reference templates. A short post-processing script then updates the role-specific Subtitle in the CV document header.

**Templates — fixed-path convention, no config key, never an external OS path (2026-07-04 fix).** All templates resolve by fixed filename inside `${CAREER_DATA}/references/templates/` — there is no `cv_template` or `word_templates_path` config key anymore, and the plugin never reads a template from outside career-data:
- `$CV_TEMPLATE` = `${CAREER_DATA}/references/templates/cv.dotx` — CV reference template, **Detailed CV Type**. Contains all custom styles, the user's name and contact info in the document header, and correct formatting throughout.
- `$CV_TEMPLATE_BRIEF` = `${CAREER_DATA}/references/templates/cv-brief.dotx` — CV reference template, **Brief CV Type** (one-page, two-column). Required only when the resolved CV Type for a role is `Brief` — see the CV Type resolution step in `career-engine-new-application/SKILL.md`/`career-engine-edit/SKILL.md`. Never used for a Detailed-type role.
- `$CL_TEMPLATE` = `${CAREER_DATA}/references/templates/cover-letter-template.dotx` — Cover letter reference template. Contains header and styles. **This must resolve from career-data, never from the plugin's own `references/` default** — the plugin's copy is the new-user default only (see `career-engine-setup/SKILL.md`), and using it in place of the user's own personalized template was a real production bug (the cover letter export silently ignored the user's actual template every run).
- `$CV_TEMPLATE_HE` = `${CAREER_DATA}/references/templates/cvHe.dotm` — Hebrew CV reference template (note the `.dotm` extension — this file is macro-enabled, not `.dotx`).
- `$CL_TEMPLATE_HE` = `${CAREER_DATA}/references/templates/he-letter.dotx` — Hebrew cover letter reference template.
- `$CV_FOOTER` = `${CAREER_DATA}/references/static-cv-footer.md` — the static Education/Languages markdown appended to every English CV before pandoc conversion (see Step 3 below). **This must resolve from career-data, never from the plugin's own `skills/career-engine-export/` copy** — same reasoning as `$CL_TEMPLATE` above, and a **confirmed real production bug, not a theoretical one**: `convert-cv.sh` used to hardcode the plugin's own copy of this file for every CV export, and that plugin-shipped copy had accumulated one real user's actual degree/university content — meaning every installation of this plugin was silently appending someone else's real Education/Languages onto every user's exported CV (fixed 2026-07-09). The plugin's own copy is the new-user blank-`{{...}}`-placeholder default only (see `career-engine-setup/SKILL.md`).
- `$CV_FOOTER_HE` = `${CAREER_DATA}/references/static-cv-footer-he.md` — the Hebrew-language equivalent, used only for Hebrew CV export (see the Hebrew production protocol below). Same career-data-only resolution rule as `$CV_FOOTER`.

**`$CV_FOOTER`/`$CV_FOOTER_HE` are conditional on `cv_footer.inject` (2026-07-12 fix) — the only templates in this list that are.** Read `cv_footer.inject` from `pipeline-preferences.json` (default `true` when the key is absent, for configs written before this feature existed). If `true` (the default): resolve both paths as above and require `$CV_FOOTER` to exist, per the paragraph below. **If `false`:** set `$CV_FOOTER=""` and `$CV_FOOTER_HE=""` — do not check for either file's existence, do not stop if they're absent, and pass the empty string through to `convert-cv.sh`/`assemble_brief_cv.py` unchanged. This is for a user who adds Education/Languages herself outside the pipeline (e.g. a personal Word macro run after export) — same "not this pipeline's job" treatment the CV's optional `## ADDITIONAL` section has always had.

Confirm each file exists before use. `$CV_TEMPLATE` and `$CL_TEMPLATE` are always required for any export — if either is missing, stop and report: "career-data is missing `references/<filename>` — run `/career-engine:setup --phase 5` to restore the default templates, or add your own at that path." `$CV_FOOTER` is required **only when `cv_footer.inject` is true** (the default) — same stop-and-report message when missing in that case; never required when `cv_footer.inject` is false. `$CV_TEMPLATE_BRIEF` follows the same required-when-needed rule as the Hebrew templates: if the resolved CV Type for this role is `Brief` and `cv-brief.dotx` is missing, stop and report the same way — never silently fall back to `$CV_TEMPLATE` (that would silently produce a Detailed-shaped document for a role the user explicitly configured as Brief). `$CV_TEMPLATE_HE`/`$CL_TEMPLATE_HE`/`$CV_FOOTER_HE` are optional — if any is missing, Hebrew export for that document type is unavailable; skip it and note it, exactly as the old `word_templates_path`-empty case did.

None of these templates should be read into context. Use them only as pandoc `--reference-doc` arguments.

---

## Prerequisites

- `pandoc` — DOCX conversion
- `python-docx` — subtitle update script (`pip install python-docx`)

---

## Step 6 production protocol

Run these steps in sequence. All bash commands run directly — no agent spawn needed.

**Environment note (R-30):** the commands below assume Path A (direct filesystem access — see the orchestrator's Mandatory path verification). On Path B (sandboxed environment with host-bridge MCP access), run every command in this protocol through the host process tool (e.g. Desktop Commander `start_process`) and write files through the host file tools. Sandbox `/tmp/` is not visible to host-side pandoc — write intermediate markdown through the host tool to the output company directory (or a host temp path) instead.

**Plugin dir:** the directory containing `agents/`, `skills/`, and `references/` — typically the plugin root.

**Output dir:** `{{OUTPUT_FOLDER}}/applications-<YYYY-MM-DD>/`

**Company directory:** Each role's files go in a subdirectory named after the hiring company. The subdirectory name is derived from the Company property: lowercase, spaces replaced with hyphens, non-alphanumeric-or-hyphen characters stripped, consecutive hyphens collapsed. If the result is empty or the company is unknown, use `unknown-company`.

```bash
COMPANY_DIR=$(echo "<company_name>" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//')
[ -z "$COMPANY_DIR" ] && COMPANY_DIR="unknown-company"
```

Examples: `"Acme Corp"` → `acme-corp` · `"Blue Sky"` → `blue-sky` · `"Acme Cybersecurity"` → `acme-cybersecurity`

### 1. Create output directory

```bash
mkdir -p "<output_dir>/<company_dir>"
```

### 2. Write markdown files to /tmp

Save the final CV markdown (from Step 4/4.5) and cover letter markdown (from Step 5) to `/tmp/`:

```
/tmp/<cv_filename>.md
/tmp/<cl_filename>.md
```

Filename convention: lowercase, no spaces, hyphens between words, `.md` extension.

### 3. Convert with pandoc

**Select the CV template path first — conditional on the resolved CV Type for this role** (read from `$PIPE/cv-type.txt`, written by the resolution step earlier in the pipeline; never re-derived here):

```bash
if [ "<resolved CV Type>" = "Brief" ]; then
  CV_TEMPLATE_FOR_EXPORT="$CV_TEMPLATE_BRIEF"
else
  CV_TEMPLATE_FOR_EXPORT="$CV_TEMPLATE"
fi
```

**Detailed — run the conversion script (unchanged):**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/career-engine-export/scripts/convert-cv.sh" \
  "/tmp/<cv_filename>.md" \
  "/tmp/<cl_filename>.md" \
  "<output_dir>/<company_dir>" \
  "$CV_FOOTER" \
  "$CV_TEMPLATE_FOR_EXPORT" \
  "$CL_TEMPLATE"
```

`$CV_TEMPLATE_FOR_EXPORT` (arg 5) resolves to either `$CV_TEMPLATE` (`cv.dotx`) or `$CV_TEMPLATE_BRIEF` (`cv-brief.dotx`) per the conditional above — `convert-cv.sh` itself needs no change for this; it already takes the template path as a plain positional argument, so only this caller-side resolution differs by CV Type. `$CL_TEMPLATE` (arg 6) is the resolved `.dotx` path from `${CAREER_DATA}/references/templates/` (fixed filename `cover-letter-template.dotx` — no config key, see the Templates section above). The personal templates live in career-data, not the plugin (R-37). The script fails fast if either is missing. (R-42 — the script previously hardcoded a literal `{{USER_DOTX_FILE}}.dotx` and a stale export-skill footer path, which broke every export. **2026-07-04 fix:** arg 6 added — the script previously hardcoded the plugin's own default `references/cover-letter-template.dotx` for every cover letter export, silently ignoring the user's actual personalized template every run.)

Pandoc inherits the header/footer from the reference template. The user's name and contacts appear automatically. Only the Subtitle (role tagline) needs updating per role.

**Brief — the CV skips pandoc entirely; only the cover letter goes through it (2026-07-10 fix — see the Brief annotation reference below for why).** `convert-cv.sh` is never called for a Brief role — pandoc's DOCX table writer cannot represent this template's nested/merged-cell layout, full empirical record below. Convert the cover letter directly, with the same two-line pandoc invocation `convert-cv.sh` already uses internally for the cover letter half:

```bash
pandoc "/tmp/<cl_filename>.md" \
  --reference-doc="$CL_TEMPLATE" \
  -o "<output_dir>/<company_dir>/<cl_filename>.docx"
```

Then assemble the CV directly with `assemble_brief_cv.py`. This one call fully replaces both this step's CV conversion AND Step 4's Subtitle update for Brief — the script writes the role tagline directly into the table's row-0 cell in the same pass, since Brief's name/tagline live in the table, not a document-header paragraph:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/career-engine-export/scripts/assemble_brief_cv.py" \
  --cv-md "/tmp/<cv_filename>.md" \
  --cv-footer "$CV_FOOTER" \
  --template "$CV_TEMPLATE_FOR_EXPORT" \
  --output "<output_dir>/<company_dir>/<cv_filename>.docx" \
  --name "<user's full name>" \
  --tagline "<role title>" \
  --contact "<contact line>" [repeat --contact once per line — city/country, phone, email, site, LinkedIn]
```

**Where each value comes from — none of it is cv-writer's own markdown, same convention as Detailed's template-baked header contact:**
- `--cv-md` / `--cv-footer` / `--template` / `--output` — the same paths already resolved earlier in this step and in the Templates section above.
- `--name` and `--contact` — the user's identity/contact values, resolved from career-data (`01-writing-rules.md` §8, R-37) exactly like every other identity placeholder this pipeline already resolves. Never parsed from cv-writer's markdown, which never emits them.
- `--tagline` — **the exact same resolved role-title value** Step 4 passes to `update-subtitle.py` for Detailed: same source, same verbatim-JD-title rule, just written into a table cell instead of a header paragraph.
- `--additional` — **omit this flag.** No property in this pipeline resolves an "Additional" value today, for either CV Type — Detailed's own `## ADDITIONAL` is added later by the user's own Word macro, post-export, never by this pipeline (see the annotation reference below). `assemble_brief_cv.py` omits the ADDITIONAL heading and content entirely when the flag isn't passed. This is a pre-existing gap, not a regression introduced by this fix.

The script parses `<cv_filename>.md` itself (cv-writer's own linear markdown — skills/summary/roles) and `$CV_FOOTER` (education/languages) via pandoc's JSON AST, and fails loudly (`RuntimeError`) if it can't find at least one role, rather than silently producing an empty Experience table.

### 4. Update the Subtitle in the CV header — Detailed only

**Brief: skip this step entirely.** The tagline is already written by Step 3's `assemble_brief_cv.py` call, directly into the table's row-0 cell — there is no document-header Subtitle paragraph to update for Brief.

Run the subtitle script on the file in the output directory (convert-cv.sh writes DOCX directly to output_dir, not /tmp):

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/career-engine-export/scripts/update-subtitle.py" \
  "<output_dir>/<company_dir>/<cv_filename>.docx" \
  "<role title>"
```

**The subtitle MUST be the exact job title the user is applying for — taken verbatim from the JD.** Examples: e.g., "Head of Marketing", "Senior Software Engineer", "Director of Product Design". NOT a generic descriptor. NOT the user's background framing. The role title. Full stop.

The cover letter header does not need a subtitle update.

### 5. Verify

```bash
ls -lh "<output_dir>/<company_dir>/<cv_filename>.docx"
ls -lh "<output_dir>/<company_dir>/<cl_filename>.docx"
```

Both files must exist and be nonzero before proceeding.

### 6. Page count check

```bash
pandoc "<output_dir>/<company_dir>/<cv_filename>.docx" -t plain | wc -w
```

This gives a plain-text word count of the full rendered document (including all headers, titles, dates, and body). **Thresholds branch by CV Type — a Brief CV's one-page target is a materially tighter constraint than Detailed's.**

**Detailed:** the user's CV is senior-level with a full work history — a clean 2-page document is normal and expected. Thresholds are calibrated accordingly:
- **Under 1050 words** — proceed to Notion writeback.
- **1050–1350 words** — likely 2 dense pages; proceed but flag in the chat summary: "CV word count at [N] — confirm 2-page fit before sending."
- **Over 1350 words** — likely over 2 pages. Return to cv-writer with: "CV plain-text word count is [N] after DOCX conversion, indicating likely overflow beyond 2 pages. Cut bullets from the lowest-priority roles to bring body word count under 1000."

**Brief:** apply the single total-body word-count backstop ceiling from `writer-craft/cv.md` §5b instead (a one-page target, not a 2-page one — do not apply Detailed's thresholds above to a Brief CV). If over the ceiling, return to cv-writer with: "Brief CV plain-text word count is [N] after DOCX conversion, over the one-page backstop ceiling — fold more roles into the `Earlier:` line or tighten bullet density (`writer-craft/SKILL.md` §5b's one-page-fit judgment principle)."

After cv-writer returns a revised draft, re-run the full export protocol from Step 2. One revision pass only — if still over threshold after one pass, proceed and flag in the chat summary.

### 7. Generate Draft Directory URL

After both files are verified, construct the Draft Directory URL for this role's directory. Hold it in memory — the pipeline writes it to the `Draft Directory` Notion property in the writeback step.

```bash
DATE_FOLDER=$(basename "<output_dir>")  # e.g. applications-2026-05-26
DRAFT_DIR_URL="{{DRAFT_DIR_URL_BASE}}${DATE_FOLDER}%2F${COMPANY_DIR}%2F"
```

**Unconfigured link base guard:** if `$DRAFT_DIR_URL_BASE` (from the career-data config key `draft_dir_url_base`) is empty, unset, or the word `skip`, leave the `Draft Directory` property empty and continue — do not write a malformed URL.


Example: `{{DRAFT_DIR_URL_BASE}}applications-2026-05-26%2Fnorthwind%2F`

---

## File naming conventions

All filenames are lowercase, no spaces, hyphens between words. Extension is `.docx`. **Unchanged by CV Type** — a Brief CV uses the same `cv-...` filename pattern as Detailed; one CV is produced per role regardless of type, so there is no naming collision to resolve.

- CV: `cv-<last-name>-<roletitle>-<company>-<monYYYY>.docx`
- Standard cover letter: `coverletter-<last-name>-<roletitle>-<company>-<monYYYY>.docx`
- Hebrew CV: `he-cv-<last-name>-<roletitle>-<company>-<monYYYY>.docx`
- Hebrew cover letter: `he-coverletter-<last-name>-<roletitle>-<company>-<monYYYY>.docx`
- Reviewer feedback: `feedback-<roletitle>-<company>-<monYYYY>.md`
- Revision log (per role): `revision-log-<roletitle>-<company>-<monYYYY>.md`
- Revision log (per run): `revision-log-<YYYY-MM-DD>.md`
- State file: `state.json`

Example: `cv-<last-name>-[role-title]-[company]-[mon-year].docx` / `revision-log-[role-title]-[company]-[mon-year].md`

---

## Hebrew DOCX production protocol

Hebrew DOCX files are produced inline in Step 6H (Standard/Edit pipelines). This section documents the bash steps for reference — they are spelled out in full in each pipeline skill.

**Footer:** Hebrew CVs use `$CV_FOOTER_HE` = `${CAREER_DATA}/references/static-cv-footer-he.md` (Hebrew-language Education and Languages sections) instead of `$CV_FOOTER`. Fixed path, no config key, career-data only — same resolution and same 2026-07-09 fix rationale as `$CV_FOOTER` in the Templates section above. Conditional on `cv_footer.inject` exactly like `$CV_FOOTER` (2026-07-12 fix, see the Templates section above) — empty when `false`, in which case the pipeline skips the concatenation below entirely rather than passing an empty path to `cat`.

**Hebrew templates:** Two dedicated templates exist for Hebrew output — both live in `${CAREER_DATA}/references/templates/`, fixed filenames, no config key and no external OS path (2026-07-04 fix — this used to point at an external, machine-specific Office templates folder via the now-removed `word_templates_path` config key):

- `$CV_TEMPLATE_HE` = `${CAREER_DATA}/references/templates/cvHe.dotm` — Hebrew CV reference template. **Note the `.dotm` extension** (macro-enabled) — not `.dotx`.
- `$CL_TEMPLATE_HE` = `${CAREER_DATA}/references/templates/he-letter.dotx` — Hebrew cover letter reference template.

If `$CV_TEMPLATE_HE`/`$CL_TEMPLATE_HE` is missing, Hebrew export for that document type is unavailable; skip it and note it. `$CV_FOOTER_HE` follows `cv_footer.inject` (see the Footer note above) — when `cv_footer.inject` is `false` it's expected to be empty/absent and never blocks Hebrew export; when `true`, a missing `$CV_FOOTER_HE` only makes Hebrew export unavailable the same way a missing `$CV_TEMPLATE_HE`/`$CL_TEMPLATE_HE` would (it's optional at preflight, per the Templates section above — the run isn't stopped for it, only Hebrew output for that role is skipped).

Both Hebrew templates support RTL formatting. Use `--reference-doc` with these templates — do not use pandoc's default template for Hebrew output.

**YAML front matter:** Hebrew markdown files must include the following front matter at the very top (before any content). The localization agent includes this in its output. Do not strip it:

```yaml
---
dir: rtl
lang: he
---
```

**Conversion steps for Hebrew CV:**

```bash
# $CV_TEMPLATE_HE resolved from ${CAREER_DATA}/references/templates/cvHe.dotm (fixed path, no config key)

# 1. Concatenate Hebrew CV markdown with Hebrew footer (if injecting)
# $CV_FOOTER_HE resolved from ${CAREER_DATA}/references/static-cv-footer-he.md (fixed path, no config key)
# $CV_FOOTER_HE is empty when cv_footer.inject is false -- skip the append entirely in that case
if [ -n "$CV_FOOTER_HE" ]; then
  cat /tmp/he-<cv_filename>.md \
      "$CV_FOOTER_HE" \
      > /tmp/he-<cv_filename>-with-footer.md
else
  cp /tmp/he-<cv_filename>.md /tmp/he-<cv_filename>-with-footer.md
fi

# 2. Convert with pandoc using Hebrew CV template
pandoc /tmp/he-<cv_filename>-with-footer.md \
  --reference-doc="${CV_TEMPLATE_HE}" \
  -o "<output_dir>/<company_dir>/he-cv-<last-name>-<roletitle>-<company>-<monYYYY>.docx"

# 3. Update subtitle
python3 "${CLAUDE_PLUGIN_ROOT}/skills/career-engine-export/scripts/update-subtitle.py" \
  "<output_dir>/<company_dir>/he-cv-<last-name>-<roletitle>-<company>-<monYYYY>.docx" \
  "<role title>"
```

**Conversion steps for Hebrew cover letter:**

```bash
# $CL_TEMPLATE_HE resolved from ${CAREER_DATA}/references/templates/he-letter.dotx (fixed path, no config key)

pandoc /tmp/he-<cl_filename>.md \
  --reference-doc="${CL_TEMPLATE_HE}" \
  -o "<output_dir>/<company_dir>/he-coverletter-<last-name>-<roletitle>-<company>-<monYYYY>.docx"
```

All files save to the role's company subdirectory:
`{{OUTPUT_FOLDER}}/applications-<YYYY-MM-DD>/<company_dir>/`

---

## CV — custom-style annotation reference

cv-writer uses pandoc's div/span syntax to apply Word custom styles. The `.dotx` template owns all formatting. Never add inline font, size, or color in the markdown.

### Section banners → Heading 2 (no annotation needed)

Standard `##` headings map automatically to the `Heading 2` style from the template:

```markdown
## SUMMARY
## SKILLS & EXPERTISE
## EXPERIENCE
## CONSULTING
## TOOLS          ← optional; include only when JD specifies relevant tools
```

**Never include in cv-writer output:** `## EDUCATION`, `## LANGUAGES`, `## ADDITIONAL` — these are injected automatically by the user's Word macros after DOCX export. They must not appear in the markdown passed to pandoc. If they appear, the macro will duplicate them in the final document.

### Summary paragraphs → Normal (no annotation needed)

Regular markdown paragraphs use the `Normal` style automatically:

```markdown
[Example — your summary paragraph goes here. Typically 1–2 sentences establishing your function and value proposition.]
```

### Builder / Leader competencies line → Normal (no annotation needed)

Plain paragraph, pipe-separated. No annotation:

```markdown
[Example — pipe-separated list of your core competencies]
```

### RoleTitle

```markdown
::: {custom-style="RoleTitle"}
Head of [Function] | [Company Name]{custom-style="ColorEmphasis"} | {{USER_CITY}}, {{USER_COUNTRY}} | [Start] -- [End]
:::
```

Notes:
- Company name uses the `ColorEmphasis` inline span for one word/phrase
- **ColorEmphasis bracket rule — MANDATORY:** The span MUST be written as `[Company Name]{custom-style="ColorEmphasis"}` — square brackets around the text, curly braces after. Writing `Company Name{custom-style="ColorEmphasis"}` (no brackets) is a hard error: pandoc renders the literal text `{custom-style="ColorEmphasis"}` into the DOCX instead of applying the style.
- Dates (after the last `|`) are NOT italicized — verified against both live templates (`cv.dotx` Detailed and `cv-brief.dotx` Brief), the `RoleTitle` style already renders the entire line bold in a single color with no per-run italic; no markdown emphasis is applied or needed
- Use `--` for en-dashes in date ranges
- **Detailed only: the whole rendered line (`Title | Company | City | Dates`, markup not counted) is 95 characters or fewer** — the gatekeeper's Gate 2 enforces it; shorten the title, not the dates

### RoleOverview

```markdown
::: {custom-style="RoleOverview"}
[Example — one sentence: company context and your scope, e.g. "B2B SaaS platform; sole [function] hire from founding through Series B, owning all GTM and content."]
:::
```

One sentence. No bold or italic markup — the style handles formatting. **Detailed only: 120 characters or fewer** (one short clause of company context + scope; Gate 2 enforces it).

### RoleActivitiesList bullets

```markdown
- ::: {custom-style="RoleActivitiesList"}
  [Example — outcome-first bullet: what changed, with metric or named result, because of your work.]
  :::

- ::: {custom-style="RoleActivitiesList"}
  [Example — outcome-first bullet: what you built or delivered, with scope or named outcome.]
  :::
```

For a role with a single bullet, use `RoleActivitySingle` instead:

```markdown
::: {custom-style="RoleActivitySingle"}
[Example — single-bullet role entry, e.g. "Fractional [function] for seed-stage SaaS clients; engagements kept open alongside full-time roles."]
:::
```

### Skills section — Scaler / Specialist (categorized block)

```markdown
::: {custom-style="SkillsHeading"}
Strategy & GTM
:::

::: {custom-style="Skills"}
Product positioning | Go-to-market strategy | ICP development | Competitive intelligence | Sales enablement
:::

::: {custom-style="SkillsHeading"}
Leadership
:::

::: {custom-style="Skills"}
[Example — pipe-separated skills for this category, e.g. "Team building | Cross-functional alignment | Board reporting"]
:::
```

### ColorEmphasis inline span

Use for company name in RoleTitle — ONE word or phrase per line, maximum:

```markdown
[Company Name]{custom-style="ColorEmphasis"}
```

### Earlier line (collapsed older roles)

```markdown
**Earlier:** [Company A], [Company B], [Company C]. Full history on LinkedIn.
```

Plain `Normal` style paragraph. "Earlier:" is bolded with standard markdown `**bold**`. **The same line carries the roles the role-tailoring plan folds (`writer-craft/cv.md` §5c):** when any folded employer is more recent than the oldest full entry, the bold prefix is `**Additional experience:**` instead — same paragraph, same position, same styling, never both lines. (`assemble_brief_cv.py` treats the one top-level paragraph inside `## EXPERIENCE` as this line whatever its prefix, so no script change is involved.) For Brief, this line closes out `## EXPERIENCE` directly (there is no `## CONSULTING` to sit between it and the rest of the document) — see the Brief annotation reference below.

---

## CV — custom-style annotation reference — Brief variant

**Two-column sidebar assembly (2026-07-10 fix) — the pandoc-table approach below is empirically ruled out; the actual mechanism is `skills/career-engine-export/scripts/assemble_brief_cv.py`, invoked at Step 6/Step 3 above.** The findings that ruled out a pandoc-table approach are kept below as the record of why this design was chosen — read them before touching the assembly script or this section, since a future edit that tries to route Brief content back through pandoc's table writer will hit the exact same wall.

**Empirically CONFIRMED against a real build — plain pandoc markdown cannot produce the two-column sidebar layout.** Two mechanisms were tested against a real `cv-template-brief-default.dotx` build (python-docx, with `RoleTitle`/`RoleActivitySingle`/`SkillsHeading`/`Skills`/`ColorEmphasis` custom styles defined, converted with `pandoc --reference-doc`):

1. **Pipe table with `::: {custom-style="..."}` div content in cells** — pandoc's pipe-table parser requires strictly single-line cell content and a `|---|---|` header separator row; multi-line block content (headings, divs) inside a cell is not parsed as a table at all — the whole block silently degrades to one literal-text paragraph, with every `|` and `:::` character rendered as visible text. **Confirmed broken.**
2. **Grid table (`+---+---+` ASCII-art borders) with block content in cells** — pandoc's grid-table parser IS designed for multi-paragraph cell content in principle, but requires the border and content rows to be exactly character-aligned to the declared column widths; a real test with hand-authored grid syntax failed to parse as a table at all (same literal-text degradation as the pipe table). Even if a perfectly-aligned grid table can be made to work, **requiring an LLM writer agent to hand-align ASCII-art table borders character-for-character, every draft and every revision, is not a reliable content-generation target** — a single misaligned dash silently breaks the whole layout with no error, exactly as observed in testing.

**What did work, confirmed in the same test:** `RoleTitle`, `RoleActivitySingle`, and `ColorEmphasis` div/span annotations applied correctly (verified via the rendered DOCX's `w:pStyle`/`w:rStyle` references) when used in normal linear (non-table) markdown — identical to how they already work for Detailed. The problem is specifically the two-column table wrapper, not the annotation system itself.

**Real per-role rows, not a single flowing sidebar/main split — confirmed 2026-07-09 against a revised `brief-default.dotx` with the actual production table structure.** The template's own worked example uses a single Word table, **N+3 rows × 3 columns**, where N = the number of individually-listed roles:
- **Column 0 — the sidebar — vertically merged across every row.** One cell spans the full table height: Contact details, Skills, Languages, Additional, and **Education** (all five, not just Skills — Education has moved out of the shared bottom-of-document footer and into the sidebar for Brief specifically; see the note on `$CV_FOOTER` below).
- **Rows 0–2 — horizontally merged across columns 1+2, full width:** row 0 = Name + Tagline (header), row 1 = the Profile Summary paragraph, row 2 = the `## EXPERIENCE` section banner.
- **Rows 3 through 3+N−1 — one row per named role, split into two real sub-columns:** column 1 (narrow) holds **only the date range**, styled `RoleActivitySingle`; column 2 (wide) holds the `RoleTitle` line — **now WITHOUT a date, just `Title | Company | Location`** — followed by that role's bullets, each its own `RoleActivitySingle` div (never `RoleActivitiesList` — Brief has no such style; every activity line, including every bullet of a multi-bullet role, is its own separate `RoleActivitySingle` paragraph, confirmed against the template's actual style definitions and the delivered worked example).

**This table shell is the template's OWN body content — it is not what pandoc's `--reference-doc` mechanism gives cv-writer for free.** `--reference-doc` only borrows **styles** (`styles.xml`) from the reference file; it does not copy the reference file's own document body, tables, or example text into pandoc's output (confirmed by direct test: converting linear markdown against this exact template produces a linear, single-column result — zero tables — even though the template file itself contains one). The table above is the **design target** that `assemble_brief_cv.py` (below) builds directly via python-docx — it does not happen automatically from pandoc conversion.

**Implemented mechanism (2026-07-10) — `skills/career-engine-export/scripts/assemble_brief_cv.py`.** cv-writer does NOT emit a pandoc table at all — it never has for Brief, and this fix didn't change that:
1. cv-writer outputs Brief content as ordinary **linear, single-column markdown** (exactly like Detailed), using the `<!-- SIDEBAR -->` ... `<!-- /SIDEBAR -->` HTML-comment markers around the `## SKILLS` block, plus a per-role date line immediately following each `RoleTitle` div (its own `RoleActivitySingle` div) so the script can tell which line is the date vs. the first bullet. This is unchanged from before this fix — cv-writer's doctrine (`writer-craft/SKILL.md` §5b, `agents/cv-writer.md`) already specified this exact format; the gap was purely on the assembly side.
2. `assemble_brief_cv.py` builds the table shell (1 vertically-merged sidebar cell spanning all rows, 3 horizontally-merged full-width header/summary/heading rows, then one two-column row per role) by opening the **actual** `cv-brief.dotx` template directly with python-docx and writing each portion's paragraphs into the correct cell, preserving custom styles — no markdown, no pandoc round-trip for the CV. It parses cv-writer's own markdown and `$CV_FOOTER` via **pandoc's JSON AST** (not regex) to build the data it needs: `pandoc -f markdown -t json` on the raw source markdown sidesteps the line-wrapping corruption that broke the annotation-only approaches above, because that corruption only ever showed up on a pandoc-rendered/re-wrapped round trip — parsing cv-writer's original markdown directly never hits it. **For Brief specifically, `$CV_FOOTER`'s Education and Languages content routes into the sidebar cell** (Languages' multiple footer lines are joined into the sidebar's single flat `Skills`-styled paragraph, matching the template's own convention; Education stays one paragraph per degree, also matching the template) — rather than appending after `## EXPERIENCE` the way Detailed's flat document does. Both CV Types read the same shared `$CV_FOOTER` source content; only the placement differs.
3. Role-row count is fully dynamic — the script clones or removes `<w:tr>` elements to match however many roles are passed, relocating the sidebar's closing bottom border to whichever row ends up last. Tested against the real template growing to 6 roles and shrinking to 1 (`skills/career-engine-export/scripts/test_assemble_brief_cv.py`).
4. Step 6 of the production protocol calls this script for Brief roles in place of `convert-cv.sh`'s CV half and `update-subtitle.py` (see Step 3/Step 4 above) — the cover letter still converts through a plain pandoc call, unaffected.

**⚠ Scope — this ONLY works against the default template or a cosmetic derivative of it.** `assemble_brief_cv.py` hard-codes the exact table shape shown above: specific rows/columns, specific merged cells (row 0 and row 2 gridSpan across columns 1-2; column 0 vertically merged from row 1 down), and specific named styles (`RoleTitle`, `RoleActivitySingle`, `SkillsHeading`, `Skills`, `PersonalDetails`, `ColorEmphasis`, `Heading 1`, `Subtitle`, `Heading 2`, `Normal`). It is safe against a personalized `cv-brief.dotx` **only** when the user changed fonts, colors, spacing, or alignment and left the table's rows/columns/merges and style names alone. It is **not** safe against a template where the table itself was restructured (rows or columns added/removed, merges changed, styles renamed or deleted) — the script cannot fill a different shape. `career-engine-setup/SKILL.md`'s "Document templates" step warns the user about this explicitly before she supplies her own file, and `validate_template_structure()` in the script itself fails loudly with a specific, itemized error (never a silent misrender, never an opaque python-docx exception) if a template reaches export time with a shape or missing style the script doesn't recognize — see the negative test in `test_assemble_brief_cv.py`.

**Two implementation findings worth keeping in mind if this script is ever touched:**
- **python-docx's `Document()` rejects a `.dotx` outright** — it checks the main part's content type (`...wordprocessingml.template.main+xml` for a `.dotx`, `...document.main+xml` for a `.docx`), not the file extension, and raises `ValueError` on the template content type. `assemble_brief_cv.py`'s `load_docx_or_dotx()` patches the `[Content_Types].xml` override in memory (no temp file) before handing the bytes to python-docx — this is required, not optional; confirmed by testing directly against the shipped `cv-brief.dotx`.
- **Some template paragraphs wrap their run in a `<w:hyperlink>` element** (e.g. the sidebar's website line) that `python-docx`'s `paragraph.runs` does not see. Clearing only `p.runs` before rewriting a reused paragraph left the old hyperlink text behind, silently concatenated onto the new content. `set_cell_paragraphs()` clears every child of the paragraph except `pPr` instead.

**Known, pre-existing gap, not introduced by this fix: no pipeline value resolves "Additional" content for either CV Type.** Detailed's `## ADDITIONAL` is added later by the user's own Word macro, post-export — the automated pipeline has never produced it. `assemble_brief_cv.py` accepts an optional `--additional` value and omits the ADDITIONAL heading and content from the sidebar entirely when it isn't supplied, the same way `## TOOLS`/`## PUBLICATIONS` are omitted when there's no qualifying content.

### Content annotations — Skills (sidebar) and Profile Summary / Experience (main column)

The content on each side uses ordinary annotations. **Education is never part of cv-writer's own markdown output for Brief, same as Detailed** — it comes from `$CV_FOOTER` (see the Templates section above), concatenated by the pipeline, not authored here:

```markdown
<!-- SIDEBAR -->
::: {custom-style="SkillsHeading"}
SKILLS
:::

::: {custom-style="Skills"}
[Example — one flat pipe-separated or line-per-skill list; no Role-Type-driven categorization, unlike Detailed's Scaler/Specialist categorized blocks]
:::
<!-- /SIDEBAR -->

## PROFILE SUMMARY

[Example — your profile paragraph, tighter than Detailed's summary; see writer-craft/cv.md §5b for the word-count backstop]

## EXPERIENCE

::: {custom-style="RoleTitle"}
Head of [Function] | [Company Name]{custom-style="ColorEmphasis"} | Location
:::

::: {custom-style="RoleActivitySingle"}
[Start] -- [End]
:::

::: {custom-style="RoleActivitySingle"}
[Example — short, condensed bullet]
:::

::: {custom-style="RoleActivitySingle"}
[Example — a second bullet for the same role, still its own RoleActivitySingle div, never a RoleActivitiesList bullet]
:::

**Earlier:** [Company A], [Company B], [Company C]. Full history on LinkedIn.
```

**RoleTitle no longer carries a date for Brief** — it is `Title | Company | Location` only (Detailed's RoleTitle is unaffected and still ends with the date range). The date is its own `RoleActivitySingle` div, immediately after `RoleTitle` and before the first bullet — this is the line `assemble_brief_cv.py` recognizes as the date (the first `RoleActivitySingle` div after a `RoleTitle`) and routes into the narrow date column; every `RoleActivitySingle` div after it is a bullet, routed to the wide title-and-bullets column instead.

Contact details (phone, email, location, site) are template-header content or the first table cell's fixed content, same convention as Detailed's header/contact info — cv-writer never writes them. (The photo, if the user's template includes one, is baked into the `.dotx` template directly — cv-writer never generates or inserts an image; see `pipeline-preferences.json` → `cv_type.brief_has_photo`.) **No `RoleOverview` annotation is ever used here** — Brief has no RoleOverview line at all (`writer-craft/SKILL.md` §5b). The `**Earlier:**` line is the last element inside `## EXPERIENCE`, not a separate section.

---

## Cover letter — custom-style annotation reference

```markdown
::: {custom-style="Salutation"}
Hi to the [Company name] team!
:::

Body paragraphs are regular markdown paragraphs (Normal style — no annotation needed).

[Full Name]{custom-style="Signature Char"}
```

---

## Cover letter approach and styles

### Word count and structure

All cover letters are limited to a single page, maximum 320 words with no minimum (not counting greeting or sign-off) — or 250 when the role's `Strategy = Strategic`. This matches the requirement in `skills/writer-craft/SKILL.md` and the gatekeeper check. Structure and voice are consistent across all letters and follow the framework below.

### Voice constraints

**Load `skills/writer-craft/letter.md` before writing any cover letter.** It defines writing mechanics, letter structure, use-case patterns, forbidden phrases, forbidden structures, and fabrication traps. Non-negotiable.

Every claim about the company must be traceable to the JD or brief. Do not infer the company's strategy, culture, or operating model from category signals. If a sentence about them cannot be sourced, cut it or rewrite it as an observation about the role.

The register is direct, specific, and confident. Energy is genuine, not performed. Warmth comes from the closing line.

The user writes about what she does, not what she avoids. Frame capability through action, not through the failure mode it prevents.

The user can express genuine interest when it is real: "I have wanted to work at X for years," "the work you are doing on Y is exactly where I want to be." Use only when true — not as a default opener.

What stays prohibited is unverifiable claims about the company itself — its strategy, uniqueness, or character. The test: if the sentence makes a claim about the company, it needs sourcing. If it makes a claim about the user's motivation, she is the source.

Do not reach for cleverness. If a line calls attention to its own phrasing, cut it.

### Cover letter framework

**Before writing:** Read the Company self-characterization section from the structured JD. This "good fit / not a good fit" or "you'll thrive here if" section is the most honest signal of what they're actually selecting for. Mirror it — not by copying it, but by demonstrating the user matches the positive signals with a specific named proof.

#### Structure, in order

**1. The opening move.** One of two things, both in first person — the opening paragraph is always the user speaking first:
- The user's genuine reaction to something specific about this role: what she recognizes, what excites her, what maps directly to work she has done. Name the role signal, then name the candidate's proof. The worked examples all follow this pattern.
- Genuine first-person interest in this specific company, when the user actually feels it. Use only when real.

Observations about the company's product, buyers, or market position belong in paragraph 2 or later. Do not open with second-person sentences — "Your buyers are technical," "Your product does X" — regardless of how accurate they are.

**2. Signalling business understanding.** A concrete observation about the company's operating model, the problem they are hiring to solve, or the structural reality of the role. Sourced from the JD. Specifics over adjectives. May fold into the opening paragraph when both beats read naturally as one.

**3. The positioning move.** Which part of the user's documented experience maps directly to what they need, and why. One named company, one named outcome.

**4. Handling adjacent or smaller-scale experience.**

THE NUMBER ONE GOLDEN RULE: COVER LETTERS ARE THE CANDIDATE'S OPPORTUNITY TO SHINE. LEAD WITH THEIR MOST RELEVANT BIGGEST STRENGTHS. NEVER PRE-EMPTIVELY EXPLAIN OR QUALIFY ANYTHING. ONLY LEAD WITH WHAT SHE HAS DONE AND NAME THE SPECIFICS THAT MAP TO WHAT THEY ARE HIRING FOR.

- Different domains and verticals are NEVER a gap and especially not a weakness.
- If there is any *perceived skill* gap the hiring manager will clock in the first 10 seconds, name the work she has done, let it stand. Do not add a scope qualifier. Lead with what was done, name the specifics, and stop.
- Do NOT volunteer scale they did not ask about. The phrasing pattern: "On the X side, I have run Y for a handful of Z clients — [named example] is one I can name. The work covered..."

**WRONG — never use these structures:**
- "The scale is different from X COMPANY — but..."
- "The closest I've worked to X is Y..."

**5. The closing posture.** A direct ask, not a request for permission. Warm or plain depending on the letter's tone. Never "I look forward to hearing from you at your earliest convenience."

### Prohibited phrasing (in addition to writer-craft skill rules)

- Never open or close with a fit claim: "This role has my name on it," "I'm the perfect candidate," "I was made for this role"
- Never volunteer a title gap — scope speaks for itself; that conversation is for the interview
- "Full disclosure" followed by a gap apology — banned
- "Whether that's the fit you need" — banned
- Never ever use "is worth naming" or "is worth calling out" — if it's worth naming, name it directly without the framing!!
