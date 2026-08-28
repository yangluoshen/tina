---
name: tina-sync
description: Synchronize a previously initialized target repository with the current Tina Workflow bundle while preserving target customizations. Use when the user asks to update, refresh, or propagate bundle changes to another repository.
---

# Tina Sync

Synchronize one explicit target per invocation. The request authorizes updating
Tina-managed content in that target, not overwriting target-owned changes.

## Resolve source, target, and mode

1. Resolve the bundle root containing this skill, `install.sh`,
   `dependencies.env`, `skills/`, `vendor/`, `schema/tina`, and
   `templates/AGENTS.md`.
2. Require an explicit target path. It must be a Git worktree root and must not
   equal the bundle root.
3. Record source and target revisions, status, staged diff, and unstaged diff.
   Existing changes belong to their respective repositories.
4. If the bundle is dirty, ask whether to sync its current working tree or stop
   until the bundle changes are committed. Never silently mix committed and
   uncommitted source content.
5. Require the installed OpenSpec version to equal the pin in
   `dependencies.env`. Do not change global software without authorization.

Read the target-local manifest at the path derived from:

```sh
git -C "$target" rev-parse --git-dir
```

Use `<git-dir>/tina-workflow/manifest`. Its recorded mode is authoritative.
Without a manifest, detect incognito mode from the marked block in the local
Git exclude file and `AGENTS.override.md`; detect normal mode from the managed
block in `AGENTS.md`. Ask if detection is ambiguous.

## Build the desired payload

Run the current bundle's `install.sh` in a temporary directory outside both
repositories. Use the validated result as the desired payload. Do not run the
installer directly in the target: an older valid installation intentionally
differs from the current bundle and would trigger overwrite protection.

The managed payload consists of staged skill files,
`.agents/skills/.openspec-target`, `openspec/schemas/tina`, and the Tina block
from `templates/AGENTS.md`. Preserve OpenSpec changes, specs, CONTEXT files,
ADRs, change artifacts, and unrelated target files.

Treat the OpenSpec config semantically. If it is absent, use the staged config.
If it exists, preserve every unrelated line and require exactly one active
config whose top-level default schema remains `tina`; never replace the whole
file merely because formatting differs.

## Track ownership

The local manifest exists to distinguish bundle updates from target edits. Keep
it outside the worktree and write it only after successful verification. Use a
stable, sorted, line-oriented format that records:

- format version, sync mode, source revision, and whether the source was dirty;
- each managed relative file path;
- its desired source SHA-256, installed target SHA-256, and policy;
- the Tina managed block as a virtual path, without hashing the rest of the
  target instruction file.

Use policy `managed` when installed content equals the desired bundle content.
Use `custom` when the user keeps or merges target-specific content. Never treat
a custom path as safe to replace merely because it has not changed since the
last sync.

For a legacy target without a manifest, compare every desired path and the
managed instruction block. Identical content is managed. Any difference has
unknown provenance: show the focused diff and ask once whether to preserve,
merge, or replace it. Record the resulting policy so later syncs do not repeat
that ambiguity.

## Plan changes

Compare desired source hashes, current target hashes, and the previous manifest
before writing anything:

- Update a `managed` file automatically only when its current target hash still
  equals the manifest's installed hash.
- Treat a changed or missing managed target as a local edit and ask whether to
  preserve, restore, or merge it.
- Preserve `custom` files. When their desired source changes, show the diff and
  ask whether to keep, merge, or adopt the bundle version.
- Add a new desired path only when its target path is absent. Existing differing
  content is a conflict, even when untracked.
- Remove a path no longer present in the desired payload only when it is
  `managed` and unchanged. Ask before removing custom or modified content.
- Stop on symlinks, malformed or repeated Tina markers, two OpenSpec config
  files, or a non-Tina default schema.

For the instruction file, replace only the canonical managed block and preserve
all text outside it. Normal mode uses `AGENTS.md`. Incognito mode uses
`AGENTS.override.md`; preserve its local content and warn when its copied
`AGENTS.md` snapshot is stale.

Present unresolved conflicts together so the user can make one coherent
decision. Do not ask about files already proven safe by the manifest.

## Apply and verify

Create a rollback backup under `<git-dir>/tina-workflow/` for every existing
path that the approved plan will change. Apply only explicit relative paths;
never use globs, broad Git restore/reset commands, or directory-wide deletion.
Stop and roll back only this sync's changes on the first failure.

In incognito mode, update the marked local-exclude block before adding new
paths, verify every untracked path with `git check-ignore -v --no-index`, and
remove obsolete patterns only after their files are gone. The target's status
and staged and unstaged diffs must match the recorded baseline after sync.

In normal mode, preserve the recorded baseline changes and report only the new
focused sync diff. Do not stage or commit it.

Run Tina schema validation and confirm the target resolves `tina` as default.
Then write the new manifest atomically and remove the rollback backup. Keep
`custom` policy for every preserved or merged target path.

Report the source revision, target mode, updated and removed paths, preserved
customizations, unresolved conflicts, manifest path, and whether a new Codex
session is required for instruction changes to load.
