// Real installer checks: ownership, relocatable payload, conflict handling, rollback.
import assert from 'node:assert/strict';
import { chmodSync, existsSync, mkdirSync, readFileSync, readdirSync, realpathSync, statSync, symlinkSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const bundle = resolve(dirname(fileURLToPath(import.meta.url)), '..');
assert(process.argv[2], 'Pass a disposable test directory');
const root = realpathSync(process.argv[2]);
const project = join(root, 'dsh-project'), presets = join(root, 'dsh-home/.agent-presets');
const install = (...args) => spawnSync(join(bundle, 'install.sh'), args, { encoding: 'utf8' });
const dsh = (target = project, presetRoot = presets) => ['--runtime', 'dsh', '--preset-root', presetRoot, target];
function pass(result) { assert.equal(result.status, 0, result.stdout + result.stderr); }
function fail(result, message) { assert.notEqual(result.status, 0); assert.match(result.stdout + result.stderr, message); }
function snapshot(path) {
  if (!existsSync(path)) return null;
  if (statSync(path).isDirectory()) return Object.fromEntries(readdirSync(path).sort().map(name => [name, snapshot(join(path, name))]));
  return createHash('sha256').update(readFileSync(path)).digest('hex');
}

mkdirSync(join(project, 'openspec'), { recursive: true });
writeFileSync(join(project, 'AGENTS.md'), 'Keep project instructions.\n');
writeFileSync(join(project, 'untouched.txt'), 'existing project content\n');
writeFileSync(join(project, 'openspec/config.yml'), 'schema: spec-driven\ncontext: Keep this context.\n');
chmodSync(join(project, 'openspec/config.yml'), 0o600);
pass(install(...dsh()));
assert.equal(readFileSync(join(project, 'openspec/config.yml'), 'utf8'), 'schema: tina\ncontext: Keep this context.\n');
assert.equal(statSync(join(project, 'openspec/config.yml')).mode & 0o777, 0o600);
assert.equal(readFileSync(join(project, 'AGENTS.md'), 'utf8'), 'Keep project instructions.\n');
assert(!existsSync(join(project, '.agents')));
assert(!existsSync(join(project, '.codex')));
assert(!existsSync(join(project, 'openspec/config.yaml')));
const preset = join(presets, 'tina'), skills = join(preset, 'skills');
assert(!existsSync(join(skills, '.openspec-target')));
assert.deepEqual(snapshot(join(skills, 'prototype')), snapshot(join(bundle, 'vendor/mattpocock-skills/skills/prototype')));
assert.deepEqual(snapshot(join(skills, 'archify')), snapshot(join(bundle, 'vendor/archify')));
assert.deepEqual(snapshot(join(skills, 'show-me')), snapshot(join(bundle, 'vendor/show-me')));
assert(existsSync(join(preset, 'LICENSE.MATTPOCOCK')));
assert.match(readFileSync(join(skills, 'tina-dsh-runtime/target-instructions.md'), 'utf8'), /## Routing/);
assert(!readFileSync(join(skills, 'tina-dsh-runtime/target-instructions.md'), 'utf8').includes('## Tina Subagent Models'));
const initial = [snapshot(project), snapshot(preset)];
pass(install(...dsh()));
assert.deepEqual([snapshot(project), snapshot(preset)], initial, 'second install must be byte-identical');
fail(install(project), /uses DSH Tina Mode/);

// Compare OpenSpec output with the real Codex generator output already produced by test.sh.
for (const name of readdirSync(join(root, 'agent-project/.agents/skills')).filter(name => name.startsWith('openspec-'))) {
  assert.deepEqual(snapshot(join(skills, name)), snapshot(join(root, 'agent-project/.agents/skills', name)));
}
const localSkill = join(skills, 'tina-apply/SKILL.md');
const originalSkill = readFileSync(localSkill);
writeFileSync(localSkill, Buffer.concat([originalSkill, Buffer.from('\nLocal customization.\n')]));
const conflict = snapshot(preset);
const fresh = join(root, 'dsh-conflict-target');
fail(install(...dsh(fresh)), /conflicting content/);
assert(!existsSync(fresh), 'preset conflict must precede project writes');
assert.deepEqual(snapshot(preset), conflict);
writeFileSync(localSkill, originalSkill);

const linkRoot = join(root, 'dsh-linked-root');
symlinkSync(presets, linkRoot);
fail(install(...dsh(fresh, linkRoot)), /Refusing symlink/);
assert(!existsSync(fresh));
mkdirSync(join(fresh, 'openspec'), { recursive: true });
symlinkSync(join(project, 'openspec/config.yml'), join(fresh, 'openspec/config.yaml'));
fail(install(...dsh(fresh)), /Refusing symlink/);
assert.deepEqual(snapshot(project), initial[0]);

const legacy = join(root, 'dsh-legacy');
mkdirSync(legacy);
writeFileSync(join(legacy, 'AGENTS.md'), '<!-- tina-workflow:start -->\nexisting Tina policy\n');
fail(install(...dsh(legacy)), /Shared Tina instructions/);
assert(!existsSync(join(legacy, 'openspec')));

// Failure after schema/config publication must restore prior config and remove only new paths.
const broken = join(root, 'dsh-rollback');
mkdirSync(join(broken, 'openspec'), { recursive: true });
writeFileSync(join(broken, 'openspec/config.yaml'), 'schema: spec-driven\ncontext: keep rollback context\n');
writeFileSync(join(broken, 'keep.txt'), 'keep');
const before = snapshot(broken);
const bin = join(root, 'dsh-failing-bin');
mkdirSync(bin);
const realOpenSpec = execFileSync('sh', ['-c', 'command -v openspec'], { encoding: 'utf8' }).trim();
writeFileSync(join(bin, 'openspec'), '#!/bin/sh\nif [ "$PWD" = "$TINA_FAILURE_TARGET" ]; then echo "injected target validation failure" >&2; exit 42; fi\nexec "$TINA_REAL_OPENSPEC" "$@"\n');
chmodSync(join(bin, 'openspec'), 0o755);
const result = spawnSync(join(bundle, 'install.sh'), dsh(broken, join(root, 'rollback-presets')), {
  encoding: 'utf8', env: { ...process.env, PATH: bin + ':' + process.env.PATH, TINA_FAILURE_TARGET: broken, TINA_REAL_OPENSPEC: realOpenSpec },
});
fail(result, /injected target validation failure/);
assert.deepEqual(snapshot(broken), before);
assert(!existsSync(join(root, 'rollback-presets')));

// DSH_HOME defaults work independently of the current directory and custom preset roots.
const defaultHome = join(root, 'default-dsh-home');
pass(spawnSync(join(bundle, 'install.sh'), ['--runtime', 'dsh', join(root, 'default-dsh-project')], {
  encoding: 'utf8', env: { ...process.env, DSH_HOME: defaultHome },
}));
assert(existsSync(join(defaultHome, '.agent-presets/tina/agent.cordis.yml')));
console.log('DSH installer checks passed');
