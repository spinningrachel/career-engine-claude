---
name: career-engine-setup
description: >
  Onboarding wizard for the career-engine plugin. Triggered when the user
  runs /career-engine:setup, says "set up the plugin", "start onboarding",
  "configure the plugin", "initialize my profile", "I just installed this",
  or any variant asking to get the plugin ready to use.
  Collects existing career materials, synthesizes framework.md, conducts
  a targeted interview to fill gaps, then configures job tracking and
  output paths. Run once; re-run any phase any time to update it.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - TodoWrite
  - WebFetch
---

# Career Engine Onboarding

> **Registry:** this pipeline is listed in the Pipeline Registry in `skills/career-engine/SKILL.md`. Actions owned by another pipeline's registry row are out of scope here — route to that pipeline instead of improvising.

This skill sets up the plugin for a new user. It builds the three reference files that all pipeline agents read before writing anything:

- `01-writing-rules.md` — fabrication guards, attribution rules, framing constraints, contact details
- `02-professional-background.md` — role facts, approved content, portfolio
- `03-framework.md` — positioning, voice, methodology, domain narratives

**Output target — the `career-data` skill, not in-plugin references (R-37).** Setup builds these files into the user's external `career-data` skill, not into the plugin's `references/`. Author the data files (`01/02/03`, `linkedin-profile.md`, `pipeline-preferences.json`, `delivered-letters/`, and the user's `.dotx`) into a working `career-data/` skill directory as you go. **Installing that directory as a real skill is environment-specific and is the single step that most often goes wrong** — follow [`references/career-data-skill-handoff.md`](../../references/career-data-skill-handoff.md) (a.k.a. "Appendix A"): in **Cowork**, you cannot save a skill directly, so you emit a `/skill-creator` handoff prompt the user pastes into **Chat** (skills are shared between Chat and Cowork, so it lands in both); in **Claude Code**, you write `~/.claude/skills/career-data/` directly. The dedicated **Build & install** step at the end of this skill runs that handoff. Write the first backup export of `career-data` to the output folder. The plugin's in-plugin `references/` stay as blank `{{...}}` templates — never personalized.

**Placeholder resolution (single-build).** Identity and config values are NOT substituted into the plugin's agent/skill/reference files — that would personalize the shared build. They live in `career-data` and agents resolve them at runtime: identity from `career-data` `01-writing-rules.md` §8, output folder and CV template from the `career-data` config (see CLAUDE.md → *Placeholder resolution*). Every step below writes these values into `career-data`, never into plugin files.

**How onboarding works:** You send your existing career materials. The agent reads them and synthesizes `03-framework.md`. You review it and respond — with feedback or approval. That response triggers a targeted interview that fills gaps and captures what the materials didn't fully show. Integration (Notion, output path) comes after.

**Run order matters.** Phase 0 (environment check) → Phase 1 (identity) → Phase 2 (content submission) → Phase 3 (synthesis) → Phase 4 (review and interview) → Phase 5 (integration) → Phase 6 (permissions) → Phase 7 (job-preferences) → **Build & install career-data** (the closing handoff step). Phases 5–7 can be deferred — the pipeline can run with Phases 1–4 complete. Whenever a setup session ends (all phases done, or the user stops), run the **Build & install** step so the work authored this session actually becomes an installed skill.

**Onboarding can be paused and resumed.** The Phase 4 interview in particular can take time. If the user needs to stop, they can resume later by running `/career-engine:setup --phase 4`. The state of `03-framework.md` is preserved between sessions — sections already confirmed have no `[DRAFT]` or `[REVIEW]` markers; sections still needing work do. The pre-flight check uses this to report progress accurately.

---

## career-data — what it is and how to keep it in sync

**Single-build architecture.** The career-engine plugin ships as one build with no personal version. It contains only code (agents, skills, blank `{{...}}` templates). All of the user's personal data — writing rules, background, framework, delivered letters, CV template — lives exclusively in the `career-data` skill created during setup. Plugin upgrades never touch it.

**Path resolution.** career-engine agents find `career-data` at run start by locating `career-data-marker.json`. They never hardcode the path. Standalone agents (outside the orchestrator) do a self-locate step before reading.

**Three runtime environments — Chat + Cowork share one skill store; Code has its own:**

| Environment | Plugin runs here? | Reads career-data from |
|---|---|---|
| Chat | **No** (plugins don't run in Chat) | Desktop app skill store. This is where `career-data` is *created* — via `/skill-creator`. |
| Cowork | Yes | Desktop app skill store (same install as Chat) — cannot save a skill itself |
| Claude Code (CLI) | Yes | `~/.claude/skills/career-data/` on local disk |

Because the plugin runs in Cowork/Code but skills are born in Chat, **the Cowork user authors `career-data` here and installs it via a Chat `/skill-creator` handoff** — see [`references/career-data-skill-handoff.md`](../../references/career-data-skill-handoff.md) ("Appendix A"). The Desktop app writes to `~/.claude/skills/` when a skill is installed — one-way, Desktop → Code. Writing directly to `~/.claude/skills/` from Code does **not** propagate back to Chat or Cowork.

**The only safe update path.** To update `career-data` after setup:
1. Generate an update-prompt file (using `career-engine/references/career-data-update-prompt-format.md`)
2. Paste it into Chat
3. Chat edits the skill, repackages as `.skill`, and reinstalls via Customize → Skills
4. If the user runs both Chat/Cowork and Claude Code, apply the update in Code too

**Never write `~/.claude/skills/career-data/` directly from Claude Code** to make a "quick" edit. It looks faster but only updates the Code copy — Chat and Cowork never see the change. The rationalization to watch for: "I can reach this file from Code, so I'll edit it here — it's faster and safer than going through Chat." This is backwards. The Chat path's friction exists because packaging a skill has integrity steps. Skipping them hides risk, it doesn't remove it.

**Exception — pipeline-owned writes:** career-engine agents writing to `career-data/references/` as part of a pipeline run (motivation-bank promotion, locked bullets, update-refs) are legitimate Code-side writes. The prohibition above applies to ad-hoc manual edits only.

---

## Phase 0 — Environment check (do this first, before the pre-flight)

**Detect which environment you are in and tell the user up front how the skill-build step will work.** This prevents the dead-end where a Cowork user authors everything, hits "Save Skill," and gets *"SKILL.md must be in the top-level folder."* The full reasoning is in [`references/career-data-skill-handoff.md`](../../references/career-data-skill-handoff.md).

Determine the environment:
- **Claude Code (CLI):** you have direct shell/filesystem access to `~/.claude/skills/`. Setup will write `career-data` there directly — no Chat handoff.
- **Cowork:** the common case for non-technical users. You cannot save a skill yourself. Setup does all the interview and authoring work here, but the **final install happens in Chat** via `/skill-creator`. If unsure whether you are in Cowork vs Code, assume Cowork and ask the user to confirm.

If in Cowork, show this once, early, with **minimal text** (render it as a visual/artifact if supported, otherwise as the text strip):

```
  Setup runs HERE in Cowork. One step happens in Chat:

  ┌──────────────┐   ┌──────────────┐   ┌────────────────────┐   ┌──────────────┐
  │  ① COPY      │ → │  ② OPEN      │ → │  ③ TYPE            │ → │  ④ PASTE     │
  │  the prompt  │   │  Chat        │   │  /skill-creator    │   │  + press     │
  │  I give you  │   │  (not Cowork)│   │  (install it first)│   │  Enter ⏎     │
  └──────────────┘   └──────────────┘   └────────────────────┘   └──────────────┘

  Why: the plugin runs in Cowork, but skills are created in Chat.
  Chat and Cowork share skills — so it'll be ready back here automatically.
```

Tell the user plainly: *"Most of setup happens right here. At the end I'll hand you one prompt to paste into Chat — that's the only step that has to leave Cowork. Make sure `/skill-creator` is installed in Chat (it's Anthropic's, nothing to worry about)."* Then continue to the pre-flight.

---

## Pre-flight — check current state

Before doing anything, assess what has been completed:

1. Check whether `career-data` is installed and complete: locate the `career-data` skill, read `career-data-marker.json`, and confirm every file in its `expected_files` is present and non-empty. Absent → new user, run full setup. Present but incomplete → report which files are missing and offer to repair. **A complete career-data with no `references/capability-profile.md` (built before 2026-10-15) is complete but un-profiled, not damaged:** say so in one line and offer to generate it now through the coach's Option 6 path (`skills/career-coach/coach-capability-profile.md` — drafted in full, confirmed once, delivered as an update prompt); the Prioritization pipeline runs without it on the title-based read until then.

2. Check `03-framework.md` for `[DRAFT]` or `[REVIEW]` markers — these indicate sections the interview hasn't confirmed yet.

3. Check whether the output folder and database have been configured (Phase 5).

Report to the user:
- Which phases are complete
- Which phases are incomplete or partially done (including how many `[DRAFT]`/`[REVIEW]` sections remain in `03-framework.md`)
- Whether the integration is configured

If resuming a partial setup, skip completed phases and go directly to the first incomplete one. If the user says they want to continue a previous interview session, load `03-framework.md`, identify remaining `[DRAFT]`/`[REVIEW]` sections, and pick up the interview from there.

---

## Phase 1 — Identity and contact

**Purpose:** Powers the CV signature, agent instructions, and file naming. Nothing works correctly without this. Takes 2 minutes.

Ask for the following. Use the placeholder name as the prompt — "What's your `{{USER_FULL_NAME}}`?" reads naturally enough.

| Placeholder | What it's for |
|---|---|
| `{{USER_FULL_NAME}}` | Full name as it appears on CVs and cover letters |
| `{{USER_FIRST_NAME}}` | First name only — used throughout agent instructions |
| `{{USER_LAST_NAME}}` | Last name only — used in output file naming |
| `{{USER_EMAIL}}` | Email address |
| `{{USER_PHONE}}` | Phone number |
| `{{USER_LINKEDIN}}` | Full LinkedIn URL |
| `{{USER_WEBSITE}}` | Personal website or portfolio domain |
| `{{USER_LOCATION}}` | City, Country |
| `{{USER_CITIZENSHIP}}` | Citizenship or right to work |
| `{{USER_PROFESSION}}` | Your profession or function (e.g., "marketing", "software engineering", "product design", "sales", "data science") |
| `{{USER_CITY}}` | City you are based in |
| `{{USER_COUNTRY}}` | Country you are based in |
| `{{USER_FUNCTION_SENIORITY_HIERARCHY}}` | Typical title tiers in your function from most senior to IC (e.g., for marketing: "CMO → VP → Head/Director → Manager → IC") |

Write these answers into `career-data` `01-writing-rules.md` Section 8 (identity), per the **Writing personal data** rule. Do NOT substitute `{{...}}` placeholders into the plugin's agent, skill, or reference files — the single build stays un-personalized; agents resolve identity values at runtime from `career-data` §8 (CLAUDE.md → *Placeholder resolution*).

---

### Language configuration

Ask:

> "What language(s) do your applications need to be in?
> (a) One language only — all applications in the same language
> (b) Two languages — some roles may need outputs in a second language (e.g., bilingual markets, international applications)
>
> If (a): what is your primary application language? (e.g., English, French, German, Spanish — or whatever you write in naturally)
> If (b): what is your primary language, and what is your second language?"

Based on their answers:

1. Write `{{USER_DEFAULT_LANGUAGE}}` and `{{USER_SECOND_LANGUAGE}}` (or `none`) into `01-writing-rules.md` Section 8.

2. Write `{{USER_DEFAULT_LANGUAGE}}` and `{{USER_SECOND_LANGUAGE}}` into `agents/localization.md` and `skills/localization/SKILL.md` (replacing placeholders).

3. **If either language is right-to-left (RTL)** — this includes Hebrew, Arabic, Persian/Farsi, Urdu, and others:
   > ⚠️ **RTL template required.** RTL text in a left-to-right Word template will render incorrectly — characters appear in the wrong order and alignment breaks. You will need a separate `.dotx` template configured for right-to-left layout before running the pipeline for RTL-language roles. See `skills/career-engine-export/SKILL.md` for template setup instructions.

   Then ask:
   > "Do you have RTL `.dotx`/`.dotm` CV and cover letter templates ready? If so, share them now and I'll install them. If not, that's fine — RTL export will be skipped until you add them later via 'update my references'."

   **No config key** (R-38, 2026-07-04 fix — `word_templates_path` is retired). Copy whatever the user provides into `career-data/references/templates/`, renamed to the fixed filenames the pipeline looks for: `cvHe.dotm` (Hebrew CV — note the `.dotm` extension, not `.dotx`) and `he-letter.dotx` (Hebrew cover letter). If skipped, do not create either file — `career-engine-export` treats their absence as "Hebrew export unavailable for now" and skips it, exactly as before. The plugin ships no generic default for either (RTL templates are not meaningfully genericizable the way the CV/cover-letter defaults are), so there is no "use the included template" option here — only bring-your-own or skip.

4. **Database reminder:** Tell the user:
   > "Add all languages you configured to the **Languages** column in your Notion (or tracking) database for each role. The pipeline reads this column to decide whether to run localization. Use the exact values you configured: `{{USER_DEFAULT_LANGUAGE}}`, `{{USER_SECOND_LANGUAGE}}` (or both). A role with Languages = `{{USER_DEFAULT_LANGUAGE}}` only gets one set of outputs. A role with Languages = `{{USER_DEFAULT_LANGUAGE}}, {{USER_SECOND_LANGUAGE}}` gets both."

5. **If the user has a second language:** update `skills/localization/SKILL.md` per the setup instruction at the bottom of its Opening section — confirm the Default Language and Second Language columns reflect the user's configured languages. See that skill for the exact algorithm.

---

Confirm: "Done. Let's move to your career materials."

---

## Phase 2 — Content submission

**Purpose:** The agent builds your positioning framework and career profile from materials you already have — rather than asking you to describe everything from scratch.

Tell the user:

> "Send me whatever you have from the list below. The more you share, the better the output. I'll read everything and build your positioning framework from it. I will **not store your files** — I'll use them to synthesize your reference files and then they're gone. The only exception is cover letters: if you tell me they're good representations of your voice, I'll add them to the plugin's delivered-letters archive (`references/delivered-letters/`, cap 6) as voice calibration anchors for future runs."

List of useful content and what each feeds:

| Content | What it feeds | Notes |
|---|---|---|
| Current CV(s) | `02-professional-background.md` — role facts (company, dates, titles, metrics, scope) | Used for facts only. Your old CV bullet language is **not** treated as approved bullets — those emerge from pipeline iterations. |
| Approved sent cover letters | `references/delivered-letters/` — the in-plugin voice-calibration archive (cap 6) | Only kept if you confirm they're good representations of your voice. Ask explicitly before storing; store via the letter-writer Option 3 entry format and update INDEX.md. |
| **LinkedIn profile PDF export** ("Save to PDF" on your own profile) | `references/linkedin-profile.md` — **stored as a permanent reference.** Every LinkedIn recommendation the plugin produces (the per-run LinkedIn updates file, the LinkedIn coach) analyses against this snapshot. Also feeds `03-framework.md` — testimonials, voice samples, domain context. | **Ask for this explicitly — it is the one item on this list to actively request, not just accept.** Skippable if the user declines: LinkedIn outputs run in fallback mode (raw signals, no profile analysis) until provided. Tell them: "You can add it any time later — export the PDF and say 'update my references'." A fresh export replaces the snapshot wholesale whenever they change their profile. |
| Performance reviews or peer feedback | `03-framework.md` — peer-attributed qualities, testimonials | Not stored. |
| Portfolio pieces or writing samples | `02-professional-background.md` Section 10 — portfolio | Not stored after synthesis. |
| Old job descriptions you were hired for | `01-writing-rules.md` — attribution rules, scope framing | Used to understand what was personal contribution vs. company-level. Not stored. |

Ask the user to send files. Wait for submission before proceeding.

---

## Phase 3 — Review and synthesize

**Purpose:** Read everything submitted and build `03-framework.md`. This is the agent's primary synthesis task — do it carefully.

### Cover letters — ask before storing

Before reading anything, ask:

> "You shared cover letters. Are these good representations of your voice — the kind of letters you'd be happy to send today? If yes, I'll add them to the plugin's delivered-letters archive so every future run can calibrate against them. If no, I'll read them for context and then they're gone."

- If yes: store each approved letter in `references/delivered-letters/` using the letter-writer Option 3 entry format (one file per letter, full text exactly as sent, metadata header) and update `INDEX.md`. Respect the cap of 6.
- If no: read them for context only, do not store

**If at least 3 letters were stored,** ask the user directly — wait for their reply before proceeding:

> "Want me to generate your voice calibration file now? It's a one-time analysis of your delivered letters that the letter-writer reads at pipeline run time instead of re-reading the archive from scratch each run — saves every future run that step. Optional: the pipeline works fine without it (both agents fall back to reading the archive directly). Say yes and I'll run the methodology in `references/voice-calibration-method.md` and write the result to `references/voice-calibration-coverletters.md`."

If yes: run the methodology now and write the file. If no, or fewer than 3 letters were stored: skip this — the user (or a future session) can generate it later using the same methodology reference.

### Read all submitted content carefully

Read every file. For each piece of content, note:
- Career history: companies, titles, dates, metrics, scope, what was built
- Voice: how the user writes, sentence patterns, vocabulary level, what they emphasise
- Positioning: what they claim as their core value, how they frame their work
- Domain depth: which verticals and sub-categories they have documented experience in
- Differentiators: what appears repeatedly as distinctive about their background
- Testimonials: any third-party quotes about their work
- Portfolio: specific work samples with descriptions and links

### Build `03-framework.md`

Fill in every section of `03-framework.md` from what the materials show. Where the materials provide clear evidence, write confident content. Where they are thin or unclear, write a best-effort draft and mark it `[REVIEW — limited evidence]` so the user knows to check it in Phase 4.

**Section-by-section guidance:**

**Category and market frame** — infer from the companies worked at, industries served, seniority of roles held. What professional category does the evidence point to?

**Voice and tone** — extract from cover letters (if approved) and LinkedIn writing. Note actual sentence patterns, vocabulary, what the user emphasises, how formal or informal. Pull 4–6 direct quotes for Voice samples. Use only documented quotes — never fabricate them.

**Core positioning statement** — synthesise from the career arc. Who hires this person, for what, and why them over alternatives? Draft from the evidence; mark as draft.

**Value pillars** — identify 2–3 recurring patterns of impact across the career. For each: what they do, what the proof is. Use specific companies and metrics from the CV.

**Professional methodology and POV** — extract from how the user describes their approach in cover letters, LinkedIn, or anywhere they explain how they work. If thin, leave placeholders.

**Domain depth** — map the career history to verticals. For each vertical: companies, what was done, what the proof point is.

**Proof points bank** — extract specific metrics and outcomes. Company → outcome → attribution (personal vs. company-level).

**ICP and target opportunities** — infer from the career stage, company sizes, and domains worked in. Draft; will be refined in the interview.

**Career-shift posture** — **never infer this silently and never leave it confident.** A career history says nothing reliable about appetite for a shift — a CV full of one function reveals nothing about whether the user *wants* a different one. Write only what the evidence implies (e.g., a fractional/consulting track record implies openness to contract work in the interim; repeated function changes may imply shift appetite) and **always mark the section `[DRAFT — confirm in interview]`** regardless of how strong the evidence seems. The Phase 4 posture questions are always asked and are the only thing that confirms this section.

**Messaging** — draft based on the positioning. Leave as draft; will be refined.

**Taglines, elevator pitches, differentiators, competitive frame, anti-positioning** — draft from the synthesis. Mark all as `[DRAFT — confirm in interview]`.

Write the completed `03-framework.md` to the references folder.

---

## Phase 4 — Framework review and interview

### Share framework.md

Present `03-framework.md` to the user and say:

> "Here's your positioning framework, built from what you sent me. Review it — especially the sections marked `[REVIEW]` or `[DRAFT]`. When you're ready, tell me what needs changing or say it looks right. Either way, I'll follow up with a few questions to fill gaps and check things your materials didn't fully capture.
>
> **A note on your files:** I've used your submitted content to build this but have not stored it. [If cover letters were kept: "Your approved cover letters are in the plugin's delivered-letters archive (`references/delivered-letters/`)."] Everything else has been read and synthesised — the original files are not in the plugin."

Wait for the user's response. Whether they give feedback or say it's fine, proceed to the interview.

### Update framework from feedback

If the user gave feedback, apply it to `03-framework.md` before proceeding.

### Interview — gap-filling and enrichment

**Apply the coach's Deep Probe Interview Mode for this entire section.** Load `career-coach/SKILL.md` → Deep Probe Interview Mode and apply its principles: 2–3 questions at a time, grouped by theme, scenario-based and behavioral rather than abstract, follow up every meaningful answer with a counter-probe. Do not deliver a form. Adjust based on what the materials already covered.

**Track what's missing from each section of `03-framework.md` and `02-professional-background.md`. Cover the most important gaps first. The goal is the real version of the user — not the polished self-presentation version.**

Core areas to cover:

**Voice, tone, and writing (always ask — even if materials were provided)**

These cannot be reliably inferred from a CV. They shape how every letter sounds and how agents calibrate register.

Don't ask "how do you want to come across?" — ask about actual moments and real reactions. Scenarios to adapt:

> "Walk me through what happens in your head when you read a cover letter that sounds like it was written by someone trying to sound impressive. What specifically makes you cringe — a phrase, a structure, a register? Give me an example if you have one."

> "You're explaining your work to someone you genuinely respect who isn't in your field — not selling yourself, just explaining what you actually do. How does that conversation sound? Start talking."

> "You have two registers you switch between — one for technical founders, one for a senior exec who doesn't want to hear the details. Are those the same voice for you, or do you shift? What changes?"

> "Is there a word or phrase you genuinely use — something you'd never want a writing agent to polish away — that captures something true about how you work or think?"

Capture actual words and phrases verbatim. Voice samples should be quoted language from the conversation, not summaries.

Write the answers into `03-framework.md` §Voice and tone and §Voice samples.

**Voice preferences never silently modify documented rules.** These answers refine register, vocabulary, and style — they do not weaken or create exceptions to any documented writing rule or prohibition (in `01-writing-rules.md` or `skills/writer-craft/SKILL.md`). If an answer conflicts with a documented behavior (e.g., the user says they love em dashes, or wants tricolons everywhere), surface the conflict and ask whether they **explicitly reject that specific documented behavior**. Only an explicit rejection changes a rule — write the change into the rule's home file and note it; never infer a rule change from a preference.

**Positioning and professional belief system**

> "If you had to name the thread that runs through every role you've taken and every decision you've made in your career — something beyond 'I wanted to grow' or 'the opportunity was good' — what would it be?"

> "What's the one thing most people in your field get wrong? The mistake you see made over and over that you genuinely can't understand. What's your theory for why they keep making it?"

> "What would the people who've worked closest to you say is the thing that makes your approach different — the thing they'd struggle to replace if you left?"

**Career facts (for `02-professional-background.md`)**
- For each major role: confirm title, dates, direct reports, key metrics, what was specifically built or changed.
- Attribution check — for any significant outcome: "Was that a company result or something you drove specifically? How much of the 300% growth was you, and how much was the market?" This shapes attribution rules in `01-writing-rules.md`.
- Consulting/fractional work: any client engagements not in the CV?

**Scope and framing (for `01-writing-rules.md`)**
- Were there outcomes in the CV that were team-delivered or company-level that agents shouldn't overclaim?
- Any roles where the title understates or overstates the scope?
- Any fractional or consulting engagement needing specific scope framing?

**Target search (for `01-writing-rules.md` Section 2)**
- What roles are you targeting — title, seniority, function?
- Company stage and size — strong preferences, hard nos?
- Geographic constraints or preferences?

**Career-shift posture (for `03-framework.md` §Career-shift posture — always ask; this cannot be inferred from materials)**

Don't ask abstractly. Use a scenario:

> "A role comes in — technically adjacent to your background, but you'd be the first person in this function at the company. No team, no playbook, no established credibility in that lane. When you're honest with yourself, is that energizing or exhausting?"

> "Beyond your established function — how open are you to a shift? Not open, open case-by-case, or is a shift actively what you're looking for? And if open: what does a shift role need to offer — seniority, specific scope, conditions — for you to actually want it? What's off the table entirely?"

Write the answers into `03-framework.md` §Career-shift posture and remove its `[DRAFT]` marker. Also capture current employment status and search mode (full-time vs. contract/freelance in the interim) in the same section if it surfaced here or anywhere in the interview.

**Enrichment probing — things users often don't volunteer**

Ask about these specifically if they haven't come up naturally:

- **Testimonials:** "Do you have any LinkedIn recommendations or client feedback we should add? Third-party quotes carry different weight than self-description."
- **Published work:** "Have you published articles, research papers, or significant public writing — even ghostwritten?"
- **Community and teaching:** "Are you active in any professional communities, do any mentoring, or hold any formal advisory roles?"
- **Voice samples:** "Is there anything you've said in a conversation, presentation, or interview that captures how you think about your work? Even a rough quote is useful."
- **Anti-positioning:** "Is there anything you've been mistakenly credited for, or a claim that would be easy to make but isn't accurate? Better to document it now."

### After the interview — update reference files

**Update `03-framework.md`:** Apply all interview answers to the relevant sections. Remove all `[REVIEW]` and `[DRAFT]` markers from sections that are now fully confirmed.

**Populate `02-professional-background.md` sub-files:**

For each role confirmed in the interview, create or update `background/background-role-facts-<company>.md` (copy from the `background-role-facts-COMPANY1.md` template, rename to the company slug):
```
### [Company] ([dates])
- Title: [answer]
- Reporting: [answer]
- Team: [answer]
- Key metrics: [answer]
- What was built: [summary from CV + interview]

**Detailed: Approved bullets**
[LEAVE EMPTY — approved bullets are populated through pipeline iterations, not setup]

**Brief: Approved bullets**
[LEAVE EMPTY — approved bullets are populated through pipeline iterations, not setup. Stays empty indefinitely if `cv_type.mode` is never `Brief` or `Variant` — cv-writer falls back to writing fresh Brief bullets from role facts when this subsection is empty, per `agents/cv-writer.md`'s Brief-Specific Rules.]
```

**Important:** Do not populate approved bullets from the user's old CV. Old CV bullet language is raw material, not approved language. Both the Detailed and Brief subsections start empty for every company and fill in as the user runs the pipeline and locks bullets she's happy with — the two are curated separately, since Brief's bullets are much shorter and more selective than Detailed's, not a shortened copy of them.

Populate `background/background-portfolio.md` from any portfolio materials submitted.
Populate `background/background-testimonials.md` from LinkedIn recommendations or peer feedback confirmed in the interview.

**Update `01-writing-rules.md`:**

Write attribution rules into Section 1 for any outcomes confirmed as company-level rather than personal contribution. Write framing rules for any scope limitations confirmed in the interview. Write the target role information into Section 2.

---

### Phase 4 — Capability profile (2026-10-15)

**Do this right after the reference files are updated and before Motivation Bank seeding.** The capability profile is the Prioritization pipeline's function-fit input: a short, title-free statement of what the user can do, in generic discipline vocabulary, derived from the files just written. Titles change across the market faster than any target-title list, so the prioritizer scores a JD's responsibilities against these lines instead of its title.

Spawn (or continue) the career coach with `${CLAUDE_PLUGIN_ROOT}/skills/career-coach/coach-capability-profile.md` loaded and follow it exactly: the coach drafts the whole profile from `02`/`background/*`, `03-framework.md`, and `linkedin-profile.md` — applying the three-way test, the portability test, the pairwise de-duplication test, and the caps (≤25 lines, ≤5 groups) — shows the user the complete draft once, and waits for a yes or line edits. **No interview and no line-by-line questions: the profile is derived, and the user's edits are applied verbatim.** On confirmation, write it to the working `career-data/references/capability-profile.md` (format: the plugin's blank `${CLAUDE_PLUGIN_ROOT}/references/capability-profile.md` minus its header comment — the written file starts at the `Generated:` line and contains no `{{`) and list it in `career-data-marker.json`'s `expected_files`. It ships with the rest of career-data at Build & install.

Tell the user, once: "This profile is what the prioritizer scores roles against, so a role whose title you'd never have listed still scores on the work it asks for. It's derived from your background, so regenerate it whenever your background files change — say 'generate my capability profile' to the career coach and it comes back for one confirmation before it's packaged."

### Phase 4 — Scope preferences (2026-10-19)

**Do this right after the capability profile is confirmed.** The coach **drafts** `scope_preferences.want` and `.avoid` — responsibilities the user wants more of and refuses to do, in generic discipline vocabulary — from the interview answers and background already in hand, shows the complete draft once, and waits for a yes or edits (same show-once-confirm discipline as the profile; never a cold questionnaire). Written in Phase 5 with the other config keys. Skippable: empty lists are valid and never block a run.

### Phase 4 — Motivation Bank seeding

**Do this after the framework/posture interview, while the user is still in a reflective frame — it is the single highest-leverage thing in all of setup.** The Motivation Bank (`background/background-motivation-bank.md`) holds the user's standing motivations and reactions in their **own verbatim words**, tagged for retrieval. It is the **letter-writer's primary content and voice source** — the writer loads it first, ahead of any constructed alternative. The richer it is, the better every cover letter, and the *less* per-role `Why I Want This Role` the user has to write over time. A well-seeded bank means future runs reuse standing motivation instead of demanding fresh input each time — eventually the user writes almost no per-role motivation at all.

So setup must actively coach this — not just mention it.

**1. Explain why it matters (say this plainly):**

> "We're now going to seed your Motivation Bank — and this is the most important thing we'll do in setup. It's where your real, standing motivations live, in your own words, tagged so the letter-writer can pull the right one for each role. Every cover letter the pipeline ever writes draws from this first. The richer and more honest this is, the better your letters — and the less you'll have to write a fresh 'Why I Want This Role' for each application. Seed it well now and it pays off on every run after."

**2. Present the recommended seed topics.** Adapt the wording to the user's profession and what surfaced in the interview, and tell them they can add their own. Default set:

- **core identity / the problem you exist to solve** — the thread that runs through your whole career
- **what energizes you** — the work that genuinely lights you up
- **why this kind of company or mission** — the type of company/mission you want to be part of and why
- **your operating philosophy / what you optimize for** — how you work, what you refuse to compromise on
- **leadership or mentorship philosophy** *(only if they lead or mentor)*
- **domain passion** — the verticals or problem spaces you genuinely care about
- **career-shift motivation** *(only if they're making a change)* — what's pulling you toward the shift

Say: "These are the topics worth seeding first — each one deserves an honest, emotional, motivational answer. Add any of your own that matter to you."

**3. Coach effort — explicitly, in plain words:**

> "Take your time with these. Put real effort in. Write honestly and specifically, in your own voice — scrappy, imperfect English is not just fine, it's *better* than polished. Real beats smooth every time. The quality of these answers directly becomes the quality of your letters: vague entries produce vague letters; specific, felt entries produce letters that sound like you and land. This is not a box to tick fast — it's the highest-leverage writing you'll do in this whole setup."

**4. Hand the user the OPENING of a career-data update prompt.** Generate it now in the canonical update-prompt format (`career-engine/references/career-data-update-prompt-format.md`) — same Chat/Code path as every other career-data edit. It targets `background/background-motivation-bank.md` and **appends rows** to the `| Tags | Motivation |` table (append-only; never rewrite, reorder, or delete existing rows; never change the two-column layout). Pre-seed one row per suggested tag (and any the user added) with the **Tags** cell filled and the **Motivation** cell left as a fill-in slot. Make clear the user types their verbatim answers into the Motivation cells **before** sending the prompt to Chat (or applying it in Code). Substitute the user's chosen/adapted tags; keep the table's existing seed row intact (append below it).

Present it as one copyable block, led by the four-step Phase 0 visual in Cowork (or written directly in Code). **If you write it to a file (2026-08-12): `<output_folder>/_career-data-updates/update-prompt-motivation-bank-<YYYYMMDD>.md`. Never inside the plugin repo, under `${CLAUDE_PLUGIN_ROOT}`, or in the current working directory — the prompt carries her personal answers. Setup is the one place where `output_folder` may not exist yet, since this run is what creates `pipeline-preferences.json`: asking her where to put it is the expected path here, not a fallback. If she has already given an output folder earlier in this setup run, use that.** Full rule at the top of `references/career-data-update-prompt-format.md`.

```
career-data update prompt — background/background-motivation-bank.md — seed Motivation Bank
Generated: <YYYY-MM-DD> | Apply in: Chat AND Code (if using both)

Context (fixed — do not change this block)
You are updating a skill called career-data. This is a packaged `.skill` file installed
via Customize → Skills in the Claude Desktop app. It contains personal career data —
writing rules, professional background, and framework files. To find career-data:

* Look for a directory containing `career-data-marker.json`
* It will be under your skills path (check `~/.claude/skills/career-data/` or the
  Desktop app's local session skills path)
* Confirm the marker file exists before editing

After making the edit below:
1. Verify the change is correct
2. Repackage the directory as a `.skill` file (zip the contents, rename to `.skill`)
3. Upload via Customize → Skills → replace the existing career-data skill
4. If you use both Chat/Cowork AND Claude Code, you must apply this update in both environments

⚠️ Do NOT paraphrase the new text. Copy it exactly as written below.

The fix
File: `references/background/background-motivation-bank.md`
APPEND the rows below to the existing `| Tags | Motivation |` table. Do not rewrite,
reorder, merge, or delete any existing row, and do not change the two-column layout.
Each Motivation cell holds my exact words — correct grammar and spelling only; never
rephrase, paraphrase, summarize, or "clean up."

Append these rows:
| core identity, the problem you exist to solve | <I fill this in, in my own words> |
| what energizes you, the work that lights you up | <I fill this in, in my own words> |
| why this kind of company or mission | <I fill this in, in my own words> |
| operating philosophy, what you optimize for | <I fill this in, in my own words> |
| leadership/mentorship philosophy | <I fill this in, in my own words — or delete this row if it doesn't apply> |
| domain passion, verticals I care about | <I fill this in, in my own words> |
| career-shift motivation | <I fill this in, in my own words — or delete this row if I'm not making a shift> |

Why: seeds my standing Motivation Bank — the letter-writer's primary content and voice
source — so every future cover letter draws from my own honest, verbatim motivations.

Verification
After applying, confirm:
* The table still has exactly two columns: `| Tags | Motivation |`
* The original seed row is untouched and my new rows were appended below it
* No other files were modified
```

Tell the user: "Fill in each Motivation cell in your own words — take your time — then this goes to Chat (or Code) the same way as the rest of your career-data, via the Build & install handoff at the end. You can also append to your Motivation Bank any time later with 'update my references'."

**Format discipline (state it once):** the Motivation Bank is a fixed two-column `| Tags | Motivation |` table, verbatim and append-only — the user's exact words, grammar/spelling corrected only, new rows appended, never the layout changed. This mirrors the structure contract in `background/background-motivation-bank.md`; do not deviate from it here.

Confirm: "Your positioning framework, career background, candidate rules, and Motivation Bank seed are now configured. Let's set up your job tracking and output folder."

---

## Phase 5 — Job tracking and output

**Purpose:** The pipeline reads roles from a job tracking source and writes results back. This phase sets up the database and configures where it lives.

Ask: "How do you want to track your job applications? Options: **Notion** (recommended — full pipeline integration with writeback), **Google Sheets**, or **another platform**."

---

### Option A — Notion

1. Say: "Use this template — it has all the required columns and select values pre-configured:
   **[Duplicate the Notion template →](https://abounding-trouser-bce.notion.site/13a6d072845047c0a99cfeb6b201091b?v=843875fd750c4a9d884b298748a4d331&pvs=143)**
   Click Duplicate, add it to your workspace, then come back."

   **If the user would rather not open the shared Notion link** — some people prefer not to duplicate a stranger's public page into their workspace, or want to inspect the schema first — offer the CSV instead: `${CLAUDE_PLUGIN_ROOT}/references/job-applications-template.csv`. It is a superset of the pipeline's required schema — every column the pipeline reads or writes, plus a handful of optional contact/referral-tracking columns some users find useful (`Connection's Email`, `HR / Recruiter Contact`, `Related Emails`, etc.) — with ten fictional example rows. In Notion: **Import → CSV**, pick the file, then set the column types Notion cannot infer (`Status` → Status; `Priority`, `Company Stage`, `CV Type`, `Relationship type`, `Source`, `JD Fetch Status`, `Manager role confirmed`, `Edit type` → Select; `Role Type`, `Languages`, `Message Channel with My Connection` → Multi-select; `Job URL`, `Draft Directory` → URL; the date columns → Date). Then delete the ten example rows. Everything downstream is identical — the pipeline reads the schema at run start either way.

2. Once they confirm it's set up, ask:
   - "Paste your database ID." (the 32-character string from the Notion URL — `notion.so/[workspace]/DATABASE_ID?v=...`)
   - Then say: "Now paste the URL for each of these views — open each one in your browser and copy the full URL from the address bar. You can skip any you haven't set up yet (the pipeline will find them automatically, but pasting them now eliminates a large background fetch every run that can cause early context compaction)."
     - **New** view URL (newly-added roles, before Prioritization has touched them)
     - **Interested** view URL (the pipeline's main queue — roles you've decided to apply for)
     - **Needs Research** view URL (roles under research before deciding)
     - **Researched** view URL (roles the coach has analysed; ready for your decision)
     - **CV Ready for Review** view URL (roles with completed pipeline output awaiting your review)
     - **Needs Editing** view URL (roles queued for the edit pipeline)
   
   Each URL looks like: `https://www.notion.so/<workspace>/<DB_ID>?v=<VIEW_ID>`. The `?v=` part is the view ID. Collect only the ones they have; leave the rest empty.

3. **Check and install the Notion MCP.** The pipeline reads and writes your Notion database using the `notionApi` MCP server. Check whether it is already connected:

   Run: `ToolSearch query="select:notionApi__API-get-self"` — if a schema is returned, the server is connected. Ask the user to confirm they can see a Notion MCP listed in their Claude settings. If connected, skip to step 4.

   If NOT connected, tell the user which environment they are in and give them the right instruction:

   **Claude Code (terminal):**
   > "Run this in your terminal:
   > ```
   > claude mcp add --transport http notion https://mcp.notion.com/mcp
   > ```
   > Then type `/mcp` in Claude Code and complete the OAuth flow to connect your Notion workspace."

   **Claude Desktop:**
   > "Go to **Settings → Connectors → Add Connector** and enter:
   > ```
   > https://mcp.notion.com/mcp
   > ```
   > Complete the OAuth flow to connect your Notion workspace."

   After they confirm it's done, verify: run `ToolSearch query="select:notionApi__API-get-self"` again. If it still returns nothing, tell the user: "The notionApi server isn't showing as connected yet — try restarting Claude and then re-run setup from here. The pipeline will not be able to read or write your Notion database until this is connected."

   Say: "**One Notion responsibility:** The MCP connection uses your personal OAuth token — it expires or can be revoked. If the pipeline ever fails to read Notion mid-run, reconnect by repeating the step above."

4. Write to the career-data config (`${CAREER_DATA}/references/pipeline-preferences.json`):
   - `database_backend` = `notion`
   - `database_id` = the database ID the user provided
   - `database_new_view_url` = the New view URL (or empty string if not provided) — fast-path for the Prioritization pipeline's `New`-status queue
   - `database_interested_view_url` = the Interested view URL (or empty string if not provided)
   - `database_hold_view_url` = the Needs Research view URL (or empty string) — key name unchanged for backward compatibility; holds the `Needs Research` view (renamed from `Hold`)
   - `database_researched_view_url` = the Researched view URL (or empty string)
   - `database_cv_ready_view_url` = the CV Ready for Review view URL (or empty string)
   - `database_edit_view_url` = the Needs Editing view URL (or empty string)
   
   (The `database_*` names are backend-neutral. Older configs may carry legacy `notion_database_id`/`notion_needs_editing_view_url` names — the pipeline reads both, but always write the `database_*` names on a fresh setup.) Do NOT substitute `{{NOTION_DATABASE_ID}}` into plugin files — every skill resolves it from the config at runtime (R-38).

6. Say: "**Important:** Do not rename the columns in your Notion database. The pipeline writes to them by exact name — renaming breaks the integration silently."

7. **CV Type property — only relevant if Variant mode is chosen later in this phase.** The duplicated template likely does not include this property yet, since it's new. Once the CV Type question below (under "Document templates") is answered, if the answer was `Variant`, come back here and say: "Since you chose to let each role decide its CV format, add a **Select** property to your Notion database named exactly `CV Type`, with two options: `Detailed` and `Brief`. You set this per role yourself — the pipeline reads it, never writes to it." Skip this step entirely if `Detailed` or `Brief` was chosen instead — there's nothing to add.
8. **Role-tailoring properties — always.** The duplicated template may predate these two. Say: "Add one **Text** property to your database, named exactly `CV Titles`. It is where the career coach writes its plan for how each of your past job titles should read on the CV for that specific role, and which unrelated roles fold into one line — you can review and edit it before any CV is written." (Standing title wishes live in `pipeline-preferences.json` → `cv_title_rules`, set in Phase 5 — per the user: "even for the 'more rigid' it's better to store this in the json. and not as a one-off per entry in the db". A legacy `CV Title Preferences` column is still read when a tracker has one; setup no longer creates it.) A tracker without `CV Titles` still works — the CV writer then makes those calls itself.

---

### Option B — Google Sheets

1. Say: "I'll create a CSV file with all the required column headers. You'll upload it to Google Sheets to create your tracking sheet with the correct structure.
   
   **A note on column names: do not rename them.** The pipeline writes to these columns by exact name. Renaming any column will break the integration silently."

2. Write a CSV file to `/tmp/career-engine-tracker.csv` containing only the header row with all required columns in order:

```
Company,Position,Job URL,Status,Priority,Priority Reason,JD Body,JD Fetch Status,Why I Want This Role,Role emphasis,JD proof,Keywords,Strategy,Role Type,Relationship type,Gap handling,Role summary,Hiring Manager's Name,Hiring manager's role,Manager role confirmed,Person who Advertised Role (if not Hiring Manager),No incumbents in this function,Landscape,Culture,Company Stage,Location,First Advertised,Last Pipeline Run,Link to CV,Draft Directory,CV File Name,Letter File Name,Languages,Edit type,CV Type,CV Titles,CV Title Preferences,Note
```

`CV Type` is included regardless of which `cv_type.mode` the user chooses — it's a normal, cheap column to have even when unused (same as `Languages` for a single-language user). It only matters when `cv_type.mode` is `Variant`; the user sets it herself per role, and since 2026-07-23 the coach fills it when empty at intake (write-only-to-empty — her own value always wins).

3. Tell the user: "Download this file and upload it to Google Sheets (File → Import → Upload). This creates your tracking sheet with all the required columns."

4. Provide the following prompt for them to run in a Google Sheets agent or Claude to set up data validation on the select columns:

Before giving this prompt to the user, substitute `{{USER_DEFAULT_LANGUAGE}}` and `{{USER_SECOND_LANGUAGE}}` with the actual values configured in Phase 1. If the user is single-language, omit `{{USER_SECOND_LANGUAGE}}` from the Languages row entirely.

```
Set up data validation (dropdown lists) on the following columns in my Google Sheet named "career-engine-tracker":

- Column "Status": allow only these exact values: New, Needs Research, Interested, CV Ready for Review, Applied, Researched, Needs Editing, Closed (Prioritization and intake set `Closed` automatically when a posting is confirmed closed — an existing tracker using `Position Closed` or `Role Closed` works too; a tracker with no such option is never broken, the pipeline reports instead of writing)
- Column "Priority": allow only these exact values: 1, 2, 3, 4, 5, 6 (the pipeline writes the number, never a word label)
- Column "JD Fetch Status": allow only these exact values: Fetched, LinkedIn-blocked, Unfetchable, Manual-entry
- Column "Company Stage": allow only these exact values: Seed, Series A, Series B, Series C, Public, PE-backed, N/A
- Column "Role Type": allow multiple selections from: Builder, Scaler, Specialist, Leader
- Column "Relationship type": allow only these exact values: Full time, Part time, Temporary, Fractional/Consulting/Freelance
- Column "Manager role confirmed": allow only these exact values: Yes, No; this is only a hypothesis
- Column "Languages": allow multiple selections from: {{USER_DEFAULT_LANGUAGE}}, {{USER_SECOND_LANGUAGE}}
  (If single-language, allow only: {{USER_DEFAULT_LANGUAGE}})
- Column "Edit type": allow only these exact values: CV, Letter, Both
- Column "CV Type": allow only these exact values: Detailed, Brief (used only if you tell the pipeline to let each role decide its own format — otherwise leave this column empty)

These values must match exactly — they are hard-coded in the pipeline that reads this sheet.
```

5. Once the user has set up their sheet, ask: "Paste your Google Sheets URL." Write it to `.claude/settings.json` under `job_tracking.source`.

6. Say: "Note: in Google Sheets mode, the pipeline reads your roles but does not write results back to the sheet. Outputs (DOCX files and coach properties) go to your output folder only."

---

### Option C — Other platform

1. Say: "I'll give you the column schema and a prompt you can use to set up your database in [platform]."

2. Provide the same CSV header row as Option B.

3. Provide a prompt the user can adapt:

```
Create a database/table with the following columns. Do not rename them — they are referenced by exact name by an external pipeline.

Columns: Company, Position, Job URL, Status, Priority, Priority Reason, JD Body, JD Fetch Status, Why I Want This Role, Role emphasis, JD proof, Keywords, Strategy, Role Type, Relationship type, Gap handling, Role summary, Hiring Manager's Name, Hiring manager's role, Manager role confirmed, Person who Advertised Role (if not Hiring Manager), No incumbents in this function, Landscape, Culture, Company Stage, Location, First Advertised, Last Pipeline Run, Link to CV, Draft Directory, CV File Name, Letter File Name, Languages, Edit type, CV Type, CV Titles, Note

Select column values (must match exactly):
- Status: New | Needs Research | Interested | CV Ready for Review | Applied | Researched | Needs Editing | Closed
- Priority: 1 | 2 | 3 | 4 | 5 | 6 (the pipeline writes the number, never a word label)
- JD Fetch Status: Fetched | LinkedIn-blocked | Unfetchable | Manual-entry
- Company Stage: Seed | Series A | Series B | Series C | Public | PE-backed | N/A
- Role Type (multi-select): Builder | Scaler | Specialist | Leader
- Relationship type: Full time | Part time | Temporary | Fractional/Consulting/Freelance
- Manager role confirmed: Yes | No; this is only a hypothesis
- Languages (multi-select): {{USER_DEFAULT_LANGUAGE}} | {{USER_SECOND_LANGUAGE}}
  (If single-language, only: {{USER_DEFAULT_LANGUAGE}})
- Edit type: CV | Letter | Both
- CV Type: Detailed | Brief (used only if you tell the pipeline to let each role decide its own format — otherwise leave empty)
```

4. Once set up, ask for the access URL or connection details. Write to `.claude/settings.json` under `job_tracking.source`.

**Output folder**
Ask the user for their output folder path. This is where all pipeline output (CVs, cover letters, feedback files) will be saved. (Voice-calibration letters live inside the plugin at `references/delivered-letters/` — not in the output folder.)

Write the path as `output_folder` in `${CAREER_DATA}/references/pipeline-preferences.json` (the career-data config). Do NOT substitute `{{OUTPUT_FOLDER}}` into plugin files — the orchestrator resolves it from the config at runtime (R-38).

**CV Type — mandatory question, never skipped.** Ask: "Which CV format do you want the pipeline to produce?
- **Detailed** (recommended default) — the existing full CV, one to two pages depending on your career length.
- **Brief** — a one-page, two-column condensed CV.
- **Not sure yet** — let each role decide instead. A `CV Type` field on your job-tracking database (set up above) overrides per role, and the career coach will also suggest a type per role during intake to help you decide."

There is no fourth option and no way to skip this question — every user gets an explicit `cv_type.mode` written, even when the honest answer is "not sure" (which writes `Variant`, itself a deliberate choice, not a default-by-omission).

Write to the career-data config (`pipeline-preferences.json` → `cv_type`):
- `mode` = `Detailed` | `Brief` | `Variant` (from the answer above)

**If `Brief` or `Variant` was chosen:** ask "Do you want to use the plugin's blank Brief template, or provide your own `.dotx`?" — same choice as the Detailed CV template below, collected now because it's part of the same decision.
- If own file: **before accepting it, tell the user this explicitly — do not skip or soften this:** "Brief CV export works by opening your `cv-brief.dotx` directly and filling in its table — it does not go through the normal document conversion. That only works if your file keeps the **same table structure** as the plugin's default (same rows and columns, same merged cells, same style names) — changing fonts, colors, spacing, or alignment is fine, but adding or removing rows/columns, changing which cells are merged, or renaming/deleting styles will break CV export for every role, not just cosmetically. If you're not sure whether your version changed the table structure, use the plugin default instead, or ask a technical person to check before relying on it." Then copy the file into `career-data/references/templates/`, renaming to the fixed filename `cv-brief.dotx` regardless of the file's original name. (`skills/career-engine-export/scripts/assemble_brief_cv.py` validates this at export time and fails with a specific, readable error rather than a corrupted document if the structure doesn't match — but catching it here, before the user has drafted a single CV against a broken template, is far better than catching it at first export.)
- If default: copy the plugin's `${CLAUDE_PLUGIN_ROOT}/references/cv-template-brief-default.dotx` into `career-data/references/templates/` as `cv-brief.dotx`.

**If the user provided her own `cv-brief.dotx`** (skip this if she used the plugin default — there's nothing to describe yet): ask, optionally, one time: "Does your Brief template include a photo?" Write the answer to `cv_type.brief_has_photo` (`yes`/`no`, blank if she'd rather not say) in the same config object — optional; `cv-writer` assumes no photo when it's blank.

**If the user chose `Variant`:** ask, optionally, one time: "Do you have your own rules of thumb for when a market or role type gets the short vs. the full CV? (e.g. 'Israeli tech: Brief unless C-suite; US roles: Detailed') — free text, skip if not." Write the answer to `cv_type.market_norms` (empty string if skipped). When populated, this is the authoritative first source for the coach's per-role CV Type recommendation (`coach-analysis.md` → CV Type judgment principle, rule 1) — her own market knowledge, never a plugin-shipped table.

**If `Variant` was chosen:** the per-role `CV Type` field must exist on whichever job-tracking backend was set up above — see the addition to Option A/B/C's instructions in Phase 5 above (the Notion template needs it added manually; the Sheets/other-platform column list already includes it).

---

**Document templates**
Every export reads five possible files from `career-data/references/templates/` by **fixed filename — there is no config key for any of them** (R-38, 2026-07-04 fix): `cv.dotx`, `cv-brief.dotx` (collected above, only if Brief/Variant was chosen), `cover-letter-template.dotx`, and the optional Hebrew pair `cvHe.dotm`/`he-letter.dotx` (collected separately below, only if the user configured a second language). The pipeline looks for these exact names and nothing else — it never reads a config key or an external OS path for any of them.

Ask: "Do you want to use the included CV and cover letter templates, or provide your own `.dotx` files?"
- If own files: copy each into `career-data/references/templates/`, **renaming to the fixed filename regardless of the file's original name** — the user's file becomes `cv.dotx` / `cover-letter-template.dotx`. The pipeline cannot find a template under any other filename.
- If default: copy the plugin's own `${CLAUDE_PLUGIN_ROOT}/references/cv-template-default.dotx` and `${CLAUDE_PLUGIN_ROOT}/references/cover-letter-template.dotx` into `career-data/references/templates/` as `cv.dotx` and `cover-letter-template.dotx`.

**Role matching and title rules (2026-10-19).** Ask once: "Should roles be matched to what you can do (responsibility coverage; titles only a nudge — the default), or to official titles only?" Write `role_matching` as `capabilities` (default) or `titles`. Then ask, optionally: "Any standing rules for how your past job titles read on a CV? (e.g. 'always keep my title at Acme')" — write each as a `cv_title_rules` entry (`employer`, `disposition` `keep`|`retitle-as`, `title`, `note`); blank is fine. Write the confirmed Phase 4 `scope_preferences` here too. All three keys are optional in the JSON block.

**CV footer (Education/Languages) — `static-cv-footer.md`, and its Hebrew twin — ask first (2026-07-12 fix).** Every CV export can append a static Education/Languages block after cv-writer's own markdown, before pandoc conversion (`$CV_FOOTER` — see `career-engine-export/SKILL.md`'s Templates section, 2026-07-09 fix); whether it does is `cv_footer.inject` in `pipeline-preferences.json` (default `true`). Ask before assuming: "Should the pipeline add your Education/Languages section to every CV automatically, or do you handle that yourself — e.g. a personal Word macro you already run after export?" — some users already have their own process and don't want a second, plugin-managed copy to keep in sync.
- **If she wants it managed:** set `cv_footer.inject` to `true` (or leave it at its default), copy the plugin's blank default `${CLAUDE_PLUGIN_ROOT}/skills/career-engine-export/static-cv-footer.md` into `career-data/references/static-cv-footer.md` (and, only if a second language was configured, `static-cv-footer-he.md` into `career-data/references/static-cv-footer-he.md`), then ask: "I've added a placeholder Education/Languages section that appears on every CV — what are your actual degrees, institutions, and languages? I'll fill it in now." Write her real answers directly into the copied career-data file, replacing the `{{...}}` placeholders — never leave this step for "later," since every export between now and then would ship the unfilled placeholder text.
- **If she manages it herself:** set `cv_footer.inject` to `false` in `pipeline-preferences.json` and skip creating `static-cv-footer.md`/`static-cv-footer-he.md` entirely — the pipeline never reads or requires them when this is `false`.

**Cover letter structure template (`cover_letter_templates.md`).** Also copy `${CLAUDE_PLUGIN_ROOT}/references/cover-letter-templates-default.md` into `career-data/references/templates/cover_letter_templates.md` — the generic, parameterized Template A (Cold/Scaffold) / Template B (Warm/Woven) structure the letter-writer selects between per JD/context (see `agents/letter-writer.md` Step 0.7). It ships with placeholder tokens and universal defaults; it is meant to be personalized over time as the user's own delivered letters accumulate.

**Tell the user, verbatim:**
> "You can replace any or all of these templates whenever you like — swap the `.dotx`/`.dotm` files for your own from any platform or design tool, and edit `cover_letter_templates.md` directly to match your own preferences and voice. One thing has to stay fixed inside the `.dotx`/`.dotm` files: the named Word styles themselves (RoleTitle, RoleOverview, Salutation, Signature Char, and the rest — see the custom-style annotation reference in `skills/career-engine-export/SKILL.md`). The pipeline finds formatting by style name, so you're free to restyle fonts, colors, and layout however you like as long as those names don't change."

**Draft Directory link base**
Ask: "Do you use a cloud file-share or file-browser app (e.g. Anchorpoint, Dropbox, Google Drive) that produces a stable folder URL pointing to your output folder? If yes, paste the base URL up to (and including) the separator before the date folder. If not, answer `skip`."

Examples of the expected format (the URL must end just before the date-folder segment):
- Anchorpoint: `https://app.anchorpoint.app/.../<workspace>/files/<path-to-output-folder>/`
- iCloud web share: share the output folder once; the link base is the part before the date-folder portion
- Answer `skip` if you don't use a cloud file browser or don't want Notion links

- Write the answer (or the literal word `skip`) as `draft_dir_url_base` in the career-data config. No plugin-file substitution (R-38).
- When the value is `skip`, the pipeline leaves the `Draft Directory` Notion property empty.

**Output directory prefix (optional)**
The pipeline creates a run folder named `<prefix>-YYYY-MM-DD` inside your output folder. Default prefix is `applications` (e.g. `applications-2026-06-15`). If you want a different name (e.g. `jobs`, `cv-runs`, `pipeline`), provide it — otherwise leave blank to use the default.
- Write the prefix (or omit the key to use the default `applications`) as `output_dir_prefix` in the career-data config.

**Default language**
Ask: "What is your primary language for CVs and cover letters? (e.g. `English`, `Hebrew`, `French`) This is used when the Notion row's `Languages` field is empty — the pipeline will produce output in this language only."
- Write the answer as `default_language` in the career-data config. If the user doesn't answer or is unsure, write `English`.

**Gap handling**
Ask: "Should the pipeline run gap analysis for every role? Gap handling identifies where your background doesn't fully match the JD and gives the coach and writers a strategy for handling each gap.

- **Enable (recommended if unsure):** The coach identifies and documents gaps for every role. You can suppress it for a specific role at any time by adding 'no gap handling' to your prompt when starting a run.
- **Disable:** Gap handling is skipped entirely for every run. Strategy and framing only — faster, but no gap analysis.

If you're not sure, leave it enabled. You can always turn it off per-role when it isn't relevant."

**Your location (recommended)**
Ask: "What's your location (city, country, or region — e.g. 'Israel', 'Germany', 'EU')? This feeds job sourcing, the coach's location research, and the CV-format recommendation for roles with unclear locations."

- Write `location_compatibility: {"my_location": "<value>"}` to the config (empty string if skipped).
- **The compatibility-verdict property is retired (2026-07-23, per the user's direct instruction)** — do not ask for or write a `database_property` key; no agent writes a location-compatibility verdict to the tracker anymore. Older configs carrying `database_property`/legacy `notion_property` are simply ignored at runtime.

**Favorite brands (optional).** Ask: "Do you have any companies you'd like to always prioritize one tier higher than the coach would normally score? If yes, list them. You can update this list at any time." Write the list to `favorite_brands` as a JSON array of strings. Empty array = no boost applied.

**Screening answers (optional).** Ask: "A few standing answers help the coach flag fit and help sourcing rank roles — answer any that apply, skip the rest (free text):
- Travel — how much are you up for? (e.g. 'open to frequent travel', 'prefer minimal', 'up to ~25%')
- Relocation — willing to relocate, and where?
- Security clearance — eligibility or status (matters for defense roles)
- Compensation floor — minimum base you'd consider
- Availability — when you could start / notice period"
Write the answers into `screening_answers` (object with `travel`, `relocation`, `security_clearance`, `compensation_floor`, `availability` — each a free-text string, blank to skip). All optional: a blank field is simply not checked. Intake flags a match or conflict in Patterns (advisory, never a gate); sourcing down-ranks a conflicting role with a visible label (never excludes it).

**Job site preferences (optional).** Ask in two parts:

1. "Are there specific job sites you always want searched? List up to 5 (e.g. Wellfound, Greenhouse, a specific industry board). These will be searched on every sourcing run, in addition to standard boards."

2. Read `${CLAUDE_PLUGIN_ROOT}/references/locale-job-boards.md`, find the row for the user's country (from the location they gave), and propose that row's boards as the local shortlist: "Based on your location, these local boards are worth prioritizing: [list the country row's ATS / VC / aggregator / localized-major entries]. Pick up to 2, and name any others specific to your location I should know about." If no country row matches, propose the generic/default row.

Write the answers into `preferred_job_sites` (up to 5 entries) and `local_job_sites` (up to 2 entries) in the career-data config. Empty arrays if the user skips or has no preferences.

**Sourcing preferences (optional — recommended).** Ask: "A few questions help sourcing find and rank the right roles — answer any that apply, skip the rest:
1. Target titles — what job titles are you targeting? List them in priority order.
2. Remote preference — remote only, hybrid, or open to all?
3. Exclude patterns — any words that should auto-exclude a role? (e.g. 'junior', 'intern')
4. Default search time range — how far back should a sourcing run look by default? (e.g. 'last week', '2 weeks', 'month')"
Write the answers into `target_titles` (array, priority order), `remote_preference`, `exclusion_patterns` (array), and `default_search_time_range` in the career-data config. If skipped, `source-open-roles`' own Gate 1 asks on first run instead — this is not a hard blocker.

**Title variants / search keywords (recommended, only if `target_titles` was just set above).** Sourcing searches each target title under several variants, not verbatim. Propose a set (~6–8 per target title) derived from the target titles just given + `USER_PROFESSION` / `USER_FUNCTION_SENIORITY_HIERARCHY`: "Here are the title variants I'd search for you — edit, add, or remove any:" then list one line per target title with its variants (e.g. *Product Marketing lead → PMM · Senior PMM · Technical PMM · Director of Product Marketing · Head of Product Marketing · GTM Lead*). Write the confirmed set into `title_variants` in the career-data config (an object keyed by target title, each value an array of variant strings) — replacing the placeholder description text. This is what `source-open-roles` reads every run.

**Rule: user-specified sites in `preferred_job_sites` and `local_job_sites` always take priority over plugin defaults. The plugin's built-in site list is a fallback, not a directive.**

- Write the gap-handling choice, your location (`my_location`), favorite brands, job site preferences, and sourcing preferences **alongside** every other key set in this phase — one career-data config file (readable everywhere, survives upgrades). The complete file (R-38):
  ```json
  {
    "gap_handling": "enabled",
    "output_folder": "<the absolute path the user gave>",
    "database_backend": "notion",
    "database_id": "<32-char DB id, or empty for non-database trackers>",
    "database_new_view_url": "<New view URL, or empty>",
    "database_interested_view_url": "<Interested view URL, or empty>",
    "database_hold_view_url": "<Needs Research view URL, or empty>",
    "database_researched_view_url": "<Researched view URL, or empty>",
    "database_cv_ready_view_url": "<CV Ready for Review view URL, or empty>",
    "database_edit_view_url": "<Needs Editing view URL, or empty>",
    "draft_dir_url_base": "<cloud-share base URL, or skip>",
    "output_dir_prefix": "applications",
    "default_language": "English",
    "location_compatibility": {
      "my_location": "<city/country/region, or empty to skip>"
    },
    "cv_type": {
      "mode": "<Detailed | Brief | Variant>",
      "brief_has_photo": "<yes / no, or empty>"
    },
    "favorite_brands": [],
    "preferred_job_sites": [],
    "local_job_sites": [],
    "target_titles": [],
    "title_variants": {},
    "remote_preference": "<remote only / hybrid / open to all, or empty>",
    "exclusion_patterns": [],
    "default_search_time_range": "last week",
    "screening_answers": {
      "travel": "<e.g. 'open to frequent travel', or empty>",
      "relocation": "<willing + where, or empty>",
      "security_clearance": "<eligibility/status, or empty>",
      "compensation_floor": "<minimum base, or empty>",
      "availability": "<start date / notice, or empty>"
    }
  }
  ```
  (`gap_handling` is `"enabled"`/`"disabled"`; `output_dir_prefix` defaults to `"applications"` if omitted; `location_compatibility.my_location` empty = location context skipped; a `database_property` key in an older config is ignored — the verdict property was retired 2026-07-23; `favorite_brands` empty array = no boost.) **Required for any run:** `output_folder`; **also required when a database backend is configured:** `database_id`. **`cv_type.mode` is always explicitly asked and written during setup** (see "CV Type" above) — never left to the JSON default; `brief_has_photo` stays optional. **Every other key is optional** — a run completes without it and the config-health notice lists what is empty/missing. There is no `cv_template` or `word_templates_path` key (R-38, 2026-07-04 fix) — CV/cover-letter/Hebrew templates resolve by fixed filename from `career-data/references/templates/`, never a config lookup. Write the `database_*` names on a fresh setup; the pipeline still reads the legacy `notion_database_id`/`notion_needs_editing_view_url`/`notion_property` names for older configs. The orchestrator and standalone entry skills resolve every `{{CONFIG}}` placeholder from this file and stop only if a *required* key is missing. Never substitute any of these into plugin files.
  (or `"disabled"`, matching the user's choice). Preserve any other keys already present in the file.
- Apply the **Writing personal data** rule: in Claude Code write `career-data` directly; in Cowork stage the change and emit the Appendix-A handoff (`references/career-data-skill-handoff.md`). Refresh the `career-data` backup export after a direct write.
- Do NOT write this preference to `~/.claude/settings.json` — that location is reachable only from the user's own machine and silently falls back to the default everywhere else. The pipeline still reads it as a legacy fallback, but `career-data` is the authority.
- Verify by reading the file back and confirming the value matches the user's choice.

Confirm: "Phase 5 complete. Job tracking, output folder, CV template, and gap handling preference are configured."

---

## Phase 6 — Permissions

**Purpose:** Without pre-approved permissions, Claude Code will pause mid-pipeline for approvals on every bash command and MCP call.

Read the current MCP tool IDs from `.claude/settings.json`. Generate the exact allow-list block for the user's `~/.claude/settings.json`:

```json
"permissions": {
  "allow": [
    "Bash(pandoc *)",
    "Bash(python3 *)",
    "Bash(cp *)",
    "Bash(ls *)",
    "Bash(mkdir *)",
    "Bash(cat *)",
    "Bash(ntn pages get *)",
    "Bash(ntn datasources query *)",
    "Bash(ntn datasources list *)",
    "Bash(ntn whoami)",
    "mcp__notionApi__API-query-data-source",
    "mcp__notionApi__API-retrieve-a-database",
    "mcp__notionApi__API-retrieve-a-page",
    "mcp__notionApi__API-retrieve-page-markdown",
    "mcp__notionApi__API-retrieve-a-page-property",
    "mcp__notionApi__API-retrieve-a-block",
    "mcp__notionApi__API-get-block-children",
    "mcp__notionApi__API-post-search",
    "mcp__notionApi__API-patch-page",
    "mcp__notionApi__API-get-self",
    "mcp__notionApi__API-get-user",
    "mcp__notionApi__API-get-users",
    "mcp__notionApi__API-list-data-source-templates",
    "mcp__notionApi__API-retrieve-a-comment",
    "mcp__linkedin-mcp__search_people",
    "mcp__linkedin-mcp__get_person_profile",
    "mcp__linkedin-mcp__get_company_profile",
    "mcp__linkedin-mcp__get_company_employees",
    "mcp__linkedin-mcp__get_company_posts",
    "mcp__linkedin-mcp__get_job_details",
    "mcp__linkedin-mcp__search_jobs",
    "mcp__linkedin-mcp__search_companies",
    "mcp__linkedin-mcp__get_my_profile",
    "mcp__linkedin-mcp__get_feed",
    "mcp__linkedin-mcp__get_inbox",
    "mcp__linkedin-mcp__get_conversation",
    "mcp__linkedin-mcp__get_sidebar_profiles",
    "WebFetch(*)",
    "WebSearch(*)"
  ]
}
```

Present the block and say:

"Add this to your `~/.claude/settings.json` under the `permissions` key. If a permissions block already exists, merge the allow arrays."

Ask: "Have you added the permissions block? You can do this now and come back, or skip and add it before your first run."

**Token usage tracking (optional but recommended):**

The pipeline tracks actual token consumption per run. Each run writes a `run-metrics-<date>.json` file to your output folder with structural metrics (roles processed, agents invoked). A Stop hook then fills in the real token counts and an estimated cost.

The hook ships with the plugin and **registers itself** via `hooks/hooks.json`, so on a current Claude Code there is nothing to configure — confirm by checking that `run-metrics-*.json` files show numeric `token_counts` after a run (not `"pending"` or `"unknown"`).

It reads counts from the session transcript and every subagent transcript (not from the hook payload, which carries no token data — R-40), and writes them into the `run-metrics` file the run created this session.

**Only if your Claude Code version does not auto-load plugin hooks**, add the block manually to `~/.claude/settings.json`, replacing `${CLAUDE_PLUGIN_ROOT}` with your plugin install path (shown in Claude Code's plugin settings):

```json
"hooks": {
  "Stop": [{
    "hooks": [{
      "type": "command",
      "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/log-token-usage.sh"
    }]
  }]
}
```

Ask: "Token tracking is built in and self-registering. Want me to verify it's firing, or generate the manual hook block as a fallback?"

Confirm: "Phase 6 complete. The pipeline will run without approval prompts."

---

## Phase 7 — Job-preferences configuration

**Purpose:** Some job searches involve geographic friction — applying internationally, working through recruiters, or submitting through platforms with strict formatting rules. This phase configures rules to handle those situations correctly. **Skip this phase entirely if the user is applying only to roles in the country they live in, in one language, submitted directly by themselves.**

Ask: "Does your job search involve any of the following? Say 'none' to skip this phase entirely.

1. Applications submitted through a recruiter or agency (you won't see the JD before they do)
2. Applying to roles in a country or market different from where you're based
3. Platform submissions (LinkedIn Easy Apply, Workday, Greenhouse) where formatting and length rules differ from a direct application
4. Applications in a language other than your primary language

If none of these apply, say 'none' and I'll skip to verification."

**If none apply:** confirm and move on. No job-preferences rules are needed for application submission.

**If any apply:** present the default job-preferences rules and ask whether they are appropriate:

---

**Default job-preferences rules (present these to the user):**

> 1. **Recruiter-submitted applications:** Remove all first-person pronouns from the CV (no "I", "my", "me"). Use action verb openings instead. Cover letters may retain first person — confirm with the recruiter.
> 2. **Remote location:** If the role lists a country/city as required and you are remote, add "(Remote)" after your location in the contact header. Do not fabricate a local address.
> 3. **Platform submissions:** Respect character or word limits if stated. Where a rich-text letter is not accepted, omit the cover letter rather than pasting into a plain-text field.
> 4. **Language:** If a role's `Languages` field includes a second language, run the localization agent after the English pipeline. The localized output is the submission copy.

---

Ask: "Do these rules match how you work, or do you need to change any of them? You can also add rules for contexts not listed here."

If the user confirms the defaults: write them to a `remote-compat` block in `.claude/settings.json` as:
```json
"remote_compat": {
  "remove_first_person_cv": true,
  "add_remote_location_label": true,
  "omit_letter_on_plain_text_platforms": true
}
```

If the user changes or adds rules: capture the custom rules in plain language and write them to `references/01-writing-rules.md` under a new section **§ Job-preferences rules**. Also write any boolean flags that changed to `.claude/settings.json`.

Confirm: "Phase 7 complete. Job-preferences rules are configured."

---

## Pipeline Orientation

Before completing onboarding, walk the user through how the pipeline works. Present this as a briefing, not a list to read.

---

### The two pipelines

**New Application pipeline** (`/career-engine` or `/career-engine`)
The main pipeline. Picks up all roles in your tracking database with Status = `Interested`, and for each one:
1. Coach analysis — reads the JD, writes Role emphasis, Strategy, Keywords, Gap handling
2. CV writer — drafts a tailored CV
3. Gatekeeper — checks the CV for rule violations
4. Recruiter review — evaluates the CV
5. Cover letter writer — writes the letter (if Why I Want This Role is filled in)
6. Cover letter gatekeeper + recruiter review
7. (Retired 2026-07-26) Humanizer — its quantitative checks now run inside the gatekeeper (Gate 10)
8. Export — produces DOCX files

**Edit pipeline** (`/career-engine --edit`)
For roles where you already have a CV and/or letter and want targeted revisions. Set `Edit type` to `CV`, `Letter`, or `Both` in your tracking database before running. Only runs the relevant sub-pipeline for each role.

---

### What is mandatory for each pipeline

| Input | New Application pipeline | Edit pipeline |
|---|---|---|
| Job URL or JD Body | Required — pipeline cannot run without one | Required |
| Status = Interested | Required | Status = any active status |
| Edit type field | Not used | Required — CV / Letter / Both |
| Why I Want This Role | **Optional.** Role-specific motivation that strengthens the letter's opener. If empty, the letter-writer works from your Motivation Bank; the letter is skipped only if neither this field nor a role-relevant Bank entry has usable material. | Optional |

---

### Why I Want This Role and the Motivation Bank — what "good" looks like

`Why I Want This Role` is your **role-specific** motivation for a given role; the **Motivation Bank** (`background/background-motivation-bank.md`, seeded during setup) is your **standing** motivation, reused across roles. Both are the same kind of content — your own words — and the same "good" standard applies to both. The letter-writer's *primary* source is the Motivation Bank; `Why I Want This Role` adds role-specific motivation on top when you provide it. The richer your Motivation Bank, the less often you'll need to write `Why I Want This Role` at all. The opener is the most important paragraph in the letter — it is what makes a letter yours rather than a template. The agent cannot invent your motivation, your specific reaction, or your angle on a company. If it does, that is fabrication.

**Good:** Specific. Your actual reaction when you read the JD. What you noticed, what excited you, what connected to something you've done or want to do. A few sentences is enough. Examples of what works:
- "The thing that grabbed me was that they're building agentic SecOps — I spent two years marketing exactly this layer and I've been watching this space evolve. I want to be the person building the story for the next platform."
- "I daydream about consumer campaigns. I've spent my whole career in B2B and I'm genuinely ready to apply what I know to products people actually want."
- "I worked at [Company] for five years and I know exactly how the enterprise buying cycle moves. This role is why I'd come back."

**Not enough:** "I think this role is a great fit." / "I'm excited about this opportunity." / "This company does interesting work." These give the agent nothing to work from. The letter will be a placeholder until you fill in more.

**How empty works:** If `Why I Want This Role` is empty, the letter-writer doesn't stop — it writes from your Motivation Bank (your standing motivations). It skips the letter only when *neither* `Why I Want This Role` *nor* any role-relevant Motivation Bank entry gives it usable material; when it skips, it tells you to add `Why I Want This Role` for that role or enrich your Bank. The agent never generates motivation on your behalf — that would not be your letter. The takeaway: seed your Motivation Bank well (see the Motivation Bank seeding step), and over time you'll rarely need to write `Why I Want This Role` at all.

---

Present this to the user and ask: "Any questions before we do a final verification check?"

---

## Build & install career-data

**If any career-data files were authored or changed this session, run this step before the session ends** (whether all phases are done or the user is stopping). It turns the working `career-data/` files into an installed skill. If nothing was authored yet (e.g. the user stopped during Phase 1 before any file was written), skip it — there is nothing to install. Follow [`references/career-data-skill-handoff.md`](../../references/career-data-skill-handoff.md) ("Appendix A") — branch on the environment detected in Phase 0:

**If in Claude Code (CLI):**
1. Write the complete `career-data/` directory to `~/.claude/skills/career-data/` (structure per the handoff reference: `SKILL.md`, `career-data-marker.json`, `references/...`).
2. Confirm `career-data-marker.json` lists every authored file in `expected_files` and each exists and is non-empty.
3. Write the first backup export of `career-data` to the output folder.
4. Tell the user it's installed **in Claude Code specifically**, and that this copy is local to Code. Chat and Cowork use a separate, shared skill store — a Code-only skill is invisible to them. So if they also use Chat and/or Cowork, `career-data` must *also* be created in Chat (via `/skill-creator`), or it won't exist in those environments.
5. **Then ask — with a visual, minimal text — whether they also use Chat/Cowork (and want the Chat handoff prompt) or are all set with Code only. This is a question: present it and wait for the reply.** Show this two-option visual (render as an artifact if supported, else the text version):

   ```
     career-data is installed in Claude Code ✅

     Do you also use Chat or Cowork?

     ┌──────────────────────────────┐   ┌──────────────────────────────┐
     │  YES — Chat/Cowork too        │   │  NO — Code only               │
     │  → I'll hand you a prompt to  │   │  → You're all set ✅          │
     │    create it in Chat          │   │                               │
     └──────────────────────────────┘   └──────────────────────────────┘
   ```

   - **If they also use Chat/Cowork:** generate the `/skill-creator` create prompt from the handoff reference's template (full file contents inline, untruncated; instruct them to attach the `.dotx` and any delivered-letter files), and present it as one copyable block led by the four-step visual from Phase 0 — exactly as the Cowork branch does below.
   - **If Code-only / all set:** confirm setup is done; no handoff needed.

**If in Cowork:**
1. **Lead with the four-step visual** from Phase 0 (render as an artifact if supported, else the text strip) — minimal words.
2. Assemble the `/skill-creator` create prompt from the handoff reference's template, filling every file's full contents inline (untruncated). For the `.dotx` and any delivered-letter files, instruct the user to attach them in Chat.
3. Present the prompt as **one copyable block** with a single instruction above it: *"Copy everything in the box, open Chat, type `/skill-creator`, paste, and press Enter."* If it exceeds one Chat message, split at a file boundary and label `Part 1 of N`.
4. Confirm `/skill-creator` is installed in Chat before they start (it's Anthropic's). If not, tell them to install it from Chat's skill list first.
5. Write the working `career-data/` directory and a backup export to the output folder so nothing is lost.
6. Tell the user: once Chat says the skill is installed, it's available back here in Cowork automatically (shared skill store) — return to Cowork and we continue. Do **not** claim the skill is installed from Cowork; only Chat installs it.

---

## Verification

Run after Phases 1–5 are complete.

1. **Placeholder scan:** `grep -r "{{USER_" ${CLAUDE_PLUGIN_ROOT}/references/ | grep -v "{{USER_ANSWER_"` — report any identity or contact placeholders still unfilled
2. **Integration check:** Confirm the output folder exists. Confirm the CV template file exists at its configured path.
3. **Dependency check:** Run `pandoc --version` and `python3 -c "import docx"`. If either is missing, ask the user: "pandoc [or python-docx] is not installed. Want me to install it for you?" If yes, run `brew install pandoc` (macOS) or `pip3 install python-docx` as appropriate using Bash. If the user is on Linux or Windows, ask them to confirm their system so you can use the right package manager command.
4. **Framework check:** Confirm `03-framework.md` has no sections still marked `[REVIEW]` or `[DRAFT]`
5. **Summary:** Report which phases are complete and which are outstanding

If Phases 1–5 are complete and dependencies are installed:

"Onboarding complete. You're ready to run `/career-engine`. Before your first run:

- Add roles to your Notion database (or CSV) and set their Status to `Interested`.
- **Why I Want This Role:** For each role you want a cover letter for, fill in the `Why I Want This Role` field in Notion before running the pipeline. Write your genuine motivation — a sentence or two is enough. If this field is empty when the pipeline runs, the cover letter will be skipped and only the CV will be delivered. The pipeline will never generate this for you.
- **Edit type (for editing runs):** When using the edit pipeline (`/career-engine --edit`), set the `Edit type` field to `CV`, `Letter`, or `Both` for each role before running. Roles without this field set will be skipped.
- **Gap handling:** Configured in Phase 5. If enabled, you can suppress it for a specific role by adding "no gap handling" to your prompt when starting a run.

Run `/career-engine` to start. The pipeline will pick up all `Interested` roles automatically."

---

## Style notes

- Direct and efficient. One theme of questions at a time.
- If the user says "skip" or "later" for anything, move on immediately and note it as outstanding.
- When building `03-framework.md`, be confident where the evidence is clear. Use `[DRAFT]` only where you are genuinely uncertain.
- Never fabricate voice samples, testimonials, or proof points. If the materials don't contain them, leave the placeholder.
- The interview is a conversation, not a form. Adjust based on what you already know from the materials.
