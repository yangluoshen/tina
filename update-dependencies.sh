#!/bin/sh
set -eu

WORKFLOW_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$WORKFLOW_ROOT/dependencies.env"

MATT_REF=${1:-$MATTPOCOCK_SKILLS_REF}
NEXT_OPENSPEC_VERSION=${2:-$OPENSPEC_VERSION}
NEXT_ARCHIFY_REF=${3:-$ARCHIFY_REF}
NEXT_SHOW_ME_REF=${4:-$SHOW_ME_REF}

case "$MATT_REF" in
  ''|-*) echo "Invalid Matt Pocock skills ref: $MATT_REF" >&2; exit 1 ;;
esac

case "$NEXT_ARCHIFY_REF" in
  ''|-*) echo "Invalid Archify ref: $NEXT_ARCHIFY_REF" >&2; exit 1 ;;
esac

case "$NEXT_SHOW_ME_REF" in
  ''|-*) echo "Invalid show-me ref: $NEXT_SHOW_ME_REF" >&2; exit 1 ;;
esac

for command in git node npm npx unzip; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command not found: $command" >&2
    exit 1
  fi
done

if [ "$NEXT_OPENSPEC_VERSION" = latest ]; then
  NEXT_OPENSPEC_VERSION=$(npm view "$OPENSPEC_PACKAGE" version)
fi

case "$NEXT_OPENSPEC_VERSION" in
  ''|*[!0-9A-Za-z.+-]*) echo "Invalid OpenSpec version: $NEXT_OPENSPEC_VERSION" >&2; exit 1 ;;
esac

UPDATE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/tina-update.XXXXXX")
trap 'rm -rf "$UPDATE_ROOT"' EXIT HUP INT TERM

MATT_CHECKOUT="$UPDATE_ROOT/mattpocock-skills"
git init -q "$MATT_CHECKOUT"
git -C "$MATT_CHECKOUT" remote add origin "$MATTPOCOCK_SKILLS_REPOSITORY"
git -C "$MATT_CHECKOUT" fetch -q --depth 1 origin "$MATT_REF"
git -C "$MATT_CHECKOUT" checkout -q --detach FETCH_HEAD
RESOLVED_MATT_REF=$(git -C "$MATT_CHECKOUT" rev-parse HEAD)

STAGED_VENDOR="$UPDATE_ROOT/vendor/mattpocock-skills"
mkdir -p \
  "$STAGED_VENDOR/skills/research" \
  "$STAGED_VENDOR/skills/grill-with-docs" \
  "$STAGED_VENDOR/skills/grilling" \
  "$STAGED_VENDOR/skills/domain-modeling" \
  "$STAGED_VENDOR/skills/handoff"

cp "$MATT_CHECKOUT/LICENSE" "$STAGED_VENDOR/LICENSE"
cp "$MATT_CHECKOUT/skills/engineering/research/SKILL.md" "$STAGED_VENDOR/skills/research/SKILL.md"
cp "$MATT_CHECKOUT/skills/engineering/grill-with-docs/SKILL.md" "$STAGED_VENDOR/skills/grill-with-docs/SKILL.md"
cp "$MATT_CHECKOUT/skills/productivity/grilling/SKILL.md" "$STAGED_VENDOR/skills/grilling/SKILL.md"
cp "$MATT_CHECKOUT/skills/productivity/handoff/SKILL.md" "$STAGED_VENDOR/skills/handoff/SKILL.md"
cp "$MATT_CHECKOUT/skills/engineering/domain-modeling/SKILL.md" "$STAGED_VENDOR/skills/domain-modeling/SKILL.md"
cp "$MATT_CHECKOUT/skills/engineering/domain-modeling/CONTEXT-FORMAT.md" "$STAGED_VENDOR/skills/domain-modeling/CONTEXT-FORMAT.md"
cp "$MATT_CHECKOUT/skills/engineering/domain-modeling/ADR-FORMAT.md" "$STAGED_VENDOR/skills/domain-modeling/ADR-FORMAT.md"

for skill in research grill-with-docs grilling domain-modeling handoff; do
  grep -q "^name: $skill$" "$STAGED_VENDOR/skills/$skill/SKILL.md"
done

ARCHIFY_CHECKOUT="$UPDATE_ROOT/archify"
git init -q "$ARCHIFY_CHECKOUT"
git -C "$ARCHIFY_CHECKOUT" remote add origin "$ARCHIFY_REPOSITORY"
git -C "$ARCHIFY_CHECKOUT" fetch -q --depth 1 origin "$NEXT_ARCHIFY_REF"
git -C "$ARCHIFY_CHECKOUT" checkout -q --detach FETCH_HEAD
RESOLVED_ARCHIFY_REF=$(git -C "$ARCHIFY_CHECKOUT" rev-parse HEAD)

ARCHIFY_RELEASE="$UPDATE_ROOT/archify-release"
mkdir -p "$ARCHIFY_RELEASE"
unzip -q "$ARCHIFY_CHECKOUT/archify.zip" -d "$ARCHIFY_RELEASE"
STAGED_ARCHIFY="$ARCHIFY_RELEASE/archify"
grep -q '^name: archify$' "$STAGED_ARCHIFY/SKILL.md"
test -f "$STAGED_ARCHIFY/LICENSE"
test -f "$STAGED_ARCHIFY/THIRD_PARTY_NOTICES.md"
node "$STAGED_ARCHIFY/bin/archify.mjs" doctor >/dev/null
node "$STAGED_ARCHIFY/bin/archify.mjs" validate architecture \
  "$STAGED_ARCHIFY/examples/web-app.architecture.json" \
  --quality showcase --json | grep -q '"ok": true'
node "$STAGED_ARCHIFY/bin/archify.mjs" deliver architecture \
  "$STAGED_ARCHIFY/examples/web-app.architecture.json" \
  "$UPDATE_ROOT/archify-smoke.html" --quality showcase --json | grep -q '"ok": true'

SHOW_ME_CHECKOUT="$UPDATE_ROOT/show-me"
git init -q "$SHOW_ME_CHECKOUT"
git -C "$SHOW_ME_CHECKOUT" remote add origin "$SHOW_ME_REPOSITORY"
git -C "$SHOW_ME_CHECKOUT" fetch -q --depth 1 origin "$NEXT_SHOW_ME_REF"
git -C "$SHOW_ME_CHECKOUT" checkout -q --detach FETCH_HEAD
RESOLVED_SHOW_ME_REF=$(git -C "$SHOW_ME_CHECKOUT" rev-parse HEAD)

STAGED_SHOW_ME="$UPDATE_ROOT/vendor/show-me"
cp -R "$SHOW_ME_CHECKOUT/plugins/show-me/skills/show-me" "$STAGED_SHOW_ME"
cp "$SHOW_ME_CHECKOUT/LICENSE" "$STAGED_SHOW_ME/LICENSE"
grep -q '^name: show-me$' "$STAGED_SHOW_ME/SKILL.md"

OPENSPEC_CHECK="$UPDATE_ROOT/openspec-check"
mkdir -p "$OPENSPEC_CHECK/openspec/schemas"
cp -R "$WORKFLOW_ROOT/schema/tina" "$OPENSPEC_CHECK/openspec/schemas/tina"
printf 'schema: tina\n' > "$OPENSPEC_CHECK/openspec/config.yaml"

(
  cd "$OPENSPEC_CHECK"
  npx --yes "$OPENSPEC_PACKAGE@$NEXT_OPENSPEC_VERSION" schema validate tina --verbose >/dev/null
  npx --yes "$OPENSPEC_PACKAGE@$NEXT_OPENSPEC_VERSION" new change dependency-smoke --schema tina >/dev/null
  npx --yes "$OPENSPEC_PACKAGE@$NEXT_OPENSPEC_VERSION" status --change dependency-smoke --json | grep -q '"schemaName": "tina"'
  npx --yes "$OPENSPEC_PACKAGE@$NEXT_OPENSPEC_VERSION" instructions proposal --change dependency-smoke --json | grep -q 'Domain Alignment'
)

cp "$STAGED_VENDOR/LICENSE" "$WORKFLOW_ROOT/vendor/mattpocock-skills/LICENSE"
for skill in research grill-with-docs grilling handoff; do
  cp "$STAGED_VENDOR/skills/$skill/SKILL.md" "$WORKFLOW_ROOT/vendor/mattpocock-skills/skills/$skill/SKILL.md"
done
for file in SKILL.md CONTEXT-FORMAT.md ADR-FORMAT.md; do
  cp "$STAGED_VENDOR/skills/domain-modeling/$file" "$WORKFLOW_ROOT/vendor/mattpocock-skills/skills/domain-modeling/$file"
done

rm -rf "$WORKFLOW_ROOT/vendor/archify"
cp -R "$STAGED_ARCHIFY" "$WORKFLOW_ROOT/vendor/archify"

rm -rf "$WORKFLOW_ROOT/vendor/show-me"
cp -R "$STAGED_SHOW_ME" "$WORKFLOW_ROOT/vendor/show-me"

PINS_TMP=$(mktemp "${TMPDIR:-/tmp}/tina-dependencies.XXXXXX")
trap 'rm -rf "$UPDATE_ROOT"; rm -f "$PINS_TMP"' EXIT HUP INT TERM
printf '%s\n' \
  "MATTPOCOCK_SKILLS_REPOSITORY=$MATTPOCOCK_SKILLS_REPOSITORY" \
  "MATTPOCOCK_SKILLS_REF=$RESOLVED_MATT_REF" \
  "ARCHIFY_REPOSITORY=$ARCHIFY_REPOSITORY" \
  "ARCHIFY_REF=$RESOLVED_ARCHIFY_REF" \
  "SHOW_ME_REPOSITORY=$SHOW_ME_REPOSITORY" \
  "SHOW_ME_REF=$RESOLVED_SHOW_ME_REF" \
  "OPENSPEC_PACKAGE=$OPENSPEC_PACKAGE" \
  "OPENSPEC_VERSION=$NEXT_OPENSPEC_VERSION" > "$PINS_TMP"
mv "$PINS_TMP" "$WORKFLOW_ROOT/dependencies.env"

echo "Dependencies updated:"
echo "  mattpocock-skills $RESOLVED_MATT_REF"
echo "  archify $RESOLVED_ARCHIFY_REF"
echo "  show-me $RESOLVED_SHOW_ME_REF"
echo "  OpenSpec $NEXT_OPENSPEC_VERSION (validated; global installation unchanged)"
