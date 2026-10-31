#!/usr/bin/env bash
# block-personal-data-writes.sh — PreToolUse hook. Refuses any tool call that would put
# personal data inside the plugin repo.
#
# WHY A HOOK AND NOT A RULE. Every other guard is downstream of the write: .gitignore
# catches it at commit, the packaging filter at build, the QA scan afterwards. Personal
# data still reached the public repo, and a personal config dump still reached eight
# shipped .plugin artifacts, because an agent that has decided to write the file has
# already defeated all three. This is the only layer that refuses the write itself.
#
# Covers Write / Edit / MultiEdit / NotebookEdit, the MCP filesystem write tools, and
# Bash commands that redirect or copy into the repo. Detection is shared with the other
# layers via scripts/personal_data_detect.py.
#
# Reads the PreToolUse payload on stdin. Exit 2 = block (stderr returns to the model).
# Any internal error exits 0 — this hook must never wedge a session; the pre-commit and
# build scans remain as backstops.

set -uo pipefail
PAYLOAD="$(cat 2>/dev/null || true)"
[ -z "$PAYLOAD" ] && exit 0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# NOTE: loaded into a variable and passed with -c, NOT via a heredoc. `python3 - <<EOF`
# reads the SCRIPT from stdin, which would consume the piped hook payload and leave
# sys.stdin empty — the hook would then exit 0 on every call, blocking nothing.
read -r -d '' PYBODY <<'PY'
import json, os, re, sys

sys.path.insert(0, os.environ.get("HOOK_SCRIPTS_DIR", ""))
try:
    import personal_data_detect as pdd
except Exception:
    sys.exit(0)  # fail open

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool = d.get("tool_name") or ""
ti = d.get("tool_input") or {}


def in_plugin_repo(p):
    """Locate the plugin repo structurally, so this works in any clone or worktree."""
    try:
        cur = os.path.dirname(os.path.abspath(p))
    except Exception:
        return None
    while True:
        manifest = os.path.join(cur, ".claude-plugin", "plugin.json")
        if os.path.isfile(manifest):
            # Only THIS plugin's repo. This hook is installed user-wide, so it also fires
            # in sessions building unrelated plugins; any plugin.json used to qualify, and
            # a different plugin's Notion IDs were blocked as if they were ours.
            try:
                with open(manifest, encoding="utf-8") as fh:
                    if json.load(fh).get("name") == "career-engine":
                        return cur
            except Exception:
                pass
            return None
        parent = os.path.dirname(cur)
        if parent == cur:
            return None
        cur = parent


def report(rel, reasons):
    bullets = "\n".join(f"  - {r}" for r in dict.fromkeys(reasons))
    sys.stderr.write(
        f"BLOCKED: refusing to put personal data in the plugin repo.\n\n"
        f"Target: {rel}\n\nWhy:\n{bullets}\n\n"
        f"The plugin is a single shared build — every user installs the same artifact, and "
        f"the built .plugin is committed to a public repo. Personal data has exactly two "
        f"homes: the career-data skill (R-37) and the user's output_folder.\n\n"
        f"Do this instead:\n"
        f"  - Personal career content -> write a career-data update prompt to "
        f"<output_folder>/_career-data-updates/ (references/career-data-update-prompt-format.md).\n"
        f"  - A path, ID, or address the code needs -> use a {{{{PLACEHOLDER}}}} or read it at "
        f"runtime from ${{CAREER_DATA}}/references/pipeline-preferences.json.\n"
        f"  - An illustrative example -> use this repo's fictional persona (example.com / "
        f"vandelay.com).\n\n"
        f"Do not route around this by renaming the file, splitting the content across "
        f"writes, or switching to Bash. Placing a placeholder on the same line does not "
        f"help either — allowed tokens neutralise only themselves, not the line. If the "
        f"value is genuinely public and belongs in the shared build, say so and ask the "
        f"user before adding a narrow exemption to scripts/personal_data_detect.py.\n"
    )
    sys.exit(2)


def check(path, body, label=None):
    """Block if `path` is inside the plugin repo and the name or body is personal."""
    if not path:
        return
    root = in_plugin_repo(path)
    if not root:
        return
    rel = os.path.relpath(os.path.abspath(path), root)
    if pdd.path_is_exempt(rel):
        return

    reasons = []
    if pdd.is_stray_output_file(os.path.basename(path)):
        reasons.append(
            "the filename marks it as a career-data update prompt, which carries personal "
            "career data. These belong under output_folder — "
            "<output_folder>/_career-data-updates/ for ad-hoc prompts, or the role's company "
            "folder for pipeline-generated ones."
        )
    for lineno, name, match, why in pdd.scan_text(body or "", rel, max_hits=4):
        snippet = match if len(match) <= 60 else match[:57] + "..."
        reasons.append(f"the content contains {name}: `{snippet}` — {why}")

    if reasons:
        report(rel + (f" (via {label})" if label else ""), reasons)


# ── Direct file-writing tools ────────────────────────────────────────────────────────
path = ti.get("file_path") or ti.get("notebook_path") or ti.get("path") or ""
parts = [
    ti.get("content"),      # Write, MCP filesystem write_file
    ti.get("new_string"),   # Edit
    ti.get("new_source"),   # NotebookEdit — was missed in the first version
    ti.get("text"),
]
for e in (ti.get("edits") or []):
    if isinstance(e, dict):
        parts.append(e.get("new_string"))
body = "\n".join(p for p in parts if isinstance(p, str) and p)
check(path, body)

# ── Bash: the biggest hole in the first version ──────────────────────────────────────
# A hook cannot reliably parse shell, so this is deliberately conservative: if the command
# both looks like it writes AND carries personal data, block it. It will not catch every
# possible shell write, and the pre-commit and build scans remain the backstop for the rest.
if tool == "Bash":
    cmd = ti.get("command") or ""
    # A shell redirect, or a copy/move/in-place edit. The lookbehind keeps `->`, `=>`,
    # `>=` and `<>` from reading as redirects — without it, any command containing an
    # arrow (common in printed output and comments) looks like a write, and the guard
    # starts firing on read-only work. A guard that cries wolf gets turned off.
    # `git` is layer 2's job, not layer 1's. A commit does not introduce new file content —
    # the content was already scanned when it was written — and commit messages legitimately
    # quote paths, addresses and IDs while describing a fix. Scanning them here blocked an
    # ordinary `git commit`, which would have made the guard the first thing anyone disabled.
    # The command must be git and NOTHING BUT git. Matching a `git` prefix was too wide:
    # `git status; cat > skills/x.md <<EOF …` disabled layer 1 outright.
    # Split on shell separators and require EVERY segment to be a git command (or a bare
    # `cd`). Requiring the whole string to contain no separator was too strict the other
    # way — `git add -A && git commit -m … && git push` is entirely git, and blocking it
    # meant the guard fired on the most routine action there is.
    _segs = [seg.strip() for seg in re.split(r"&&|\|\||[;|]", cmd) if seg.strip()]
    if _segs and all(re.match(r"(cd\s+\S+|git(\s|$))", seg) for seg in _segs):
        sys.exit(0)

    # A shell redirect, or a write-shaped command. Two deliberate narrowings:
    #  - the lookbehind keeps `->`, `=>`, `>=` and `<>` from reading as redirects;
    #  - the command words are anchored to command position, because `install`, `dd`, `cp`
    #    and `mv` are ordinary English words and matched inside prose ("the uvx install
    #    line…"), which fired the guard on read-only work.
    # ONE definition, used both to decide "is this a write?" and to count write constructs
    # for the unparsed-target fallback. Two copies drifted once already.
    WRITE_RX = re.compile(
        r"(?<![-=<>!])>>?\|?\s*['\"]?[\w./$~-]"   # >, >>, and the >| clobber redirect
        r"|(?:^|[;&|]\s*|\$\(\s*)(?:tee|cp|mv|install|rsync|dd)\s"
        r"|sed\s+-i"
        # In-place editors whose target is positional. They must appear HERE, not only in
        # the target extractor: the extractor runs inside `if writes:`, so a writer missing
        # from this alternation skips the whole Bash branch and the catch-all never runs.
        r"|perl\s+[-\w]*i[-\w]*\s|(?:^|[;&|]\s*)(?:ex|ed|patch|sponge)\s"
        r"|open\([^)]*['\"][wa]"
        r"|write_text\(|\.write\("
    )
    writes = WRITE_RX.search(cmd)
    if writes:
        cwd = d.get("cwd") or os.getcwd()
        cwd_root = in_plugin_repo(os.path.join(cwd, "x")) or in_plugin_repo(cwd)

        # Does this command write INTO a plugin repo?
        #
        # Two wrong answers already shipped here, in opposite directions. Keying on "the
        # session's cwd is in the repo" blocked writes that LEAVE the repo (a report to
        # /tmp). Then resolving targets but still gating on a cwd-derived root made the
        # whole layer blind whenever the session ran from anywhere else — `cp /tmp/leak.md
        # <repo>/references/x.md` from $HOME sailed through, which is precisely the
        # helpful-agent shape this guard exists for.
        #
        # The target decides, not the session. Resolve each target and ask whether IT is
        # inside a plugin repo; fall back to cwd only when nothing parses.
        # Extract a target from every write construct we can parse. Redirects are not the
        # only shape: `tee`, `dd of=`, `sed -i` and `open(…, 'w')` all name their target as
        # a plain argument, and leaving them out meant a write into the repo from an
        # outside cwd was invisible — M1 again, one level down.
        target_patterns = [
            r">>?\|?\s*['\"]?([\w./$~-]+)",                                   # > >> >|
            r"(?:^|[;&|]\s*)(?:cp|mv|install|rsync)\s+[^\n;&|]*?['\"]?([\w./$~-]+)['\"]?\s*(?=$|[;&|])",
            r"\btee\s+(?:-a\s+)?['\"]?([\w./$~-]+)",
            r"\bdd\s+[^\n;&|]*\bof=['\"]?([\w./$~-]+)",
            r"\bopen\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"][wa]",
            # No pattern for `sed -i` on purpose. Its own expression contains the pipe and
            # quotes that argument-splitting relies on (`sed -i '' 's|a|b|' file`), and a
            # naive pattern captures the `s` of the expression as the target — which is
            # worse than no pattern at all, because a bogus target makes the command look
            # parsed and suppresses the catch-all below. Let sed fall through to it.
        ]
        targets = []
        for rx in target_patterns:
            targets += re.findall(rx, cmd, re.M)
        targets = [t for t in targets if t not in ("/dev/null", "&1", "&2")]

        writes_into_repo = False
        root = None
        for tgt in targets:
            resolved = os.path.abspath(tgt if os.path.isabs(tgt) else os.path.join(cwd, tgt))
            tgt_root = in_plugin_repo(resolved)
            if tgt_root:
                writes_into_repo, root = True, tgt_root
                break

        # Fallback for writes we could NOT parse (a heredoc, an exotic tool). Gate it on
        # "some write construct produced no target", not on "no target at all" — otherwise
        # one benign parseable write (`echo ok > /tmp/log`) suppresses the fallback for an
        # unparseable one beside it in the same command, which is how a `sed -i` into the
        # repo slipped through.
        # Count write constructs with the SAME pattern that decided there was a write at
        # all. Keeping a second, hand-copied copy of it here is how `perl -pi` slipped
        # through after being added to the first one: the counter returned 0, so
        # `unparsed` was False and both fallbacks were skipped.
        n_constructs = len(WRITE_RX.findall(cmd))
        unparsed = n_constructs > len(targets)

        if not writes_into_repo and unparsed:
            # Some write construct did not yield a target — `sed -i 's|a|b|' <path>` is the
            # awkward case, since its own expression contains the pipe that argument
            # splitting relies on. Rather than out-parse the shell, look at every path-like
            # token in the command and ask whether any of them lands in a plugin repo.
            # Conservative in the right direction: it can only ever add a check.
            for tok in re.findall(r"['\"]?((?:/|\./|\.\./)[\w./$~-]+)['\"]?", cmd):
                tok_root = in_plugin_repo(os.path.abspath(tok))
                if tok_root:
                    writes_into_repo, root = True, tok_root
                    break

        if not writes_into_repo and unparsed and cwd_root:
            # Still nothing resolvable, but the session sits inside the repo and something
            # unparsed is writing — a heredoc to a relative path, most likely.
            writes_into_repo, root = True, cwd_root

        if writes_into_repo:
            # The repo's own absolute path is a LOCATION, not a payload: `cd <repo> && …`
            # is the normal way to address it and must not read as a leak.
            #
            # ⛔ Strip ONLY the repo root and the cwd — never $HOME. Stripping $HOME made
            # the guard blind to exactly the leaks that matter: on the user's own machine
            # every real personal path is under her home directory. The June 2026 file that
            # shipped in eight builds was an output_folder, a draft-dir link and an iCloud
            # path, all under her $HOME — this guard would have waved every one of them
            # through. A `cd ~` is already covered by cwd.
            # Strip the repo root always. Strip cwd ONLY when cwd is itself inside the
            # repo — otherwise this is N1 all over again by another route: a session run
            # from $HOME would strip $HOME, and every personal path on this machine lives
            # under it. Verified by a battery case (`cp into repo from outside`).
            scan_src = cmd
            strip = [root]
            if cwd_root and cwd.startswith(cwd_root):
                strip.append(cwd)
            for loc in filter(None, strip):
                scan_src = scan_src.replace(loc, " ")

            reasons = []
            # Only when the name is a write TARGET — after a redirect, or as the last
            # argument to a copy/move. Merely mentioning the pattern (documenting it,
            # grepping for it) is not a write, and flagging that made it impossible to
            # write about the guard at all.
            if re.search(
                r">>?\s*['\"]?\S*update-prompt-[^\s'\"]*\.md"
                r"|(^|\s)(cp|mv|install|rsync)\s[^\n|;]*\bupdate-prompt-[^\s'\"]*\.md",
                cmd,
            ):
                reasons.append(
                    "the command writes a file named update-prompt-*.md into the plugin repo; "
                    "those carry personal career data and belong under output_folder."
                )
            for lineno, name, match, why in pdd.scan_text(scan_src, "", max_hits=3):
                snippet = match if len(match) <= 60 else match[:57] + "..."
                reasons.append(f"the command contains {name}: `{snippet}` — {why}")
            if reasons:
                report("a Bash write inside the plugin repo", reasons)

sys.exit(0)
PY

printf '%s' "$PAYLOAD" | HOOK_SCRIPTS_DIR="$HERE" python3 -c "$PYBODY"
rc=$?
[ "$rc" -eq 2 ] && exit 2
exit 0
