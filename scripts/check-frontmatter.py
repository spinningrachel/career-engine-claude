#!/usr/bin/env python3
"""Frontmatter validity gate — every shipped Markdown file that opens with a
frontmatter block must carry YAML the installer can parse.

Why this exists (2026-10-15): the Desktop app's plugin installer refused a shipped
build with "saving file 'agents/career-coach.md' would remove its frontmatter ...
because its frontmatter is not valid YAML". The description line carried unquoted
inner double quotes inside a double-quoted scalar. Nothing in the three QA layers
parsed frontmatter as YAML — every check was a grep — so the defect reached the
artifact. This script is the parse. It runs in the pre-commit hook, the build
script (pre-build), and qa-mechanical Check 72 (repo and unzipped artifact).

Rules:
  1. Agents (agents/*.md) and skills (skills/*/SKILL.md) MUST open with a
     frontmatter block: line 1 is exactly '---'. Any text above it hides the
     block from the platform (the humanizer lost its tool allowlist that way).
     They must also carry non-empty 'name' and 'description' keys.
  2. Every other shipped .md whose first line is '---' (references, background
     templates, skill sub-files) must parse too — the installer may parse any
     file it writes. Files with no frontmatter are not required to have one.
  3. The block must load as a YAML mapping, with NO duplicate keys — PyYAML
     silently keeps the last value, but the JavaScript readers most installers
     use reject duplicates, so the gate rejects them as well.

Usage: check-frontmatter.py <repo-or-unzipped-artifact-root>
Exit 0 = clean; 1 = a file failed; 2 = the gate itself could not run.
"""
import os
import sys

try:
    import yaml
except ImportError:  # fail closed — the gate must never pass by accident
    print("check-frontmatter: PyYAML is required (pip install pyyaml)")
    sys.exit(2)

SKIP_DIRS = {".git", "docs", ".claude", ".mcpb-cache", "__pycache__", "node_modules"}
EXCLUDE_FILES = {"README.md", "CLAUDE.md", "CONNECTORS.md"}


class StrictLoader(yaml.SafeLoader):
    """SafeLoader that rejects duplicate mapping keys (js-yaml behaviour)."""


def _construct_mapping(loader, node, deep=False):
    seen = set()
    for key_node, _ in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in seen:
            raise yaml.constructor.ConstructorError(
                "while constructing a mapping", node.start_mark,
                f"found duplicate key {key!r}", key_node.start_mark)
        seen.add(key)
    return yaml.SafeLoader.construct_mapping(loader, node, deep)


StrictLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _construct_mapping)


def is_required(rel):
    parts = rel.split(os.sep)
    if len(parts) == 2 and parts[0] == "agents" and parts[1].endswith(".md"):
        return True
    if len(parts) == 3 and parts[0] == "skills" and parts[2] == "SKILL.md":
        return True
    return False


root = sys.argv[1] if len(sys.argv) > 1 else "."
candidates = []
for dirpath, dirnames, filenames in os.walk(root):
    dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
    for name in sorted(filenames):
        if name.endswith(".md") and name not in EXCLUDE_FILES:
            candidates.append(os.path.join(dirpath, name))

required = [p for p in candidates if is_required(os.path.relpath(p, root))]
if not required:
    print(f"check-frontmatter: no agent or skill files under {root}")
    sys.exit(2)

errors = []
checked = 0
for path in candidates:
    rel = os.path.relpath(path, root)
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    opens_with_block = bool(lines) and lines[0].strip() == "---"
    if not opens_with_block:
        if is_required(rel):
            errors.append(f"{rel}: first line is not '---' (frontmatter must open the file)")
        continue
    checked += 1
    try:
        end = lines.index("---", 1)
    except ValueError:
        errors.append(f"{rel}: frontmatter has no closing '---'")
        continue
    block = "\n".join(lines[1:end])
    try:
        data = yaml.load(block, Loader=StrictLoader)
    except yaml.YAMLError as exc:
        msg = "; ".join(s for s in (getattr(exc, "context", None), getattr(exc, "problem", None)) if s) \
            or str(exc).splitlines()[0]
        errors.append(f"{rel}: frontmatter is not valid YAML — {msg}")
        continue
    if not isinstance(data, dict):
        errors.append(f"{rel}: frontmatter is not a YAML mapping")
        continue
    if is_required(rel):
        for key in ("name", "description"):
            if not str(data.get(key) or "").strip():
                errors.append(f"{rel}: frontmatter is missing '{key}'")

if errors:
    print("check-frontmatter: FAIL")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
print(f"check-frontmatter: OK ({checked} frontmatter blocks parsed, "
      f"{len(required)} agents/skills required)")
