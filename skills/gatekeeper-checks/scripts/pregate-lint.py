#!/usr/bin/env python3
"""
pregate-lint.py
Standard-library-only pre-gate linter for cv-writer and letter-writer.

Purpose: writers run this on their own draft BEFORE returning to the
orchestrator/gatekeeper. It reports EVERY violation of the deterministic
(string-matchable) subset of the gatekeeper checks defined in
skills/gatekeeper-checks/{cv-gates.md,letter-gates.md} — unlike the agent
gatekeeper, which is instructed to stop at the first violation per check.
This script is advisory-fast-path only: passing it does NOT mean the
gatekeeper will pass the draft (semantic/judgment checks aren't attempted
here), and failing it does not itself block a pipeline round — it's a
cheap self-check writers run before spawning the real gatekeeper.

Usage:
    python3 pregate-lint.py --type cv|letter <file.md>
    python3 pregate-lint.py --selftest

Output:
    LINE <n>: <check-id>: <matched text> -- <rule>
    ... (one line per violation/warning, sorted by line number)
    PREGATE: <N> violations, <M> warnings

Exit code: 0 if zero violations (warnings never block), 1 otherwise.

--------------------------------------------------------------------------
DATA PROVENANCE (2026-07-22 context-diet split moved the gate text out of
SKILL.md into cv-gates.md / letter-gates.md; SKILL.md is now a routing file.
Gate numbers were preserved verbatim in the split -- see SKILL.md's
"Where the checks live" table. Every list below cites the sub-file + gate
it was copied from. Do not add an entry here without a matching citation;
do not remove an entry without confirming it left the source file too.)
--------------------------------------------------------------------------
"""
import argparse
import re
import sys

# ==========================================================================
# DATA -- extracted verbatim (or as regex families for bracket-templated
# phrases) from skills/gatekeeper-checks/{cv-gates.md,letter-gates.md}.
# ==========================================================================

# --- letter-gates.md, Gate 6 Tier 1, "Cliche and vague filler" list --------
# The two items the list itself calls out as "emphasis intensifiers" are
# split into their own list per the task's "banned intensifiers" category.
LETTER_INTENSIFIERS = [
    "genuinely",
    "actually",
    "real",
]

# Remaining literal entries from the same "Cliche and vague filler" bullet
# (letter-gates.md Gate 6 Tier 1). "rare" is kept literal per the source's
# own "'rare' as self-descriptor" wording -- flagged as a plain word hit,
# same literal-string-search standard the skill itself mandates.
LETTER_CLICHE_FILLER = [
    "specialism",
    "straightforward",
    "dynamic",
    "extensive experience",
    "proven track record",
    "passionate about",
    "results-driven",
    "at the intersection",
    "I would welcome the chance to",
    "significant part of my career",
    "up close",
    "at an inflection point",
    "rare",
    "that made it land",
]
# Bracket-templated members of the same bullet, encoded as regex families.
# ("X is [something], not [something] as a positioning claim" is excluded --
# it names a syntactic *shape*, not a literal string or closed word-class,
# so it is not part of the deterministic subset this script covers.)
LETTER_CLICHE_FILLER_PATTERNS = [
    r"behind the \w+",
    r"quietly \w+ing",
    r"I have .+ on exactly that",
    r"what puts me closest to what",
    r"I know how to speak to buyers",
]

# --- letter-gates.md, Gate 6 Tier 1, "AI vocabulary -- ban every instance" -
# "system (figurative -- exempt only an actual software/technical system)"
# is excluded: the skill's own parenthetical says telling figurative from
# literal use needs judgment, so it fails the "deterministic" bar.
LETTER_AI_VOCABULARY = [
    "crucial", "pivotal", "vibrant", "showcase", "showcasing", "tapestry",
    "underscore", "landscape", "testament", "enduring", "foster",
    "fostering", "garner", "interplay", "intricate", "intricacies",
    "foundational", "transformative", "robust", "seamless",
    "comprehensive", "playbook", "leverage", "synergy", "spearhead",
    "paradigm", "mandate", "blank page",
]

# --- letter-gates.md, Gate 6 Tier 1, "Cover-letter-only phrase bans" -------
LETTER_PHRASE_BANS_LITERAL = [
    "I was just doing",
    "I know how to sell",
    "I knew this was mine",
    "I spent the better part of a decade",
    "handed me",
]
# 2026-07-14 grep-family additions named explicitly in the same bullet.
LETTER_PHRASE_BANS_PATTERNS = [
    r"exactly that",
    r"in (?:their|the) flow",
    r"toward the",
    r"I've read",
    r"I have read",
    r"read the.*posting",
    r"read the.*JD",
    r"read.*twice",
    r"twice.*read",
]

# --- letter-gates.md, Gate 6 Tier 1, "Fit-declaration family" --------------
LETTER_FIT_DECLARATION_LITERAL = [
    "was mine",
    "meant for me",
    "meant to be",
    "this is the seat",
    "this is the one",
]
LETTER_FIT_DECLARATION_PATTERNS = [
    r"the moment I saw",
    r"knew.*mine",
    r"recognized.*immediately",
]

# --- letter-gates.md, Gate 6 Tier 1, "Builder-origin phrase cap" -----------
# "More than ONE total occurrence across the body = FAIL. ANY occurrence
# while 'from scratch' also appears anywhere in the body = FAIL."
LETTER_BUILDER_ORIGIN_PATTERNS = [r"zero to", r"zero-to", r"from zero"]
LETTER_BUILDER_ORIGIN_CAP = 1
LETTER_FROM_SCRATCH_PATTERN = r"from scratch"

# --- letter-gates.md, Gate 7, first bullet ("Em dashes ... zero permitted")
# Gate 7 is Tier 2 for the Cover Letter Check's own grading (see letter-gates.md
# "Grading and Pass Threshold" -- Gate 7 is not in the Tier 1 list), so this
# fires as a WARNING here, not a violation, matching the skill's own tiering.
EM_DASH_CHAR = "—"  # —

# --- letter-gates.md, Gate 1, body word-count ceiling ----------------------
LETTER_BODY_MAX_WORDS_DEFAULT = 320
LETTER_BODY_MAX_WORDS_STRATEGIC = 250  # when this letter's Strategy = Strategic

# --- cv-gates.md, Gate 3 -- "No em dash" / "No colon" (both Hard fail) -----
# (CV type only -- letter-gates.md documents no colon ban for the letter body.)

# --- cv-gates.md, Gate 3 -- "AI-tell vocabulary" (Advisory) ----------------
CV_AI_TELL_VOCABULARY = [
    "crucial", "pivotal", "vibrant", "showcase", "showcasing", "tapestry",
    "underscore", "landscape", "testament", "enduring", "foster",
    "fostering", "garner", "interplay", "intricate", "intricacies",
    "foundational", "transformative", "robust", "seamless",
    "comprehensive", "leverage", "synergy", "spearhead", "paradigm",
    "know what it takes", "land",
    # "CV-only additions" from the same bullet:
    "think outside the box", "value add", "go-to person", "bottom line",
    "big picture", "cutting-edge", "game-changer", "guru", "ninja",
    "rockstar", "world-class", "paradigm shift", "scalable", "disruptive",
    "innovative", "holistic approach", "agile",
]

# --- cv-gates.md, Gate 3 -- "Named phrase bans" (Advisory) -----------------
CV_NAMED_PHRASE_BANS_LITERAL = [
    "that made it land",
    "at an inflection point",
    "up close",
    "specialism",
    "rare",
]
CV_NAMED_PHRASE_BANS_PATTERNS = [
    r"behind the \w+",
    r"quietly \w+ing",
]

# --- cv-gates.md, Gate 3 -- "Soft-skill filler banned" (Hard fail) ---------
# The source qualifies this as a FAIL "if present without bullet-level
# substantiation" -- judging substantiation needs a human read, so this
# script flags every literal hit for manual review rather than silently
# passing (documented limitation, not a silent narrowing of the rule).
CV_SOFT_SKILL_FILLER = [
    "works independently",
    "self-starter",
    "takes initiative",
    "manages own workload",
    "team player",
]

# --- cv-gates.md, Gate 1 -- Detailed Summary word/sentence ceiling ---------
# ("Detailed: <=120 words, 1 paragraph, <=4 sentences ... Hard fail.")
# Brief's Profile Summary has no standalone numeric ceiling in cv-gates.md
# (it shares a whole-CV backstop with no stated number) -- not enforced here.
CV_SUMMARY_MAX_WORDS = 120
CV_SUMMARY_MAX_SENTENCES = 4

# --- cv-gates.md, Gate 2 -- Detailed length limits (2026-10-20, per the user) -
# Detailed only (Brief is held to one page by its own backstop).
#   * RoleOverview line  <= 120 characters
#   * RoleTitle line     <= 95 characters (rendered text: markup stripped)
#   * Total CV body      <= 890 words, NOT counting Education / Languages / Additional
#     (the user's own footer content, appended at export and never in a draft)
CV_ROLE_OVERVIEW_MAX_CHARS = 120
CV_ROLE_TITLE_MAX_CHARS = 95
CV_TOTAL_MAX_WORDS = 890

# --- cv-gates.md, Gate 5 -- Skills Section Content (Hard fail) -------------
# Stopwords for the heading-word-repetition check (small closed list, not
# from the skill -- used only to filter function words out of headings
# before comparing against skills-list items).
HEADING_STOPWORDS = {
    "skills", "skill", "and", "with", "from", "that", "this", "into",
    "your", "their", "about", "across", "over", "under", "using",
    "within", "based",
}

# Small synonym table for the noun-doublet WARNING check (task-specified
# pairs: management/leadership, workflows/systems, positioning/messaging).
DOUBLET_SYNONYMS = {
    ("management", "leadership"), ("leadership", "management"),
    ("workflows", "systems"), ("systems", "workflows"),
    ("positioning", "messaging"), ("messaging", "positioning"),
}

WORD_RE = re.compile(r"[A-Za-z']+")
SENTENCE_SPLIT_RE = re.compile(r"(?<=[.!?])\s+(?=[A-Z\"'])")


# ==========================================================================
# Violation record + generic scanners
# ==========================================================================

class Violation:
    __slots__ = ("line", "check_id", "matched", "rule", "severity")

    def __init__(self, line, check_id, matched, rule, severity):
        self.line = line
        self.check_id = check_id
        self.matched = matched
        self.rule = rule
        self.severity = severity  # "violation" or "warning"

    def render(self):
        tag = "" if self.severity == "violation" else "[WARNING] "
        matched = self.matched.strip() or "(no excerpt)"
        return f"LINE {self.line}: {self.check_id}: {matched} -- {tag}{self.rule}"


def _compile_literal(phrases):
    escaped = "|".join(re.escape(p) for p in phrases)
    return re.compile(r"\b(?:" + escaped + r")\b", re.IGNORECASE)


def _compile_patterns(patterns):
    return re.compile(r"(?:" + "|".join(patterns) + r")", re.IGNORECASE)


def scan_lines(lines, regex, check_id, rule, severity, skip_idx=None):
    skip_idx = skip_idx or set()
    hits = []
    for idx, line in enumerate(lines):
        if idx in skip_idx:
            continue
        for m in regex.finditer(line):
            hits.append(Violation(idx + 1, check_id, m.group(0), rule, severity))
    return hits


def phrase_check(lines, literal, patterns, check_id, rule, severity, skip_idx=None):
    hits = []
    if literal:
        hits += scan_lines(lines, _compile_literal(literal), check_id, rule, severity, skip_idx)
    if patterns:
        hits += scan_lines(lines, _compile_patterns(patterns), check_id, rule, severity, skip_idx)
    return hits


FENCE_OR_HEADING_RE = re.compile(r"^\s*(:{3,4}|#{1,6}\s|```)")


def _structural_skip_idx(lines):
    """Line indexes that are pandoc div-fences / markdown headings -- excluded
    from the em-dash/colon body-copy scan so the fence syntax (':::') and any
    heading markup don't false-positive as banned punctuation."""
    return {i for i, line in enumerate(lines) if FENCE_OR_HEADING_RE.match(line)}


# ==========================================================================
# Detailed length limits (cv-gates.md Gate 2, 2026-10-20) -- Detailed only.
# ==========================================================================

_SPAN_RE = re.compile(r"\[([^\]]*)\]\{[^}]*\}")
_COMMENT_RE = re.compile(r"<!--.*?-->")
_STYLE_DIV_RE = re.compile(r'^\s*:{3,4}\s*\{custom-style="([^"]+)"\}\s*$')
_FENCE_CLOSE_RE = re.compile(r"^\s*:{3,4}\s*$")
_EXCLUDED_SECTION_RE = re.compile(r"^##\s+(EDUCATION|LANGUAGES|ADDITIONAL)\b", re.IGNORECASE)


def _rendered(text):
    """Rendered text of one line: [x]{custom-style=..} spans reduced to x,
    HTML comments dropped, list markers and surrounding whitespace removed."""
    text = _COMMENT_RE.sub("", text)
    text = _SPAN_RE.sub(r"\1", text)
    text = re.sub(r"^\s*(?:[-*+]|\d+\.)\s+", "", text)
    return text.strip()


def _style_blocks(lines, style):
    """Yield (line_no, rendered_text) for each custom-style div of `style`."""
    i = 0
    while i < len(lines):
        m = _STYLE_DIV_RE.match(lines[i])
        if m and m.group(1) == style:
            body = []
            j = i + 1
            while j < len(lines) and not _FENCE_CLOSE_RE.match(lines[j]):
                body.append(lines[j])
                j += 1
            yield i + 1, _rendered(" ".join(b.strip() for b in body if b.strip()))
            i = j
        i += 1


def count_cv_words(lines):
    """Countable CV words: whitespace tokens with at least one letter or digit
    (so '|' separators and bullet dashes never count), div fences and HTML
    comments excluded, '## EDUCATION/LANGUAGES/ADDITIONAL' sections excluded."""
    total, skipping = 0, False
    for line in lines:
        if re.match(r"^##\s", line):
            skipping = bool(_EXCLUDED_SECTION_RE.match(line))
        if skipping or FENCE_OR_HEADING_RE.match(line) and not line.lstrip().startswith("#"):
            continue
        total += sum(1 for tok in _rendered(line).split() if re.search(r"[A-Za-z0-9]", tok))
    return total


def check_cv_length_limits(lines):
    if any(re.match(r"^##\s+PROFILE SUMMARY\b", l, re.IGNORECASE) for l in lines):
        return []  # Brief -- one-page backstop governs, not these Detailed limits
    hits = []
    for ln, text in _style_blocks(lines, "RoleOverview"):
        if len(text) > CV_ROLE_OVERVIEW_MAX_CHARS:
            hits.append(Violation(
                ln, "CV-ROLE-OVERVIEW-LENGTH", f"{len(text)} chars",
                f"RoleOverview is {len(text)} characters, over the {CV_ROLE_OVERVIEW_MAX_CHARS}-character "
                f"Detailed ceiling (cv-gates.md Gate 2; Hard fail).", "violation"))
    for ln, text in _style_blocks(lines, "RoleTitle"):
        if len(text) > CV_ROLE_TITLE_MAX_CHARS:
            hits.append(Violation(
                ln, "CV-ROLE-TITLE-LENGTH", f"{len(text)} chars",
                f"RoleTitle line is {len(text)} characters, over the {CV_ROLE_TITLE_MAX_CHARS}-character "
                f"Detailed ceiling (cv-gates.md Gate 2; Hard fail).", "violation"))
    words = count_cv_words(lines)
    if words > CV_TOTAL_MAX_WORDS:
        hits.append(Violation(
            1, "CV-TOTAL-WORDCOUNT", f"{words} words",
            f"CV body is {words} words, over the {CV_TOTAL_MAX_WORDS}-word Detailed ceiling, not counting "
            f"Education/Additional (cv-gates.md Gate 2; Hard fail). Cut by the 'Cut priority order' in "
            f"writer-craft/cv.md section 6; fold a role before trimming proof the role most needs.", "violation"))
    return hits


# ==========================================================================
# Builder-origin phrase cap (letter-gates.md Gate 6 Tier 1) -- whole-body cap,
# not a per-line pattern, so it gets its own function.
# ==========================================================================

def check_builder_origin_cap(lines):
    pattern = _compile_patterns(LETTER_BUILDER_ORIGIN_PATTERNS)
    matches = []
    for idx, line in enumerate(lines):
        for m in pattern.finditer(line):
            matches.append((idx + 1, m.group(0)))
    from_scratch = _compile_patterns([LETTER_FROM_SCRATCH_PATTERN])
    has_from_scratch = any(from_scratch.search(line) for line in lines)

    rule = (
        "Builder-origin phrase cap: more than 1 total occurrence of "
        "zero to/zero-to/from zero, or any occurrence while 'from scratch' "
        "also appears, is a violation (letter-gates.md Gate 6 Tier 1)."
    )
    if len(matches) > LETTER_BUILDER_ORIGIN_CAP or (has_from_scratch and matches):
        return [
            Violation(line_no, "LETTER-BUILDER-ORIGIN", text, rule, "violation")
            for line_no, text in matches
        ]
    return []


# ==========================================================================
# Word-count ceilings
# ==========================================================================

def _find_letter_body(lines):
    start, end = 0, len(lines)
    for i, line in enumerate(lines):
        if re.match(r"^\s*Hi to\b", line, re.IGNORECASE):
            start = i + 1
            break
    for i in range(len(lines) - 1, -1, -1):
        if "{{USER_FULL_NAME}}" in lines[i]:
            end = i
            break
    return lines[start:end]


def check_letter_body_word_count(lines, strategic=False):
    body_lines = _find_letter_body(lines)
    words = WORD_RE.findall(" ".join(body_lines))
    cap = LETTER_BODY_MAX_WORDS_STRATEGIC if strategic else LETTER_BODY_MAX_WORDS_DEFAULT
    if len(words) > cap:
        rule = (
            f"Body word count {len(words)} exceeds the {cap}-word ceiling "
            f"(letter-gates.md Gate 1; advisory/round-aware in the real "
            f"gatekeeper, but always worth fixing before round 1)."
        )
        return [Violation(len(lines), "LETTER-BODY-WORDCOUNT", f"{len(words)} words", rule, "warning")]
    return []


def _find_section(lines, heading_re):
    start = None
    for i, line in enumerate(lines):
        if heading_re.match(line):
            start = i + 1
            break
    if start is None:
        return None
    end = len(lines)
    for i in range(start, len(lines)):
        if re.match(r"^##\s", lines[i]):
            end = i
            break
    return lines[start:end]


def check_cv_summary_wordcount(lines):
    section = _find_section(lines, re.compile(r"^##\s+SUMMARY\b", re.IGNORECASE))
    if section is None:
        return []  # Detailed SUMMARY heading absent -- Brief has no documented numeric ceiling here.
    text = " ".join(section)
    words = WORD_RE.findall(text)
    sentences = [s for s in SENTENCE_SPLIT_RE.split(re.sub(r"\s+", " ", text).strip()) if s.strip()]
    hits = []
    if len(words) > CV_SUMMARY_MAX_WORDS:
        rule = (
            f"Summary is {len(words)} words, over the {CV_SUMMARY_MAX_WORDS}-word "
            f"Detailed ceiling (cv-gates.md Gate 1; Hard fail)."
        )
        hits.append(Violation(1, "CV-SUMMARY-WORDCOUNT", f"{len(words)} words", rule, "violation"))
    if len(sentences) > CV_SUMMARY_MAX_SENTENCES:
        rule = (
            f"Summary has {len(sentences)} sentences, over the "
            f"{CV_SUMMARY_MAX_SENTENCES}-sentence Detailed ceiling (cv-gates.md Gate 1; Hard fail)."
        )
        hits.append(Violation(1, "CV-SUMMARY-SENTENCECOUNT", f"{len(sentences)} sentences", rule, "violation"))
    return hits


# ==========================================================================
# CV Skills-section content checks (pandoc custom-style blocks) --
# these are new checks per the task spec, not extracted from a SKILL.md list.
# Format mirrored from delivered CVs / skills/career-engine-export examples:
#   :::: {custom-style="SkillsHeading"}
#   Heading text
#   :::
#
#   ::: {custom-style="Skills"}
#   Item one | Item two | Item three
#   :::
# ==========================================================================

SKILLS_HEADING_OPEN_RE = re.compile(r'^\s*:{3,4}\s*\{custom-style="SkillsHeading"\}\s*$')
SKILLS_OPEN_RE = re.compile(r'^\s*:{3,4}\s*\{custom-style="Skills"\}\s*$')
FENCE_CLOSE_RE = re.compile(r"^\s*:{3,4}\s*$")

PAREN_ENUM_RE = re.compile(r"\(([^)]*)\)")
DOUBLET_RE = re.compile(r"\b([A-Za-z][A-Za-z\-]{2,})\s+and\s+([A-Za-z][A-Za-z\-]{2,})\b", re.IGNORECASE)


def _significant_words(text):
    return {
        w.lower() for w in WORD_RE.findall(text)
        if len(w) > 4 and w.lower() not in HEADING_STOPWORDS
    }


def _shares_stem(a, b, min_len=5):
    a, b = a.lower(), b.lower()
    if len(a) < min_len or len(b) < min_len:
        return False
    return a[:min_len] == b[:min_len]


def find_skills_blocks(lines):
    """Yield (heading_text, [(line_no, item_text), ...]) for each
    SkillsHeading/Skills block pair found in the document."""
    blocks = []
    i = 0
    n = len(lines)
    while i < n:
        if SKILLS_HEADING_OPEN_RE.match(lines[i]):
            j = i + 1
            heading_parts = []
            while j < n and not FENCE_CLOSE_RE.match(lines[j]):
                heading_parts.append(lines[j])
                j += 1
            heading_text = " ".join(p.strip() for p in heading_parts if p.strip())
            j += 1  # past the heading's closing fence
            while j < n and lines[j].strip() == "":
                j += 1
            if j < n and SKILLS_OPEN_RE.match(lines[j]):
                k = j + 1
                items = []
                while k < n and not FENCE_CLOSE_RE.match(lines[k]):
                    line_no = k + 1
                    for raw_item in lines[k].split("|"):
                        item = raw_item.strip()
                        if item:
                            items.append((line_no, item))
                    k += 1
                blocks.append((heading_text, items))
                i = k + 1
                continue
        i += 1
    return blocks


def check_skills_sections(lines):
    hits = []
    for heading_text, items in find_skills_blocks(lines):
        heading_words = _significant_words(heading_text)
        for line_no, item in items:
            item_lower = item.lower()

            # heading-word repetition
            if heading_words:
                for hw in heading_words:
                    if re.search(r"\b" + re.escape(hw) + r"\b", item_lower):
                        rule = (
                            f"Skills item repeats its own heading's significant word "
                            f"'{hw}' (heading: '{heading_text}') -- new check, cv-gates.md "
                            f"Gate 5 Skills-Section-Content contract."
                        )
                        hits.append(Violation(line_no, "CV-SKILL-HEAD-REPEAT", item, rule, "violation"))

            # parenthetical enumeration inside a skills item
            for m in PAREN_ENUM_RE.finditer(item):
                inner = m.group(1)
                if "," in inner or "/" in inner:
                    rule = (
                        "Parenthetical enumeration inside a skills item -- new check, "
                        "cv-gates.md Gate 5 Skills-Section-Content contract."
                    )
                    hits.append(Violation(line_no, "CV-SKILL-PAREN-ENUM", item, rule, "violation"))
                    break

            # noun doublet "X and Y" -- warning only
            for m in DOUBLET_RE.finditer(item):
                x, y = m.group(1), m.group(2)
                pair = (x.lower(), y.lower())
                if pair in DOUBLET_SYNONYMS or _shares_stem(x, y):
                    rule = (
                        f"Noun doublet '{x} and {y}' -- shared stem or synonym-table match "
                        f"(management/leadership, workflows/systems, positioning/messaging) -- "
                        f"new check, cv-gates.md Gate 5 Skills-Section-Content contract."
                    )
                    hits.append(Violation(line_no, "CV-SKILL-DOUBLET", m.group(0), rule, "warning"))
    return hits


# ==========================================================================
# Top-level scans per --type
# ==========================================================================

def scan_cv(lines):
    hits = []
    skip_idx = _structural_skip_idx(lines)

    hits += scan_lines(
        lines, re.compile(re.escape(EM_DASH_CHAR)),
        "CV-EMDASH", "No em dash anywhere (cv-gates.md Gate 3; Hard fail).",
        "violation", skip_idx,
    )
    hits += scan_lines(
        lines, re.compile(r":"),
        "CV-COLON", "No colon anywhere in body copy (cv-gates.md Gate 3; Hard fail).",
        "violation", skip_idx,
    )
    hits += phrase_check(
        lines, CV_AI_TELL_VOCABULARY, None,
        "CV-AI-VOCAB", "AI-tell vocabulary (cv-gates.md Gate 3; Advisory, scored).",
        "warning",
    )
    hits += phrase_check(
        lines, CV_NAMED_PHRASE_BANS_LITERAL, CV_NAMED_PHRASE_BANS_PATTERNS,
        "CV-NAMED-PHRASE", "Named phrase ban (cv-gates.md Gate 3; Advisory).",
        "warning",
    )
    hits += phrase_check(
        lines, CV_SOFT_SKILL_FILLER, None,
        "CV-SOFT-SKILL",
        "Soft-skill filler without bullet-level substantiation -- flagged for "
        "manual substantiation review (cv-gates.md Gate 3; Hard fail).",
        "violation",
    )
    hits += check_cv_summary_wordcount(lines)
    hits += check_skills_sections(lines)
    hits += check_cv_length_limits(lines)
    return hits


def scan_letter(lines, strategic=False):
    hits = []
    hits += phrase_check(
        lines, LETTER_INTENSIFIERS, None,
        "LETTER-INTENSIFIER", "Banned emphasis intensifier (letter-gates.md Gate 6 Tier 1; Hard fail).",
        "violation",
    )
    hits += phrase_check(
        lines, LETTER_CLICHE_FILLER, LETTER_CLICHE_FILLER_PATTERNS,
        "LETTER-CLICHE-FILLER", "Cliche/vague filler (letter-gates.md Gate 6 Tier 1; Hard fail).",
        "violation",
    )
    hits += phrase_check(
        lines, LETTER_AI_VOCABULARY, None,
        "LETTER-AI-VOCAB", "AI vocabulary (letter-gates.md Gate 6 Tier 1; Hard fail).",
        "violation",
    )
    hits += phrase_check(
        lines, LETTER_PHRASE_BANS_LITERAL, LETTER_PHRASE_BANS_PATTERNS,
        "LETTER-PHRASE-BAN", "Cover-letter-only phrase ban (letter-gates.md Gate 6 Tier 1; Hard fail).",
        "violation",
    )
    hits += phrase_check(
        lines, LETTER_FIT_DECLARATION_LITERAL, LETTER_FIT_DECLARATION_PATTERNS,
        "LETTER-FIT-DECLARATION", "Fit-declaration family (letter-gates.md Gate 6 Tier 1; Hard fail).",
        "violation",
    )
    hits += check_builder_origin_cap(lines)
    hits += scan_lines(
        lines, re.compile(re.escape(EM_DASH_CHAR)),
        "LETTER-EMDASH",
        "Em dash in letter body (letter-gates.md Gate 7; Tier 2 -- scored, not Tier 1).",
        "warning",
    )
    hits += check_letter_body_word_count(lines, strategic=strategic)
    return hits


# ==========================================================================
# CLI
# ==========================================================================

def run_lint(path, doc_type, strategic=False):
    with open(path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()
    if doc_type == "cv":
        return scan_cv(lines)
    return scan_letter(lines, strategic=strategic)


def print_report(hits):
    hits = sorted(hits, key=lambda v: v.line)
    for v in hits:
        print(v.render())
    violations = sum(1 for v in hits if v.severity == "violation")
    warnings = sum(1 for v in hits if v.severity == "warning")
    print(f"PREGATE: {violations} violations, {warnings} warnings")
    return violations


# ==========================================================================
# --selftest -- embedded fixtures, one clean + one violating text per check.
# ==========================================================================

def _lines(text):
    return text.splitlines()


def selftest():
    failures = []

    def expect_clean(label, scan_fn, clean_text, check_id):
        hits = [h for h in scan_fn(_lines(clean_text)) if h.check_id == check_id]
        if hits:
            failures.append(f"{label}: expected clean, got {[h.render() for h in hits]}")

    def expect_dirty(label, scan_fn, dirty_text, check_id):
        hits = [h for h in scan_fn(_lines(dirty_text)) if h.check_id == check_id]
        if not hits:
            failures.append(f"{label}: expected a hit for {check_id}, got none")

    cv_scan = scan_cv
    letter_scan = scan_letter

    # CV-EMDASH
    expect_clean("CV-EMDASH", cv_scan, "## SUMMARY\nBuilt programs across three regions.", "CV-EMDASH")
    expect_dirty("CV-EMDASH", cv_scan, "## SUMMARY\nBuilt programs — across three regions.", "CV-EMDASH")

    # CV-COLON
    expect_clean("CV-COLON", cv_scan, "## SUMMARY\nLed programs across regions.", "CV-COLON")
    expect_dirty("CV-COLON", cv_scan, "## SUMMARY\nSkills: leadership and growth.", "CV-COLON")

    # CV-AI-VOCAB
    expect_clean("CV-AI-VOCAB", cv_scan, "## SUMMARY\nLed cross-region programs.", "CV-AI-VOCAB")
    expect_dirty("CV-AI-VOCAB", cv_scan, "## SUMMARY\nDrove a robust and seamless rollout.", "CV-AI-VOCAB")

    # CV-NAMED-PHRASE
    expect_clean("CV-NAMED-PHRASE", cv_scan, "## SUMMARY\nLed the launch end to end.", "CV-NAMED-PHRASE")
    expect_dirty("CV-NAMED-PHRASE", cv_scan, "## SUMMARY\nA specialism in enterprise GTM.", "CV-NAMED-PHRASE")

    # CV-SOFT-SKILL
    expect_clean("CV-SOFT-SKILL", cv_scan, "## SUMMARY\nShipped three launches solo.", "CV-SOFT-SKILL")
    expect_dirty("CV-SOFT-SKILL", cv_scan, "## SUMMARY\nA proven self-starter.", "CV-SOFT-SKILL")

    # CV-SUMMARY-WORDCOUNT / CV-SUMMARY-SENTENCECOUNT
    clean_summary = "## SUMMARY\n" + " ".join(["word"] * 50) + ".\n## EXPERIENCE\n"
    dirty_summary = "## SUMMARY\n" + " ".join(["word"] * 150) + ".\n## EXPERIENCE\n"
    expect_clean("CV-SUMMARY-WORDCOUNT", cv_scan, clean_summary, "CV-SUMMARY-WORDCOUNT")
    expect_dirty("CV-SUMMARY-WORDCOUNT", cv_scan, dirty_summary, "CV-SUMMARY-WORDCOUNT")

    # CV-ROLE-OVERVIEW-LENGTH / CV-ROLE-TITLE-LENGTH / CV-TOTAL-WORDCOUNT (Detailed only)
    ok_role = (
        '::: {custom-style="RoleTitle"}\n'
        'Director, Marketing | [Acme]{custom-style="ColorEmphasis"} | Tel Aviv | Jan 2020 -- Dec 2023\n'
        ':::\n\n'
        '::: {custom-style="RoleOverview"}\n'
        'Series C security platform; led GTM and partner marketing.\n'
        ':::\n'
    )
    long_overview = ok_role.replace("Series C security platform; led GTM and partner marketing.", "x" * 121)
    long_title = ok_role.replace("Director, Marketing", "Director, Marketing and Go-To-Market Strategy and Partner Programs and Field Operations")
    expect_clean("CV-ROLE-OVERVIEW-LENGTH", cv_scan, ok_role, "CV-ROLE-OVERVIEW-LENGTH")
    expect_dirty("CV-ROLE-OVERVIEW-LENGTH", cv_scan, long_overview, "CV-ROLE-OVERVIEW-LENGTH")
    expect_clean("CV-ROLE-TITLE-LENGTH", cv_scan, ok_role, "CV-ROLE-TITLE-LENGTH")
    expect_dirty("CV-ROLE-TITLE-LENGTH", cv_scan, long_title, "CV-ROLE-TITLE-LENGTH")
    body_ok = "## SUMMARY\n" + " ".join(["word"] * 800) + ".\n"
    body_long = "## SUMMARY\n" + " ".join(["word"] * 900) + ".\n"
    body_footer_only = body_ok + "## EDUCATION\n" + " ".join(["word"] * 300) + "\n"
    brief_long = "## PROFILE SUMMARY\n" + " ".join(["word"] * 900) + ".\n"
    expect_clean("CV-TOTAL-WORDCOUNT", cv_scan, body_ok, "CV-TOTAL-WORDCOUNT")
    expect_dirty("CV-TOTAL-WORDCOUNT", cv_scan, body_long, "CV-TOTAL-WORDCOUNT")
    expect_clean("CV-TOTAL-WORDCOUNT(education excluded)", cv_scan, body_footer_only, "CV-TOTAL-WORDCOUNT")
    expect_clean("CV-TOTAL-WORDCOUNT(brief exempt)", cv_scan, brief_long, "CV-TOTAL-WORDCOUNT")

    # CV-SKILL-HEAD-REPEAT
    clean_skills = (
        ':::: {custom-style="SkillsHeading"}\n'
        "Strategy & GTM\n"
        ":::\n\n"
        '::: {custom-style="Skills"}\n'
        "Product positioning | Sales enablement\n"
        ":::\n"
    )
    dirty_skills = (
        ':::: {custom-style="SkillsHeading"}\n'
        "Strategy & GTM\n"
        ":::\n\n"
        '::: {custom-style="Skills"}\n'
        "Go-to-market strategy execution\n"
        ":::\n"
    )
    expect_clean("CV-SKILL-HEAD-REPEAT", cv_scan, clean_skills, "CV-SKILL-HEAD-REPEAT")
    expect_dirty("CV-SKILL-HEAD-REPEAT", cv_scan, dirty_skills, "CV-SKILL-HEAD-REPEAT")

    # CV-SKILL-PAREN-ENUM
    clean_paren = (
        ':::: {custom-style="SkillsHeading"}\n'
        "Leadership\n"
        ":::\n\n"
        '::: {custom-style="Skills"}\n'
        "Team building | Cross-functional alignment\n"
        ":::\n"
    )
    dirty_paren = (
        ':::: {custom-style="SkillsHeading"}\n'
        "Leadership\n"
        ":::\n\n"
        '::: {custom-style="Skills"}\n'
        "Messaging (positioning, narrative, competitive)\n"
        ":::\n"
    )
    expect_clean("CV-SKILL-PAREN-ENUM", cv_scan, clean_paren, "CV-SKILL-PAREN-ENUM")
    expect_dirty("CV-SKILL-PAREN-ENUM", cv_scan, dirty_paren, "CV-SKILL-PAREN-ENUM")

    # CV-SKILL-DOUBLET (warning)
    clean_doublet = (
        ':::: {custom-style="SkillsHeading"}\n'
        "Leadership\n"
        ":::\n\n"
        '::: {custom-style="Skills"}\n'
        "Team building | Board reporting\n"
        ":::\n"
    )
    dirty_doublet = (
        ':::: {custom-style="SkillsHeading"}\n'
        "Leadership\n"
        ":::\n\n"
        '::: {custom-style="Skills"}\n'
        "Management and leadership\n"
        ":::\n"
    )
    expect_clean("CV-SKILL-DOUBLET", cv_scan, clean_doublet, "CV-SKILL-DOUBLET")
    expect_dirty("CV-SKILL-DOUBLET", cv_scan, dirty_doublet, "CV-SKILL-DOUBLET")

    # LETTER-INTENSIFIER
    expect_clean("LETTER-INTENSIFIER", letter_scan, "Hi to the team!\nI led the launch.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-INTENSIFIER")
    expect_dirty("LETTER-INTENSIFIER", letter_scan, "Hi to the team!\nI genuinely led the launch.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-INTENSIFIER")

    # LETTER-CLICHE-FILLER
    expect_clean("LETTER-CLICHE-FILLER", letter_scan, "Hi to the team!\nI led the launch.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-CLICHE-FILLER")
    expect_dirty("LETTER-CLICHE-FILLER", letter_scan, "Hi to the team!\nI have a proven track record.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-CLICHE-FILLER")

    # LETTER-AI-VOCAB
    expect_clean("LETTER-AI-VOCAB", letter_scan, "Hi to the team!\nI led the launch.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-AI-VOCAB")
    expect_dirty("LETTER-AI-VOCAB", letter_scan, "Hi to the team!\nA seamless and robust rollout.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-AI-VOCAB")

    # LETTER-PHRASE-BAN
    expect_clean("LETTER-PHRASE-BAN", letter_scan, "Hi to the team!\nI led the launch.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-PHRASE-BAN")
    expect_dirty("LETTER-PHRASE-BAN", letter_scan, "Hi to the team!\nI've read the posting twice.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-PHRASE-BAN")

    # LETTER-FIT-DECLARATION
    expect_clean("LETTER-FIT-DECLARATION", letter_scan, "Hi to the team!\nI led the launch.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-FIT-DECLARATION")
    expect_dirty("LETTER-FIT-DECLARATION", letter_scan, "Hi to the team!\nThis is the seat.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-FIT-DECLARATION")

    # LETTER-BUILDER-ORIGIN
    expect_clean("LETTER-BUILDER-ORIGIN", letter_scan, "Hi to the team!\nI grew the team from zero to 13.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-BUILDER-ORIGIN")
    expect_dirty("LETTER-BUILDER-ORIGIN", letter_scan, "Hi to the team!\nI grew zero to 13 and went zero-to-one twice.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-BUILDER-ORIGIN")

    # LETTER-EMDASH (warning)
    expect_clean("LETTER-EMDASH", letter_scan, "Hi to the team!\nI led the launch.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-EMDASH")
    expect_dirty("LETTER-EMDASH", letter_scan, "Hi to the team!\nI led the launch — end to end.\nLooking forward,\n{{USER_FULL_NAME}}", "LETTER-EMDASH")

    # LETTER-BODY-WORDCOUNT (warning)
    clean_letter_wc = "Hi to the team!\n" + " ".join(["word"] * 100) + "\nLooking forward,\n{{USER_FULL_NAME}}"
    dirty_letter_wc = "Hi to the team!\n" + " ".join(["word"] * 400) + "\nLooking forward,\n{{USER_FULL_NAME}}"
    expect_clean("LETTER-BODY-WORDCOUNT", letter_scan, clean_letter_wc, "LETTER-BODY-WORDCOUNT")
    expect_dirty("LETTER-BODY-WORDCOUNT", letter_scan, dirty_letter_wc, "LETTER-BODY-WORDCOUNT")

    if failures:
        print("SELFTEST FAILED:")
        for f in failures:
            print(f"  - {f}")
        return False
    print("SELFTEST: all checks fired correctly on their fixtures (clean passes, dirty flags).")
    return True


def main():
    parser = argparse.ArgumentParser(description="Pre-gate lint for cv-writer/letter-writer drafts.")
    parser.add_argument("file", nargs="?", help="Draft markdown file to lint.")
    parser.add_argument("--type", choices=["cv", "letter"], help="Document type.")
    parser.add_argument("--strategic", action="store_true",
                         help="Letter only: use the 250-word Strategy=Strategic ceiling instead of 320.")
    parser.add_argument("--selftest", action="store_true", help="Run embedded fixture self-tests and exit.")
    args = parser.parse_args()

    if args.selftest:
        ok = selftest()
        sys.exit(0 if ok else 1)

    if not args.type or not args.file:
        parser.error("--type and <file.md> are required (or pass --selftest)")

    hits = run_lint(args.file, args.type, strategic=args.strategic)
    violations = print_report(hits)
    sys.exit(1 if violations > 0 else 0)


if __name__ == "__main__":
    main()
