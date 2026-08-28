---
name: tina-init
description: Initialize Tina Workflow from this bundle in an empty or existing target repository while preserving existing project files. Use when the user asks to install or initialize Tina Workflow in another repository.
---

# Tina Init

Use this repository's `install.sh`; do not reproduce its copy or merge logic.
The user's request authorizes changes only inside the selected target repository.

## Resolve the source and target

1. Resolve the bundle root containing this skill, `install.sh`,
   `dependencies.env`, and `templates/AGENTS.md`. Stop if those files do not
   identify one unambiguous bundle root.
2. Require an explicit target path. If the user did not provide one, or the
   path could refer to either the bundle or the target, ask before changing
   anything. Resolve it to an absolute path.
3. Never install into the bundle root unless the user explicitly confirms that
   exact target after seeing the resolved path.
4. Check that `openspec` exists. If it is missing, report the prerequisite and
   the pinned version from `dependencies.env`; do not install global software
   without separate authorization.

Never copy the bundle's root `AGENTS.md`. The installer appends the target
instructions from `templates/AGENTS.md` as a managed block.

## Inspect before installing

Inspect the target read-only. If it is a Git worktree, record `git status
--short` so existing changes are not attributed to the installation.

- A missing or empty target can go directly to the installer.
- For an existing repository, inspect `AGENTS.md`, `openspec/config.yaml`,
  `openspec/config.yml`, `openspec/schemas/tina`, and the destination skill
  directories named by `install.sh`.
- Treat identical managed content as already installed. Existing unrelated
  files are not conflicts.
- Do not edit, move, delete, or overwrite a conflicting path during inspection.

Run:

```sh
"$bundle_root/install.sh" "$target"
```

The installer performs all authoritative conflict checks before it copies Tina
content. Do not bypass those checks or invoke `openspec init` separately.

## Handle conflicts

When the installer refuses a target, preserve the target as-is. Summarize the
exact conflicting paths and the relevant diff or error, then ask only for the
decision needed to continue.

- An existing `AGENTS.md` without Tina markers is safe: the installer preserves
  it and appends one managed block.
- For malformed markers or a modified managed block, ask whether to abort or
  move the user's custom text outside the markers and restore the canonical
  block. Preserve all text outside the block. Never choose which instructions
  win on the user's behalf.
- For a non-Tina default OpenSpec schema, or both `config.yaml` and `config.yml`,
  ask which active config and default schema the repository should use.
- For a differing skill or `openspec/schemas/tina`, ask whether to keep it and
  abort, review a semantic merge, or replace it. Do not treat a directory-wide
  diff as safe to merge.
- Refuse to follow or replace conflicting symlinks. Ask the user how the target
  should represent that path.

After the user chooses, make the smallest approved change. If replacement is
requested, move the old path to a unique sibling backup instead of deleting it,
then rerun `install.sh`. For an `AGENTS.md` merge, retain the user's content
outside exactly one canonical Tina managed block.

## Verify and report

Require the installer to complete its schema validation. In a Git worktree,
review the post-install status and focused diff without altering pre-existing
changes. Report the paths created or changed, content preserved, any backup
paths, and any unresolved choice. Do not commit the target repository.
