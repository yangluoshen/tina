#!/bin/sh
set -eu

WORKFLOW_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$WORKFLOW_ROOT/dependencies.env"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/tina-workflow.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

mkdir "$TEST_ROOT/project"
"$WORKFLOW_ROOT/install.sh" "$TEST_ROOT/project" >/dev/null
"$WORKFLOW_ROOT/install.sh" "$TEST_ROOT/project" >/dev/null

PROJECT="$TEST_ROOT/project"
test "$(grep -Fc '<!-- tina-workflow:start -->' "$PROJECT/AGENTS.md")" -eq 1
grep -q '^# Tina Workflow$' "$PROJECT/AGENTS.md"
if grep -q '^# Repository Instructions$' "$PROJECT/AGENTS.md"; then
  echo "Repository Instructions leaked into the target project" >&2
  exit 1
fi
grep -q '^schema: tina$' "$PROJECT/openspec/config.yaml"
test -f "$PROJECT/.agents/skills/tina-propose/SKILL.md"
test -f "$PROJECT/.agents/skills/domain-modeling/CONTEXT-FORMAT.md"
test -n "$MATTPOCOCK_SKILLS_REF"
test -n "$OPENSPEC_VERSION"

(
  cd "$PROJECT"
  openspec schema validate tina --verbose >/dev/null
  openspec new change smoke --schema tina >/dev/null
  openspec status --change smoke --json | grep -q '"schemaName": "tina"'
  openspec instructions proposal --change smoke --json | grep -q 'Domain Alignment'
)

printf '\nlocal edit\n' >> "$PROJECT/.agents/skills/tina-propose/SKILL.md"
if "$WORKFLOW_ROOT/install.sh" "$PROJECT" >/dev/null 2>&1; then
  echo "Installer overwrote a conflicting skill" >&2
  exit 1
fi

echo "Smoke test passed"
