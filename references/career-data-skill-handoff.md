# career-data skill handoff — create, install, update (Appendix A)

This is the canonical procedure for getting the `career-data` skill into the right place,
in every environment. Other files refer to it as **"Appendix A"** or **"the Appendix-A handoff."**
When they do, they mean this file.

It exists because the single hardest step of setup — turning the authored career-data files
into an installed, shared skill — depends on a platform reality that is easy to get wrong.

---

## The platform reality (read this first)

Three facts govern everything below:

1. **The career-engine plugin runs in Cowork and Claude Code only — NOT in Chat.** A
   non-technical user almost always runs setup from **Cowork**.
2. **Skills are shared between Chat and Cowork** (one Desktop app skill store). A skill
   created in Chat is immediately available in Cowork, and vice-versa.
3. **`/skill-creator` lives in Chat.** It is the reliable way to turn a folder of files into
   an installed `.skill`. Cowork cannot reliably save a skill itself — it writes `SKILL.md`
   to a nested session path and the "Save Skill" step fails with *"SKILL.md must be in the
   top-level folder."*

Put together: **the user runs setup in Cowork, but `career-data` must be born in Chat.** The
job of setup is therefore not to install the skill from Cowork — it is to hand the user a
ready-to-paste Chat prompt that does it for them. Because Chat and Cowork share a skill store,
once Chat creates `career-data` it is instantly usable back in Cowork with no extra step.

| Environment user is in | How `career-data` gets created/installed |
|---|---|
| **Cowork** (the common case) | Setup authors the files, then emits a `/skill-creator` handoff prompt. User copies it to **Chat**, runs `/skill-creator`, pastes, presses Enter. Skill appears in both Chat and Cowork. |
| **Claude Code (CLI)** | Setup writes the skill directly to `~/.claude/skills/career-data/`. No handoff needed. (Technical users only.) |
| **Chat** | The plugin does not run here, so setup never starts here. Chat is only the *destination* for the Cowork handoff. |

---

## The visual the agent must show (Cowork handoff)

When setup is in Cowork and reaches the build step, **lead with a visual, not a wall of text.**
Render this four-step strip (use an artifact/HTML visual if the environment supports it;
otherwise show the plain-text version). Keep words minimal — the user should grasp it in one
glance.

```
  ┌──────────────┐   ┌──────────────┐   ┌────────────────────┐   ┌──────────────┐
  │  ① COPY      │ → │  ② OPEN      │ → │  ③ TYPE            │ → │  ④ PASTE     │
  │  the prompt  │   │  Chat        │   │  /skill-creator    │   │  + press     │
  │  below ⤵     │   │  (not Cowork)│   │  (must be installed)│   │  Enter ⏎     │
  └──────────────┘   └──────────────┘   └────────────────────┘   └──────────────┘

  Chat and Cowork share skills — once Chat builds it, it's ready in Cowork too.
```

Then output the handoff prompt in a single copyable block (below). One sentence above it:
*"Copy everything in the box, paste it into Chat after `/skill-creator`, and press Enter."*

---

## The Cowork → Chat create prompt (handoff template)

Fill this with the user's authored content at runtime, then present it as one copyable block.
Embed the text files inline; for binary files (the `.dotx`) and the delivered-letter examples,
instruct the user to attach them in Chat.

```
Create a skill called career-data using /skill-creator.

career-data is a personal data store for the career-engine plugin. It holds my writing
rules, professional background, positioning framework, and pipeline configuration. Build it
as a skill with this exact structure, then package and install it via Customize → Skills.

**Some directories below are seeded with only the fixed-name files this setup run
produced — that is expected and correct, not incomplete.** `background/` and `framework/`
grow over time: a role-facts file is added per employer, a framework file per methodology or
POV, as the user's positioning work develops in later sessions (via `update-refs`). Create
every directory now, even ones that hold only one or two files today.

career-data/
├── SKILL.md
├── career-data-marker.json
└── references/
    ├── _STRUCTURE-DO-NOT-CHANGE.md      ← the structure contract; preserve section structure
    ├── pipeline-preferences.json        ← per-install config; ALWAYS here, never at the skill root (2026-07-24 fix — this tree used to draw it at root, contradicting the structure contract and every runtime read; skills built from the old tree have it at root and runtime falls back to that location)
    ├── 01-writing-rules.md
    ├── 02-professional-background.md    ← router (see background/ below)
    ├── 03-framework.md                  ← positioning/voice, +methodology router (see framework/ below)
    ├── linkedin-profile.md
    ├── capability-profile.md            ← the coach-derived, user-confirmed capability profile (setup Phase 4); the Prioritization pipeline's function-fit input
    ├── background/
    │   ├── background-cv-summaries.md
    │   ├── background-motivation-bank.md
    │   ├── background-approved-bullets.md
    │   ├── background-role-facts-<company-slug>.md   ← one per employer confirmed in the interview; filenames and count vary per user
    │   ├── background-testimonials.md
    │   ├── background-portfolio.md
    │   └── background-cross-cutting-skills.md
    ├── framework/                        ← one file per methodology/POV topic surfaced in the interview; filenames, count, and topics vary per user — may be thin or absent for a brand-new user and grow via update-refs later
    │   └── framework-<topic-slug>.md
    ├── voice-and-identity/
    │   ├── personal-brand-context.md     ← optional; only if the user did personal-brand work during setup
    │   └── linkedin-post-strategy.md     ← optional; only if the user set LinkedIn content goals during setup
    ├── templates/
    │   ├── cv.dotx                       ← I will attach this file, or use the plugin's own default
    │   ├── cover-letter-template.dotx    ← I will attach this file, or use the plugin's own default
    │   ├── cover_letter_templates.md     ← the plugin's generic Template A/B structure doc
    │   ├── cvHe.dotm                     ← optional, only if I configured a second RTL language and provided one
    │   └── he-letter.dotx                ← optional, only if I configured a second RTL language and provided one
    └── delivered-letters/
        └── INDEX.md                      ← I will attach any delivered-letter files too, if any exist yet

SKILL.md contents:
[FULL SKILL.md CONTENT — the description must say this is the career-engine personal data
store, loaded on request, never auto-applied]

career-data-marker.json contents:
[FULL MARKER JSON — including expected_files list, which MUST list every file actually
created above (including references/_STRUCTURE-DO-NOT-CHANGE.md) by its real path — do not
list a file that wasn't created, and do not omit one that was]

references/_STRUCTURE-DO-NOT-CHANGE.md contents:
[FULL CONTENT, untruncated — a verbatim copy of the plugin's
references/career-data-structure.md. This is the structure contract: it lists every
load-bearing file and section heading and the Section 5 Motivation Bank table format.
Keep it inside the skill so it sits in front of you on every future edit. Edit content
WITHIN sections freely; do NOT rename, renumber, reorder, or delete any section or file,
and do NOT change the Motivation Bank table format — structural changes go through the
career-engine update-refs skill, not an ad-hoc edit.]

references/01-writing-rules.md contents:
[FULL CONTENT, untruncated]

references/capability-profile.md contents (only if generated this session — setup Phase 4):
[FULL CONTENT, untruncated — the user-confirmed profile exactly as confirmed, starting at its
`Generated:` line, no header comment, no placeholders. Omit this block entirely, and leave the
file out of expected_files, if no profile was generated this session.]

references/02-professional-background.md contents:
[FULL router content — the routing table pointing at the background/ sub-files above, per
the structure contract. Do not inline the sub-file content here; it lives in its own file.]

references/03-framework.md contents:
[FULL CONTENT, untruncated — positioning/voice sections inline, plus the methodology router
table pointing at the framework/ sub-files above, per the structure contract]

references/linkedin-profile.md contents:
[FULL CONTENT, untruncated]

references/background/background-*.md contents (one block per file actually created above):
[FULL CONTENT, untruncated, per file]

references/framework/framework-*.md contents (one block per file actually created above,
omit entirely if none were produced this session):
[FULL CONTENT, untruncated, per file]

references/voice-and-identity/*.md contents (omit entirely if neither was produced this
session):
[FULL CONTENT, untruncated, per file]

references/templates/cover_letter_templates.md contents:
[FULL CONTENT, untruncated — the plugin's generic default, or the user's own if they
provided one]

references/pipeline-preferences.json contents:
[FULL JSON, untruncated]

For the `.dotx`/`.dotm` templates and any delivered-letter files: I am attaching them to this
message — place the templates in references/templates/ (renamed to the fixed filenames
above regardless of their original names) and the letters in references/delivered-letters/.

After building:
1. Confirm career-data-marker.json lists every file above in expected_files —
   including references/_STRUCTURE-DO-NOT-CHANGE.md.
2. Confirm references/_STRUCTURE-DO-NOT-CHANGE.md is present and matches the structure
   contract verbatim; preserve its section structure on any future edit (edit content
   within sections; structural changes go through the update-refs skill).
3. Package the directory as a .skill and install via Customize → Skills.
4. Tell me the skill is installed so I can return to Cowork and continue.

⚠️ Do NOT paraphrase any file content above. Copy it exactly as written.
```

**If the prompt is too long for one Chat message,** split at a file boundary and label
`Part 1 of N — wait for all parts before building`. The final part carries the "After building"
checklist.

---

## Claude Code path (direct write, then offer the Chat handoff)

When setup runs in Claude Code, write the skill directly to `~/.claude/skills/career-data/`
with the same structure, confirm `career-data-marker.json` lists every file in `expected_files`,
and write the first backup export to the output folder. Tell the user it is installed **in
Claude Code specifically**, and that this copy is local to Code.

Then **proactively offer the Chat handoff** — do not just mention it in passing. Chat and Cowork
share a separate skill store; a Code-only skill is invisible to them, so a user who also uses
Chat/Cowork needs `career-data` created in Chat too. Ask, with a minimal-text visual, whether
they also use Chat/Cowork and want the prompt, or are all set with Code only:

```
  career-data is installed in Claude Code ✅

  Do you also use Chat or Cowork?

  ┌──────────────────────────────┐   ┌──────────────────────────────┐
  │  YES — Chat/Cowork too        │   │  NO — Code only               │
  │  → I'll hand you a prompt to  │   │  → You're all set ✅          │
  │    create it in Chat          │   │                               │
  └──────────────────────────────┘   └──────────────────────────────┘
```

This is a question — present it and wait for the reply. If they also use Chat/Cowork, generate
the Cowork → Chat create prompt above (full file contents inline; `.dotx` and letters attached)
and present it led by the four-step visual. If Code-only, confirm done — no handoff needed.

---

## Ongoing updates (after the skill already exists)

This file covers first-time creation. For **edits to an already-installed** `career-data`
(new facts, preference changes, corrections), the mechanism is the same Cowork → Chat handoff,
but the prompt is an *update* prompt, not a create prompt. Use the format in
[`career-data-update-prompt-format.md`](career-data-update-prompt-format.md):

- **In Claude Code:** write the change directly to `career-data`, then refresh the backup export.
- **In Cowork:** the skills mount is read-only — never write a divergent copy. Stage the change
  to the output folder as `pending-career-data-updates.md` and emit the update-prompt for the
  user to apply in Chat.

Either way: if the user runs both Chat/Cowork and Code, the update must be applied in both.
