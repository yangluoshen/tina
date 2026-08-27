# Repository Instructions

This repository builds the Personal Coding Workflow bundle. Its root
`AGENTS.md` governs maintenance here and must never be copied into target
projects; `templates/AGENTS.md` is the Target Instructions source.

## Source Layout

- `schema/personal-coding/`: the project-level OpenSpec schema and templates.
- `skills/coding-workflow-*/`: private orchestration skills.
- `vendor/mattpocock-skills/`: pinned, unmodified upstream skill files.
- `templates/AGENTS.md`: the managed block installed into target projects.
- `install.sh`: non-destructive installer; `test.sh`: its smoke test.
- `tmp/`: ignored research clones, never commit them.

## Maintenance Rules

- Never edit vendored skill content. Replace a snapshot as a unit and update
  `vendor/mattpocock-skills/UPSTREAM` when upgrading.
- Keep private policy out of `openspec-*` and vendored skills; change only the
  `coding-workflow-*` wrappers, custom schema, or Target Instructions.
- Keep the schema limited to proposal, specs, conditional design, and tasks.
- Preserve installer conflict checks and existing target-project content.
- Run `./test.sh` after changing the schema, skills, Target Instructions, or
  installer.
