# Repository Instructions

This repository builds the Tina Workflow bundle. Its root
`AGENTS.md` governs maintenance here and must never be copied into target
projects; `templates/AGENTS.md` is the Target Instructions source.

## Source Layout

- `schema/tina/`: the project-level OpenSpec schema and templates.
- `skills/tina-*/`: private orchestration skills.
- `vendor/mattpocock-skills/`: pinned, unmodified upstream skill files.
- `dependencies.env`: exact upstream revisions tested with this bundle.
- `update-dependencies.sh`: the only supported dependency refresh path.
- `templates/AGENTS.md`: the managed block installed into target projects.
- `install.sh`: non-destructive installer; `test.sh`: its smoke test.
- `tmp/`: ignored research clones, never commit them.

## Maintenance Rules

- Never edit vendored skill content or OpenSpec-generated `openspec-*` skills.
- Update dependencies only with `./update-dependencies.sh <matt-ref> <openspec-version>`.
  Use `main latest` only when intentionally testing the
  newest upstream releases.
- Keep dependency pins in `dependencies.env`; do not duplicate versions in
  private skills, schemas, templates, or Target Instructions.
- An update may replace only the selected vendored files and dependency pins.
  Keep all compatibility policy in private wrappers and the custom schema.
- The updater validates OpenSpec in an isolated `npx` run. It must never install,
  upgrade, or remove a global OpenSpec package.
- Keep private policy out of `openspec-*` and vendored skills; change only the
  `tina-*` wrappers, custom schema, or Target Instructions.
- Keep the schema limited to proposal, specs, conditional design, and tasks.
- Preserve installer conflict checks and existing target-project content.
- Run `./test.sh` after changing the schema, skills, Target Instructions, or
  installer, and after every dependency update. Review the complete dependency
  diff before committing it.

# No AI Slop

Write like a competent person with something specific to say. Deliver the answer, explanation, or decision without announcing that you are about to deliver it.

Start with substance. Remove throat-clearing such as “Here’s the thing,” “It’s worth noting,” “Let me be clear,” and previews of the section that follows. Do not manufacture emphasis with “This matters,” “Let that sink in,” “Full stop,” or claims that something is profound, crucial, difficult, or significant. Show the fact, consequence, or constraint that earns the emphasis.

Prefer concrete nouns and active verbs. Name the actor when responsibility matters: “the team postponed the release,” not “the release was postponed.” Do not give abstractions false agency: data does not speak, decisions do not emerge, and culture does not change itself. Identify who interpreted, decided, or changed what. Use passive voice only when the actor is unknown or genuinely irrelevant.

State the positive claim directly. Avoid canned pivots such as “not X, but Y,” negative runways that list what something is not, rhetorical questions answered in the next sentence, and setup lines such as “Here’s why.” Do not use sentence fragments, one-line paragraph endings, or em dashes as stage lighting for ordinary points. A sharp sentence should be sharp because its content is precise.

Choose plain, specific language over business jargon, vague declarations, and inflated abstractions. Replace “navigate the evolving landscape” with the actual action and situation. Remove softeners and intensifiers that do not change the claim. Treat words such as “really,” “actually,” “deeply,” “fundamentally,” “always,” and “never” as prompts to verify or tighten the sentence, not as a mechanical blacklist.

Vary sentence and paragraph length without forcing a pattern. Avoid repeated three-item lists, stacked short sentences, identical paragraph endings, and other rhythms that make the prose feel generated. Use “you” when addressing the reader helps; avoid generic claims about what “people” think or do unless evidence supports them.

Trust the reader. Do not restate the conclusion, explain obvious transitions, grant permission (“and that’s okay”), narrate the document’s structure, or add a motivational closing by default. Keep necessary qualifications, safety warnings, evidence, and technical detail. Cut only language that does not improve meaning, accuracy, or navigation.

Before sending, read the draft once for directness, specificity, agency, rhythm, and density. Rewrite any sentence that announces a point instead of making it. Delete anything the reader can remove without losing meaning.
