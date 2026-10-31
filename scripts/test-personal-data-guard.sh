#!/usr/bin/env bash
# Regression battery for the personal-data guard (scripts/block-personal-data-writes.sh
# + scripts/personal_data_detect.py). Every case here is a real evasion or a real false
# positive found in review — run it after ANY change to the detectors.
#
#   bash scripts/test-personal-data-guard.sh
#
# NOTE ON THE FIXTURES. The leak-shaped values below are ASSEMBLED AT RUNTIME from
# fragments, so no literal personal-data pattern appears in this file. That is deliberate:
# an earlier version spelled them out and had to be exempted from every detector, which
# made this file a dumping ground that was also shipped inside the .plugin. A test for the
# guard must not be a hole in it. Keep the assembly if you add cases.

set -uo pipefail
R="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
H="$R/scripts/block-personal-data-writes.sh"
pass=0; fail=0

t() { # name, payload, expected_exit
  printf '%s' "$2" | bash "$H" >/dev/null 2>&1
  rc=$?
  if [ "$rc" = "$3" ]; then printf '  ✓ %-44s exit=%s\n' "$1" "$rc"; pass=$((pass+1))
  else printf '  ✗ %-44s exit=%s want=%s\n' "$1" "$rc" "$3"; fail=$((fail+1)); fi
}

U="/U""sers"                       # home-path prefix
OTHER="$U/someoneelse/Docs/out"    # a path that is not this machine's
MINE="$HOME/Docs/out"              # a path under THIS user's home — the ones that matter
NID="3465ef1aa634""80a283cfdf847cb47404"                 # bare 32-hex tracker id
DID="1a2b3c4d-5e6f-7a8b-9c0d""-1e2f3a4b5c6d"             # dashed, the form Notion URLs use
UID_UC="1A2B3C4D5E6F7A8B""9C0D1E2F3A4B5C6D"              # uppercase hex
MAIL="someone@""place.tld"
NEARMISS="$U/yousef/Documents/out" # username starting with a placeholder word

echo "MUST BLOCK (exit 2):"
t "value + {{placeholder}} same line"    "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$R/references/_t.md\",\"content\":\"out: $OTHER, tpl: {{CV_TEMPLATE}}\"}}" 2
t "value + example.com same line"        "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$R/references/_t.md\",\"content\":\"id $NID # see example.com\"}}" 2
t "value + guard-script name on line"    "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$R/references/_t.md\",\"content\":\"$OTHER # built by build-plugin.sh\"}}" 2
t "dashed UUID tracker id"               "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$R/references/_t.md\",\"content\":\"database_id: $DID\"}}" 2
t "uppercase hex tracker id"             "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$R/references/_t.md\",\"content\":\"database_id: $UID_UC\"}}" 2
t "username starting with placeholder"   "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$R/references/_t.md\",\"content\":\"path: $NEARMISS/\"}}" 2
t "NotebookEdit new_source"              "{\"tool_name\":\"NotebookEdit\",\"tool_input\":{\"notebook_path\":\"$R/x.ipynb\",\"new_source\":\"p='$OTHER/'\"}}" 2
t "MultiEdit edits[].new_string"         "{\"tool_name\":\"MultiEdit\",\"tool_input\":{\"file_path\":\"$R/CLAUDE.md\",\"edits\":[{\"new_string\":\"$OTHER/\"}]}}" 2
t "MCP filesystem write_file"            "{\"tool_name\":\"mcp__filesystem__write_file\",\"tool_input\":{\"path\":\"$R/references/_t.md\",\"content\":\"$OTHER/\"}}" 2
t "Desktop Commander write_file"         "{\"tool_name\":\"mcp__Desktop_Commander__write_file\",\"tool_input\":{\"path\":\"$R/references/_t.md\",\"content\":\"$NID\"}}" 2
t "Bash heredoc into repo"               "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"cat > references/x.md <<EOF\nid: $NID\nEOF\"}}" 2
t "Bash echo redirect into repo"         "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"echo '$OTHER/' > references/x.md\"}}" 2
t "Bash leak under THIS user's HOME"     "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"echo '$MINE/' > references/x.md\"}}" 2
t "git prefix then a write"              "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"git status; echo '$OTHER/' > skills/x.md\"}}" 2
t "Bash cp of an update-prompt file"     "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"cp /tmp/a.md ./update-prompt-x.md\"}}" 2
t "stray update-prompt filename"         "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$R/update-prompt-x.md\",\"content\":\"harmless\"}}" 2
t "leak in a nested subdirectory"        "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$R/skills/career-coach/_t.md\",\"content\":\"$OTHER/\"}}" 2
t "leak into the test file itself"       "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$R/scripts/test-personal-data-guard.sh\",\"content\":\"$MAIL and $OTHER/\"}}" 2
# M1: the TARGET decides, not the session. Same write, three different cwds — all must block.
t "into repo, cwd=/tmp"                  "{\"tool_name\":\"Bash\",\"cwd\":\"/tmp\",\"tool_input\":{\"command\":\"echo '$OTHER/' > $R/skills/x.md\"}}" 2
t "into repo, cwd=\$HOME"                "{\"tool_name\":\"Bash\",\"cwd\":\"$HOME\",\"tool_input\":{\"command\":\"echo '$OTHER/' > $R/skills/x.md\"}}" 2
t "cp into repo from outside"            "{\"tool_name\":\"Bash\",\"cwd\":\"$HOME\",\"tool_input\":{\"command\":\"cp $MINE/notes.md $R/references/x.md\"}}" 2
# KNOWN LIMIT, asserted so it stays visible: `cp /tmp/opaque.md <repo>/x.md` is ALLOWED —
# the hook sees the command, never the source file's contents. Layers 2 and 3 catch it.
t "cp of an opaque file (known limit)"   "{\"tool_name\":\"Bash\",\"cwd\":\"$HOME\",\"tool_input\":{\"command\":\"cp /tmp/opaque.md $R/references/x.md\"}}" 0
# M3: >| is a clobber redirect and was skipped entirely by the write-detector.
t "clobber redirect >| into repo"        "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"echo '$OTHER/' >| skills/x.md\"}}" 2
# P1: writers that name their target positionally, from a cwd outside the repo.
t "tee into repo, cwd=/tmp"              "{\"tool_name\":\"Bash\",\"cwd\":\"/tmp\",\"tool_input\":{\"command\":\"echo '$OTHER/' | tee $R/skills/x.md\"}}" 2
t "dd of= into repo, cwd=/tmp"           "{\"tool_name\":\"Bash\",\"cwd\":\"/tmp\",\"tool_input\":{\"command\":\"dd of=$R/skills/x.md <<EOF\n$OTHER/\nEOF\"}}" 2
t "python open() into repo, cwd=/tmp"    "{\"tool_name\":\"Bash\",\"cwd\":\"/tmp\",\"tool_input\":{\"command\":\"python3 -c \\\"open('$R/skills/x.md','w').write('$OTHER/')\\\"\"}}" 2
t "sed -i into repo, cwd=/tmp"           "{\"tool_name\":\"Bash\",\"cwd\":\"/tmp\",\"tool_input\":{\"command\":\"sed -i '' 's|A|$OTHER/|' $R/skills/x.md\"}}" 2
t "perl -pi into repo, cwd=/tmp"         "{\"tool_name\":\"Bash\",\"cwd\":\"/tmp\",\"tool_input\":{\"command\":\"perl -pi -e 's|A|$OTHER/|' $R/skills/x.md\"}}" 2
# P2: a benign parseable write must not suppress the fallback for an unparseable one.
t "benign redirect + sed -i into repo"   "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"echo ok > /tmp/log.txt && sed -i '' 's|A|$OTHER/|' skills/x.md\"}}" 2
t "benign redirect + open() into repo"   "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"echo ok > /tmp/log.txt; python3 -c \\\"open('skills/x.md','w').write('$OTHER/')\\\"\"}}" 2

echo "MUST ALLOW (exit 0):"
t "cd into repo then write"              "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"cd $R && echo hi > notes.md\"}}" 0
t "write that LEAVES the repo"           "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"echo '$MAIL' > /tmp/report.md\"}}" 0
t "placeholders + example.com only"      "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$R/CLAUDE.md\",\"new_string\":\"Use \\\${CAREER_DATA} and {{USER_FIRST_NAME}}; mail user@example.com\"}}" 0
t "documented placeholder home path"     "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$R/CLAUDE.md\",\"new_string\":\"e.g. $U/<name>/Documents/out\"}}" 0
t "same leak OUTSIDE the repo"           "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"/tmp/o/update-prompt-x.md\",\"content\":\"$OTHER/\"}}" 0
t "read-only bash"                       "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"grep -rn foo skills/\"}}" 0
t "prose containing the word install"    "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"git commit -m 'the uvx install line contradicted the table'\"}}" 0
t "git commit quoting an address"        "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"git commit -m 'author was $MAIL'\"}}" 0
t "chained git add/commit/push"          "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"git add -A && git -c user.email='$MAIL' commit -q -m 'msg' && git push -q origin main\"}}" 0
t "bash printing an arrow"               "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"echo 'a -> b'\"}}" 0
t "grep for the prompt filename"         "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"grep -rn 'update-prompt-' skills/\"}}" 0
t "guard script edits itself"            "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$R/scripts/personal_data_detect.py\",\"new_string\":\"r'($U/|/home/)[A-Za-z0-9._-]+/'\"}}" 0
t "session scratch UUID path"            "{\"tool_name\":\"Bash\",\"cwd\":\"$R\",\"tool_input\":{\"command\":\"echo hi > /private/tmp/claude-503/0f4e55e3-8a25-4708-92c8-c58efc9bd67a/scratchpad/n.md\"}}" 0
OP="$(mktemp -d)"; mkdir -p "$OP/.claude-plugin" "$OP/skills/x"; echo '{"name":"unrelated-plugin"}' > "$OP/.claude-plugin/plugin.json"
t "unrelated plugin's skills dir + tracker id" "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$OP/skills/x/SKILL.md\",\"content\":\"db $NID\"}}" 0
t "malformed payload (fail open)"        "not json" 0
t "empty payload (fail open)"            "" 0

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
