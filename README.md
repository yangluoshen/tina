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
        ├── $tina-architecture when topology affects the Change split
        │     └── one tina_architect creates and revises the model
        └── human confirms the Architecture Model
        ↓
docs/proposal-plan/<date>-<scenarios>.md
        └── implementation Changes + a separate story-level QA Change
        ↓
/goal Execute $tina-propose-run <proposal-plan>.md
        ├── one tina_proposer per Change
        └── one global tina_proposal_reviewer after all proposals
        ↓
human review
        ↓
$tina-apply <scope>
        └── one implementer per implementation Change, then commit
        ↓ returns control
$tina-qa <qa-change or plan>
        └── one QA agent tests original user stories; fresh agents fix issues
        ↓ returns control
$tina-code-review <request or plan>
        └── one reviewer checks the complete diff's code and architecture quality
              └── fresh agents fix issues; rerun story QA before re-review
        ↓
$tina-verify
        ↓
$openspec-archive-change
```

Core constraints:

- One Change carries one intent, at most two capabilities, about eight coarse
  tasks, and fits a single focused implementation or QA session.
- Plan QA as a separate Change whose scenarios follow the original request's
  user stories and interactions across the full implementation. Its tasks
  record acceptance evidence; a QA-only Change references product specs and
  uses `skip_specs: true` without duplicating capability deltas.
- Proposal narrative defaults to Chinese while preserving existing headings,
  identifiers, paths, code, and domain terms.
- Read the applicable `CONTEXT.md`, `CONTEXT-MAP.md`, and ADRs before planning,
  implementation, and verification.
- Architecture alignment stores its confirmed typed source in
  `docs/architecture/<scope>.architecture.json`. Generated Archify HTML and
  Delta files are non-normative review projections.
- `change.html` is optional. Generate it only when the user explicitly requests
  HTML visualization; otherwise skip it without asking. When generated, it is a
  software-diagram projection for human review and the Markdown sources remain
  authoritative.
- Request-level planning includes a QA Change even with one implementation
  Change. `$tina-propose-run` creates both kinds of artifacts; `$tina-apply`
  executes implementation Changes and `$tina-qa` executes QA Changes.
- Normal routing separates implementation, QA, code review, verification, and
  archive. A `$tina-yolo` request authorizes the workflow through verification; archive
  still requires a separate request.

## Install with one instruction

Open the target repository in Codex and send:

```text
请读取 https://raw.githubusercontent.com/yangluoshen/tina/main/INSTALL.md，将 Tina 安装到当前仓库。
```

Append `使用 incognito 模式，保持 Git 状态不变。` for a local-only installation,
or replace `当前仓库` with an explicit target path. The agent follows
[INSTALL.md](INSTALL.md), acquires the source outside the target, and runs the
existing initializer with the pinned OpenSpec through `npm exec`. Git, Node.js,
and npm are required; no preinstalled Tina skill or global OpenSpec is needed.
Start a new Codex session after installation. The URL requires this guide to be
published; a local checkout's `INSTALL.md` path works before publication.

## Manual installation prerequisites

- Git
- Node.js 18 or newer and npm
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
- installs the private `tina-*` skills plus pinned Matt Pocock, Archify, and show-me
  skills;
- installs the project-level `tina` schema and sets it as the default;
- appends the Target Instructions as a managed block in the target `AGENTS.md`;
- validates the resolved schema.

Installation is non-destructive. Reinstalling identical content is safe. If a
target skill, schema, or managed `AGENTS.md` block has been modified, the
installer refuses to overwrite it and shows the diff. Existing project files are
never silently replaced.

## Daily use

Use `$tina-yolo <task>` to delegate the complete workflow:

```text
$tina-yolo <task>
  → tina-research → tina-propose-plan → tina-propose-run
  → tina-apply → tina-qa → tina-code-review → tina-verify
```

YOLO skips grilling and intermediate questions. The orchestrator decides scope,
architecture, and UX choices, records assumptions and trade-offs in
`docs/proposal-plan/<date>-<scenarios>.md`, and writes qualifying ADRs. It keeps
the size gate, independent reviews, QA, and local commits, returning verification
failures to implementation until the task passes. The plan records progress for
continuation after interruption. Unavailable prerequisites or permissions are
reported as blockers, never as completion. YOLO does not automatically push,
deploy, or archive, and applies only to the requested task.

Use `$show-me <topic>` for a concise visual explanation with diagrams, code
sketches, or a focused HTML artifact. The skill comes from
[HumanLayer](https://github.com/humanlayer/skills/blob/main/plugins/show-me/skills/show-me/SKILL.md).

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

This step runs research, grilling, domain alignment, conditional architecture
alignment, and the size gate, then confirms implementation Changes and a separate
QA Change. The plan retains the original request, user stories, acceptance
criteria, and QA coverage and prerequisites. When
components, connections, or boundaries affect the split, `$tina-architecture`
spawns one `tina_architect` to create or update an Architecture Model. Human
feedback returns to the same architect until the model is confirmed before the
size gate. The step writes the confirmed strategy to
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

### 4. Implement, QA, review, verify, and archive

```text
$tina-apply <scope>
$tina-qa <qa-change or plan>
$tina-code-review <request or plan>
$tina-verify <change-name>
$openspec-archive-change <change-name>
```

`$tina-apply` implements and commits implementation Changes in dependency order,
then returns control. It starts only after explicit user authorization and leaves
QA Changes for `$tina-qa`. An independent QA agent tests the original user stories,
records issues in `docs/qa/issues/`, and updates the QA Change's acceptance tasks.
The summary remains `docs/qa/apply.md`.

`$tina-code-review` uses an independent reviewer to assess the original request's
complete diff for code smells, unnecessary complexity, and architectural problems.
QA and `$tina-verify` check functional completeness. For required QA or review
issues, the main agent starts fresh bug-fix implementers; issues have no owning
implementation Change. Review findings also go into `docs/qa/issues/`. Fixes
retest the original user stories, and review fixes also receive another review.
`$tina-yolo` automatically chains these stages through verification.
Archive also requires a separate user request.

## Files installed in a target repository

```text
target-repository/
├── AGENTS.md
├── .agents/skills/
│   ├── openspec-*/
│   ├── tina-research/
│   ├── tina-yolo/
│   ├── tina-architecture/
│   ├── tina-propose-plan/
│   ├── tina-propose-run/
│   ├── tina-apply/
│   ├── tina-qa/
│   ├── tina-code-review/
│   ├── tina-change-visual/
│   ├── tina-verify/
│   ├── archify/
│   ├── show-me/
│   └── pinned upstream skills such as research, grilling, and domain-modeling
├── .codex/agents/
│   ├── tina-architect.toml
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
vendor/archify/             Pinned, unmodified Archify Skill package
vendor/show-me/             Pinned, unmodified HumanLayer skill and license
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
idempotency, conflict protection, schema resolution, dynamic instructions,
QA task tracking without product spec deltas, Archify validation, and the
`change.html` template.

## Updating dependencies

Refresh pinned upstream snapshots and dependency pins only through the update
script:

```sh
./update-dependencies.sh <matt-ref> <openspec-version> [archify-ref] [show-me-ref]
```

Use the latest upstream releases only when intentionally testing them:

```sh
./update-dependencies.sh main latest main main
```

Run `./test.sh` afterward and review the full dependency diff before committing.
The script validates OpenSpec in an isolated `npx` run and never modifies a
global OpenSpec installation.
