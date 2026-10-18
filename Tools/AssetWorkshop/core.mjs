export const roles = ['style', 'moodboard', 'composition'];
export const models = ['gpt-image-1.5', 'gpt-image-2.5-sunburst', 'gpt-image-2.5-flare'];

export function defaults() {
  return ['Inventory icon', 'Ability icon', 'Portrait', 'Environment prop', 'Enemy sprite'].map((name, i) => ({
    id: `preset-${i + 1}`, name, version: 1, referenceIds: [],
    style: 'Stylized fantasy ARPG. Clear silhouettes, restrained palette, consistent upper-left lighting. Define your palette, outlines, shading, and materials here before generating a collection.',
    framing: [
      'One complete item, centered, three-quarter view, generous padding. Recognizable at 64 pixels. No text, border, or extra objects.',
      'One strong symbolic composition, readable at 64 pixels. No lettering or UI border.',
      'Head and shoulders, three-quarter view, consistent eye level and portrait crop. No lettering.',
      'One complete prop, three-quarter top-down view. No ground plane or scenery. Consistent perspective.',
      'One complete character, three-quarter top-down view, neutral standing pose. Keep feet and all equipment visible. No scenery.'
    ][i],
    width: i === 2 ? 256 : i === 4 ? 128 : 64,
    height: i === 2 ? 256 : i === 4 ? 128 : 64,
    pixelated: false, background: 'transparent'
  }));
}

export function fail(message, status = 400) { const e = new Error(message); e.status = status; throw e; }
export function slug(value) { return String(value).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 70) || 'asset'; }
export function textField(value, name, max = 8000) {
  if (typeof value !== 'string' || !value.trim() || value.length > max) fail(`${name} is required (maximum ${max} characters).`);
  return value.trim();
}
export function dimension(value) {
  const n = Number(value);
  if (!Number.isInteger(n) || n < 16 || n > 2048) fail('Export dimensions must be integers from 16 to 2048.');
  return n;
}
export function decodeImage(dataUrl) {
  const m = /^data:image\/(png|jpeg|webp);base64,([A-Za-z0-9+/=]+)$/.exec(dataUrl || '');
  if (!m) fail('Choose a PNG, JPEG, or WebP image.');
  const bytes = Buffer.from(m[2], 'base64');
  if (bytes.length > 15 * 1024 * 1024) fail('Images must be 15 MB or smaller.');
  const png = bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]));
  const jpeg = bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
  const webp = bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP';
  if (!(m[1] === 'png' && png || m[1] === 'jpeg' && jpeg || m[1] === 'webp' && webp)) fail('Image contents do not match the file type.');
  if (png && (bytes.length < 33 || bytes.toString('ascii', 12, 16) !== 'IHDR' || bytes.readUInt32BE(16) < 1 || bytes.readUInt32BE(20) < 1)) fail('Invalid PNG image header.');
  return { bytes, mime: `image/${m[1]}`, ext: m[1] === 'jpeg' ? 'jpg' : m[1] };
}
export function assemblePrompt(preset, description, references, revision) {
  const purpose = { style: 'Rendering style: match palette, outlines, shading, materials, and detail level. Do not copy its subject.', moodboard: 'Overall visual direction and atmosphere. Do not reproduce the collage or layout.', composition: 'Subject shape, pose, and composition only. Render it in the approved style.' };
  return [
    `Create a game asset: ${description}.`,
    `ASSET TYPE: ${preset.name}. STYLE VERSION: ${preset.version}.`,
    `ART DIRECTION:\n${preset.style}`,
    `FRAMING:\n${preset.framing}`,
    `DELIVERY: ${preset.background === 'transparent' ? 'Isolate on a fully transparent background.' : 'Use an opaque background.'} Final display size ${preset.width} x ${preset.height} pixels. Prioritize readability at that size.`,
    ...references.map((r, i) => `Image ${i + 1} (${r.name}): ${purpose[r.role]}`),
    ...(revision ? [`Image ${references.length + 1} is the candidate to revise. Preserve its subject and all details not explicitly changed. Keep matching the original style references. Requested correction: ${revision.instruction}`] : [])
  ].join('\n\n');
}

export async function requestImages({ apiKey, settings, prompt, images, fetchImpl = fetch }) {
  if (!apiKey) fail('Add an OpenAI API key in Connection to generate images. Local review and exports work without one.', 409);
  const values = { model: settings.model, prompt, n: settings.count, size: '1024x1024', quality: settings.quality, background: settings.background, output_format: 'png' };
  const headers = { Authorization: `Bearer ${apiKey}` };
  let body;
  if (images.length) {
    body = new FormData();
    for (const [key, value] of Object.entries(values)) body.append(key, String(value));
    if (settings.model === 'gpt-image-1.5') body.append('input_fidelity', 'high');
    for (const img of images) body.append('image[]', new Blob([img.bytes], { type: img.mime }), img.name);
  } else {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(values);
  }
  let response;
  try {
    response = await fetchImpl(`https://api.openai.com/v1/images/${images.length ? 'edits' : 'generations'}`, { method: 'POST', headers, body, signal: AbortSignal.timeout(600000) });
  } catch { fail('The image service did not respond. Check your connection. A timed-out request may still incur a charge; check your API usage before retrying.', 502); }
  const result = await response.json().catch(() => ({}));
  if (!response.ok) {
    const detail = String(result.error?.message || `Image API returned ${response.status}`).replaceAll(apiKey, '[redacted]');
    fail(detail, 502);
  }
  if (!result.data?.length || result.data.some(x => !x.b64_json)) fail('The image service returned no image data.', 502);
  return result;
}
