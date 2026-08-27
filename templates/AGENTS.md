# Personal Coding Workflow

OpenSpec is the planning system. The project default schema is `personal-coding`.

## Routing

- Never use `$openspec-explore`. Use `$coding-workflow-research` for exploration,
  feasibility work, unfamiliar APIs, and version-sensitive facts.
- Use `$coding-workflow-propose` for every new proposal. Do not call
  `$openspec-propose` directly; the private wrapper owns research, grilling,
  domain alignment, and the size gate.
- Use `$openspec-apply-change` only after the user explicitly authorizes
  implementation.
- Use `$coding-workflow-verify` before archive.
- Use `$openspec-archive-change` only when the user explicitly requests archive.

## Domain Model

Read the applicable `CONTEXT-MAP.md` or `CONTEXT.md` and related ADRs before
planning, implementation, and verification. Keep CONTEXT files as pure
glossaries. Update a term immediately when it is settled; create an ADR only
when a decision is hard to reverse, surprising without context, and a real
trade-off. Proposals and designs must cite and respect these files.

## Change Size

One Change has one intent, at most two capabilities, about eight coarse tasks,
and fits one focused implementation session. When any limit is exceeded, stop
and propose an ordered set of smaller Changes. Never create all split Changes
without confirmation and never hide excess scope inside oversized tasks.

## Ownership

Directories named `openspec-*` are managed by OpenSpec. Vendored Matt Pocock
skills are unchanged snapshots. Put personal behavior only in
`coding-workflow-*` skills and the `personal-coding` schema.
