---
name: plugin-builder
description: >
  Working doctrine for plugin-builder sessions: where content belongs, how to
  make a clean change, how to check for regressions, how to package, and how to
  open a PR. Loaded by the plugin-builder agent at the start of every session.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - TodoWrite
---

# Plugin Builder — Working Doctrine

This skill is the craft layer for plugin-builder sessions. The governing rules live in `CLAUDE.md` — read that first. This skill gives you the decision trees, checklists, and conventions you need to apply those rules without re-deriving them every time.

---

## The Three Questions Before Every Change

Before touching any file, answer these three questions:

1. **What content type is this?** (See content-type decision tree below.)
2. **Which file owns this content type?** (See content placement rules in CLAUDE.md.)
3. **Is it personal data?** If yes, it belongs in `career-data`, never the plugin.

If you cannot answer all three confidently, ask the user before writing.

---

## Content-Type Decision Tree

```
Is it a rule about what to write, how to write it, or a writing philosophy?
  → skill file (skills/<name>/SKILL.md)

Is it a step-by-step procedure, a routing decision, or an output format spec?
  → agent file (agents/<name>.md)

Is it the user's personal data — role facts, voice profile, sent letters, .dotx?
  → career-data skill (never the plugin)

Is it a blank template with {{...}} placeholders for the user to fill at setup?
  → references/ in the plugin

Is it a slash command that invokes a skill or agent?
  → commands/ in the plugin
```

When something could fit two categories, the tie-break is: **does it apply every time this task runs?** If yes → skill. If it varies by session input → agent.

---

## Before Writing a New Agent

A new agent needs all of the following in the same session. Do not close the session until every item is done:

- [ ] Agent file at `agents/<name>.md` with frontmatter (`name`, `description`, `tools`)
- [ ] Skill directory at `skills/<name>/SKILL.md` with frontmatter (`name`, `description`, `allowed-tools`)
- [ ] If it introduces a new pipeline: a row in the Pipeline Registry in `CLAUDE.md` and in the `career-engine` entry skill
- [ ] If it reads reference files: a loading table in the agent file pointing at the right files
- [ ] If it writes new reference files: those files added to `references/REFERENCES.md` and wired into every consuming agent
- [ ] QA run and `.plugin` rebuild

A half-wired agent is worse than no agent — it will silently fail at runtime.

---

## Before Editing an Existing Agent or Skill

**Letter pipeline files require special care.** `letter-writer.md`, `cv-writer.md`, `writer-craft/SKILL.md` (and its `core.md`/`cv.md`/`letter.md` sub-files), `gatekeeper-checks/SKILL.md` (and its `cv-gates.md`/`letter-gates.md`/`coach-gates.md` sub-files), `gatekeeper.md`, `humanizer.md`, and `humanizer/SKILL.md` require full read-before-edit and explicit rule-removal confirmation from the user before any rule is deleted or weakened.

1. Read the file you are editing in full, not just the section you intend to change.
2. Check the regression table in `CLAUDE.md` for any row that mentions this file. Read the "Confirmed fix" column — your change must not undo it.
3. If you are moving content between files (e.g., from agent to skill), confirm the move does not break any other file that references it by path or by name.
4. If you are renaming anything: update every file that references the old name, excluding QA ban lists and plan docs from find-replace (update those by hand, as noted in R-26).

---

## Regression Check Discipline

After making any change, scan the CLAUDE.md regression table for every file you touched. For each match:

- State the regression number and name
- State whether your change affects the confirmed fix
- If it does affect it, confirm the fix is still intact or explain why the change is safe

Do not write "regression checks: N/A." Every edit touches at least one file; every file has at least one regression that mentions its directory. Show your work.

---

## Packaging

After QA passes, rebuild the plugin:

```bash
bash scripts/build-plugin.sh
```

That is the whole build (2026-08-12 — it replaced a hand-copied `python3 -c` snippet, which had already drifted out of sync with `CLAUDE.md`'s copy: this file's version was missing the `update-prompt-*.md` and `session.jsonl` exclusions entirely, so a build run from these instructions would have zipped personal files straight into the shipped artifact). The script scans the tree for personal data, parses every frontmatter block as YAML (`scripts/check-frontmatter.py` — the Desktop installer rejects the whole plugin on one unparseable description line, 2026-10-15), builds, then re-opens the finished zip and scans **what actually ships** — and refuses to leave you a shippable artifact if any of the three steps trips. See CLAUDE.md → Packaging and → Personal data never enters this repo.

Confirm `career-engine.plugin` was produced and its timestamp is current. Do not report the session complete until the rebuilt `.plugin` exists.

---

## PR Checklist

**⛔ Push/merge gate (2026-07-24, per the user's direct instruction: "make sure the qa agent also always runs when I ask you to push and merge, and when it runs in this case, it always traces, fixes and then ALSO ALWAYS checks the README, Claude.md and Wiki in the repo and makes all necessary updates, changes, deletions, etc.").** Every push or merge request triggers, before anything is pushed:
1. **The full QA gate** — all three layers (`scripts/qa-mechanical.sh` + parity, the diff-scoped sweep, the semantic passes including trace-a-run), even if QA already ran earlier in the session on individual edits — the pre-push pass covers the branch's whole cumulative diff against the merge target.
2. **Every finding fixed** (by the main session, per the usual division: the QA agent reports, the session fixes, QA re-verifies).
3. **The docs-sync pass — always, not only when the diff looks doc-relevant:** check `README.md` (including the changelog), `CLAUDE.md` (cross-file contracts, glossary, key design decisions), and the **GitHub Wiki** (`<repo>.wiki.git` — clone it, review every page against current doctrine) for anything the branch's changes made stale, wrong, or missing — and apply all necessary updates, changes, and deletions before the push. Wiki edits are committed and pushed to the wiki repo as part of the same session.

Any user may open a PR. Before committing:

- [ ] `git status` is clean except for the files you changed
- [ ] The `.plugin` is rebuilt and included in the commit
- [ ] No personal data is in the diff (`grep -r "@" --include="*.md"` and scan for emails, real company names from the user's history, real file paths)
- [ ] The commit message follows the pattern: `<verb> <what>: <one-line why>` — e.g., `Add plugin-builder agent and skill: self-service plugin editing workflow`
- [ ] QA passed

PR body should include:
- What changed (one bullet per file or logical group)
- Why (the user request or regression being fixed)
- QA result (PASS or the check number that failed and was addressed)

To open the PR:

```bash
git add <files>
git commit -m "your message"
git push -u origin <branch>
gh pr create --title "..." --body "..."
```

If working on `main` directly (no feature branch), confirm with the user before pushing.

---

## Common Mistakes to Avoid

**Writing doctrine in agent files.** If you find yourself writing "how to write a strong opener" or "the voice rule for X" in an agent, stop — that belongs in the skill.

**Writing personal data in the plugin.** Real company names, the user's email, actual file paths, real `.dotx` filenames — none of these belong in any plugin file. Use `{{...}}` placeholders.

**Forgetting to wire a new file.** A new reference file that no agent loads is invisible. A new agent that no command or entry skill invokes is unreachable. Wire everything in the same session.

**Skipping the QA gate.** The mandatory stop in `CLAUDE.md` is not optional. Even a one-line change requires a QA run. The QA agent catches drift that looks fine locally.

**Running find-replace on ban lists.** When renaming a file or agent, exclude QA ban lists and the CLAUDE.md regression table from find-replace. Those files enumerate old names intentionally (to catch them) — overwriting them defeats the check.
