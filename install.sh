#!/usr/bin/env bash
# Installs (or updates / uninstalls) My Dev Team into a local Agentforce project folder.
#
#   ./install.sh <target-project-dir>              install or update
#   ./install.sh <target-project-dir> --uninstall  remove
#
# Copies the six agents into <target>/.claude/agents/, templates into
# <target>/.claude/my-dev-team/templates/, and adds a managed routing block to
# <target>/CLAUDE.md. Locally modified agent files are backed up before update.
# Never touches INCIDENTS.md, DECISIONS.md, PRDs, or source.
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <target-project-dir> [--uninstall]" >&2
  exit 2
fi

SOURCE="$(cd "$(dirname "$0")" && pwd)"
[ -d "$1" ] || { echo "Target folder not found: $1" >&2; exit 1; }
TARGET="$(cd "$1" && pwd)"
MODE="${2:-install}"
[ "$TARGET" != "$SOURCE" ] || { echo "Target must be a project folder, not the My-Agentforce-Dev-Team repo itself." >&2; exit 1; }

AGENTS="orchestrator architect builder qa shipper sentinel"
AGENTS_DIR="$TARGET/.claude/agents"
TEAM_DIR="$TARGET/.claude/my-dev-team"
CLAUDE_MD="$TARGET/CLAUDE.md"
BEGIN_MARKER='<!-- BEGIN MY-DEV-TEAM'
END_MARKER='<!-- END MY-DEV-TEAM -->'

# Print CLAUDE.md without the managed block, trailing blank lines trimmed.
strip_block() {
  awk -v b="$BEGIN_MARKER" -v e="$END_MARKER" '
    index($0, b) == 1 { skip = 1; next }
    skip && index($0, e) == 1 { skip = 0; next }
    !skip { lines[++n] = $0 }
    END { while (n > 0 && lines[n] ~ /^[[:space:]]*$/) n--; for (i = 1; i <= n; i++) print lines[i] }
  ' "$1"
}

if [ "$MODE" = "--uninstall" ]; then
  for a in $AGENTS; do
    if [ -f "$AGENTS_DIR/$a.md" ]; then rm "$AGENTS_DIR/$a.md"; echo "removed  .claude/agents/$a.md"; fi
  done
  if [ -d "$TEAM_DIR" ]; then rm -rf "$TEAM_DIR"; echo "removed  .claude/my-dev-team/"; fi
  if [ -f "$CLAUDE_MD" ] && grep -qF "$BEGIN_MARKER" "$CLAUDE_MD"; then
    rest="$(strip_block "$CLAUDE_MD")"
    if [ -n "$(printf '%s' "$rest" | tr -d '[:space:]')" ]; then printf '%s\n' "$rest" > "$CLAUDE_MD"; else rm "$CLAUDE_MD"; fi
    echo "removed  My Dev Team block from CLAUDE.md"
  fi
  echo
  echo "My Dev Team uninstalled from $TARGET. Project logs (INCIDENTS.md, DECISIONS.md, SOLUTION-BLUEPRINT.md, PRDs) were left in place."
  exit 0
fi
[ "$MODE" = "install" ] || { echo "unknown option: $MODE" >&2; exit 2; }

mkdir -p "$AGENTS_DIR" "$TEAM_DIR/templates"
STAMP="$(date +%Y%m%d-%H%M%S)"

for a in $AGENTS; do
  src="$SOURCE/agents/$a.md"; dst="$AGENTS_DIR/$a.md"
  if [ -f "$dst" ]; then
    if cmp -s "$src" "$dst"; then echo "same     .claude/agents/$a.md"; continue; fi
    cp "$dst" "$dst.bak-$STAMP"
    echo "backup   .claude/agents/$a.md -> $a.md.bak-$STAMP"
  fi
  cp "$src" "$dst"
  echo "install  .claude/agents/$a.md"
done

cp -R "$SOURCE/templates/." "$TEAM_DIR/templates/"
echo "install  .claude/my-dev-team/templates/"

VERSION="$(git -C "$SOURCE" rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "My-Agentforce-Dev-Team $VERSION installed $(date +%Y-%m-%dT%H:%M:%S)" > "$TEAM_DIR/VERSION"

SNIPPET="$SOURCE/templates/CLAUDE.md.snippet"
if [ -f "$CLAUDE_MD" ]; then
  if grep -qF "$BEGIN_MARKER" "$CLAUDE_MD"; then echo "update   CLAUDE.md (My Dev Team block)"; else echo "append   CLAUDE.md (My Dev Team block)"; fi
  rest="$(strip_block "$CLAUDE_MD")"
  if [ -n "$(printf '%s' "$rest" | tr -d '[:space:]')" ]; then
    { printf '%s\n\n' "$rest"; cat "$SNIPPET"; } > "$CLAUDE_MD.tmp"
  else
    cat "$SNIPPET" > "$CLAUDE_MD.tmp"
  fi
  mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
else
  cat "$SNIPPET" > "$CLAUDE_MD"
  echo "create   CLAUDE.md"
fi

cat <<EOF

My Dev Team ($VERSION) installed into $TARGET

Before first use, install these Claude Code plugins/skills (see README):
  - salesforce-development, salesforce-code-quality, experience-lwc  (forcedotcom/sf-skills)
  - agentforce-adlc                                                  (SalesforceAIResearch/agentforce-adlc)
  - phase skills: salesforce-design, salesforce-develop, salesforce-test,
                  salesforce-release, salesforce-observe, salesforce-document

Then open Claude Code in that folder and say:  My Dev Team, build <what you need>
EOF
