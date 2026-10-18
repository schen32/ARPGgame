# Cleric — native 32 × 32 pixel art

Redrawn directly on 32 × 32 canvases in Aseprite from the supplied reference. Details are simplified at native resolution rather than shrinking the 64 × 64 sprites.

- `cleric-32-four-directions.aseprite`: four tagged static frames: front, right, back, left; six editable layers.
- `cleric-32-front.png`, `cleric-32-right.png`, `cleric-32-back.png`, `cleric-32-left.png`: individual transparent 32 × 32 PNGs.
- `cleric-32-sheet.png`: transparent 64 × 64 sheet; front/right on top, back/left below.
- `cleric-32-preview.png`: 8× nearest-neighbor display preview only.
- `draw-cleric-32.lua`: reproducible native Aseprite drawing and export script.
- `source-reference.png`: supplied reference.

Left mirrors right. These are static directional poses, not walk animation frames. This asset set is separate from the existing 64 × 64 game character.
