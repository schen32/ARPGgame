import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { deflateSync } from 'node:zlib';
import { createWorkshopServer } from '../server.mjs';
import { assemblePrompt, decodeImage, defaults, requestImages } from '../core.mjs';

// A real, decodable PNG fixture. No provider calls or paid generations in tests.
function png(width = 32, height = 32) {
  const crc = data => { let n = 0xffffffff; for (const byte of data) { n ^= byte; for (let i = 0; i < 8; i++) n = (n >>> 1) ^ ((n & 1) ? 0xedb88320 : 0); } return (n ^ 0xffffffff) >>> 0; };
  const chunk = (type, data) => { const head = Buffer.from(type), length = Buffer.alloc(4), checksum = Buffer.alloc(4); length.writeUInt32BE(data.length); checksum.writeUInt32BE(crc(Buffer.concat([head, data]))); return Buffer.concat([length, head, data, checksum]); };
  const header = Buffer.alloc(13); header.writeUInt32BE(width); header.writeUInt32BE(height, 4); header[8] = 8; header[9] = 6;
  const pixels = Buffer.alloc(height * (width * 4 + 1));
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) { const offset = y * (width * 4 + 1) + 1 + x * 4; pixels.set([120, 160, 75, x > 3 && x < width - 4 ? 255 : 0], offset); }
  return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk('IHDR', header), chunk('IDAT', deflateSync(pixels)), chunk('IEND', Buffer.alloc(0))]);
}
const fixture = png(), image = `data:image/png;base64,${fixture.toString('base64')}`;

async function workshop(t, options = {}) {
  const dataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'asset-workshop-test-'));
  const server = createWorkshopServer({ dataDir, apiKey: '', ...options });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  t.after(async () => { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); fs.rmSync(dataDir, { recursive: true, force: true }); });
  const initial = await (await fetch(`${base}/api/state`)).json();
  const post = async (route, body, headers = {}) => { const response = await fetch(`${base}/api/${route}`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-Workshop-Token': initial.token, ...headers }, body: JSON.stringify(route === 'generate' ? { provider: 'api', ...body } : body) }); return { status: response.status, body: await response.json() }; };
  return { dataDir, server, base, initial, post };
}

test('prompt maps references to roles and keeps revision changes explicit', () => {
  const prompt = assemblePrompt(defaults()[0], 'Iron axe', [{ name: 'Approved icon', role: 'style' }, { name: 'Sketch', role: 'composition' }], { instruction: 'Broaden the blade.' });
  assert.match(prompt, /Image 1 \(Approved icon\).*Rendering style/);
  assert.match(prompt, /Image 2 \(Sketch\).*Subject shape/);
  assert.match(prompt, /Image 3 is the candidate to revise/);
  assert.match(prompt, /Broaden the blade/);
});

test('provider uses JSON for fresh images and multipart for references', async () => {
  const calls = [];
  const fetchImpl = async (url, options) => { calls.push({ url, options }); return Response.json({ data: [{ b64_json: fixture.toString('base64') }] }); };
  const args = { apiKey: 'test-only-key', settings: { model: 'gpt-image-1.5', count: 2, quality: 'medium', background: 'transparent' }, prompt: 'Iron axe', fetchImpl };
  await requestImages({ ...args, images: [] });
  assert.match(calls[0].url, /generations$/);
  assert.equal(JSON.parse(calls[0].options.body).n, 2);
  await requestImages({ ...args, images: [{ bytes: fixture, mime: 'image/png', name: 'ref.png' }] });
  assert.match(calls[1].url, /edits$/);
  assert.equal(calls[1].options.body.getAll('image[]').length, 1);
  assert.equal(calls[1].options.body.get('input_fidelity'), 'high');
  await requestImages({ ...args, settings: { ...args.settings, model: 'gpt-image-2.5-flare' }, images: [{ bytes: fixture, mime: 'image/png', name: 'ref.png' }] });
  assert.equal(calls[2].options.body.has('input_fidelity'), false);
});

test('full workflow persists presets, generates with original references, revises, approves, and exports', async t => {
  const calls = [];
  const w = await workshop(t, { apiKey: 'test-only-key', fetchImpl: async (url, options) => { calls.push({ url, body: options.body }); return Response.json({ data: [{ b64_json: fixture.toString('base64') }], usage: { total_tokens: 42 } }); } });
  const preset = w.initial.presets[0];
  const saved = await w.post('presets', { ...preset, style: 'Muted green, dark outlines.', width: 32, height: 32 });
  assert.equal(saved.status, 200); assert.equal(saved.body.version, 2);
  const ref = await w.post('references', { presetId: preset.id, role: 'style', name: 'Approved original', dataUrl: image });
  assert.equal(ref.status, 200);
  const args = { presetId: preset.id, description: 'Iron axe', model: 'gpt-image-1.5', count: 1, quality: 'medium' };
  const generated = await w.post('generate', args);
  assert.equal(generated.status, 200);
  const candidate = generated.body.candidates[0];
  assert.equal(candidate.references[0].id, ref.body.id);
  assert.equal(candidate.presetSnapshot.version, 3);
  assert.equal(candidate.usage.total_tokens, 42);
  const revision = await w.post('generate', { ...args, parentId: candidate.id, instruction: 'Broaden the blade.' });
  assert.equal(revision.status, 200);
  assert.equal(calls[1].body.getAll('image[]').length, 2);
  assert.equal(revision.body.candidates[0].parentId, candidate.id);
  await w.post('presets', { ...saved.body, style: 'Different later direction.' });
  const state = await (await fetch(`${w.base}/api/state`)).json();
  assert.equal(state.candidates.find(c => c.id === candidate.id).presetSnapshot.style, 'Muted green, dark outlines.');
  assert.equal((await w.post('export', { id: candidate.id, dataUrl: image, width: 32, height: 32 })).status, 400);
  assert.equal((await w.post('candidates/approve', { id: candidate.id, approved: true })).status, 200);
  const exported = await w.post('export', { id: candidate.id, dataUrl: image, width: 32, height: 32, pixelated: true });
  assert.equal(exported.status, 200);
  const output = await fetch(`${w.base}${exported.body.image}`);
  assert.equal(output.headers.get('content-type'), 'image/png');
  assert.deepEqual(Buffer.from(await output.arrayBuffer()), fixture);
  const record = await (await fetch(`${w.base}${exported.body.metadata}`)).json();
  assert.equal(record.candidate.prompt, candidate.prompt);
  assert.equal(record.export.width, 32);
  assert.equal((await w.post('candidates/reference', { id: candidate.id, presetId: preset.id })).status, 200);
  assert.equal(JSON.parse(fs.readFileSync(path.join(w.dataDir, 'workshop.json'))).candidates.length, 2);
});

test('local import/review/export works without an API key; key is never persisted', async t => {
  const w = await workshop(t);
  const imported = await w.post('candidates/import', { presetId: w.initial.presets[0].id, description: 'Existing sword', dataUrl: image });
  assert.equal(imported.status, 200);
  assert.equal((await w.post('generate', { presetId: w.initial.presets[0].id, description: 'Sword', model: 'gpt-image-1.5', quality: 'low', count: 1 })).status, 409);
  await w.post('connection', { key: 'test-session-key-never-persist' });
  const state = await (await fetch(`${w.base}/api/state`)).json(); assert.equal(state.connected, true);
  assert.ok(!JSON.stringify(state).includes('test-session-key-never-persist'));
  assert.ok(!fs.readFileSync(path.join(w.dataDir, 'workshop.json'), 'utf8').includes('test-session-key-never-persist'));
  await w.post('connection', { clear: true });
  assert.equal((await (await fetch(`${w.base}/api/state`)).json()).connected, false);
  const reopened = createWorkshopServer({ dataDir: w.dataDir, apiKey: '' });
  await new Promise(resolve => reopened.listen(0, '127.0.0.1', resolve));
  const restored = await (await fetch(`http://127.0.0.1:${reopened.address().port}/api/state`)).json();
  assert.equal(restored.candidates[0].description, 'Existing sword');
  reopened.closeAllConnections(); await new Promise(resolve => reopened.close(resolve));
});

test('rejects external origins, missing mutation tokens, path traversal, invalid uploads/settings', async t => {
  const w = await workshop(t);
  assert.equal((await w.post('connection', { key: 'x' }, { Origin: 'https://external.example' })).status, 403);
  assert.equal((await w.post('connection', { key: 'x' }, { 'X-Workshop-Token': '' })).status, 403);
  assert.equal((await w.post('references/project', { presetId: w.initial.presets[0].id, role: 'style', path: '../../README.md' })).status, 400);
  assert.equal((await w.post('presets', { ...w.initial.presets[0], width: 0 })).status, 400);
  assert.equal((await w.post('references', { presetId: w.initial.presets[0].id, role: 'other', name: 'x', dataUrl: image })).status, 400);
  assert.equal((await w.post('references', { presetId: w.initial.presets[0].id, role: 'style', name: 'x', dataUrl: 'data:image/png;base64,aGVsbG8=' })).status, 400);
  assert.throws(() => decodeImage('data:image/svg+xml;base64,abcd'), /PNG, JPEG, or WebP/);
});

test('provider errors are actionable and never echo the key', async t => {
  const w = await workshop(t, { apiKey: 'test-secret', fetchImpl: async () => Response.json({ error: { message: 'Invalid test-secret key.' } }, { status: 401 }) });
  const result = await w.post('generate', { presetId: w.initial.presets[0].id, description: 'Sword', model: 'gpt-image-1.5', quality: 'low', count: 1 });
  assert.equal(result.status, 502); assert.match(result.body.error, /Invalid \[redacted\] key/);
  const state = await (await fetch(`${w.base}/api/state`)).json(); assert.equal(state.busy, false);
});

test('prevents overlapping generation charges while keeping state readable', async t => {
  let release, started;
  const ready = new Promise(resolve => started = resolve);
  const w = await workshop(t, { apiKey: 'test-only-key', fetchImpl: async () => { started(); await new Promise(resolve => release = resolve); return Response.json({ data: [{ b64_json: fixture.toString('base64') }] }); } });
  const args = { presetId: w.initial.presets[0].id, description: 'Sword', model: 'gpt-image-1.5', quality: 'low', count: 1 };
  const first = w.post('generate', args); await ready;
  assert.equal((await (await fetch(`${w.base}/api/state`)).json()).busy, true);
  const second = await w.post('generate', args); assert.equal(second.status, 409);
  release(); assert.equal((await first).status, 200);
});

test('subscription mode uses Codex, retains reference snapshots, and never calls the API transport', async t => {
  const calls = [];
  const w = await workshop(t, { apiKey: 'must-not-use', fetchImpl: () => { throw new Error('API transport must never be used'); }, subscriptionClient: {
    status: async () => ({ connected: true, plan: 'plus' }),
    generate: async input => { calls.push(input); return { data: [{ b64_json: fixture.toString('base64') }] }; }
  } });
  assert.equal(w.initial.provider, 'subscription');
  const status = await (await fetch(`${w.base}/api/subscription/status`)).json(); assert.equal(status.plan, 'plus');
  const presetId = w.initial.presets[0].id;
  await w.post('references', { presetId, role: 'style', name: 'Original style', dataUrl: image });
  const result = await w.post('generate', { provider: 'subscription', presetId, description: 'Iron axe', quality: 'low', count: 1 });
  assert.equal(result.status, 200);
  assert.equal(calls.length, 1); assert.equal(calls[0].images.length, 1);
  assert.equal(result.body.candidates[0].settings.provider, 'subscription');
  assert.match(result.body.candidates[0].settings.model, /Codex/);
  const choice = await w.post('provider', { provider: 'api' }); assert.equal(choice.body.provider, 'api');
  assert.equal((await w.post('provider', { provider: 'other' })).status, 400);
});

test('subscription failure cannot fall back to API billing', async t => {
  let apiCalls = 0;
  const w = await workshop(t, { apiKey: 'must-not-use', fetchImpl: () => { apiCalls++; }, subscriptionClient: {
    status: async () => ({ connected: false }), generate: async () => { throw new Error('Usage limit reached'); }
  } });
  const result = await w.post('generate', { provider: 'subscription', presetId: w.initial.presets[0].id, description: 'Sword', quality: 'low', count: 1 });
  assert.equal(result.status, 500); assert.equal(apiCalls, 0);
  assert.equal((await (await fetch(`${w.base}/api/state`)).json()).busy, false);
});

test('project style and reference board apply across asset types without changing historical records', async t => {
  const rendered = [];
  const w = await workshop(t, { subscriptionClient: {
    status: async () => ({connected:true,plan:'plus'}),
    generate: async input => { rendered.push(input); return {data:[{b64_json:fixture.toString('base64')}]}; }
  }});
  await w.post('workspace', {style:'Teal pixel art, dark outlines.'});
  const ref = await w.post('references', {useWorkspace:true,name:'Shared style',role:'style',dataUrl:image});
  assert.equal(ref.status, 200);
  const args = {provider:'subscription',useWorkspace:true,description:'Axe',quality:'medium',count:1};
  const first = await w.post('generate', {...args,presetId:w.initial.presets[0].id});
  const second = await w.post('generate', {...args,presetId:w.initial.presets[3].id});
  assert.equal(first.status, 200); assert.equal(second.status, 200);
  assert.equal(rendered[0].images.length, 1); assert.equal(rendered[1].images.length, 1);
  assert.match(rendered[1].prompt, /Teal pixel art/);
  assert.equal(second.body.candidates[0].references[0].id,ref.body.id);
  await w.post('references/role', {useWorkspace:true,referenceId:ref.body.id,role:'moodboard'});
  await w.post('workspace', {style:'Later art direction.'});
  const state = await (await fetch(`${w.base}/api/state`)).json();
  assert.equal(state.candidates.find(c=>c.id===first.body.candidates[0].id).references[0].role,'style');
  assert.equal(state.candidates.find(c=>c.id===first.body.candidates[0].id).presetSnapshot.style,'Teal pixel art, dark outlines.');
  assert.equal((await w.post('workspace',{style:''})).status,400);
  assert.equal((await w.post('references/role',{useWorkspace:true,referenceId:'missing',role:'style'})).status,400);
});

test('workspace migration preserves saved presets and picks an existing reference board', async t => {
  const w = await workshop(t);
  const saved = JSON.parse(fs.readFileSync(path.join(w.dataDir,'workshop.json')));
  delete saved.workspace;
  saved.presets[2].style='Existing portrait style';
  saved.presets[2].referenceIds=['existing-reference'];
  saved.references.push({id:'existing-reference',name:'Original reference',role:'style',file:'old.png',url:'/media/old.png',mime:'image/png'});
  fs.writeFileSync(path.join(w.dataDir,'workshop.json'),JSON.stringify(saved));
  const restarted=createWorkshopServer({dataDir:w.dataDir,apiKey:''});
  await new Promise(resolve=>restarted.listen(0,'127.0.0.1',resolve));
  try {
    const restored=await(await fetch(`http://127.0.0.1:${restarted.address().port}/api/state`)).json();
    assert.equal(restored.workspace.style,'Existing portrait style');
    assert.deepEqual(restored.workspace.referenceIds,['existing-reference']);
    assert.deepEqual(restored.presets,saved.presets);
  } finally {restarted.closeAllConnections();await new Promise(resolve=>restarted.close(resolve));}
});
