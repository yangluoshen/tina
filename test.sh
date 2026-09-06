#!/bin/sh
set -eu

WORKFLOW_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$WORKFLOW_ROOT/dependencies.env"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/tina-workflow.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

mkdir "$TEST_ROOT/bin" "$TEST_ROOT/cli-project"
ln -s "$WORKFLOW_ROOT/install.sh" "$TEST_ROOT/bin/tina-init"
(
  cd "$TEST_ROOT/cli-project"
  PATH="$TEST_ROOT/bin:$PATH" tina-init . >/dev/null
)
test -f "$TEST_ROOT/cli-project/openspec/config.yaml"

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
test -f "$PROJECT/.agents/skills/tina-propose-plan/SKILL.md"
test -f "$PROJECT/.agents/skills/tina-propose-run/SKILL.md"
test -f "$PROJECT/.agents/skills/tina-architecture/SKILL.md"
test -f "$PROJECT/.agents/skills/tina-apply/SKILL.md"
test -f "$PROJECT/.agents/skills/tina-change-visual/SKILL.md"
test -f "$PROJECT/.agents/skills/tina-change-visual/assets/change.html"
test -f "$PROJECT/.agents/skills/handoff/SKILL.md"
test -f "$PROJECT/.agents/skills/domain-modeling/CONTEXT-FORMAT.md"
test -f "$PROJECT/.agents/skills/archify/SKILL.md"
test -f "$PROJECT/.agents/skills/archify/THIRD_PARTY_NOTICES.md"
grep -q '^name: show-me$' "$PROJECT/.agents/skills/show-me/SKILL.md"
test -f "$PROJECT/.agents/skills/show-me/LICENSE"
diff -qr "$WORKFLOW_ROOT/vendor/show-me" "$PROJECT/.agents/skills/show-me"
node "$PROJECT/.agents/skills/archify/bin/archify.mjs" doctor >/dev/null
node "$PROJECT/.agents/skills/archify/bin/archify.mjs" validate architecture \
  "$PROJECT/.agents/skills/archify/examples/web-app.architecture.json" \
  --quality showcase --json | grep -q '"ok": true'
for agent in tina-architect tina-proposer tina-proposal-reviewer tina-implementer tina-qa tina-code-reviewer; do
  agent_file="$PROJECT/.codex/agents/$agent.toml"
  test -f "$agent_file"
  grep -q '^name = ' "$agent_file"
  grep -q '^description = ' "$agent_file"
  grep -q '^developer_instructions = ' "$agent_file"
done
test -n "$MATTPOCOCK_SKILLS_REF"
test -n "$ARCHIFY_REF"
test -n "$SHOW_ME_REF"
test -n "$OPENSPEC_VERSION"
grep -q 'tina_architect' "$PROJECT/.agents/skills/tina-architecture/SKILL.md"

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
grep -q 'tina-change-visual' "$PROJECT/.agents/skills/tina-propose-plan/SKILL.md"
grep -q 'tina-architecture' "$PROJECT/.agents/skills/tina-propose-plan/SKILL.md"

printf '\nlocal edit\n' >> "$PROJECT/.agents/skills/archify/SKILL.md"
if "$WORKFLOW_ROOT/install.sh" "$PROJECT" >/dev/null 2>&1; then
  echo "Installer overwrote a conflicting Archify skill" >&2
  exit 1
fi
cp "$WORKFLOW_ROOT/vendor/archify/SKILL.md" "$PROJECT/.agents/skills/archify/SKILL.md"

printf '\nlocal edit\n' >> "$PROJECT/.agents/skills/show-me/SKILL.md"
cp "$PROJECT/.agents/skills/show-me/SKILL.md" "$TEST_ROOT/show-me-local.md"
if "$WORKFLOW_ROOT/install.sh" "$PROJECT" >/dev/null 2>&1; then
  echo "Installer overwrote a conflicting show-me skill" >&2
  exit 1
fi
cmp "$TEST_ROOT/show-me-local.md" "$PROJECT/.agents/skills/show-me/SKILL.md"
cp "$WORKFLOW_ROOT/vendor/show-me/SKILL.md" "$PROJECT/.agents/skills/show-me/SKILL.md"

printf '\nlocal edit\n' >> "$PROJECT/.agents/skills/tina-propose-plan/SKILL.md"
if "$WORKFLOW_ROOT/install.sh" "$PROJECT" >/dev/null 2>&1; then
  echo "Installer overwrote a conflicting skill" >&2
  exit 1
fi

AGENT_PROJECT="$TEST_ROOT/agent-project"
"$WORKFLOW_ROOT/install.sh" "$AGENT_PROJECT" >/dev/null
printf '\n# local edit\n' >> "$AGENT_PROJECT/.codex/agents/tina-qa.toml"
if "$WORKFLOW_ROOT/install.sh" "$AGENT_PROJECT" >/dev/null 2>&1; then
  echo "Installer overwrote a conflicting agent" >&2
  exit 1
fi

echo "Smoke test passed"
