#!/bin/sh
set -eu

WORKFLOW_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=${1:-.}

if [ ! -d "$TARGET" ]; then
  echo "Target directory does not exist: $TARGET" >&2
  exit 1
fi

TARGET_ROOT=$(CDPATH= cd -- "$TARGET" && pwd)

if ! command -v openspec >/dev/null 2>&1; then
  echo "OpenSpec is required. Install it, then rerun this script." >&2
  exit 1
fi

check_directory() {
  source_dir=$1
  destination_dir=$2

  if [ -e "$destination_dir" ] || [ -L "$destination_dir" ]; then
    if [ ! -d "$destination_dir" ] || ! diff -qr "$source_dir" "$destination_dir" >/dev/null 2>&1; then
      echo "Refusing to overwrite existing directory: $destination_dir" >&2
      if [ -d "$destination_dir" ]; then
        diff -ru "$destination_dir" "$source_dir" >&2 || true
      fi
      exit 1
    fi
  fi
}

copy_directory() {
  source_dir=$1
  destination_dir=$2

  if [ ! -e "$destination_dir" ]; then
    mkdir -p "$(dirname -- "$destination_dir")"
    cp -R "$source_dir" "$destination_dir"
  fi
}

for skill in coding-workflow-research coding-workflow-propose coding-workflow-verify; do
  check_directory "$WORKFLOW_ROOT/skills/$skill" "$TARGET_ROOT/.agents/skills/$skill"
done

for skill in research grill-with-docs grilling domain-modeling; do
  check_directory "$WORKFLOW_ROOT/vendor/mattpocock-skills/skills/$skill" "$TARGET_ROOT/.agents/skills/$skill"
done

check_directory "$WORKFLOW_ROOT/schema/personal-coding" "$TARGET_ROOT/openspec/schemas/personal-coding"

START_MARKER='<!-- personal-coding-workflow:start -->'
END_MARKER='<!-- personal-coding-workflow:end -->'
AGENTS_FILE="$TARGET_ROOT/AGENTS.md"

if [ -L "$AGENTS_FILE" ]; then
  echo "Refusing to edit symlink: $AGENTS_FILE" >&2
  exit 1
fi

if [ -f "$AGENTS_FILE" ]; then
  start_count=$(grep -Fc "$START_MARKER" "$AGENTS_FILE" || true)
  end_count=$(grep -Fc "$END_MARKER" "$AGENTS_FILE" || true)
  if [ "$start_count" -ne "$end_count" ] || [ "$start_count" -gt 1 ]; then
    echo "Malformed workflow markers in $AGENTS_FILE" >&2
    exit 1
  fi
  if [ "$start_count" -eq 1 ]; then
    managed_block=$(mktemp "${TMPDIR:-/tmp}/personal-coding-agents.XXXXXX")
    trap 'rm -f "$managed_block"' EXIT HUP INT TERM
    awk -v start="$START_MARKER" -v end="$END_MARKER" '
      $0 == start { inside = 1; next }
      $0 == end { inside = 0; next }
      inside { print }
    ' "$AGENTS_FILE" > "$managed_block"
    if ! cmp -s "$WORKFLOW_ROOT/templates/AGENTS.md" "$managed_block"; then
      echo "Refusing to overwrite a modified workflow block in $AGENTS_FILE" >&2
      diff -u "$managed_block" "$WORKFLOW_ROOT/templates/AGENTS.md" >&2 || true
      exit 1
    fi
    rm -f "$managed_block"
    trap - EXIT HUP INT TERM
  fi
fi

for config in "$TARGET_ROOT/openspec/config.yaml" "$TARGET_ROOT/openspec/config.yml"; do
  if [ -L "$config" ]; then
    echo "Refusing to edit symlink: $config" >&2
    exit 1
  fi
  if [ -f "$config" ]; then
    schema_count=$(grep -c '^schema[[:space:]]*:' "$config" || true)
    if [ "$schema_count" -gt 1 ]; then
      echo "Multiple top-level schema keys in $config" >&2
      exit 1
    fi
    current_schema=$(sed -n 's/^schema[[:space:]]*:[[:space:]]*//p' "$config")
    if [ -n "$current_schema" ] && [ "$current_schema" != spec-driven ] && [ "$current_schema" != personal-coding ]; then
      echo "Refusing to replace existing default schema '$current_schema' in $config" >&2
      exit 1
    fi
  fi
done

if [ -f "$TARGET_ROOT/openspec/config.yaml" ] && [ -f "$TARGET_ROOT/openspec/config.yml" ]; then
  echo "Both openspec/config.yaml and openspec/config.yml exist; keep only the active one." >&2
  exit 1
fi

(
  cd "$TARGET_ROOT"
  openspec init --tools codex
)

for skill in coding-workflow-research coding-workflow-propose coding-workflow-verify; do
  copy_directory "$WORKFLOW_ROOT/skills/$skill" "$TARGET_ROOT/.agents/skills/$skill"
done

for skill in research grill-with-docs grilling domain-modeling; do
  copy_directory "$WORKFLOW_ROOT/vendor/mattpocock-skills/skills/$skill" "$TARGET_ROOT/.agents/skills/$skill"
done

copy_directory "$WORKFLOW_ROOT/schema/personal-coding" "$TARGET_ROOT/openspec/schemas/personal-coding"

CONFIG_FILE="$TARGET_ROOT/openspec/config.yaml"
if [ -f "$TARGET_ROOT/openspec/config.yml" ]; then
  CONFIG_FILE="$TARGET_ROOT/openspec/config.yml"
fi

config_tmp=$(mktemp "${TMPDIR:-/tmp}/personal-coding-config.XXXXXX")
trap 'rm -f "$config_tmp"' EXIT HUP INT TERM
if grep -q '^schema[[:space:]]*:' "$CONFIG_FILE"; then
  awk '/^schema[[:space:]]*:/ { print "schema: personal-coding"; next } { print }' "$CONFIG_FILE" > "$config_tmp"
else
  cp "$CONFIG_FILE" "$config_tmp"
  printf '\nschema: personal-coding\n' >> "$config_tmp"
fi
mv "$config_tmp" "$CONFIG_FILE"
trap - EXIT HUP INT TERM

if [ ! -f "$AGENTS_FILE" ]; then
  : > "$AGENTS_FILE"
fi
if ! grep -Fq "$START_MARKER" "$AGENTS_FILE"; then
  if [ -s "$AGENTS_FILE" ]; then
    printf '\n' >> "$AGENTS_FILE"
  fi
  printf '%s\n' "$START_MARKER" >> "$AGENTS_FILE"
  cat "$WORKFLOW_ROOT/templates/AGENTS.md" >> "$AGENTS_FILE"
  printf '%s\n' "$END_MARKER" >> "$AGENTS_FILE"
fi

(
  cd "$TARGET_ROOT"
  openspec schema validate personal-coding --verbose
  openspec schema which personal-coding
)

echo "Personal coding workflow installed in $TARGET_ROOT"
