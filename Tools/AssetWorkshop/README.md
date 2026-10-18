# Asset Workshop

A minimal, local art workshop for this ARPG. Requires Node.js 22+ and the official Codex CLI signed in with ChatGPT. No dependency installation is needed.

## Start

From the repository root:

```powershell
node Tools/AssetWorkshop/server.mjs
```

Open http://127.0.0.1:4319, or double-click `Start-Workshop.cmd`. The server binds only to this computer. Set `ASSET_WORKSHOP_PORT` if port 4319 is busy. An older workshop instance at port 4317 redirects to the updated interface. If Codex isn't on PATH, set `ASSET_WORKSHOP_CODEX` to its absolute executable path.

## Everyday workflow

1. **References:** add a moodboard or an approved asset. Click a reference to change its role (style, mood, or shape) or remove it. References are shared across asset types. You can also drag an image onto the board. Settings contains a picker for existing images in `GodotStarter/Art`.
2. **Style instructions:** expand once to describe the visual style. Changes save automatically and apply to subsequent assets across the project. Failed saves are displayed and unsaved edits trigger a warning when leaving.
3. **Describe your asset:** choose an asset type and describe what to make, then Generate. Each request makes one image at standard quality using your ChatGPT subscription through Codex.
4. **Review:** Refine reveals a correction field and uses the selected image plus your original references. Another version creates a fresh alternative. Keep saves a keeper to your collection and reveals Download PNG.
5. **Export:** Download uses the original asset type's dimensions. Expand Export options to choose another size or enable nearest-neighbor pixel-art downsampling. The complete source is fitted proportionally without cropping or stretching; existing transparency is preserved. This tool does not remove opaque backgrounds. An approved result can also be added to the reference board here.

History keeps every generated or imported image, including earlier versions. Filter to Kept to see your collection. To review existing art without generating, use History → Import image.

The main screen has no preset management, model selection, quality/batch controls, or API connection form. Existing presets and historical candidate records are preserved. On the first launch of the simplified interface, an existing preset with references supplies the project style board; otherwise the first preset supplies the initial style. New generation and import records snapshot the shared project style and reference board. Older records retain their original snapshots.

## Subscription connection

The header shows connection status. Open Settings if you need to reconnect; run `codex login` in a terminal, choose ChatGPT, then Check connection.

The official local Codex app-server owns authentication and token renewal. The workshop never reads your authentication token files. It verifies a ChatGPT login, strips API-key variables from the renderer environment, and uses built-in image generation in an ephemeral, read-only session. Shell, apps, plugins, hooks, browser use, and delegation are disabled for rendering. Only completed image results are accepted.

Images consume included Codex usage and can take several minutes. Quality and output resolution are managed by Codex; final dimensions are applied on export. Check usage before retrying a timeout. The interface always explicitly selects subscription mode and never falls back to API billing. The previous API adapter remains in the backend for compatibility, but is not used by this interface.

Official guidance: [Image generation and subscription usage](https://learn.chatgpt.com/docs/image-generation).

## Saved files

The ignored `data/` folder beside `server.mjs` contains:

- `workshop.json`: project style, reference assignments, presets, approvals, and generation history.
- `images/`: original generated images, uploaded references, and imports.
- `exports/`: downloaded PNGs and corresponding JSON generation records.

Back up the entire folder to preserve the library and its references. Exports remain separate from game assets until copied into your desired Unity/Godot directory. New exports can use different dimensions without changing the original generation record.

## Verify

```powershell
node --test Tools/AssetWorkshop/test/*.test.mjs
```

Tests use mock provider transports and real PNG fixtures, consuming no subscription usage or API credits. They cover sign-in checks, billing separation, generation/revision/reference flows, approvals, exports, persistence, workspace migration, and preservation of historical styles.
