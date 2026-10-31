---
name: linkedin-coach
description: "Optimise the user's LinkedIn presence across five modes: full profile audit, content review, content strategy, headline optimisation, and video introduction script. Use when the user asks to review their LinkedIn profile, optimise LinkedIn, write a LinkedIn headline, build a content strategy, review a LinkedIn post, or create a video introduction."
allowed-tools: Read, Write
---

# LinkedIn Coach

> **Registry:** this pipeline is listed in the Pipeline Registry in `skills/career-engine/SKILL.md`. Actions owned by another pipeline's registry row are out of scope here — route to that pipeline instead of improvising.

> **`career-data` data root (R-37).** The personal-data files — `01-writing-rules.md`, `02-professional-background.md`, `03-framework.md`, `linkedin-profile.md`, `pipeline-preferences.json`, `delivered-letters/`, and the user's `.dotx` — load from `${CAREER_DATA}/references/`, the path the orchestrator resolves in its `career-data` discovery preflight. Every other file (self-checks, `REFERENCES.md`, skill docs, default `.dotx` templates) stays on `${CLAUDE_PLUGIN_ROOT}`. If `${CAREER_DATA}` is not set (direct or standalone invocation outside the orchestrator), locate the `career-data` skill yourself, confirm `career-data-marker.json`, and apply the orchestrator's healthy / damaged / absent outcomes before reading. A configured user's missing `career-data` is a hard stop — never silently fall back to blank templates.

**Shared rules — load first.** This is a standalone entry skill: before producing any output, load `${CLAUDE_PLUGIN_ROOT}/references/shared-voice-rules.md` yourself. All prohibitions in §§1–6 of that file apply to every output this skill produces. Rules tagged **[LI]** in shared-voice-rules.md are LinkedIn-specific. The Output Standards below are supplementary deltas; shared-voice-rules.md is the primary prohibition layer.

Comprehensive LinkedIn optimisation across five modes. Choose the one that fits your situation.

**─── FRAMEWORK PRIMACY — GOVERNS EVERY MODE ───**

**`03-framework.md` is the primary source of truth about who the user is and what they are positioning toward. LinkedIn is a tool this skill helps them improve — never a source of truth about their goals.** Treat the framework as background guidance for every recommendation in every mode. The profile is permanent and serves the user's whole positioning: a single application, a single target role, or any one run's signals — including a role that represents a career shift — must not pull recommendations toward themselves unless the change also strengthens the overall positioning. Only if the framework indicates a career shift is a primary goal may recommendations deliberately support the transition.

**Profile source ladder (for any mode that reads the profile):**
1. **`references/linkedin-profile.md`** — the permanent profile reference, when present and not still templated (content containing the characters `{{` and `}}` means not yet provided). This is the canonical snapshot agents base recommendations on; the user replaces it with a new LinkedIn PDF export via update-refs whenever they change their profile.
2. **Ask the user** to paste sections or share a PDF/screenshot — and note they can make it permanent by saying "update my references."

## Capabilities

| # | Capability | When to Use |
|:--|:-----------|:------------|
| A | Full Profile Audit | Complete profile review and optimisation for a target role or audience |
| B | Content Review | Analyse existing posts for audience alignment and impact |
| C | Content Strategy | Build a sustainable 3x/week posting strategy |
| D | Headline Optimisation | Quick headline-only focus |
| E | Video Introduction | 30-second profile video script |

---

## A. Full Profile Audit

**What you need:** LinkedIn profile content + career goals or target role (goals read from `03-framework.md` first — see Framework Primacy above).

**Step 1 — Acquire the profile via the Profile source ladder** (defined at the top of this skill):

1. Read `references/linkedin-profile.md` — if present and not templated, this is the profile source. Note its snapshot date in the audit output.
2. Otherwise ask: "Please paste your LinkedIn About section, current headline, and your most recent 3 experience entries — or share a PDF export. A PDF export can also become your permanent profile reference (say 'update my references'), so every future run analyses your real profile."

**Step 2 — Profile sections review**

Review each section against the target role or audience:

**Headline (120 chars):**
- Does it function as a value statement, not a job title?
- Does it name who it's for (audience signal) or what outcome it creates?
- Is it discoverable — would a recruiter searching for this candidate's skills find it?
- Provide 3 rewrite options with trade-off notes.

**About section:**
- Does it open with a hook that earns the reader's next 30 seconds?
- Does it answer: what do I do, who for, what's different about how I do it, and what's the proof?
- Does it close with a clear call to action?
- Word count: aim for 1,500–2,000 characters (LinkedIn shows ~300 before "see more").
- Provide a rewritten version.

**Experience entries:**
- Are bullets results-first (outcome → action) or task-first (action → implied outcome)?
- Is each role's contribution to the headline narrative clear?
- Are metrics used where available, and are they specific enough to be credible?
- Flag any entry that does more harm than good (gaps, unexplained departures, misaligned roles).

**Skills section:**
- Are the top 3 skills (shown before "see more") the most strategically important ones?
- Are there obvious skills missing that the target role would search for?

**Activity / content:**
- Is there visible activity? LinkedIn's algorithm deprioritises inactive profiles.
- Does recent activity reinforce the headline narrative?

**Step 3 — Discoverability check**

- Are keywords from the target JD present in the headline, About, and experience entries?
- Custom URL configured?
- "Open to work" or "hiring" banner — confirm intent before recommending change.

**Output:** Save to `{{OUTPUT_FOLDER}}/applications/[role-slug]/linkedin-profile-review.md` (or workspace root for general improvement).

---

## B. Content Review

**What you need:** one or more existing posts + target audience description.

For each post, analyse:

1. **Hook:** Does the first line earn the scroll-stop? Would a target audience member keep reading?
2. **Core idea:** Is there one clear, arguable idea — or is it a list with no point of view?
3. **Proof:** Is the claim supported by specific experience, data, or example — or is it generic advice?
4. **CTA:** Does it end with something that invites a response, or does it just stop?
5. **Voice:** Is this distinctly the author's voice, or does it sound like it could have been written by anyone in their field?

Provide a score (1–5) for each dimension and a specific rewrite suggestion for the weakest dimension.

**Output:** Inline in conversation (copy-paste ready).

---

## C. Content Strategy

**What you need:** role, expertise areas, career goals, target audience, and realistic time commitment.

**Step 1 — Discover content pillars**

Ask:
1. What are the 3–5 topics you could write about from direct experience, not research? (Not what you should write about — what you can write about with authority.)
2. What do you believe about your field that most people in it get wrong or understate?
3. What questions do you get asked by peers, clients, or candidates that you always have a good answer to?

Map answers to content pillars. Each pillar must pass this test: "Could I write 20 posts on this topic from my own experience without repeating myself?"

**Step 2 — Cadence design**

LinkedIn algorithm rewards consistency above volume. Recommend:
- 3x/week as the standard cadence
- Format mix: Tactical (how-to, lessons learned) / Strategic (point of view, industry observation) / Story (personal experience, behind-the-scenes)
- One post per week should be high-effort (original thinking, strong hook, invites discussion)
- Two posts per week can be lower-effort (short insight, question, share with commentary)

Adapt cadence down to 1x/week if the user has less than 2 hours/week.

**Step 3 — Engagement network**

A content strategy without an engagement network reaches no one. Recommend:
- Follow 20–30 accounts in three tiers: industry voices (10), peers (10), rising voices (10)
- Spend 15 minutes/day engaging with these accounts before posting (comment, not just like)

**Step 4 — 4-week content calendar**

Produce a specific 4-week calendar with:
- Week, day, format (Tactical / Strategic / Story)
- Specific topic or prompt (not "post about AI" — "the mistake I see most product managers make when writing AI prompts")
- Target length (100 words / 300 words / 600 words)

**Output:** Save to `{{OUTPUT_FOLDER}}/applications/[role-slug]/content-strategy.md` and `{{OUTPUT_FOLDER}}/applications/[role-slug]/content-calendar.md`.

---

## D. Headline Optimisation

**What you need:** career goals and target audience. Current headline optional.

LinkedIn headlines work as value statements, not job titles.

**Ask:** "What is the primary goal of your LinkedIn presence right now?"
- Job search → headline signals readiness and target role
- Thought leadership → headline signals domain and audience
- Client acquisition → headline signals outcome you create for clients
- Networking → headline signals who you are and what you're building
- Board / advisory → headline signals sector expertise and governance lens

**Headline structure options:**

1. **Value statement:** "[Outcome] for [Audience] | [Proof signal]"
   - Example: "AI go-to-market for B2B SaaS | Former VP @ [Company]"

2. **Role + differentiation:** "[Title] | [What makes this different]"
   - Example: "Product Director | Building AI teams that ship"

3. **Audience-first:** "Helping [Audience] [achieve outcome] | [Credential]"
   - Example: "Helping Series A founders hire their first product team | Ex-Google"

4. **POV signal:** "[Claim or belief] | [Title] @ [Company or stage]"
   - Example: "AI is a GTM problem, not a tech problem | Head of Product"

Provide 3 options with trade-off notes. State the keyword strategy for each.

**Output:** Inline in conversation (copy-paste ready). No file save needed.

---

## E. Video Introduction

**What you need:** career goals, target audience, key messages.

LinkedIn profile videos display on the profile photo — they are the first impression in a search result or connection request.

**Structure:** Hook (5 sec) → Value (10 sec) → Proof (10 sec) → CTA (5 sec)

**Script templates by goal:**

**Job search:**
```
Hook: "I'm [Name] — I help companies [specific outcome]."
Value: "I've spent [N] years working on [specific problem space] — specifically [most relevant angle]."
Proof: "Most recently at [Company], I [specific achievement in one sentence]."
CTA: "I'm open to [role type] roles. Connect with me or message me directly."
```

**Client acquisition:**
```
Hook: "[Specific problem your clients face] — that's what I work on."
Value: "I work with [specific client type] on [specific problem] using [distinctive approach]."
Proof: "[Result or client type you've helped] — [one specific example or metric]."
CTA: "If that sounds like your situation, let's talk."
```

**Thought leadership:**
```
Hook: "[Provocative claim or question about your domain]."
Value: "I'm [Name]. I [role/work] — and I write and speak about [specific topic]."
Proof: "[Why you're credible — specific experience or publication]."
CTA: "Follow me for [type of content]."
```

Provide all three options as complete scripts. User picks one, then receive:
- Recording tips (eye contact, background, lighting — 3 bullet points)
- Technical setup checklist (phone vs. webcam, landscape vs. portrait, max length 30 seconds)

**Output:** Inline in conversation (copy-paste ready).

---

## Output Standards

- Write in the user's preferred language — do not default to any specific regional variant
- Voice and style rules: see `references/shared-voice-rules.md` §§1–6. LinkedIn-specific relaxations are tagged **[LI]** there (e.g., colons permitted for list introductions; em dashes remain a hard ban on all surfaces).
- No hyperbole: no "game-changing," "revolutionary," "supercharge" (covered by shared-voice-rules §2 banned vocabulary)
- Use the Oxford comma (serial comma: "skills, experience, and qualifications")
- Never fabricate credentials, metrics, employers, or publications. Use `{{PLACEHOLDER}}` if a fact is unconfirmed
- Address the user as "you" in coaching dialogue. In drafts (bios, posts, scripts), use the appropriate person and tense for the format

---

## Related Skills

- **/career-engine:personal-brand** — builds the brand strategy layer above LinkedIn tactics. Run that first if the user needs a full positioning framework.
- **/career-engine:career-coach** — for role-specific LinkedIn optimisation tied to an active application.
