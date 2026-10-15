#!/usr/bin/env bash
# build-plugin.sh — build career-engine.plugin, then refuse to ship it if it carries
# personal data.
#
# This replaced a hand-copied python snippet that lived in two files. A snippet you paste
# is a snippet you can paste incompletely: the copy in skills/plugin-builder/SKILL.md was
# missing the `update-prompt-*.md` exclusion entirely, so a build run from those
# instructions would have zipped personal files into the shipped artifact — which is very
# likely how eight builds in June 2026 did exactly that. One command, always the same,
# always verified.
#
# Usage: bash scripts/build-plugin.sh

set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

# ── 1. Pre-build gate ────────────────────────────────────────────────────────
if ! bash "$REPO/scripts/scan-personal-data.sh"; then
  echo ""
  echo "❌ Build aborted — personal data is present in the working tree."
  echo "   Fix it before building; a build made now would ship it."
  exit 1
fi
# Frontmatter must parse as YAML — the Desktop installer refuses the whole plugin
# otherwise (2026-10-15: career-coach.md shipped with unescaped inner quotes).
FM_RC=0; python3 "$REPO/scripts/check-frontmatter.py" "$REPO" || FM_RC=$?
if [ "$FM_RC" -eq 2 ]; then
  echo ""
  echo "❌ Build aborted — the frontmatter gate could not run (PyYAML is a maintainer dependency: pip install pyyaml)."
  exit 1
elif [ "$FM_RC" -ne 0 ]; then
  echo ""
  echo "❌ Build aborted — a shipped .md has frontmatter that is not valid YAML."
  echo "   The installer rejects the whole plugin on one bad file."
  exit 1
fi

# ── 2. Build ─────────────────────────────────────────────────────────────────
python3 - <<'PY'
import zipfile, os, fnmatch
exclude = {'.git', 'docs', '.mcpb-cache', '.claude', '__pycache__', '.DS_Store', '.in_use', 'session.jsonl'}
count = 0
with zipfile.ZipFile('career-engine.plugin', 'w', zipfile.ZIP_STORED) as zf:
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in exclude]
        for file in files:
            if file in exclude or file.endswith('.plugin'):
                continue
            if fnmatch.fnmatch(file, 'update-prompt-*.md'):
                continue
            # Test harnesses are not part of the product, and the guard battery
            # in particular must never ship (it exercises leak-shaped inputs).
            if fnmatch.fnmatch(file, 'test-*') or fnmatch.fnmatch(file, 'test_*'):
                continue
            zf.write(os.path.join(root, file), os.path.join(root, file)[2:])
            count += 1
print(f"Built career-engine.plugin — {count} files.")
PY

# ── 3. Post-build gate: inspect the artifact itself, not the source ──────────
# A clean source tree can still produce a dirty artifact (a stale zip, a bad filter, a
# file added between scan and build). This checks what actually ships, using the same
# detection module as the block hook and the pre-commit scan.
python3 - "$REPO" <<'PY'
import io, os, re, sys, zipfile
sys.path.insert(0, os.path.join(sys.argv[1], "scripts"))
import personal_data_detect as pdd

# Office files are ZIPs of XML. The 2026-07-09 leak was real institution names inside a
# .dotx's document.xml, so skipping them here would skip the exact file type that last
# shipped personal data.
OOXML = (".dotx", ".dotm", ".docx", ".xlsx", ".pptx")
BINARY = (".png", ".jpg", ".jpeg", ".gif", ".pdf", ".ico", ".woff", ".woff2", ".pyc")


def ooxml_text(blob):
    out = []
    try:
        inner = zipfile.ZipFile(io.BytesIO(blob))
    except Exception:
        return ""
    for n in inner.namelist():
        if not n.endswith(".xml"):
            continue
        try:
            x = inner.read(n).decode("utf-8", "ignore")
        except Exception:
            continue
        out.append(re.sub(r"<[^>]+>", " ", x))   # strip tags, keep the visible text
    return "\n".join(out)


hits = []
z = zipfile.ZipFile("career-engine.plugin")
for name in z.namelist():
    if name.endswith("/"):
        continue
    if pdd.is_stray_output_file(name.rsplit("/", 1)[-1]):
        hits.append(f"[stray-output-file] {name}")
        continue
    if name.endswith(BINARY):
        continue
    blob = z.read(name)
    if name.endswith(OOXML):
        text, label = ooxml_text(blob), f"{name} (inside the Office XML)"
    else:
        try:
            text, label = blob.decode("utf-8"), name
        except UnicodeDecodeError:
            continue
    for lineno, det, match, why in pdd.scan_text(text, name, max_hits=3):
        hits.append(f"[{det}] {label}: …{match}…")

if hits:
    print("\n❌ SHIPPING BLOCKED — personal data found inside career-engine.plugin:\n")
    for h in dict.fromkeys(hits):
        print("  " + h)
    print("\nThe built artifact is committed to a public repo and downloaded by users.")
    print("Do not commit this build. Fix the source, then rebuild.")
    sys.exit(1)

print("✓ Artifact verified — no personal data in the shipped build (Office files included).")
PY
