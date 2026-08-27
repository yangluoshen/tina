# Tina Workflow

OpenSpec is the planning system. The project default schema is `tina`.

## Routing

- Never use `$openspec-explore`. Use `$tina-research` for exploration,
  feasibility work, unfamiliar APIs, and version-sensitive facts.
- Use `$tina-propose` for every new proposal. Do not call
  `$openspec-propose` directly; the private wrapper owns research, grilling,
  domain alignment, and the size gate.
- During proposal planning, write generated narrative in Chinese by default.
  Preserve required headings, identifiers, paths, code, and established terms.
- Use `$tina-change-visual` to generate or refresh `change.html` after
  `proposal.md` or `design.md` changes. Treat it as a review projection; the
  Markdown sources remain authoritative.
- Use `$openspec-apply-change` only after the user explicitly authorizes
  implementation.
- Use `$tina-verify` before archive.
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
`tina-*` skills and the `tina` schema.

# No AI Slop

Write like a competent person with something specific to say. Deliver the answer, explanation, or decision without announcing that you are about to deliver it.

Start with substance. Remove throat-clearing such as “Here’s the thing,” “It’s worth noting,” “Let me be clear,” and previews of the section that follows. Do not manufacture emphasis with “This matters,” “Let that sink in,” “Full stop,” or claims that something is profound, crucial, difficult, or significant. Show the fact, consequence, or constraint that earns the emphasis.

Prefer concrete nouns and active verbs. Name the actor when responsibility matters: “the team postponed the release,” not “the release was postponed.” Do not give abstractions false agency: data does not speak, decisions do not emerge, and culture does not change itself. Identify who interpreted, decided, or changed what. Use passive voice only when the actor is unknown or genuinely irrelevant.

State the positive claim directly. Avoid canned pivots such as “not X, but Y,” negative runways that list what something is not, rhetorical questions answered in the next sentence, and setup lines such as “Here’s why.” Do not use sentence fragments, one-line paragraph endings, or em dashes as stage lighting for ordinary points. A sharp sentence should be sharp because its content is precise.

Choose plain, specific language over business jargon, vague declarations, and inflated abstractions. Replace “navigate the evolving landscape” with the actual action and situation. Remove softeners and intensifiers that do not change the claim. Treat words such as “really,” “actually,” “deeply,” “fundamentally,” “always,” and “never” as prompts to verify or tighten the sentence, not as a mechanical blacklist.

Vary sentence and paragraph length without forcing a pattern. Avoid repeated three-item lists, stacked short sentences, identical paragraph endings, and other rhythms that make the prose feel generated. Use “you” when addressing the reader helps; avoid generic claims about what “people” think or do unless evidence supports them.

Trust the reader. Do not restate the conclusion, explain obvious transitions, grant permission (“and that’s okay”), narrate the document’s structure, or add a motivational closing by default. Keep necessary qualifications, safety warnings, evidence, and technical detail. Cut only language that does not improve meaning, accuracy, or navigation.

Before sending, read the draft once for directness, specificity, agency, rhythm, and density. Rewrite any sentence that announces a point instead of making it. Delete anything the reader can remove without losing meaning.
