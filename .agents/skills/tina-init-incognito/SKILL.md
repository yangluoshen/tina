---
name: tina-init-incognito
description: Initialize Tina Workflow as ignored, repository-local files without changing tracked content or Git status. Use when the user asks for an incognito, local-only, or Git-invisible Tina setup in another repository.
---

# Tina Init Incognito

Create a local working setup whose files remain on disk but do not appear in
Git status. Do not claim that the filesystem is unchanged.

Use Git's repository-local exclude file, resolved by `git rev-parse --git-path
info/exclude`. Do not modify the target's `.gitignore`: that file may be
tracked, so changing it would violate the incognito contract. Never use
`git update-index --assume-unchanged` or `--skip-worktree` to conceal edits to
tracked files.

## Codex instruction behavior

Codex checks `AGENTS.override.md` before `AGENTS.md` in each directory and uses
at most one of them. It discovers the instruction chain once when a session
starts. See the [official OpenAI documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

Therefore, a new root `AGENTS.override.md` must contain the target's existing
root `AGENTS.md` text followed by the canonical Tina managed block. Otherwise
the override would hide the repository's instructions. If an override already
exists, preserve it and append the Tina block instead; do not also duplicate
`AGENTS.md`. Tell the user to start a new Codex session after installation.

## Preconditions

1. Resolve the bundle root containing this skill, `install.sh`,
   `dependencies.env`, and `templates/AGENTS.md`.
2. Require an explicit target path. It must resolve to a Git worktree root and
   must not equal the bundle root. Ask when either identity is ambiguous.
3. Record the target's status, unstaged diff, and staged diff before changing
   anything. Existing dirty or untracked files belong to the user.
4. Check that `openspec` exists. Do not install global software without
   separate authorization.

The incognito contract cannot hide changes to tracked files. Stop and ask the
user to choose a normal installation, a separate worktree, or no installation
when a required target path is tracked with incompatible content. The same
rule applies when an existing untracked file would be overwritten.

## Stage the standard installation

Create a temporary directory outside the target and run the bundle's
`install.sh` there. Use that validated result as the payload; do not run the
installer or `openspec init` directly in the target.

From the staged result, select only:

- `.agents/skills/.openspec-target` and each staged skill directory;
- `openspec/config.yaml` or `openspec/config.yml`;
- `openspec/schemas/tina`.

Do not copy the staged `AGENTS.md`. Build `AGENTS.override.md` from the target's
instructions and `templates/AGENTS.md` as described above.

## Preflight the target

For every payload destination:

- Keep identical content without rewriting it.
- Copy only to an absent path that will be ignored.
- Stop on a symlink, a differing tracked path, or differing untracked content.
- If a tracked OpenSpec config already selects `tina`, preserve it and skip the
  staged config. If it selects another schema, incognito initialization cannot
  replace the default; ask the user how to proceed.

For `AGENTS.override.md`:

- If it is tracked and lacks an exact canonical Tina block, incognito setup
  cannot modify it.
- If it is absent, derive it from the current root `AGENTS.md` and append one
  canonical block between `<!-- tina-workflow:start -->` and
  `<!-- tina-workflow:end -->`.
- If an untracked override exists without markers, append the block while
  preserving its content.
- Treat an exact existing block as installed. Stop on modified, malformed, or
  repeated markers and ask the user how to merge them.

Warn that a derived override is a snapshot: when the repository changes its
root `AGENTS.md`, regenerate the override before the next Codex session.

## Add local excludes and copy

Append one marked block to the repository-local exclude file. Include only the
exact untracked destinations selected from the staged payload plus
`/AGENTS.override.md`; do not ignore all of `.agents/` or `openspec/`, because
that would hide future project work. Reuse a valid existing block and stop on
modified or repeated markers.

Use these markers:

```text
# tina-workflow-incognito:start
# tina-workflow-incognito:end
```

Verify each untracked destination with `git check-ignore -v --no-index` before
copying or editing it. Then copy the selected staged paths and write the
override. Track every path created during this run. On any failure, remove only
those newly created paths, restore any pre-existing untracked override from a
temporary backup, and remove the exclude block added by this run. Never roll
back with a broad Git command.

## Verify and report

Run the Tina schema validation and confirm that the target resolves `tina` as
its default. Compare post-install status and staged and unstaged diffs with the
recorded baseline; they must be unchanged. Confirm the installed local paths
are ignored and no tracked file was rewritten.

Report the local exclude file, ignored paths, any content reused, and the
`AGENTS.override.md` snapshot warning. Do not commit, modify `.gitignore`, or
remove the temporary staging directory until verification finishes.
