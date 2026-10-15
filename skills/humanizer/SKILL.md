---
name: humanizer
description: "RETIRED from all pipelines (2026-07-26, per the user) — loaded only for explicit standalone use; never part of a pipeline round. Complete doctrine for the humanizer agent — the former final-stage editing pass that removes AI writing patterns from a gatekeeper-approved cover letter. Contains the R-37/R-41 mechanics, the input contract, the six-step editing procedure, the Quantitative Final Gate, and the voice calibration protocol (pipeline vs standalone). Relocated from `skills/writer-craft/SKILL.md` §12-13 (Humanizer Mechanics and Voice Calibration Protocol) — that content was humanizer-specific and not used by cv-writer or letter-writer, the writer-craft skill's other two consumers."
---

> **⛔ RETIRED FROM ALL PIPELINES (2026-07-26, per the user's direct instruction, 2026-07-26: "The only thing humanizer seems to actually effectively be doing is taking semi and/or non-slop and turning it into its own version of slop. Not helpful. give the gatekeeper the quantitative checks and get rid of humanizer").** The Quantitative Final Gate below now lives in the gatekeeper's Gate 10 (`skills/gatekeeper-checks/letter-gates.md`) — that copy is authoritative; this file is history plus explicit user-initiated standalone use only.

# Humanizer — Doctrine and Procedure

This is the humanizer agent's complete pattern list and procedure. The agent file (`agents/humanizer.md`) holds identity, scope, and invocation; this skill holds the mechanics — what to load, what to do, in what order, and the gate that must pass before returning output.

---

## `career-data` data root (R-37)

The personal-data files — `01-writing-rules.md`, `02-professional-background.md`, `03-framework.md`, `linkedin-profile.md`, `pipeline-preferences.json`, `delivered-letters/`, and the user's `.dotx` — load from `${CAREER_DATA}/references/`, the path the orchestrator resolves in its `career-data` discovery preflight and passes into this spawn. Every other file (self-checks, `REFERENCES.md`, skill docs, default `.dotx` templates) stays on `${CLAUDE_PLUGIN_ROOT}`.

If `${CAREER_DATA}` was not provided (direct or standalone invocation), locate the `career-data` skill yourself, confirm `career-data-marker.json`, and apply the orchestrator's healthy / damaged / absent outcomes before reading. A configured user's missing `career-data` is a hard stop — never silently fall back to blank templates.

---

## Output protocol (R-41)

The orchestrator passes the letter at `LETTER_PATH` (the orchestrator names the file; `$PIPE/letter-final.md` in the new-application pipeline) — edit it **in place** (do not return the letter body). Write your change log to `$PIPE/humanizer-changes.md`.

Return ONLY a 1-line status: `Humanized: <n> sentences changed → $PIPE/humanizer-changes.md` (or `No changes`). Edit only the letter file; write only the change-log file. **Your entire reply must be exactly that one status line and NOTHING else** — no preamble, no analysis, no narration. Do all editing/checking silently; the change-log file is where reasoning belongs, never the reply. Extra prose in the reply is an R-41 violation that re-bloats the orchestrator context this file mechanism exists to keep small.

---

## Input contract

**What I receive:**
- `CAREER_DATA=${CAREER_DATA}` — path to the career-data skill (for the delivered-letters archive and voice fingerprint)
- `LETTER_PATH` — the path to the final cover-letter markdown the orchestrator wants humanized, to edit in place (the orchestrator names the file; `$PIPE/letter-final.md` in the new-application pipeline)
- `$PIPE/voice-calibration.md` *(pipeline mode only, optional)* — a copy of the durable `${CAREER_DATA}/references/voice-calibration-coverletters.md` file, made by the orchestrator at new-application Step 4.9 / edit Step E6.8 when that durable file exists. When provided, read it AND the delivered-letters archive sample — see the Voice Calibration Protocol; the file supplements the archive, it never replaces it.
- `gap_handling_mode` *(one-word run token, passed to every pipeline agent — 2026-07-14 universal spawn parameter)* — requires no action from me; I edit language, not gap strategy. Its presence is sanctioned and is not the role-specific context the rule below bans.
- `OPENER_TEXT` *(pipeline mode, optional — 2026-07-24)* — the letter's opening sentence(s) pasted verbatim from the user-reviewed Letter Outline `Opener:` line. **PROTECTED TEXT: never edit, rephrase, trim, or "improve" it in any way** — it is the user's own reviewed prose (her bank sentence, her Notion review), which is exactly the register I calibrate everything else toward, and the final pre-export check diffs the letter against it verbatim. Every opener-directed item in my procedure and Final Gate (role-in-sentence-1, opening rhythm, transition density) treats the protected span as satisfied/out-of-scope and applies from the first unprotected sentence onward. Sanctioned like `gap_handling_mode` — not role-specific context.

**I do not receive and must not use:** Role summary, strategy, JD, Keywords, Why I Want This Role, or any role-specific context. If any of these are passed in the spawn call, ignore them. My inputs are the letter text, the career-data path, the optional `$PIPE/voice-calibration.md` file, and the no-action `gap_handling_mode` token.

---

## Editing procedure

1. **Load voice calibration.** My positive calibration anchor — what I am rewriting *toward*, not just what I am rewriting away from. Follow the Voice Calibration Protocol below in full — it defines pipeline mode (a `$PIPE/voice-calibration.md` file was provided) vs standalone mode (none was provided; read the durable career-data file directly, or the archive if that doesn't exist either). Do not start the pattern pass until calibration is loaded (or the archive is confirmed genuinely empty).

2. **Read the voice fingerprint.** Read `${CAREER_DATA}/references/03-framework.md` §Voice and tone and §Voice fingerprint (quantitative targets: length, sentence rhythm and spread, vocabulary commonness, person, tense — plus the flex variables that are the user's choice per letter, never mandated). The fingerprint and the calibration source (durable file or archive) together are the register authority; if either is missing or still templated, proceed on whichever exists.

3. **Load the pattern list.** Load `${CLAUDE_PLUGIN_ROOT}/skills/writer-craft/core.md` — the `[ALL]` sections (punctuation, vocabulary, structural bans, sentence mechanics). Load this skill's own Mechanics section below for the step-by-step procedure and the Quantitative Final Gate (sentence range, paragraph variance, passive density, hedging count) that must be verified before returning output. *(Prefix all plugin file paths with `${CLAUDE_PLUGIN_ROOT}/` — bare relative paths fail when this agent runs as a subagent.)* The delivered letters (or the durable calibration file) also serve the instinct check in Step 5 below.

4. **Work through the steps in order** (Step 0 through Step 5 below; **Step 0 — native, idiomatic English — runs first**). For each step: read every sentence in the letter one by one, compare it against every rule in that step's table one by one, rewrite immediately if it violates. Even if that means rewriting the same sentence multiple times. **Step 2 — the sentence-structure syntax rules (dangling participles, long noun-phrase subjects, relative clause embedding, false range, AI vocabulary bans, -ing appendages, em dashes, copula avoidance, passive voice, etc.) — is non-negotiable and runs on EVERY letter without exception. It cannot be skipped, soft-applied, or deferred. A letter that has not passed Step 2 has not been humanized.**

4a. **Exhaustiveness pass (applies to every step, not just Step 2).** Finding and fixing one instance of a rule does not clear the letter of that rule — a sentence-by-sentence read finds the *first* instance, not every instance. Before moving on to the next step, re-scan the whole letter once more against every rule you just fixed at least one violation of, specifically looking for a second occurrence of the same pattern (a gerund-phrase/abstract-label subject fixed in one paragraph but left standing in another; an approach-announcement-via-label rewritten once but not caught the second time it appears). A rule applied to one sentence and missed on an identical construction elsewhere in the same letter counts as a failure of that step, not a partial pass.

5. Where a sentence has no violations in any step: leave it exactly as written.

6. Where linguistic instinct flags something as AI-generated even if it doesn't match a named pattern: fix it and note it in the change log.

7. **Run the Final Gate.** Run every item in the Quantitative Final Gate below before returning anything. If any item fails, fix the violation and rerun the checklist from the top. Not done until every box passes. Returning output before the Final Gate is complete is a hard failure.

---

## Hard constraints

> **Letter pipeline file.** Before changing anything here, read the full file and confirm no load-bearing rule is being removed. Removing a rule is not the same as simplifying — check that the behavior it encodes is preserved elsewhere or explicitly retired by the user.

- Do not add content. Do not add proof points, company references, or new claims.
- Do not change the structure of the letter unless it serves your only goal of "humanizing" the language — paragraph order, word count target, and the strategic argument are not mine to touch.
- Do not introduce new sentences unless it is in order to fix existing ones. Only fix existing ones.
- Fixing AI patterns means making the writing simple, direct and more human — never less.
- If fixing a violation would require inventing new content that isn't documented, flag it in the change log and leave the sentence as-is.

---

## Humanizer Mechanics

The humanizer runs after the gatekeeper passes a letter. It does not draft, strategize, evaluate fit, or check fabrication. It does not add content — no new proof points, claims, or sentences. It only fixes existing ones. If fixing a violation would require inventing content, flag it in the change log and leave the sentence as-is.

**Run in order. Do not skip steps. Do not return output until every step and the Final Gate pass.**

**Step 0 — Native, idiomatic English (run first).** Every sentence must read as natural, fluent English judged against the delivered letters (or the durable calibration file). Three checks per sentence: (1) non-idiomatic/translated-feeling → rewrite to the same meaning in natural English - for example, "I stood up the entire function" should be rewritten to "I implemented the entire function"; another example: "I walked into semiconductor and computer-vision buyers" should be rewritten to "I interacted with semiconductor and computer-vision buyers"; (2) meaning unrecoverable → flag in the change log under "Unrecoverable sentence(s)," never invent a meaning. (3) Make sure the overall grammar is correct: check use of commas, periods, and semicolons to avoid run-on sentences and sentence fragments. Ensure pronoun clarity and consistent verb tense. 
**Never "correct" the user's voice** — informality, directness, fragments, and intentional stylistic choices consistent with the calibration source are not violations here. When unsure whether something is broken English or her intentional voice, treat it as her voice and leave it.

**Step 1 — Top 5 (the highest-yield checks; run these even under time pressure):**
1. Antithesis / pivot formula — absolute ban. Never write "[Subject] does/has X, but [subject] is Y." Includes: "It's not about X, it's about Y." / "This isn't just A, it's B." / "Not X — Y." Test: remove the "but" clause and everything before it. Treat it as fully non-negotiable, not a style preference.
2. [CL] Appended negating contrast — absolute ban, no carve-outs. The construction "[claim], not [X]" or "[claim], not as [X]" appended to a sentence. Fail: "I can execute quickly, not just strategize." Fix: make the positive claim and stop — cut everything from the comma forward.
3. False range — totalizing-claim family, not one syntax. "Everything from messaging to competitive analysis" is one surface form; "across every channel," "in every market," "across the whole funnel," "across the entire org" are the same violation — claiming a scope spans "everything"/"every X" without naming the real things inside it. Test: could you name the 2-4 real things this phrase stands in for? If not, cut the totalizing wrapper and name the specific things.
4. Approach-announcement — method-before-demonstration family, not one phrase. "My approach is..." is one surface form; "I go deep on the product," "I take a [X] approach," "I make it a point to..." are the same violation — naming a way of working as a claim with no specific instance attached. Fail: "My approach is deliberately research-first: every deliverable is backed by a thinking process I can stand behind." Fix: "At [Company], I spent the first three weeks interviewing buyers before writing a line of copy." Show it in action; never announce it.
5. Subject-first — no expletive constructions, no abstract label noun-phrase subjects (archive-consistent ramps pass).

**Step 2 — Sentence structure:** no dangling participles; no long noun-phrase or wh-clause-stacked subjects/objects; no inanimate or abstract-noun subject performing an action that requires human agency, skill, or intent — build, craft, drive, sharpen, unlock, power, position, deliver, and any other verb where the honest test is "could only a person actually do this?" (the list is illustrative, not exhaustive — apply the test, not just the named verbs; e.g. "Social-first sharpens that discipline" fails the test exactly as "X builds Y" does, even though "sharpens" isn't itself named here); parallel structure in coordinated clauses; no "and...and...and" stacking; sentence-length balance judged by ear against the calibration source — a paragraph that reads monotone needs intervention (see the Final Gate).

Contrived tricolons — ban the rhetorical tricolon assembled to sound impressive. Test: was it built to sound impressive, or to list real things that happened? Also banned: the same sentence opening used 3+ times in a row (monotone run).

[CL] -ing phrases appended after a main clause — max 3 per letter, every one content-bearing. "Contributing to," "showcasing," "highlighting," "enabling" tacked onto a complete sentence. A tail with real content (a real outcome, a real list) is fine at low count; a decorative tail ("…showcasing expertise") is banned at any count.

**Step 3 — Voice and vocabulary:** apply `skills/writer-craft/core.md` §2-§4 (AI vocabulary, banned phrases, antithesis, false range, approach-announcement, idioms) plus: passive voice rewritten active; "serves as/stands as/acts as" → "is"; no expert-claims not from the candidate's own words; no agent-invented methodology; no demonstrative pointing at an agent-coined abstraction ("that exact loop," "this same playbook" — name the actual work instead); filler phrases cut. **Named explicitly (writer-craft §2 bans this, but it is easy to under-apply as a background rule rather than an active check): metaphors and similes, including hollow spatial/abstract metaphors** — "the repeatable system underneath," "the muscle behind X," "what's driving this" — name the actual thing instead of pointing at a spatial abstraction of it.

**Step 4 — Structure:** company name in paragraph 1; role title in the first sentence; no repeated example, proof point, or number; no repeated distinctive 2-3 word phrase; every pronoun/demonstrative still has a live antecedent after cuts. **Mandatory trigger, not just a general reminder: any edit anywhere in Step 1-3 that changes a sentence's grammatical subject requires an immediate check, right then, of every pronoun/demonstrative in that sentence and the sentence immediately following it** — a subject-changing edit is the single highest-risk cause of an orphaned "it," "that adoption," or "this shift," and is exactly the case a generic "re-verify after every edit" reminder is too easy to skip on. Also: zero rhetorical questions in the opener, max 1 in the whole letter; no manufactured opener or strategy-analysis opener; close is its own paragraph; greeting format correct; no company-product-problem references, even subtle ones.

**Step 5 — Instinct check:** re-read the calibration source (durable file or delivered letters), read the revised letter sentence by sentence, ask "does this sound like it belongs there — same register, same directness, same rhythm?" Fix and log anything that sounds assembled even if it passed every named rule.

### Quantitative Final Gate — verify before returning, in order

These are demonstrated as real, load-bearing mechanics — the humanizer used exactly these to fix real issues in separate test runs. Not shelf-ware; do not cut.

1. **Sentence-length variation, calibrated — never manufactured (reframed 2026-07-16; formerly a "≥20-word range, one ≤8/one ≥25" quota).** Compare the letter's sentence-length spread against the archive's real figures (`corpus-stats.py` below — run it whenever the archive exists; its output replaces any static target). Flat, uniformly mid-length rhythm is a flag. **But the ONLY sanctioned fix is re-integrating real content — recombining a stitched pair, letting an existing punchline stand alone — never inserting a fragment, splitting a sentence, or trimming one solely to move the numbers.** A fragment with no semantic job is an AI tell this agent exists to REMOVE; the old quota provably manufactured them. If the letter's rhythm is flat and no content-borne fix exists, note it in the change log and leave the text alone — a flat-but-hers letter beats a bursty-but-fake one.
2. **Paragraph-length variation — same standard, same constraint.** Adjacent paragraphs of near-identical length read templated; compare against the archive's shape. Fix only through content moves that survive every other rule (merging a paragraph that genuinely continues its neighbor's argument, per the letter's own flow); never pad or shave to hit a spread. When the letter's structure is deliberate (e.g. a many-short-paragraph delivered register the archive itself shows), matching the archive IS the pass — log the observation, change nothing.
3. **Passive density ≤15%** (aim ≤10%). Count passive sentences ÷ total sentences.
4. **Hedging density = 0.** Epistemic hedges ("arguably," "perhaps," "I think," "I feel"), modal hedges ("could be," "seem to," "tend to"), soft qualifiers ("to some extent," "somewhat," "fairly"), boilerplate softeners ("I would love to," "I hope to"). Zero tolerance — direct future modals ("I will," "I can") and named conditionals ("If selected, I would lead...") are not hedging.
5. **Transition density ≤1 paragraph opener** from the prohibited class: "Furthermore," "Moreover," "Additionally," "However" (at paragraph start), "Therefore," "Consequently," "In addition," "That said," "On the other hand." ("And," "but," "so" don't count.)
6. **No Antithesis / pivot formula and no Appended negating contrast at all whatsoever.** Density = 0. Anything else is a HARD FAIL.

**Any FAIL on any of the six = fix and re-run the Final Gate from the top. Not done until every check passes.**

**Optional: real computed targets instead of the static defaults above.** `skills/humanizer/scripts/corpus-stats.py` is a generic, standard-library-only script that computes sentence-length distribution, subject-first-opener %, contraction rate, digit density, Flesch-Kincaid grade, and type-token ratio from any directory of letter files. When a delivered-letters archive exists (`${CAREER_DATA}/references/delivered-letters/`), run it against that directory — `python3 ${CLAUDE_PLUGIN_ROOT}/skills/humanizer/scripts/corpus-stats.py <archive_dir>` — and use its output as the real, per-user comparison figures for the variation checks 1-2 above. When no archive exists or the script cannot run, judge against the general shape (short declaratives coexisting with long, clause-trailing sentences) — there are no static numeric quotas anymore (2026-07-16); a number can flag, only content can fix.

---

## Voice Calibration Protocol

**The delivered-letters archive is always read — in every mode (restored 2026-07-16, per the user's direct instruction; the calibration file supplements the archive, it never replaces it).** The calibration file gives the statistical fingerprint; the real letters give the actual sound. Editing toward the fingerprint alone produces text that is grammatically hers and audibly not hers.

**Pipeline mode (`$PIPE/voice-calibration.md` provided):** Read it (it is a copy of the durable `${CAREER_DATA}/references/voice-calibration-coverletters.md` file, made by the orchestrator before this spawn — new-application Step 4.9 / edit Step E6.8). **Then** read `${CAREER_DATA}/references/delivered-letters/INDEX.md` and 3 letters from the archive (prefer domain-closest per the index notes, else any 3; fewer than 3 exist → read all).

**Standalone mode, or pipeline mode with no `$PIPE/voice-calibration.md`** (the orchestrator found no durable file to copy — new user, or the update-prompt delivering it hasn't been applied yet): fall back in order —
1. **Durable file present** at `${CAREER_DATA}/references/voice-calibration-coverletters.md`: read it, **then** read the archive sample exactly as pipeline mode does (INDEX + 3 letters).
2. **Durable file absent:** read `${CAREER_DATA}/references/delivered-letters/INDEX.md`, then read every letter in the archive (not 2-3 — all of them). If the archive is unreachable (path invalid, permission error, career-data absent): hard stop, do not proceed — report "Humanizer failed — delivered-letters archive is unreachable. Confirm `${CAREER_DATA}` is set correctly." If it exists but is genuinely empty (count = 0, no files): fall back further to `${CAREER_DATA}/references/03-framework.md` §Voice and tone, and note the fallback. Respect any do-not-copy caveats in the INDEX voice notes.

(In pipeline mode and fallback 1, an archive that exists but is genuinely empty — new user — is the one legitimate skip of the archive sample; the calibration file alone completes the gate. An unreachable archive is a hard stop in every mode.)

Note six dimensions from whichever calibration source was used: sentence length pattern, word-choice level, paragraph openers, punctuation habits, transitions, verbal tics. Match these — don't just remove AI tells, replace them with the calibration source's actual patterns. Additionally read `${CAREER_DATA}/references/03-framework.md` §Voice fingerprint — the quantitative targets (length, sentence rhythm and spread, vocabulary commonness, person, tense) that anchor the Final Gate metrics above.

**Regenerating the calibration file.** `${CAREER_DATA}/references/voice-calibration-coverletters.md` is a durable file the user regenerates manually when needed (new delivered letters added, a new output type needing its own calibration file, or a new user's first calibration). The generic six-dimension analysis method for producing it lives in `references/voice-calibration-method.md` — it is not part of this agent's own procedure; it is a standalone methodology a human or a future agent runs on demand.
