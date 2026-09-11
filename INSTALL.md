# Install Tina from the target repository

Open the target repository in Codex and send:

```text
请读取 https://raw.githubusercontent.com/yangluoshen/tina/main/INSTALL.md，将 Tina 安装到当前仓库。
```

For local-only installation, append `使用 incognito 模式，保持 Git 状态不变。`
To select another target, replace `当前仓库` with its absolute path. A local
checkout of this file also works before the guide is published.

## Instructions for the installing agent

This is an installation entrypoint, not a prerequisite skill. Read the selected
initialization skill as a file; it does not need to appear in the current
session's skill catalog. Keep the existing initializer as the implementation.

### Resolve the target before changing directories

Use the path the user named. When the user says "current repository", resolve
the current project/worktree root to an absolute `$target` before acquiring the
source. That explicit repository selection satisfies the init skill's target
requirement; do not ask for the path again. Ask only if the project identity is
ambiguous. Read applicable target instructions and record existing changes.

Default to normal installation. Use incognito when the user requests it, local
only, or unchanged Git status; it requires a Git worktree root. Do not turn an
existing incognito installation into a normal installation on a generic rerun;
preserve its mode and follow the selected init skill's conflict checks.

### Acquire one source revision outside the target

Use an explicitly provided local Tina checkout when available. Otherwise clone
`https://github.com/yangluoshen/tina.git` into a temporary directory outside the
target. Use the user's requested ref, or upstream `main` by default. Resolve
and record the full commit SHA, and read this guide and the initialization skill
from that same checkout. If the requested revision lacks this guide, report it
rather than mixing files from different revisions.

Set `$bundle_root` to that checkout. Keep all downloaded source and temporary
tool/staging directories outside the target, including in incognito mode. Do
not copy the source repository's root `AGENTS.md` into the target. A supplied
dirty checkout requires authorization to use its uncommitted contents; reuse
authorization already given and record the dirty state. Do not reset it.

### Provide the pinned OpenSpec without a global installation

Require Git, Node.js, and npm. Read `dependencies.env` from `$bundle_root` for
the OpenSpec package and version; do not substitute `latest`. Use a fresh empty
`$tool_run` directory outside the source and target as the working directory for
tool invocations, so the target's local package executables are not preferred.

```sh
. "$bundle_root/dependencies.env"
cd "$tool_run"
npm exec --yes --package="$OPENSPEC_PACKAGE@$OPENSPEC_VERSION" -- openspec --version
```

Require the reported version to match the pin. Evaluate the init skill's
OpenSpec prerequisite in this environment, and prefix every installer and
subsequent OpenSpec invocation with the same `npm exec` package selection.
It supplies the CLI to the installer and its child processes through `PATH`.
This downloads into npm's cache without installing global software or adding
dependencies to the target's package manifest. Report an unavailable package,
incompatible runtime, or download failure; do not change global software.

### Run the existing mode and verify

- Normal: read `.agents/skills/tina-init/SKILL.md` from `$bundle_root` and follow
  it with the resolved absolute target. Its installer invocation becomes:

  ```sh
  npm exec --yes --package="$OPENSPEC_PACKAGE@$OPENSPEC_VERSION" -- "$bundle_root/install.sh" "$target"
  ```

- Incognito: read `.agents/skills/tina-init-incognito/SKILL.md` and follow its
  complete staging, preflight, local exclude, override, rollback, and verification
  procedure. Wrap its temporary staging installer in the same `npm exec`
  environment. Never run `install.sh` directly against the target in this mode.

For later schema verification, run from `$tool_run` with the target as the
child shell's working directory:

```sh
npm exec --yes --package="$OPENSPEC_PACKAGE@$OPENSPEC_VERSION" -- sh -c 'cd "$1" && openspec schema validate tina --verbose && openspec schema which tina' sh "$target"
```

Preserve the init skill's conflict decisions and existing target content. The
installation request does not authorize overwriting customizations, committing,
deploying, or starting an application workflow. Finish its verification before
removing only the temporary paths created for this attempt. Keep a supplied
local checkout. Report source SHA, absolute target, mode, verification results,
and any blockers. Ask the user to start a new Codex session to load the installed
skills and instructions; do not claim the current session has reloaded them.
