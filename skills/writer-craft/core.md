# Writer Craft — [ALL] Core Rules (§1–4, §12)

> Moved verbatim from `skills/writer-craft/SKILL.md` on 2026-07-22 (context-diet split). Section numbers (§) are preserved from the consolidated doctrine; `SKILL.md` is now the routing file. No rule was changed or removed in the move.

## [ALL] §1 — Absolute Punctuation Bans

**Em dash (—): zero, anywhere, no exceptions, no carve-outs.** Not "as a list separator," not for asides, not as a colon substitute. This was the single largest violation category in condensed-prompt testing (5 of 6 advisory hits in one test) specifically because a narrower "as a list separator" framing let other em-dash uses through. Fix: period (new sentence), comma (tight aside), or restructure. Before returning any output, search for `—`. Any hit means not done.

**Colon (:) — banned in CV and cover letter body copy [CV][CL].** Not for role labeling, not for introducing explanations, not before lists, not as an em-dash substitute. A real test letter used two colons that only the humanizer caught — a narrower rule ("avoid colons in lists") would have missed both. If you reach for a colon, restructure the sentence.

---

## [ALL] §2 — Banned Vocabulary (curated, high-signal subset)

**AI-tell words — cut on sight, replace with plain language:**
crucial, pivotal, vibrant, showcase/showcasing, tapestry (figurative), underscore (verb), landscape (abstract noun, e.g. "the marketing landscape"), testament, enduring, foster/fostering, garner, interplay, intricate/intricacies, foundational, transformative, robust, seamless, comprehensive, playbook (abstract concept — a real halted role shipped it to the final coach-review pass because this list was missing it while the gatekeeper's Gate 6 list, which cites this section as its source, banned it), leverage (verb), synergy, spearhead, paradigm, "know what it takes," land (verb, e.g. "make it land")

**Hollow self-description — replace with a specific named outcome:**
results-driven, passionate, dynamic, proactive, experienced, highly qualified, top performer, thought leadership, industry expert, motivated, track record, effective, seasoned, action-oriented

**Personal-voice exemption — same rule as the idiom exemption below, extended to this whole section.** A word on the lists above is banned as a *generic AI-tell* — the ban assumes an agent reached for it as filler. It stops being a violation when it's confirmed as the user's own authentic word choice: verbatim in her delivered-letters archive, her `01-writing-rules.md`, or her Why I Want This Role / personal input. Confirmed example: "passionate" and "at heart" identity idioms are her own voice, not agent filler — a gate that flags them without checking her own archive first is producing a false positive, not catching a real defect. When in doubt and no verbatim match is found in her own material, treat it as the generic AI-tell and flag it.

**[CV] Additional CV-only bans:** think outside the box, value add, go-to person, bottom line, big picture, cutting-edge, game-changer, guru, ninja, rockstar, world-class, paradigm shift, scalable, disruptive, innovative, holistic approach, agile. **Soft-skill filler is banned:** "works independently," "self-starter," "takes initiative," "manages own workload," "team player" as a standalone claim — demonstrate through bullet substance, never state it.

**Named phrase bans [ALL]:**

| Banned | Fix |
|---|---|
| "that made it land" | Name what it was and the result |
| "behind the [noun]" (e.g. "behind the coverage") | Name the actual work |
| "at an inflection point" | Name the specific moment |
| "quietly [verb]ing" | Name the action directly |
| "rare" as a self-descriptor | Demonstrate through specifics |
| "up close" | Cut it |
| "specialism" | Not a word — use "multi-disciplinary" or "[X] disciplines" |

**[CL] Cover-letter-only phrase bans:** "I was just doing X" (name company/role/outcome), "I know how to sell X" (name company and result), "I knew this was mine" (any variant — state the reaction directly), "I spent the better part of a decade..." (name the years), metaphors and similes (name the actual thing).

**[CL] Cover-letter-only bans — 2026-07-14 additions. Every one of these shipped in a real letter batch the user rejected outright; none is a style preference:**

| Banned | Why / Fix |
|---|---|
| "mandate" | Pipeline-internal analysis vocabulary (the `Role emphasis` **Mandate** label) leaking into letter prose — never her voice. Say what the job is in plain words. |
| "system" (figurative) | "Builds the system before it exists," "the system I built" meaning a function or process. Allowed only for an actual software/technical system. |
| "from a blank page" / figurative "blank page" | Not her phrase. Use documented phrasing instead (subject to the "zero to" cap below). |
| "for exactly that" / "exactly that combination" / "exactly that" as demonstrative emphasis | Points back at a recitation instead of saying the thing. Name the thing. |
| "in their flow" / "in the flow" (figurative) | Invented jargon ("kept developers in their flow"). Name what actually happened. |
| "toward the" as motion-metaphor motivation ("pulled me toward the [role]," "drew me toward") | Agent voice, not hers. State the want directly in her own words. Treat any letter-body "toward the" as a violation by default. |
| "handed me" as employer-agency framing ("never handed me a settled direction") | A company doesn't hand direction. Describe what she actually did, sourced from documented background. |

**"zero to" usage cap [CL] — allowed ONCE per letter, and only if "from scratch" is not already used.** "Zero to one," "zero-to-N," "from zero": maximum one occurrence in the whole body, and zero occurrences if "from scratch" appears anywhere in the letter. A real rejected letter carried three builder-origin phrases ("zero-to-one," "grew from zero to 13," "built from zero") — one is a credential, three are a tic.

**Narrating the act of reading the posting — banned, any version [CL].** "I've read the [Role Title] posting twice," "I read the posting and...," "the line about [X] is the one I read twice," "I've gone back to the posting" — performing diligence is not a reaction, and no version of this move may appear anywhere in a letter, opener or body. Two real letters shipped it in the same batch, in two different surface forms ("I've read the ... posting twice" and "is the one I read twice") — treat it as a family, not a fixed string. See §8 — the worked example there deliberately does not model this.

**Idioms — absolute ban [ALL], one exception.** Any figurative phrase used non-literally ("hit the ground running," "wear many hats," "move the needle," "low-hanging fruit," "at the end of the day," "take it to the next level," "raise the bar," "think outside the box," and all similar) is banned — UNLESS it appears verbatim in the user's own Why I Want This Role or personal input, in which case it is her voice and may be used exactly as written. When in doubt, treat it as an idiom and replace it.

---

## [ALL] §3 — Structural Anti-Patterns

**Antithesis / pivot formula — absolute ban.** Never write "[Subject] does/has X, but [subject] is Y." Includes: "It's not about X, it's about Y." / "This isn't just A, it's B." / "Not X — Y." **Test:** remove the "but" clause and everything before it. If what remains is clearer and stronger, the setup was unnecessary — cut it. This tripped as a real violation in condensed-prompt testing; treat it as fully non-negotiable, not a style preference.

**[CL] Appended negating contrast — absolute ban, no carve-outs.** The construction "[claim], not [X]" or "[claim], not as [X]" appended to a sentence. Fail: "I can execute quickly, not just strategize." Fix: make the positive claim and stop — cut everything from the comma forward.

**False range — totalizing-claim family, not one syntax.** "Everything from X to Y" is one surface form of a broader violation: claiming a scope spans "everything" or "every X" without naming the real things inside it. "Across every channel," "in every market," "across the whole funnel," "across the entire org" are the same violation in different words — not a narrower list to memorize, a family to recognize. Test: could you name the 2-4 real things this phrase stands in for? If not, cut the totalizing wrapper and name the specific things.

**Approach-announcement — method-before-demonstration family, not one phrase.** "My approach is..." is one surface form of a broader violation: naming or describing a methodology, depth of engagement, or way of working as a claim, with no specific instance attached. "I go deep on the product," "I take a [X] approach," "I make it a point to..." are the same violation. Test: does the sentence claim a way of working without immediately naming a specific company/artifact/outcome where she did it? Fail: "My approach is deliberately research-first: every deliverable is backed by a thinking process I can stand behind." Fix: "At [Company], I spent the first three weeks interviewing buyers before writing a line of copy." Show it in action; never announce it.

**Contrived tricolons — ban the rhetorical kind, keep real parallels.** A rhetorical tricolon assembled to sound impressive is banned. Parallel lists of real things (including 4-5 part parallels) are the user's style and are welcome. **Test:** was it built to sound impressive, or to list real things that happened? Also banned: the same sentence opening used 3+ times in a row (monotone run).

**[CL] -ing phrases appended after a main clause — max 3 per letter, every one content-bearing.** "Contributing to," "showcasing," "highlighting," "enabling" tacked onto a complete sentence. A tail with real content (a real outcome, a real list) is fine at low count; a decorative tail ("...showcasing expertise") is banned at any count.

**[CL] Unsubstantiated company-character claims and overreach — banned.** Never attribute something documented for only one past role to multiple roles, and never assert a fact about the company's business, culture, or product the user has not sourced from her own words or documented background. A real test overreach: claiming "AI agents doing the execution both times" when only one employer's bullets supported it. Every claim about scope, attribution, or pattern must be checkable against the specific role(s) it's grounded in — not generalized because it sounds better. **Prior-state claims about her own past employers are the same rule:** "I rebuilt what existed at [Company]," "I inherited a mess," "took over a stalled function" — what existed (or didn't exist) before her arrival is a factual claim that must trace to documented background like any other. A real rejected letter claimed "I rebuilt what existed at [Company]" about a company where the documented record shows she built the function from nothing — the claim was not just unsourced, it was backwards.

---

## [ALL] §4 — Sentence Mechanics

**Passive voice — rewrite active almost always.** Find the passive, ask who did the action, make them the subject. Fail: "The company was acquired by Contoso." Fix: "Contoso acquired the company."

**[CL] Subject-first rule.** Prefer "I" or a named entity as the sentence subject. Archive-consistent ramps (dependent clauses, prepositional openers matching the delivered letters) are the user's register and pass. **Hard ban, no carve-out:** expletive constructions ("There was/is/are") and abstract label noun-phrase subjects ("The founding-marketer part is..."). Fix: "I just finished building [thing] at [Company]."

**Sentence-length variation [ALL].** Mix long and short deliberately — short lands emphasis, long carries nuance. A paragraph that reads monotone — noticeably same-length, same-shape sentences with no variation — needs intervention: break a long sentence in two, fuse two short ones, or land the point in one short sentence. This is a calibration target judged by ear against the delivered letters, not a word-count formula; do not restructure a paragraph that already reads naturally.

**[CL] Sentence-rhythm variation — calibrated to her letters, never manufactured (reframed 2026-07-16; formerly a mechanical "one ≤8 AND one ≥25 words" floor).** Her delivered letters vary sentence length naturally — short declaratives land next to long, clause-trailing sentences (see the Voice Gate read and §8's Annotated Exemplar). Write with that variation from the draft; a letter of uniformly mid-length sentences reads flat and has reached export before. **But the variation must ride on real content: never write a fragment, or split a sentence, solely to satisfy a length target.** A short sentence earns its place by doing a job (an identity fragment, a causal fragment, a punchline after a long chain — §8's exemplar); a fragment with no job is an AI tell, not rhythm — the mechanical floor this rule replaces demonstrably manufactured them ("Doing good. Win win."). This is the gatekeeper's Gate 7 rhythm check and the humanizer's Quantitative Final Gate, both now measured against the archive's real statistics when available.

**Synonym cycling — ban [ALL].** Pick the right word and repeat it. Rotating synonyms to avoid repetition is an AI tell.

**[CL] Copula avoidance.** "Serves as / stands as / acts as" where "is" works. Use "is."

**Filler phrases — cut without replacement [ALL]:** "in order to" → "to"; "at this point in time" → "now"; "it is important to note that" → cut, start with the claim; "due to the fact that" → "because"; "has the ability to" → "can"; "in the event that" → "if."

---

## [ALL] §12 — Positive Writing Standards

- Direct statements without hedging; specific details, not abstractions
- Concrete examples and named outcomes; active voice and clear causality
- Trust the reader's intelligence; show expertise through specifics, never through labels
- Specific company names, numbers, and named outcomes — never generic claims
- Name the mechanism behind why something worked, not just that it worked
- One good example beats three paragraphs of argument

**Verbatim-preservation principle.** If the user's own words already say something well — in career-data, in WIWTR, or in a previous delivered letter — reuse them directly. Do not paraphrase, "clean up," or synthesize a smoother version, the same discipline already mandated for the Motivation Bank. This is a positive instruction, not just a permission: reusing exact phrasing that already worked isn't merely allowed, it's actively better — the sentiment lands more convincingly, and the user is far more likely to recognize the syntax as genuinely her own. Actively pull proven phrasing from the delivered-letters archive when it fits a new letter, rather than reworking it into something new because it happened to appear elsewhere already. Verbatim reuse across letters is not a defect — writing every letter from scratch is exhausting, and reusing proven, working phrasing is efficient. **This explicitly includes motivation and emotion (2026-07-16, per the user's direct instruction): her expressed enthusiasm, reactions, and want-statements in delivered letters and `03-framework.md` are sanctioned motivation sources alongside the Motivation Bank — never invent emotion, but never treat her already-expressed emotion as off-limits either. One constraint: lift an emotion only where it genuinely applies to the target role — a role-specific reaction moves to a new letter only when it is true for that role too.

**Applied as a drafting ORDER, not just an editing principle (2026-07-14):** assemble the draft from her existing verbatim material FIRST — matching Motivation Bank rows, delivered-letter phrasings, approved summaries and testimonials, `03-framework.md` lines — copying the pieces and adjusting only for context, connectors, and flow. Compose fresh prose only where nothing exists to assemble. Fresh composition calibrated to her voice afterward is the inversion that produces agent-tell letters: nearly every violation family this doctrine bans (AI vocabulary, invented jargon, manufactured openers, recited research) enters through freshly-composed sentences, almost never through her own copied ones. See the letter-writer's Assemble-before-you-compose step.

**Assembly semantics (2026-07-16 — "verbatim" is not "raw"):** her material comes in two classes, and assembly treats them differently.
- **Finished prose** (a Bank row written as sentences, a delivered-letter phrasing, an approved summary): carry it intact — this is the verbatim-preservation principle exactly as stated above.
- **Note-form shorthand** (a telegraphic WIWTR jot, a label, a fragment — "Doing good. Win win."): this is *meaning*, not prose. Develop it into a sentence in her voice that preserves her exact words *inside* a grammatical frame wherever possible ("Doing good while doing what I'm best at — that's the win-win I've chased since..."), never paste it raw as if it were a finished sentence. **Confirmed production failure:** a real shipped letter opened its second paragraph with the user's raw note "Doing good. Win win." — verbatim protection applied to shorthand produced a non-sequitur that 16 gatekeeper passes then refused to touch. Verbatim-paste of shorthand is §8's Failure mode A wearing the assembly rule as cover; it is a Gate 2 hard fail, not protected reuse.

**One argument, the coach's outline as the spine (corrected 2026-07-16 — per the user: WIWTR does NOT set the order; it is usually a scrap pile of notes, not a sequence).** The letter is ONE argument. Its paragraph structure and order come from the coach's pre-draft outline (`$PIPE/coach-outline.md` — per-paragraph claim / LEAD / SUPPORT argument plan since 2026-10-21, restored as writer input 2026-07-16): follow it. When no outline exists (standalone mode), the selected template's block order is the spine. **WIWTR is raw material, never a sequence** — mine it for content and voice, placing each piece where it does real work in the outline's structure. **`Role emphasis` selects the content:** it names what matters most in this role, so it decides which proof points, Bank entries, and WIWTR pieces carry the letter and what content type leads — the user usually writes WIWTR only after reviewing `Role emphasis` (and `Culture`), so the two are aligned by design; a letter whose emphasis ignores `Role emphasis` is mis-aimed even if every sentence is hers. Proof paragraphs slot INTO the argument (each substantiating the claim just made), and every paragraph must pick up from the one before it — a thread continued, a question answered, an argument extended. A structurally-valid stack of paragraphs that each pass their own gates but don't follow from each other is a failed letter (Gate 9 discourse-flow check). Before returning any draft, read only the paragraphs' first sentences in sequence: they should read as one person making one case.
