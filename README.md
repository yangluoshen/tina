# Tina Workflow

Tina Workflow is a personal planning and coding workflow bundle for Codex. It
uses OpenSpec to organize domain modeling, proposals, behavior specs,
conditional design, task breakdown, and verification into an installable,
reviewable, repeatable process.

## Core flow

```text
$tina-research (optional)
        ↓
$tina-propose-plan
        ↓
docs/proposal-plan/<date>-<scenarios>.md
        ↓
/goal Execute $tina-propose-run <proposal-plan>.md
        ├── one tina_proposer per Change
        └── one global tina_proposal_reviewer after all proposals
        ↓
human review
        ↓
$tina-apply <scope>
        ├── one implementer per Change, then commit that Change
        ├── one global QA pass after all Changes
        └── one global code review after QA
        ↓
$tina-verify
        ↓
$openspec-archive-change
```

Core constraints:

- One Change carries one intent, at most two capabilities, about eight coarse
  tasks, and fits a single focused implementation session.
- Proposal narrative defaults to Chinese while preserving existing headings,
  identifiers, paths, code, and domain terms.
- Read the applicable `CONTEXT.md`, `CONTEXT-MAP.md`, and ADRs before planning,
  implementation, and verification.
- `change.html` is optional. Generate it only when the user explicitly requests
  HTML visualization; otherwise skip it without asking. When generated, it is a
  software-diagram projection for human review and the Markdown sources remain
  authoritative.
- A single Change can still use `$tina-propose-plan` to create full OpenSpec
  artifacts and then `$openspec-apply-change`. Multi-Change work uses
  `$tina-propose-run` and `$tina-apply`.
- Implementation, verification, and archive are separate user-authorized steps.

## Prerequisites

- Git
- Node.js and npm
- Codex
- An OpenSpec CLI matching the version pinned by this bundle

Install the matching OpenSpec version from the bundle root:

```sh
. ./dependencies.env
npm install -g "$OPENSPEC_PACKAGE@$OPENSPEC_VERSION"
```

## Install into a target repository

Link the installer to a user command directory already on `PATH`:

```sh
mkdir -p "$HOME/.local/bin"
ln -s "$PWD/install.sh" "$HOME/.local/bin/tina-init"
```

Then initialize a target repository:

```sh
cd /path/to/target-repository
tina-init .
```

You can also pass another target directory. Missing parent directories are
created as needed:

```sh
tina-init /absolute/path/to/target-repository
```

The installer:

- runs `openspec init --tools codex`;
- installs the private `tina-*` skills and pinned Matt Pocock skills;
- installs the project-level `tina` schema and sets it as the default;
- appends the Target Instructions as a managed block in the target `AGENTS.md`;
- validates the resolved schema.

Installation is non-destructive. Reinstalling identical content is safe. If a
target skill, schema, or managed `AGENTS.md` block has been modified, the
installer refuses to overwrite it and shows the diff. Existing project files are
never silently replaced.

## Daily use

### 1. Research (optional)

Use for unfamiliar APIs, version-sensitive facts, or feasibility questions:

```text
$tina-research <question>
```

Research uses high-trust primary sources and saves a cited Research Note.

### 2. Confirm the Change split

```text
$tina-propose-plan <change or goal to implement>
```

This step runs research, grilling, domain alignment, and the size gate, then
confirms an ordered list of Changes. It writes the confirmed strategy to
`docs/proposal-plan/<date>-<scenarios>.md` and ends with the next `/goal`
prompt. Success criteria and the stopping condition come from this planning
session rather than a fixed template.

### 2.1 Run the proposal workflow

Copy the next-step prompt from `$tina-propose-plan`:

```text
/goal Execute $tina-propose-run docs/proposal-plan/<date>-<scenarios>.md.
Follow the success criteria and stopping condition in that file.
Do not grill, ask for individual confirmation, or archive.
```

The goal spawns one `tina_proposer` per Change. After all Changes are proposed,
it spawns one `tina_proposal_reviewer` for the whole run. If the verdict is
`Needs changes`, the review returns to the relevant proposer; the same global
reviewer re-reviews until the plan file's stopping condition is met.

### 3. Human review

Review the Markdown sources. Open `change.html` only when HTML visualization was
explicitly requested:

1. `proposal.md`: problem, intent, and scope;
2. `specs/**/*.md` when present: observable and testable behavior;
3. `design.md`: technical choices, alternatives, and risks;
4. `tasks.md`: task dependencies and explicit verification.

### 4. Implement, verify, and archive

```text
$tina-apply <scope>
$tina-verify <change-name>
$openspec-archive-change <change-name>
```

`$tina-apply` implements each Change in dependency order and commits it. After
all Changes are committed, it runs one global QA pass and then one global code
review over the full run. It only starts after explicit user authorization.
Archive also requires a separate user request. A single Change can still use
`$openspec-apply-change` directly.

## Files installed in a target repository

```text
target-repository/
├── AGENTS.md
├── .agents/skills/
│   ├── openspec-*/
│   ├── tina-research/
│   ├── tina-propose-plan/
│   ├── tina-propose-run/
│   ├── tina-apply/
│   ├── tina-change-visual/
│   ├── tina-verify/
│   └── pinned upstream skills such as research, grilling, and domain-modeling
├── .codex/agents/
│   ├── tina-proposer.toml
│   ├── tina-proposal-reviewer.toml
│   ├── tina-implementer.toml
│   ├── tina-qa.toml
│   └── tina-code-reviewer.toml
└── openspec/
    ├── config.yaml
    └── schemas/tina/
        ├── schema.yaml
        └── templates/
```

## Repository layout

```text
schema/tina/               Tina OpenSpec schema and templates
skills/tina-*/             Private orchestration skills maintained here
vendor/mattpocock-skills/  Pinned, unmodified upstream skill snapshots
templates/AGENTS.md        Target Instructions installed into target repos
dependencies.env           The single source of dependency pins
install.sh                 Non-destructive installer
test.sh                    Installer and schema smoke test
update-dependencies.sh     The only supported dependency refresh path
```

The root `AGENTS.md` governs this bundle only and must not be copied into target
projects. Target projects receive `templates/AGENTS.md`.

## Verification

After changing the schema, skills, agents, Target Instructions, or installer:

```sh
./test.sh
```

The test installs the workflow twice in a temporary directory and verifies
idempotency, conflict protection, schema resolution, dynamic instructions, and
the `change.html` template.

## Updating dependencies

Refresh pinned upstream snapshots and dependency pins only through the update
script:

```sh
./update-dependencies.sh <matt-ref> <openspec-version>
```

Use the latest upstream releases only when intentionally testing them:

```sh
./update-dependencies.sh main latest
```

Run `./test.sh` afterward and review the full dependency diff before committing.
The script validates OpenSpec in an isolated `npx` run and never modifies a
global OpenSpec installation.
