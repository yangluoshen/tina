---
name: univer-craft
description: Research Univer Office SDK and route Univer App work to the appropriate Tina skill in new or existing repositories. Use for Univer integration, feasibility, planning, or an explicitly requested implementation or verification stage. For autonomous completion, use univer-craft-yolo.
---

# Univer Craft

Help build Univer Apps using Tina. This is a Univer-specific research and
dispatch layer, not a fixed sequence of stages. Select the work that the user's
request and repository state require. An SDK question can end with an answer;
an implementation request can resume an existing Change.

Univer Craft depends on Tina. Keep Univer guidance in these skills and their
references; never add a dependency on Univer Craft to Tina skills, agents,
schema, or Target Instructions.

## Shared context and research

This section also applies when loaded by `$univer-craft-yolo`.

- Locate the target repository from the user's path or the current project.
  Read applicable instructions, CONTEXT files, ADRs, package manifests,
  lockfiles, relevant code, existing Research Notes, and active Tina artifacts.
  Identify the actual app root in a monorepo and preserve unrelated changes.
- Locate the installed Tina skills and read the entrypoint needed for this
  request. Tina is a collection of `tina-*` skills, not a `$tina` command. For
  planning and execution, verify the target resolves the `tina` OpenSpec schema
  and has the required Tina agents and dependencies. If anything is missing,
  report the exact prerequisite and an installation instruction using the
  available Tina bundle/installer. Do not invent an installer path or replace
  Tina with a private workflow. Independent repository/doc inspection can
  continue while execution is blocked. If no installation source can be found,
  normal mode asks for the bundle location; YOLO records the missing source as
  a blocker and finishes independent work without asking an intermediate question.
- Identify the requested product, observable behavior, deployment/runtime, and
  installed SDK packages and versions. Read
  [the SDK research map](references/univer-sdk.md) for the relevant layer:
  Web engines/editor/headless runtime, Server collaboration and integrations,
  or AI agent tools. A feature may cross layers; follow only dependencies needed
  for that feature. Do not assume every Univer App needs all three SDKs.
- When the repository lacks Univer knowledge, APIs are unfamiliar, or evidence
  is missing or version-sensitive, invoke `$tina-research` with a bounded
  question, the user outcome, repository constraints, installed versions, and
  the relevant sources from the map. Reuse sufficient compatible Research Notes;
  resolve gaps rather than repeating broad research.
- Start external discovery at `https://docs.univer.ai/llms.txt` and the relevant
  layer index. Try a page's `.md` form; if it fails or returns HTML, use the
  canonical page, index, or official repository. A missing Markdown endpoint
  does not prove the feature is unsupported. Do not fetch the full documentation
  bundle by default.
- Before implementing an SDK integration, read the relevant pages in full,
  including linked prerequisites; inspect the closest official example's
  complete execution path and the SDK root/relevant package READMEs. Reuse a
  current local checkout or clone the relevant official example into the repo's
  ignored research area. Trace configuration, registration, shared modules,
  data flow, and cleanup as needed. Check APIs against installed types/source
  when the repository version differs from current docs. Do not implement from
  an index, isolated snippet, or remembered API alone.
- Require research to record dated source links, the versions examined,
  confirmed capabilities, assumptions/unknowns, integration boundaries, and the
  decision it unblocks. Use the repository's Research Note location, or
  `docs/research/` if none exists. Pass its actual path into the selected Tina
  stage and relevant agents, together with the original request and acceptance
  criteria. Research does not create an OpenSpec Change by itself.

## Repository defaults

For a new repository without an established application stack, default to pnpm
and TypeScript. Choose the smallest framework/runtime justified by the requested
app and supported SDK example. Use strict TypeScript, a committed pnpm lockfile,
clear development/build/typecheck commands, and focused checks of the requested
behavior. Document required environment variables and startup steps; keep
secrets outside source control. Add server processes, workspaces, or deployment
infrastructure only when the requested behavior requires them. Tina metadata
alone does not make an otherwise empty repository an existing app.

For an existing repository, preserve its language, package manager, framework,
directory layout, component patterns, styling, tests, authentication, and
deployment conventions. Extend the existing integration boundary. Do not
migrate it to pnpm/TypeScript, replace configuration, or scaffold over existing
files merely to match a Univer example. Check SDK version compatibility and
explain any necessary change before a hard-to-reverse migration.

## Normal dispatch

Use the matching entrypoint, respecting its prerequisites and existing user
authorization. This table contains alternatives, not a checklist.

| Current request/state | Tina entrypoint |
| --- | --- |
| Explain, explore, assess feasibility, or resolve SDK uncertainty | `$tina-research` only as needed; answer with evidence |
| Design or plan a feature without a confirmed split | `$tina-propose-plan`, with relevant Research Note paths |
| Generate proposals from a confirmed Proposal Plan | `$tina-propose-run`, with the exact plan path |
| Implement an authorized, prepared Change or plan | `$tina-apply`, with the implementation scope |
| Accept user stories, review code, or verify Changes | `$tina-qa`, `$tina-code-review`, or `$tina-verify`, matching the request |
| User delegates the full task autonomously | `$univer-craft-yolo` |

If a requested stage lacks required artifacts, identify the missing prerequisite
and use the stage that supplies it within the user's scope. Do not restart
completed planning or chain implementation, QA, review, and verification simply
because this wrapper was invoked. Once prerequisites and required approvals are
satisfied, continue to the originally authorized stage; completing a prerequisite
does not require renewed authorization. Let Tina own its stage mechanics and agents.

Return the answer or completed stage result, relevant Research Note/artifact
paths, and the next useful execution instruction in the user's language. Make
it copyable: name the actual Tina skill, real plan/Change path when one exists,
the user's concrete objective, and the Research Note to read. Preserve Tina's
`/goal` handoff when required. If no further work is needed, say so; do not invent
a follow-up stage. Suggested stages beyond the user's authorized request remain
handoffs; do not automatically execute them.
