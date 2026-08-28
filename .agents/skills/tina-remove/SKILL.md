---
name: tina-remove
description: Remove Tina Workflow from a user-selected target repository without deleting project data or unrelated OpenSpec content. Use when the user asks to uninstall, remove, or detach Tina Workflow from another repository.
---

# Tina Remove

Remove only content installed and managed by this bundle. The request authorizes
changes only inside the selected target repository; it does not authorize
deleting project artifacts created while using the workflow.

## Resolve and inspect

1. Resolve the bundle root containing this skill, `install.sh`, `skills/`,
   `vendor/mattpocock-skills/`, `schema/tina`, and `templates/AGENTS.md`.
2. Require an explicit target path and resolve it to an absolute path. If it is
   missing, ambiguous, or equals the bundle root, stop and ask the user.
3. Inspect the target read-only. Record `git status --short` when it is a Git
   worktree so existing changes are not attributed to removal.
4. Reject symlinked managed paths. Do not follow a symlink to inspect, edit, or
   remove its target.

Build a removal plan from `install.sh`, not from a duplicated hard-coded file
list. Classify each installed directory with `diff -qr` against its bundle
source as absent, canonical, or modified.

Also inspect:

- the Tina block between `<!-- tina-workflow:start -->` and
  `<!-- tina-workflow:end -->` in the target `AGENTS.md`;
- the active `openspec/config.yaml` or `openspec/config.yml` and its top-level
  `schema` value;
- whether both config filenames exist;
- which generic vendored skills from `install.sh` are present.

Preserve `.agents/skills/openspec-*`, `openspec/changes`, `openspec/specs`,
`CONTEXT.md`, `CONTEXT-MAP.md`, ADRs, generated change artifacts, and all other
project files. They are not Tina-owned installation files.

## Resolve choices before removal

Show the exact plan before changing the target. Ask only for choices that
cannot be recovered from the target or its version history:

- If the active schema is `tina`, determine the previous default from clear
  repository history when possible. Otherwise ask whether to use another
  installed schema or remove the top-level `schema` key. Do not remove
  `openspec/schemas/tina` while the config still selects it.
- Generic vendored skills may predate Tina or serve other workflows. Preserve
  them by default; remove an exact canonical copy only when the user explicitly
  includes shared dependencies in the removal scope.
- For a modified Tina skill, schema, or managed `AGENTS.md` block, show the
  focused diff and ask whether to preserve it, move it to a backup, or abort.
  Never discard modified content.
- For malformed or repeated Tina markers, ask how to identify the intended
  block. Never guess the deletion range.
- If both OpenSpec config filenames exist or schema history is ambiguous, ask
  which file and fallback schema are authoritative.

If no Tina-managed content exists, report that the target is already clean and
make no changes.

## Remove the approved scope

Apply the approved plan in this order:

1. Update the active config's top-level `schema` value while preserving every
   unrelated line, comment, and setting.
2. Remove exactly one canonical Tina block from `AGENTS.md`, preserving all
   text outside the markers. Leave an empty `AGENTS.md` in place unless its
   provenance proves Tina created it and the user approved deleting it.
3. Remove canonical Tina skill directories and `openspec/schemas/tina` using
   explicit resolved paths. Do not use globs or broad recursive targets.
4. Remove approved canonical generic skill directories. Preserve OpenSpec's
   generated skills and CLI installation.
5. Remove parent directories only with `rmdir`, so non-empty project
   directories survive.

Canonical content is reproducible from the bundle. For approved removal of any
modified content, move it into one unique backup directory at the target root,
preserving its relative path; do not delete it. Stop on the first failed move,
edit, or removal and report the remaining plan without continuing.

## Verify and report

Confirm that the config no longer selects `tina`, the managed block is absent,
and every approved directory is absent. If OpenSpec remains configured, run a
read-only schema resolution command for its selected schema when available.
Review the focused Git diff without altering pre-existing changes.

Report removed paths, preserved project and OpenSpec content, backup paths,
the resulting default schema, and anything the user chose to keep. Do not
commit the target repository or uninstall OpenSpec globally.
