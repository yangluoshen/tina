---
name: univer-craft-init-incognito
description: Initialize both Tina Workflow and Univer Craft as ignored repository-local files while preserving tracked content and Git status. Use for an incognito, local-only, or Git-invisible Univer Craft setup in a target Git repository.
---

# Univer Craft Init Incognito

Read and follow [Tina Init Incognito](../tina-init-incognito/SKILL.md), applying
the combined payload and exclude ownership rules below. Retain its explicit
target requirement, Git worktree checks, baseline capture, conflict protection,
instruction preservation, rollback, and verification. The bundle must also
contain `install-univer-craft.sh` and both Univer Craft source skill directories.

## Stage both components

Use `install-univer-craft.sh` in place of `install.sh` for the temporary staged
installation outside the target:

```sh
"$bundle_root/install-univer-craft.sh" "$staging"
```

Select Tina's normal staged payload plus the complete staged directories
`.agents/skills/univer-craft/` and `.agents/skills/univer-craft-yolo/`, including
the SDK research reference. Never run either installer or `openspec init`
directly in the target in this mode.

Preflight the entire combined payload before changing the target or its local
exclude file. Apply Tina's identical/absent/conflicting path rules to the two
extension directories as well. A conflict in either component blocks copying
both. Reuse an already installed, compatible Tina setup without rewriting it.

Build or reuse `AGENTS.override.md` exactly as Tina Init Incognito specifies;
never copy the bundle's root `AGENTS.md` or the staged `AGENTS.md`. Univer Craft
guidance lives in its skills and needs no extra instruction block.

## Keep exclude ownership separate

Use the repository-local exclude file resolved by Git. Tina's marked block
contains only Tina's payload destinations and its instruction override. Put
the selected untracked Univer Craft destinations in a separate block:

```text
# univer-craft-incognito:start
/.agents/skills/univer-craft/
/.agents/skills/univer-craft-yolo/
# univer-craft-incognito:end
```

Include only the untracked destinations that this installation needs. Preserve
an existing valid extension block and add only missing entries. Stop on
modified, malformed, repeated, or unfamiliar entries in either managed block;
preserve unrelated exclude content. Do not put extension entries in Tina's
block, broaden exclusions to parent directories, edit `.gitignore`, or conceal
tracked edits with index flags. Preserve status in every linked worktree that
shares the exclude file, as required by the base skill.

Back up the whole exclude file before editing either block. Verify every
selected untracked path is ignored before copying. Apply Tina's rollback to
the entire combined payload: track newly created paths from both components,
restore any modified pre-existing untracked override, and restore the original
exclude file on failure. Never remove reused files or pre-existing blocks.

## Verify the combined result

Complete Tina's schema/default checks and compare both installed extension
directories with their bundle sources using `diff -qr`. Verify their untracked
paths are ignored. Require Git status, staged diff, unstaged diff, and tracked
file content to match their baselines, including linked worktrees affected by
shared exclusions. An idempotent rerun must reuse identical content and keep
one valid block per component.

Report that both Tina and Univer Craft are installed locally, the resolved
exclude file, reused content, and verification results. Carry forward Tina's
override snapshot warning and instruction to start a new Codex session. Do not
commit, launch an app workflow, or change Tina's own initialization skills.
