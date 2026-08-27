#!/bin/sh
set -eu

WORKFLOW_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$WORKFLOW_ROOT/dependencies.env"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/tina-workflow.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

PROJECT="$TEST_ROOT/missing/project"
"$WORKFLOW_ROOT/install.sh" "$PROJECT" >/dev/null
"$WORKFLOW_ROOT/install.sh" "$PROJECT" >/dev/null
test "$(grep -Fc '<!-- tina-workflow:start -->' "$PROJECT/AGENTS.md")" -eq 1
grep -q '^# Tina Workflow$' "$PROJECT/AGENTS.md"
if grep -q '^# Repository Instructions$' "$PROJECT/AGENTS.md"; then
  echo "Repository Instructions leaked into the target project" >&2
  exit 1
fi
grep -q '^schema: tina$' "$PROJECT/openspec/config.yaml"
test -f "$PROJECT/.agents/skills/tina-propose/SKILL.md"
test -f "$PROJECT/.agents/skills/tina-change-visual/SKILL.md"
test -f "$PROJECT/.agents/skills/tina-change-visual/assets/change.html"
test -f "$PROJECT/.agents/skills/domain-modeling/CONTEXT-FORMAT.md"
test -n "$MATTPOCOCK_SKILLS_REF"
test -n "$OPENSPEC_VERSION"

CHANGE_TEMPLATE="$PROJECT/.agents/skills/tina-change-visual/assets/change.html"
grep -q 'role="img"' "$CHANGE_TEMPLATE"
grep -q 'tabindex="0"' "$CHANGE_TEMPLATE"
grep -q '<title id="change-overview-title">' "$CHANGE_TEMPLATE"
grep -q '<desc id="change-overview-desc">' "$CHANGE_TEMPLATE"
if grep -Eqi '<script|<iframe|<object|<embed|(src|href)="https?://' "$CHANGE_TEMPLATE"; then
  echo "change.html template is not static and self-contained" >&2
  exit 1
fi

(
  cd "$PROJECT"
  openspec schema validate tina --verbose >/dev/null
  openspec new change smoke --schema tina >/dev/null
  openspec status --change smoke --json | grep -q '"schemaName": "tina"'
  openspec instructions proposal --change smoke --json | grep -q 'Domain Alignment'
)
grep -q 'tina-change-visual' "$PROJECT/.agents/skills/tina-propose/SKILL.md"

printf '\nlocal edit\n' >> "$PROJECT/.agents/skills/tina-propose/SKILL.md"
if "$WORKFLOW_ROOT/install.sh" "$PROJECT" >/dev/null 2>&1; then
  echo "Installer overwrote a conflicting skill" >&2
  exit 1
fi

echo "Smoke test passed"
