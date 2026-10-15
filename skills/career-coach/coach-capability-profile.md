# Capability profile — generation doctrine (2026-10-15, per the user)

Loaded by the career coach for two invocations only: setup Phase 4 (new user) and the career-data-update mode's "generate my capability profile" request (existing user — upgrade or refresh). Nothing else reads this file. The Prioritization pipeline consumes the profile; it never generates one.

## Why this file exists

Job titles drift. The same work ships under "Product Marketing," "Revenue Enablement," "Go-to-Market Lead," or "Growth" depending on the company and the year, and any user's target-title list goes stale as fast as the market renames things. A real run scored a role at the weaker-fit tier on its title and department alone while two-thirds of its responsibilities were work the user had done for years — the scorer had no title-free view of what she can do. The capability profile is that view: a short, derived, regenerable statement of capabilities in generic discipline vocabulary, so function fit can be scored as responsibility coverage instead of a label match.

The user's own requirement for it: discerning enough that the list is not repetitive, and transferable across roles.

## Inputs

Read, in this order, from `${CAREER_DATA}/references/`: `02-professional-background.md` and every `background/background-*.md` sub-file it routes to (role facts first — they carry the documented work), `03-framework.md` (value pillars, proof points, methodology sub-files), and `linkedin-profile.md` when present. `01-writing-rules.md` governs fabrication: a capability line must trace to documented work in those files, never to an inference about what someone with this history "would" be able to do.

## Output

`${CAREER_DATA}/references/capability-profile.md`, in the format of the plugin's blank template `${CLAUDE_PLUGIN_ROOT}/references/capability-profile.md`: a `Generated:` line, then at most 5 discipline groups (`## <group>`), each holding capability lines (`- <line>`), at most 25 lines in total, at most 20 words per line.

## Procedure

**1. Extract.** From the inputs, list every distinct thing the user has done — one candidate line per activity, in the user's documented scope. Over-collect here; the tests below cut.

**2. Strip to a capability (the transferability test, part one).** Rewrite each candidate with no employer, product, customer, industry, or title in it, in generic discipline vocabulary (positioning, launch, enablement content, lifecycle, ABM, PLG, partner onboarding, technical-to-business translation, documentation suites, and the like). "Wrote the onboarding and training suite for an industrial-sensor distributor network" becomes "Translate technically complex products into material non-technical buyers and partners can act on." Proof stays in the background files; the line carries the capability only.

**3. The three-way test (from the CV skills-section rule).** Keep a line only if it names a capability the user DOES. Cut a line that names knowledge ABOUT a domain ("cybersecurity," "industrial automation") or a title ("founding marketer," "head of marketing"). Domain knowledge belongs in `03-framework.md` §Domain depth, where the coach reads it at intake; it is not a capability and it is not portable.

**4. The portability test (transferability, part two).** For each surviving line, ask: would this read as true on a job description in at least two different functions or industries? A line that only makes sense inside one employer's context, one product category, or one function's jargon is rewritten one level more generic, or cut if that empties it.

**5. The pairwise de-duplication test.** Compare every surviving line against every other. Two lines that describe the same capability at different altitudes ("built launch messaging" / "owned positioning for releases") or in different words collapse into one, at the altitude that still passes the portability test. A capability that recurs across several employers is one line, not one per employer. Run this pass after grouping as well as before — near-duplicates hide in different groups.

**6. Group and cap.** Sort the survivors into at most 5 discipline groups named in generic vocabulary (e.g. "Positioning and messaging," "Enablement and documentation," "Launch and lifecycle," "Research and insight," "Leadership and operating"). Cap the file at 25 lines. If more survive, cut the ones with the thinnest documentation first, never the ones that merely look less impressive.

**7. Self-check before showing the draft** (fail any item → fix, re-run):
- No line contains an employer, product, customer, industry, or title.
- No line is knowledge-about or a title.
- No pair of lines is a near-duplicate (altitude, wording, or per-employer repetition).
- Every line passes the two-functions portability test.
- Every line traces to documented work in the inputs (fabrication rule).
- ≤25 lines, ≤5 groups, ≤20 words per line.

**8. Show the whole draft once, then wait for confirmation (per the user: "drafts the profile fully from background and then asks for final confirmation before packaging").** Present the complete file as one block. Ask for a yes, or line edits. Do not ask line-by-line questions, do not interview, and do not package, write, or generate an update prompt before the user confirms. Apply her edits verbatim (a line she rewrites is hers; do not re-run the tests against her wording), then show the final file once more only if her edits changed more than three lines.

**9. Deliver by invocation:**
- **Setup Phase 4 (new user):** write the confirmed file to the working `career-data/references/capability-profile.md`; it ships with the rest of career-data in the Build & install step; add it to `career-data-marker.json`'s `expected_files`.
- **Career-data-update mode (existing user — upgrade or refresh):** generate the update prompt in the canonical format (`${CLAUDE_PLUGIN_ROOT}/references/career-data-update-prompt-format.md`), targeting `references/capability-profile.md` with the full confirmed content (create or replace the whole file), plus a verification line that the file has no `{{` left and the marker's `expected_files` lists it. Write the prompt under `<output_folder>/_career-data-updates/` with the `capability-profile` topic slug and the date, per the format file's location rule — never inside the plugin repo or the working directory. The user pastes, repackages, and reinstalls through the normal path; this mode never writes career-data directly.

## What this file is not

- Not a CV section, a bio, or letter material. The writers never load it; they read the background files, which hold the proof.
- Not a replacement for `target_titles` in `pipeline-preferences.json`. Sourcing still needs words to search with. Scoring no longer does.
- Not a replacement for the coach's requirements-coverage scoring at intake, which reads the full background and always overwrites the prioritizer's provisional score.
