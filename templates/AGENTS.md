# Tina Workflow

OpenSpec is the planning system. The project default schema is `tina`.

## Routing

- Never use `$openspec-explore`. Use `$tina-research` for exploration,
  feasibility work, unfamiliar APIs, and version-sensitive facts.
- Use `$tina-propose-plan` for research, grilling, domain alignment, size gate,
  and confirming an ordered Change list. Do not call `$openspec-propose`
  directly; the private wrapper owns those steps.
- After the split is confirmed, start the long propose/review loop with
  `/goal Execute $tina-propose-run docs/proposal-plan/<date>-<scenarios>.md.
  Follow the success criteria and stopping condition in that file.` The
  proposal-plan file is the only source of truth for completion.
- During proposal planning, write generated narrative in Chinese by default.
  Preserve required headings, identifiers, paths, code, and established terms.
- Use `$tina-change-visual` to generate or refresh `change.html` after
  `proposal.md` or `design.md` changes. Treat it as a review projection; the
  Markdown sources remain authoritative.
- Use `$openspec-apply-change` only after the user explicitly authorizes
  implementation.
- Use `$tina-apply <scope>` after explicit authorization to run the
  implement/QA/review loop and commit each Change before moving on.
- Use `$tina-verify` before archive.
- Use `$openspec-archive-change` only when the user explicitly requests archive.

## Tina Subagent Models

| role | deepseek profile | openai profile |
|---|---|---|
| `tina-implementer` | `deepseek-v4-flash` / `max` | `gpt-5.6-terra` / `max` |
| `tina-qa` | `deepseek-v4-flash-vision-exp` / `max` | `gpt-5.6-sol` / `medium` |
| `tina-proposer`, `tina-proposal-reviewer`, `tina-code-reviewer` | `deepseek-v4-pro` / `high` | `gpt-5.6-sol` / `high` |

Spawn each role with the pair for the active profile. Do not hardcode these
models in the agent TOML files.

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
`tina-*` skills and the `tina` schema.
