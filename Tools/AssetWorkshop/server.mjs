import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomUUID, timingSafeEqual } from 'node:crypto';
import fs from 'node:fs';
import { defaults, roles, models, fail, textField, dimension, decodeImage, assemblePrompt, requestImages, slug } from './core.mjs';
import { subscriptionStatus, subscriptionImages } from './subscription.mjs';

const root = path.dirname(fileURLToPath(import.meta.url));
const projectArt = path.resolve(root, '../../GodotStarter/Art');
const types = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp', '.json': 'application/json' };
const sameSecret = (a, b) => typeof a === 'string' && a.length === b.length && timingSafeEqual(Buffer.from(a), Buffer.from(b));

export function createWorkshopServer({ dataDir = path.join(root, 'data'), apiKey = process.env.OPENAI_API_KEY || '', fetchImpl = fetch, subscriptionClient = { status: subscriptionStatus, generate: subscriptionImages } } = {}) {
  for (const folder of ['', 'images', 'exports']) fs.mkdirSync(path.join(dataDir, folder), { recursive: true });
  const statePath = path.join(dataDir, 'workshop.json');
  let state = fs.existsSync(statePath) ? JSON.parse(fs.readFileSync(statePath, 'utf8')) : { presets: defaults(), references: [], candidates: [] };
  if (!state.workspace) {
    const source = state.presets.find(p => p.referenceIds.length) || state.presets[0];
    state.workspace = { style: source.style, referenceIds: [...source.referenceIds], version: 1 };
  }
  let sessionKey = apiKey, busy = false;
  const token = randomUUID();
  const save = () => { fs.writeFileSync(`${statePath}.tmp`, JSON.stringify(state, null, 2)); fs.renameSync(`${statePath}.tmp`, statePath); };
  save();
  const getPreset = id => state.presets.find(x => x.id === id) || fail('Preset not found.', 404);
  const getCandidate = id => state.candidates.find(x => x.id === id) || fail('Candidate not found.', 404);
  const getReferences = preset => preset.referenceIds.map(id => state.references.find(r => r.id === id) || fail('A saved reference is missing.'));
  function storeImage(dataUrl) {
    const image = decodeImage(dataUrl), file = `${randomUUID()}.${image.ext}`;
    fs.writeFileSync(path.join(dataDir, 'images', file), image.bytes);
    return { file, mime: image.mime, url: `/media/${file}` };
  }
  function addReference(input, preset) {
    if (!roles.includes(input.role)) fail('Invalid reference role.');
    const name = textField(input.name, 'Reference name', 150);
    if (preset.referenceIds.length >= 6) fail('Use at most six references per preset.');
    const ref = { id: randomUUID(), name, role: input.role, ...storeImage(input.dataUrl) };
    state.references.push(ref); preset.referenceIds.push(ref.id); preset.version++; save();
    return ref;
  }
  const readImage = r => ({ name: r.file, mime: r.mime, bytes: fs.readFileSync(path.join(dataDir, 'images', r.file)) });
  const json = (res, value, status = 200) => { res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(value)); };
  const serve = (res, target) => {
    if (!fs.existsSync(target) || !fs.statSync(target).isFile()) fail('File not found.', 404);
    res.writeHead(200, { 'Content-Type': types[path.extname(target)] || 'application/octet-stream', 'Cache-Control': 'no-cache', 'X-Content-Type-Options': 'nosniff' });
    fs.createReadStream(target).pipe(res);
  };
  const publicState = () => ({ ...state, provider: state.provider || 'subscription', connected: Boolean(sessionKey), busy, token, models });
  const server = http.createServer(async (req, res) => {
    try {
      const host = req.headers.host || '';
      if (!/^(127\.0\.0\.1|localhost):\d+$/.test(host)) fail('Use the local workshop address.', 403);
      if (req.headers.origin && ![`http://${host}`, `http://localhost:${server.address().port}`, `http://127.0.0.1:${server.address().port}`].includes(req.headers.origin)) fail('Cross-origin requests are not allowed.', 403);
      res.setHeader('Referrer-Policy', 'no-referrer');
      res.setHeader('Content-Security-Policy', "default-src 'self'; img-src 'self' data: blob:; style-src 'self'; script-src 'self'; connect-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'none'");
      const url = new URL(req.url, `http://${host}`), route = url.pathname;
      if (req.method === 'GET') {
        if (route === '/api/state') return json(res, publicState());
        if (route === '/api/subscription/status') return json(res, await subscriptionClient.status());
        if (route === '/api/project-images') {
          const files = [];
          const walk = dir => { if (!fs.existsSync(dir)) return; for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
            const full = path.join(dir, entry.name);
            if (entry.isDirectory()) walk(full);
            else if (entry.isFile() && /\.(png|jpe?g|webp)$/i.test(entry.name)) files.push({ path: path.relative(projectArt, full).split(path.sep).join('/'), name: entry.name });
          } };
          walk(projectArt); return json(res, files);
        }
        if (route.startsWith('/media/')) {
          const file = route.slice(7); if (!/^[a-zA-Z0-9-]+\.(png|jpg|webp)$/.test(file)) fail('Invalid file.');
          return serve(res, path.join(dataDir, 'images', file));
        }
        if (route.startsWith('/exports/')) {
          const file = route.slice(9); if (!/^[a-zA-Z0-9-]+\.(png|json)$/.test(file)) fail('Invalid file.');
          res.setHeader('Content-Disposition', `attachment; filename="${file}"`); return serve(res, path.join(dataDir, 'exports', file));
        }
        const files = { '/': 'index.html', '/app.js': 'app.js', '/style.css': 'style.css' };
        if (files[route]) return serve(res, path.join(root, 'public', files[route]));
        fail('Not found.', 404);
      }
      if (req.method !== 'POST') fail('Method not allowed.', 405);
      if (!sameSecret(req.headers['x-workshop-token'], token)) fail('Refresh the workshop before making changes.', 403);
      if (!req.headers['content-type']?.startsWith('application/json')) fail('Expected JSON.', 415);
      const chunks = []; let size = 0;
      for await (const chunk of req) { size += chunk.length; if (size > 22 * 1024 * 1024) fail('Upload is too large.', 413); chunks.push(chunk); }
      let input; try { input = JSON.parse(Buffer.concat(chunks).toString()); } catch { fail('Invalid JSON.'); }
      if (!input || typeof input !== 'object' || Array.isArray(input)) fail('Expected an object.');
      if (route === '/api/provider') {
        if (!['subscription', 'api'].includes(input.provider)) fail('Invalid generation provider.');
        state.provider = input.provider; save(); return json(res, { provider: state.provider });
      }
      if (route === '/api/connection') {
        if (input.clear) sessionKey = apiKey;
        else sessionKey = textField(input.key, 'API key', 500);
        return json(res, { connected: Boolean(sessionKey) });
      }
      if (route === '/api/workspace') {
        state.workspace.style = textField(input.style, 'Style instructions');
        state.workspace.version++; save(); return json(res, state.workspace);
      }
      if (route === '/api/presets') {
        const existing = input.id ? getPreset(input.id) : null;
        const source = !existing && input.sourcePresetId ? getPreset(input.sourcePresetId) : null;
        const preset = { id: existing?.id || randomUUID(), name: textField(input.name, 'Preset name', 100), style: textField(input.style, 'Art direction'), framing: textField(input.framing, 'Framing'), width: dimension(input.width), height: dimension(input.height), pixelated: Boolean(input.pixelated), background: input.background === 'opaque' ? 'opaque' : 'transparent', version: (existing?.version || 0) + 1, referenceIds: [...(existing?.referenceIds || source?.referenceIds || [])] };
        if (existing) state.presets[state.presets.indexOf(existing)] = preset; else state.presets.push(preset);
        save(); return json(res, preset);
      }
      const referenceBoard = () => input.useWorkspace ? state.workspace : getPreset(input.presetId);
      if (route === '/api/references') return json(res, addReference(input, referenceBoard()));
      if (route === '/api/references/project') {
        if (typeof input.path !== 'string' || input.path.includes('..') || !/\.(png|jpe?g|webp)$/i.test(input.path)) fail('Invalid project image.');
        const full = path.resolve(projectArt, input.path);
        if (!full.startsWith(projectArt + path.sep) || !fs.existsSync(full) || !fs.realpathSync(full).startsWith(fs.realpathSync(projectArt) + path.sep)) fail('Project image not found.');
        const ext = path.extname(full).toLowerCase(), mime = types[ext];
        return json(res, addReference({ ...input, name: path.basename(full), dataUrl: `data:${mime};base64,${fs.readFileSync(full).toString('base64')}` }, referenceBoard()));
      }
      if (route === '/api/references/role') {
        const board = referenceBoard();
        if (!roles.includes(input.role) || !board.referenceIds.includes(input.referenceId)) fail('Invalid reference.');
        const ref = state.references.find(r => r.id === input.referenceId); ref.role = input.role;
        board.version++; save(); return json(res, ref);
      }
      if (route === '/api/references/detach') {
        const preset = referenceBoard(); preset.referenceIds = preset.referenceIds.filter(id => id !== input.referenceId); preset.version++; save(); return json(res, preset);
      }
      if (route === '/api/prompt' || route === '/api/generate') {
        const preset = structuredClone(getPreset(input.presetId));
        if (input.useWorkspace) Object.assign(preset, { style: state.workspace.style, referenceIds: [...state.workspace.referenceIds], version: `${preset.version}.${state.workspace.version}`, workspaceVersion: state.workspace.version });
        const description = textField(input.description, 'Asset description', 3000);
        const refs = getReferences(preset);
        const parent = input.parentId ? getCandidate(input.parentId) : null;
        const instruction = parent ? textField(input.instruction, 'Correction', 2000) : '';
        const prompt = assemblePrompt(preset, description, refs, parent ? { instruction } : null);
        if (route === '/api/prompt') return json(res, { prompt });
        if (busy) fail('A generation is already running. Wait for it to finish.', 409);
        const provider = input.provider || state.provider || 'subscription';
        if (!['subscription', 'api'].includes(provider) || (provider === 'api' && !models.includes(input.model)) || !['low', 'medium', 'high'].includes(input.quality) || !Number.isInteger(input.count) || input.count < 1 || input.count > 4) fail('Invalid generation settings.');
        const images = refs.map(readImage); if (parent) images.push(readImage(parent));
        const settings = { provider, model: provider === 'subscription' ? 'Codex built-in image generation' : input.model, quality: input.quality, count: input.count, background: preset.background };
        busy = true;
        try {
          const result = provider === 'subscription'
            ? await subscriptionClient.generate({ settings, prompt, images, cwd: path.resolve(dataDir) })
            : await requestImages({ apiKey: sessionKey, settings, prompt, images, fetchImpl });
          const batchId = randomUUID(), createdAt = new Date().toISOString();
          const candidates = result.data.map(item => ({ id: randomUUID(), batchId, description, presetId: preset.id, presetSnapshot: preset, references: structuredClone(refs), settings, prompt, parentId: parent?.id || null, instruction, createdAt, approved: false, usage: result.usage || null, revisedPrompt: item.revised_prompt || null, ...storeImage(`data:image/png;base64,${item.b64_json}`) }));
          state.candidates.unshift(...candidates); save(); return json(res, { candidates, warning: result.warning || null });
        } finally { busy = false; }
      }
      if (route === '/api/candidates/import') {
        const preset = structuredClone(getPreset(input.presetId));
        if (input.useWorkspace) Object.assign(preset, { style: state.workspace.style, referenceIds: [...state.workspace.referenceIds], version: `${preset.version}.${state.workspace.version}`, workspaceVersion: state.workspace.version });
        const candidate = { id: randomUUID(), description: textField(input.description, 'Asset name', 3000), presetId: preset.id, presetSnapshot: preset, references: structuredClone(getReferences(preset)), prompt: 'Imported for local review.', settings: { source: 'import' }, createdAt: new Date().toISOString(), approved: false, ...storeImage(input.dataUrl) };
        state.candidates.unshift(candidate); save(); return json(res, candidate);
      }
      if (route === '/api/candidates/approve') {
        const c = getCandidate(input.id); c.approved = Boolean(input.approved); save(); return json(res, c);
      }
      if (route === '/api/candidates/reference') {
        const c = getCandidate(input.id); if (!c.approved) fail('Approve the candidate before using it as a style reference.');
        return json(res, addReference({ name: c.description.slice(0, 150), role: 'style', dataUrl: `data:${c.mime};base64,${readImage(c).bytes.toString('base64')}` }, referenceBoard()));
      }
      if (route === '/api/export') {
        const c = getCandidate(input.id); if (!c.approved) fail('Approve this candidate before exporting.');
        const image = decodeImage(input.dataUrl); if (image.ext !== 'png') fail('Exports must be PNG.');
        const width = dimension(input.width), height = dimension(input.height);
        if (image.bytes.readUInt32BE(16) !== width || image.bytes.readUInt32BE(20) !== height) fail('Export image dimensions do not match.');
        const name = `${slug(c.description)}-${width}x${height}-${randomUUID().slice(0, 8)}`;
        fs.writeFileSync(path.join(dataDir, 'exports', `${name}.png`), image.bytes);
        fs.writeFileSync(path.join(dataDir, 'exports', `${name}.json`), JSON.stringify({ candidate: c, export: { width, height, pixelated: Boolean(input.pixelated), createdAt: new Date().toISOString() } }, null, 2));
        return json(res, { image: `/exports/${name}.png`, metadata: `/exports/${name}.json`, name });
      }
      fail('Not found.', 404);
    } catch (e) { if (!res.headersSent) json(res, { error: e.status ? e.message : 'The workshop could not complete this request. Check local disk access and try again.' }, e.status || 500); else res.end(); }
  });
  server.requestTimeout = 660000;
  return server;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const server = createWorkshopServer();
  const port = Number(process.env.ASSET_WORKSHOP_PORT || 4319);
  server.listen(port, '127.0.0.1', () => console.log(`Asset Workshop: http://127.0.0.1:${port}`));
  server.on('error', error => { console.error(error.code === 'EADDRINUSE' ? `Port ${port} is busy. Set ASSET_WORKSHOP_PORT to another port.` : error.message); process.exitCode = 1; });
}
