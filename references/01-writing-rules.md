# Who {{USER_FIRST_NAME}} Is

**Configuration reference — load first.** Rules, guards, operational framing, and contact details. Approved career content (role facts, approved bullets, testimonials, portfolio) is in `references/02-professional-background.md`. Professional philosophy, methodology, and domain narratives are in `references/03-framework.md`.

> **Setup required.** Fill in every `{{...}}` placeholder before running the pipeline for the first time. The more precisely you document your facts here, the less you will need to correct agent output. Every fabrication guard and framing rule you define here is enforced across every agent, every run.

---

## Contents

1. [Rules](#section-1--rules) — Attribution rules, fabrication guards, framing rules, JD term guardrails.
2. [Identity and Framing](#section-2--identity-and-framing) — Operational identity, target roles, differentiators, voice.
3. [Professional Frameworks and Philosophy](#section-3--professional-frameworks-and-philosophy) — Extracted to `03-framework.md`.
4. [Domain Depth and Verticals](#section-4--domain-depth-and-verticals) — Extracted to `03-framework.md`.
5. [Voice and Source Material](#section-5--voice-and-source-material) — Tone calibration, published work, proof points.
6. [Reference Details](#section-8--reference-details) — Education, languages, contact, skills, tools.

---

## Section 1 — Rules

Read this section before doing anything. These rules exist because agents make predictable errors without them. They are non-negotiable.

### Priority Framework

Used by the career coach to score roles. Define your scoring criteria here — agents apply them in order when assessing fit. Replace every `{{...}}` with your actual priorities.

**1. Domain fit** — {{USER_FIRST_NAME}}'s strongest verticals or functional areas, in priority order:
- {{USER_DOMAIN_1}} *(e.g., the industry, technology area, or function where your experience is deepest)*
- {{USER_DOMAIN_2}}
- {{USER_DOMAIN_3}}
- {{USER_DOMAIN_4}}

*What to put here: be specific. "Enterprise software" is less useful to an agent than "cloud infrastructure / platform engineering" or "financial services operations / regulatory compliance" or "consumer healthcare / clinical workflow design." The more specific, the more accurately the coach scores fit.*

**2. Seniority match** — {{USER_FIRST_NAME}}'s target level:
- Level: {{USER_SENIORITY_LEVEL}} *(e.g., Senior IC, Staff/Principal, Manager, Director, VP, Partner)*
- Roles that align: {{USER_TARGET_ROLES}} *(list the actual titles you're targeting — used for sourcing searches and as an advisory signal only; since 2026-10-15 the Prioritization pipeline scores function fit as coverage of a JD's responsibilities against your `capability-profile.md`, so a title missing from this list never lowers a score)*
- Seniority notes: {{USER_SENIORITY_NOTES}} *(e.g., "open to one level down if domain fit is strong"; "not interested in people management")*

**3. Company stage fit** — {{USER_FIRST_NAME}} thrives in:
- {{USER_STAGE_PREFERENCE}} *(e.g., seed through Series B, growth-stage, late-stage or pre-IPO, public company, enterprise, nonprofit, regulated industry)*
- Context: {{USER_STAGE_NOTES}} *(why? what have you learned about where you do your best work?)*

**4. Geographic / remote fit:**
- Based in: {{USER_LOCATION}}
- Viable: {{USER_REMOTE_PREFERENCE}} *(e.g., fully remote; local hybrid; specific countries or timezones)*
- Hard exclusions: {{USER_GEO_EXCLUSIONS}} *(e.g., "onsite-only roles outside [city]" or "US residency required")*
- For remote-advertised roles, a geographic restriction in the text is a soft signal, not an automatic disqualifier: apply the Remote-geography weighting in `skills/career-coach/SKILL.md` Part 0 (exception-path check first — EOR, out-of-country hires, a restriction rationale the user's location satisfies; max one-tier discount with an `ask-first` flag when a path exists). Score Fifth on geography only for structural restrictions (legal residency, citizenship, clearance, payroll-stated-no-exceptions) with no exception path found.

**5. Risk signals** — Lower the priority for:
- {{USER_RISK_SIGNAL_1}} *(e.g., roles where your research reveals the title overstates the actual scope)*
- {{USER_RISK_SIGNAL_2}} *(e.g., company stages that have been poor fit historically)*
- Vague titles with no domain anchor, structural geographic exclusions with no exception path, or roles where company research reveals a strong mismatch between title and scope

**6. Advertised date** — Use with discretion. A very recent JD with strong fit may be more urgent than an older one, but fit outweighs recency.

**7. Open Application override** — Any role where {{USER_FIRST_NAME}} is applying without a specific open listing (unsolicited application, speculative outreach) is automatically `Fifth` regardless of domain fit. Hard floor.

**Score ranges:**
- `Highest` — Urgent. Drop everything.
- `First` — Excellent fit. Strong domain, right seniority, right stage, no red flags.
- `Second` — Strong fit. Domain or seniority match clear; minor friction elsewhere.
- `Third` — Reasonable fit. Worth applying but the cover letter has work to do.
- `Fourth` — Weaker fit. Possible if {{USER_FIRST_NAME}} wants to stretch.
- `Fifth` — Weakest fit. Flag the specific friction clearly.

---

### Attribution rules

Document the claims about your background that must be handled precisely — things that are true but easy for an agent to overstate or misframe.

*What to put here: for each role or project where the scope was limited, fractional, or shared with others, document the correct framing. Agents will inflate what you "owned" without these guards.*

- **{{COMPANY_OR_PROJECT_1}} scope:** {{CORRECT_FRAMING}} *(e.g., "Delivered scoped consulting work — do not frame as owning the full [function].")*
- **{{COMPANY_OR_PROJECT_2}} scope:** {{CORRECT_FRAMING}}
- **Metrics ownership:** *(If specific numbers belong to the company/team and not to you personally, document them here: "The [metric] belongs to company context, not personal attribution.")*
- **Managed-vs-executed:** If you managed people who produced work, document: "Leading a team that delivered X ≠ personally delivering X."

---

### Fabrication guards

Specific facts agents must never get wrong. Document the correct version once — agents check these on every output.

*What to put here: think about every time you've had to correct an AI writing about your background. The pattern is usually inflated scope, wrong metric, wrong company, or wrong framing. Each guard is: "Never say [X]. Correct: [Y]."*

**Never say about {{USER_FIRST_NAME}}:**
- Never say: {{FABRICATION_GUARD_1}} — Correct: {{CORRECT_VERSION}}
- Never say: {{FABRICATION_GUARD_2}} — Correct: {{CORRECT_VERSION}}

**Easily confused distinctions in {{USER_FIRST_NAME}}'s background:**

*What to put here: if you've worked in similar domains across multiple companies, or two roles look alike on paper, document the distinctions. Without these, agents blend them.*

- **{{THING_1}} vs {{THING_2}}:** {{EXPLAIN_THE_DISTINCTION}}

---

### Idiom prohibition

**All idioms are absolutely prohibited** in any cover letter, CV, or agent-written professional content — unless the idiom appears verbatim in the user's Why I Want This Role content, in which case it may be used exactly as written (it is the user's voice). This rule applies equally to the letter-writer, humanizer, and any other writing agent.

Idioms include any figurative phrase used non-literally: "hit the ground running," "wear many hats," "put my thinking cap on," "move the needle," "low-hanging fruit," "at the end of the day," "take it to the next level," "raise the bar," "think outside the box," and all similar expressions. When in doubt about whether something is an idiom, treat it as one and replace it with a plain statement of the underlying meaning.

---

### Framing rules

How your background should and should not be presented in any document.

- **No company names in CV summary.** Descriptors only: "seed-stage fintech platform" not "[Company Name]."
- **No dates for:** {{SECTIONS_WITHOUT_DATES}} *(e.g., education; early career)*
- **{{USER_FRAMING_RULE_1}}** *(e.g., "Consulting/freelance work: frame as 'fractional practice kept open between full-time roles' — never invent specific engagement dates.")*
- **{{USER_FRAMING_RULE_2}}**

**Seniority transitions:** If you are targeting roles at a different level than your most recent title, define the framing here. Is this a deliberate choice or a constraint? What is the honest reason? Agents need this to handle the topic correctly in cover letters.

**Fabrication protection:** A reviewer flag that cannot be closed with documented facts is left unaddressed. Never fabricate to satisfy reviewer feedback.

---

### JD term guardrails — map before concluding "no match"

*What to put here: JD terms that look like gaps in your background but are actually covered by your experience under a different name. Agents flag these as gaps without this table. Format: "[JD term] → [your documented experience that covers it]."*

| JD term | {{USER_FIRST_NAME}}'s documented match |
|---|---|
| {{JD_TERM_1}} | {{YOUR_EXPERIENCE_THAT_COVERS_IT}} |
| {{JD_TERM_2}} | {{YOUR_EXPERIENCE_THAT_COVERS_IT}} |
| {{JD_TERM_3}} | {{YOUR_EXPERIENCE_THAT_COVERS_IT}} |

*Examples by profession — replace with your own:*
- *Software engineering:* "Distributed systems" → your specific work on message queues, event-driven architecture, or microservices at [Company]
- *Finance:* "M&A modeling" → your comparable transaction analysis, DCF work, or deal support at [Company]
- *UX / product design:* "Design systems" → your component library, design token documentation, or cross-product consistency work at [Company]
- *Operations / process:* "Lean / Six Sigma" → your specific process improvement work and outcomes at [Company]
- *Data science / engineering:* "MLOps" → your model deployment pipeline, monitoring, and retraining work at [Company]
- *Legal:* "Regulatory compliance" → your specific regulatory frameworks, jurisdictions, or compliance programs you've led

---

## Section 2 — Identity and Framing

→ For {{USER_FIRST_NAME}}'s professional philosophy and methodology, see `references/03-framework.md`.

### Operational Identity

*What to put here: 3–5 sentences describing who {{USER_FIRST_NAME}} is professionally. This is the master description that agents draw from when writing summaries and openers. Specific over vague — agents will reproduce whatever you write here.*

{{USER_FULL_NAME}} is {{USER_PROFESSIONAL_DESCRIPTION}}.

**Current active tracks:**
1. {{USER_TRACK_1}} *(e.g., job searching — targeting [specific role types and industries])*
2. {{USER_TRACK_2}} *(e.g., consulting / freelancing — what kind and for whom)*
3. {{USER_TRACK_3}} *(optional — e.g., teaching, advising, open-source work)*

**What {{USER_FIRST_NAME}} leads with:** {{USER_LEAD_WITH}}

*What to put here: function and outcomes, or credentials and titles — whichever is more compelling given your background. Most people default to titles; most strong candidates lead with what they changed or built.*

**Aspiration:** {{USER_ASPIRATION}}

---

### Differentiators

*What to put here: your 2–4 genuine differentiators — the claims a cover letter can lead with. Each must be earned by specific, documented evidence. Name the proof point. Do not list aspirational qualities.*

**{{DIFFERENTIATOR_1_NAME}}:** {{DIFFERENTIATOR_1_DESCRIPTION}} Proof: {{DIFFERENTIATOR_1_PROOF}}

**{{DIFFERENTIATOR_2_NAME}}:** {{DIFFERENTIATOR_2_DESCRIPTION}} Proof: {{DIFFERENTIATOR_2_PROOF}}

**{{DIFFERENTIATOR_3_NAME}}:** {{DIFFERENTIATOR_3_DESCRIPTION}} Proof: {{DIFFERENTIATOR_3_PROOF}}

*Examples by profession — replace with your own differentiators:*
- *Engineering:* "Systems thinker — I trace features to architecture before writing a line. Proof: redesigned the auth service at [Company] to support 10× load without breaking backward compatibility."
- *Finance:* "Speed under pressure — three closed deals in 90-day sprints without a miss. Proof: [Company] Q4 2023, [Company] Series B close, [Company] bridge round."
- *Design:* "Research before pixels — I run user interviews before opening the design tool. Proof: the onboarding redesign at [Company] was preceded by 14 user sessions that entirely changed the initial direction."
- *Operations:* "Process archaeologist — I document the informal system before replacing it. Proof: the [Company] routing project started with three days of floor observation; the final design had zero edge-case incidents in the first six months."
- *Sales:* "Builder of process, not just quota — I document the playbook while running it. Proof: the outbound framework I built at [Company] is still in use two years after I left."

**For cover letters:** Identify which 1–3 differentiators are genuinely relevant to this specific role. Foreground those. Do not list all of them in any single letter.

---

### Peer-Attributed Qualities

*What to put here: qualities drawn from feedback, recommendations, and performance reviews — not self-claims. Documented social proof carries more weight than self-description. List only qualities that are actually attested.*

**Attested qualities:** {{USER_ATTESTED_QUALITIES}} *(e.g., "fast learner, collaborative, technically credible, direct communicator, reliable under pressure")*

**Attribution language options:**
- "As colleagues have said..." / "Peers describe me as..."
- "Clients and managers consistently note that I..."
- "Those I've worked with describe me as..."

**Usage rules:**
- One attribution pattern per letter, two at absolute most.
- Always follow with specific, named proof. The quality is the claim; the proof is what makes it real.
- Match the quality to what the role specifically needs.

---

### Drumbeat / Ongoing Presence

*What to put here: communities, channels, and ongoing activities that represent genuine professional participation — not campaign-activated. These show up in cover letters when the role calls for community presence, thought leadership, or network-driven credibility.*

**Communities {{USER_FIRST_NAME}} actively participates in:**
- {{COMMUNITY_1}} *(name, platform, and what the participation looks like — e.g., "answers questions weekly on [Slack/forum/community name]")*
- {{COMMUNITY_2}}

**Professional network context:** {{USER_NETWORK_NOTES}}

---

## Section 3 — Professional Frameworks and Philosophy

→ Extracted to `references/03-framework.md`. Load that file for professional methodology, positioning philosophy, domain narratives, and documented POV positions.

---

## Section 4 — Domain Depth and Verticals

→ Extracted to `references/03-framework.md`. Load that file for per-domain narratives, the Fast Learning Argument, and adaptability framing.

---

## Section 5 — Voice and Source Material

### Documented Proof Points

*What to put here: specific, named outcomes agents can cite. Format: outcome → company → one sentence of context. Agents use these when writing bullets and cover letter proof paragraphs. Vague claims ("improved processes") are useless — named, specific claims are the asset.*

- **{{PROOF_POINT_1}}:** [Outcome] at [Company]. Context: [one sentence on what produced it.]
- **{{PROOF_POINT_2}}:** [Outcome] at [Company]. Context: [one sentence on what produced it.]
- **{{PROOF_POINT_3}}:** [Outcome] at [Company]. Context: [one sentence on what produced it.]

*Format example: "Cut deployment time 40% at [Company] — rewrote the CI pipeline to run tests in parallel instead of sequence." Not: "Improved deployment processes."*

### Published Work / Thought Leadership

*What to put here: articles, papers, talks, open-source contributions, conference presentations, or other public work. Agents reference these as proof of domain depth.*

- **{{WORK_TITLE}}** — [Platform / venue] — [One-line description of what it demonstrates about your expertise]

### Tone Reference

| Context | Register | Example anchor |
|---|---|---|
| {{CONTEXT_1}} | {{REGISTER}} | {{EXAMPLE}} |
| {{CONTEXT_2}} | {{REGISTER}} | {{EXAMPLE}} |
| {{CONTEXT_3}} | {{REGISTER}} | {{EXAMPLE}} |

*What to put here: How does your voice shift across contexts? Formal/informal, hedged/direct, technical/accessible? Agents calibrate tone from this table. Leave blank and they'll default to generic professional.*

---

## Section 8 — Reference Details

### Education

- **{{DEGREE_1}}** — {{INSTITUTION_1}}
- **{{DEGREE_2}}** — {{INSTITUTION_2}}

*Add "No dates" here if you prefer education to appear without graduation years.*

### Languages

- {{LANGUAGE_1}} — {{PROFICIENCY_1}}
- {{LANGUAGE_2}} — {{PROFICIENCY_2}}

### Personal Context

*What to put here: volunteering, certifications, community involvement, side projects — anything relevant to how you present yourself professionally.*

- {{CONTEXT_1}}
- {{CONTEXT_2}}

### Contact

- **Email:** {{USER_EMAIL}}
- **Phone:** {{USER_PHONE}}
- **LinkedIn:** {{USER_LINKEDIN}}
- **Website / Portfolio:** {{USER_PORTFOLIO_URL}}

### Core Skills (CV-ready list)

*What to put here: organize your skills into categories that match how they appear in JDs for your target roles. Use the vocabulary your industry uses. A software engineer, financial analyst, designer, and operations leader will each have different category names and terms.*

**{{SKILL_CATEGORY_1}}:** {{SKILLS_LIST}}

**{{SKILL_CATEGORY_2}}:** {{SKILLS_LIST}}

**{{SKILL_CATEGORY_3}}:** {{SKILLS_LIST}}

**{{SKILL_CATEGORY_4}}:** {{SKILLS_LIST}}

### Tools

*What to put here: tools and software grouped by category. Use the exact product names that appear in JDs for your target roles. If a tool has multiple common names, use the one the market uses.*

**{{TOOL_CATEGORY_1}}:** {{TOOLS_LIST}}

**{{TOOL_CATEGORY_2}}:** {{TOOLS_LIST}}

**{{TOOL_CATEGORY_3}}:** {{TOOLS_LIST}}
