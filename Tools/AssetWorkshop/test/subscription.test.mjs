import { test } from 'node:test';
import assert from 'node:assert/strict';
import { subscriptionStatus, subscriptionImages, openCodex } from '../subscription.mjs';
import { EventEmitter } from 'node:events';
import { PassThrough } from 'node:stream';

function fakeCodex({ account = { type: 'chatgpt', planType: 'plus' }, failTurn = false, missingImage = false } = {}) {
  const requests = [], listeners = new Set(); let closed = false;
  return {
    requests, get closed() { return closed; }, notify() {}, close() { closed = true; },
    onNotification(fn) { listeners.add(fn); return () => listeners.delete(fn); },
    async request(method, params) {
      requests.push({ method, params });
      if (method === 'account/read') return { account };
      if (method === 'thread/start') return { thread: { id: 'test-render' } };
      if (method === 'turn/start') {
        if (!missingImage) for (const fn of listeners) fn({ method: 'item/completed', params: { threadId: 'test-render', item: { type: 'imageGeneration', status: 'completed', result: 'aW1hZ2U=', revisedPrompt: 'Revised art brief' } } });
        for (const fn of listeners) fn({ method: 'turn/completed', params: { threadId: 'test-render', turn: { status: failTurn ? 'failed' : 'completed', error: failTurn ? { message: 'Usage limit reached' } : null } } });
      }
      return {};
    }
  };
}

test('subscription status reads only the supported account RPC and hides email', async () => {
  const client = fakeCodex({ account: { type: 'chatgpt', planType: 'plus', email: 'private@example.test' } });
  assert.deepEqual(await subscriptionStatus({ open: () => client }), { connected: true, plan: 'plus' });
  assert.equal(client.closed, true);
  assert.ok(!client.requests.some(r => r.method === 'turn/start'));
});

test('API-key authentication is rejected before inference', async () => {
  const client = fakeCodex({ account: { type: 'apiKey' } });
  const result = await subscriptionStatus({ open: () => client });
  assert.equal(result.connected, false); assert.match(result.message, /will not use an API key/);
  assert.ok(!client.requests.some(r => r.method === 'turn/start'));
});

test('subscription generation sends original references and accepts only completed image events', async () => {
  const client = fakeCodex();
  const result = await subscriptionImages({ settings: { count: 2, quality: 'low' }, prompt: 'Iron axe', images: [{ mime: 'image/png', bytes: Buffer.from('reference') }], cwd: process.cwd(), open: () => client });
  assert.equal(result.data.length, 2);
  const start = client.requests.find(r => r.method === 'thread/start').params;
  assert.equal(start.ephemeral, true); assert.equal(start.sandbox, 'read-only');
  const turn = client.requests.find(r => r.method === 'turn/start').params;
  assert.equal(turn.input[1].url, 'data:image/png;base64,cmVmZXJlbmNl');
  assert.equal(client.closed, true);
});

test('subscription failure and image-less completion are not reported as success', async () => {
  for (const options of [{ failTurn: true }, { missingImage: true }]) {
    const client = fakeCodex(options);
    await assert.rejects(subscriptionImages({ settings: { count: 1, quality: 'low' }, prompt: 'Iron axe', images: [], cwd: process.cwd(), open: () => client }), /Usage limit|without producing an image/);
    assert.equal(client.closed, true);
  }
});

test('local Codex transport strips API credentials and denies tool approval requests', async () => {
  const child = new EventEmitter(); child.stdin = new PassThrough(); child.stdout = new PassThrough(); child.stderr = new PassThrough(); child.kill = () => {};
  let launch;
  const client = openCodex({ spawnImpl: (command, args, options) => { launch = { command, args, options }; return child; } });
  assert.equal(launch.options.windowsHide, true);
  assert.equal(launch.options.env.OPENAI_API_KEY, undefined);
  assert.ok(launch.args.includes('forced_login_method="chatgpt"'));
  assert.ok(launch.args.includes('shell_tool'));
  const request = client.request('account/read');
  child.stdout.write(JSON.stringify({ id: 1, result: { account: { type: 'chatgpt' } } }) + '\n');
  assert.equal((await request).account.type, 'chatgpt');
  client.close();
});
