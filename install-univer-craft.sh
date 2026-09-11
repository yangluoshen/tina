#!/bin/sh
set -eu

UNIVER_CRAFT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=${1:-.}

# Preflight both extensions before the Tina installer changes the target.
for skill in univer-craft univer-craft-yolo; do
  source_dir="$UNIVER_CRAFT_ROOT/skills/$skill"
  destination_dir="$TARGET/.agents/skills/$skill"
  if [ -L "$destination_dir" ]; then
    echo "Refusing to overwrite symlink: $destination_dir" >&2
    exit 1
  fi
  if [ -e "$destination_dir" ]; then
    if [ ! -d "$destination_dir" ] || ! diff -qr "$source_dir" "$destination_dir" >/dev/null 2>&1; then
      echo "Refusing to overwrite existing directory: $destination_dir" >&2
      if [ -d "$destination_dir" ]; then
        diff -ru "$destination_dir" "$source_dir" >&2 || true
      fi
      exit 1
    fi
  fi
done

"$UNIVER_CRAFT_ROOT/install.sh" "$TARGET"

for skill in univer-craft univer-craft-yolo; do
  destination_dir="$TARGET/.agents/skills/$skill"
  if [ ! -e "$destination_dir" ]; then
    cp -R "$UNIVER_CRAFT_ROOT/skills/$skill" "$destination_dir"
  fi
done

echo "Univer Craft installed in $TARGET"
