#!/usr/bin/env node
// Stage with the existing installer; publish only the DSH preset and project schema.
import {
  chmodSync, cpSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync,
  readdirSync, realpathSync, renameSync, rmSync, rmdirSync, writeFileSync,
} from 'node:fs';
import { dirname, isAbsolute, join, relative, resolve, sep } from 'node:path';
import { homedir, tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const bundle = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const scratch = mkdtempSync(join(realpathSync(tmpdir()), 'tina-dsh-'));
const undo = [];

function info(path) {
  try { return lstatSync(path); }
  catch (error) { if (error.code === 'ENOENT') return undefined; throw error; }
}

function checkedPath(input) {
  let path = resolve(input);
  // macOS exposes the system temporary directories through these aliases.
  if (process.platform === 'darwin') {
    for (const alias of ['/tmp', '/var']) {
      if (path === alias || path.startsWith(`${alias}/`)) path = realpathSync(alias) + path.slice(alias.length);
    }
  }
  for (let part = path; ; part = dirname(part)) {
    if (info(part)?.isSymbolicLink()) throw new Error(`Refusing symlink: ${part}`);
    if (part === dirname(part)) break;
  }
  return path;
}

function sameTree(source, target) {
  const a = info(source), b = info(target);
  if (!a || !b || a.isSymbolicLink() || b.isSymbolicLink()) return false;
  if (a.isFile() && b.isFile()) return readFileSync(source).equals(readFileSync(target));
  if (!a.isDirectory() || !b.isDirectory()) return false;
  const entries = readdirSync(source).sort(), other = readdirSync(target).sort();
  return entries.length === other.length && entries.every((name, index) =>
    name === other[index] && sameTree(join(source, name), join(target, name)));
}

function preflight(source, destination) {
  checkedPath(destination);
  if (info(destination) && !sameTree(source, destination)) {
    throw new Error(`Refusing to overwrite conflicting content: ${destination}`);
  }
}

function makeParents(path) {
  if (info(path)) {
    if (!info(path).isDirectory()) throw new Error(`Not a directory: ${path}`);
    return;
  }
  makeParents(dirname(path));
  mkdirSync(path);
  undo.push(() => rmdirSync(path));
}

function publish(source, destination, replace = false) {
  if (sameTree(source, destination)) return;
  checkedPath(destination);
  const previous = info(destination);
  if (previous && !replace) throw new Error(`Destination appeared during installation: ${destination}`);
  makeParents(dirname(destination));
  const staging = mkdtempSync(join(dirname(destination), '.tina-stage-'));
  try {
    const payload = join(staging, 'payload');
    cpSync(source, payload, { recursive: true });
    const backup = previous ? readFileSync(destination) : undefined;
    if (previous) chmodSync(payload, previous.mode);
    // The destination is absent, or the one preflighted config file.
    renameSync(payload, destination);
    undo.push(() => {
      if (backup === undefined) rmSync(destination, { recursive: true, force: true });
      else writeFileSync(destination, backup, { mode: previous.mode });
    });
  } finally { rmSync(staging, { recursive: true, force: true }); }
}

function run(command, args, cwd) {
  execFileSync(command, args, { cwd, stdio: 'inherit', env: { ...process.env, OPENSPEC_TELEMETRY: '0' } });
}

try {
  let presetRoot = join(process.env.DSH_HOME || join(homedir(), '.dsh'), '.agent-presets');
  let targetArg;
  const args = process.argv.slice(2);
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--preset-root') {
      if (!args[i + 1] || args[i + 1].startsWith('-')) throw new Error('--preset-root requires a directory');
      presetRoot = args[++i];
    } else if (args[i].startsWith('-') || targetArg !== undefined) {
      throw new Error('Usage: install.sh --runtime dsh [--preset-root <root>] [target]');
    } else targetArg = args[i];
  }
  const target = checkedPath(targetArg ?? '.');
  const preset = checkedPath(join(presetRoot, 'tina'));
  const overlaps = (a, b) => { const rel = relative(a, b); return rel === '' || (!isAbsolute(rel) && rel !== '..' && !rel.startsWith(`..${sep}`)); };
  if (overlaps(target, bundle) || overlaps(bundle, target)) throw new Error('DSH target must be outside the Tina source tree');
  if (overlaps(target, preset) || overlaps(preset, target) || overlaps(bundle, preset) || overlaps(preset, bundle)) {
    throw new Error('Preset, target, and Tina source directories must not overlap');
  }
  if (info(target) && !info(target).isDirectory()) throw new Error(`Not a directory: ${target}`);

  for (const name of ['AGENTS.md', 'CLAUDE.md', 'AGENTS.local.md', 'CLAUDE.local.md', 'AGENTS.override.md']) {
    const path = join(target, name);
    if (existsSync(path) && readFileSync(path, 'utf8').includes('<!-- tina-workflow:start -->')) {
      throw new Error(`Shared Tina instructions prevent mode isolation: ${path}. Migrate them explicitly before DSH installation.`);
    }
  }
  const configs = ['config.yaml', 'config.yml'].map(name => checkedPath(join(target, 'openspec', name)));
  if (configs.every(path => info(path))) throw new Error('Both OpenSpec config.yaml and config.yml exist');
  const config = configs.find(path => info(path)) ?? configs[0];
  const originalConfig = info(config) ? readFileSync(config, 'utf8') : undefined;
  if (originalConfig !== undefined) {
    const keys = originalConfig.match(/^schema\s*:.*$/gm) ?? [];
    if (keys.length > 1) throw new Error('Multiple top-level schema keys in OpenSpec config');
    if (keys.length && !/^schema\s*:\s*(tina|spec-driven)\s*$/.test(keys[0])) {
      throw new Error('Refusing to replace an unrecognized or non-Tina default schema');
    }
  }

  const staged = join(scratch, 'project');
  run(join(bundle, 'install.sh'), [staged], bundle);
  const desiredPreset = join(scratch, 'tina');
  cpSync(join(bundle, 'presets/dsh/tina'), desiredPreset, { recursive: true });
  cpSync(join(staged, '.agents/skills'), join(desiredPreset, 'skills'), { recursive: true });
  // This generator marker selects Codex; it is not a skill or a DSH runtime setting.
  rmSync(join(desiredPreset, 'skills/.openspec-target'), { force: true });
  cpSync(join(bundle, 'skills/tina-dsh-runtime'), join(desiredPreset, 'skills/tina-dsh-runtime'), { recursive: true });
  // Keep the existing target policy as the source, without its Codex-only model table.
  const policy = readFileSync(join(bundle, 'templates/AGENTS.md'), 'utf8')
    .replace(/## Tina Subagent Models\n[\s\S]*?(?=## Domain Model)/, '');
  writeFileSync(join(desiredPreset, 'skills/tina-dsh-runtime/target-instructions.md'), policy);
  for (const name of ['MATTPOCOCK', 'ARCHIFY', 'SHOW_ME', 'IMPECCABLE']) {
    const path = { MATTPOCOCK: 'vendor/mattpocock-skills/LICENSE', ARCHIFY: 'vendor/archify/LICENSE', SHOW_ME: 'vendor/show-me/LICENSE', IMPECCABLE: 'vendor/impeccable/LICENSE' }[name];
    cpSync(join(bundle, path), join(desiredPreset, `LICENSE.${name}`));
  }

  const schema = join(target, 'openspec/schemas/tina');
  const marker = join(target, 'openspec/.tina-dsh.json');
  const stagedMarker = join(scratch, 'tina-dsh.json');
  writeFileSync(stagedMarker, JSON.stringify({ runtime: 'dsh', preset }, null, 2) + '\n');
  const stagedConfig = join(staged, 'openspec/config.yaml');
  if (originalConfig !== undefined) {
    writeFileSync(stagedConfig, /^schema\s*:/m.test(originalConfig)
      ? originalConfig.replace(/^schema\s*:.*$/m, 'schema: tina')
      : originalConfig + '\nschema: tina\n');
  }
  preflight(desiredPreset, preset);
  preflight(join(staged, 'openspec/schemas/tina'), schema);
  preflight(stagedMarker, marker);
  run('openspec', ['schema', 'validate', 'tina', '--verbose'], staged);

  publish(join(staged, 'openspec/schemas/tina'), schema);
  if (originalConfig !== undefined && readFileSync(config, 'utf8') !== originalConfig) {
    throw new Error('OpenSpec config changed during installation');
  }
  publish(stagedConfig, config, originalConfig !== undefined);
  run('openspec', ['schema', 'validate', 'tina', '--verbose'], target);
  run('openspec', ['schema', 'which', 'tina'], target);
  publish(desiredPreset, preset);
  publish(stagedMarker, marker);
  undo.length = 0;
  console.log(`DSH Tina files installed. Project: ${target}\nPreset: ${preset}\nOpen a new DSH Web session and verify the preset, skill sources, and role permissions before using the workflow.`);
} catch (error) {
  console.error(error.message);
  for (const rollback of undo.reverse()) {
    try { rollback(); } catch (failure) { console.error(`Rollback needs attention: ${failure.message}`); }
  }
  process.exitCode = 1;
} finally {
  rmSync(scratch, { recursive: true, force: true });
}
