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

