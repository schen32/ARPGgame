# Concept 8: blonde heroine

Drawn directly in Aseprite using integer pixel coordinates and a 26-color palette, plus transparency. Reference: `../female-hero-concepts-10.png`, second row, fourth character.

- `concept-08-blonde-32x32.aseprite`: 32x32 canvas, four static frames tagged **up, down, left, right**, with editable cloak, clothing, hair/face, and accessory layers.
- `concept-08-four-directions.aseprite`: all four directions side by side, with named 32x32 slices.
- `concept-08-four-directions.png`: transparent 128x32 sheet; columns are **up, down, left, right**.
- `concept-08-up.png`, `concept-08-down.png`, `concept-08-left.png`, `concept-08-right.png`: transparent 32x32 exports.
- `concept-08-preview.png`: 8x nearest-neighbor preview in the same direction order.

Frame/slice pivot: (16, 30). These are idle facing poses, not a walking animation. The right hand carries the small blue charm from the concept.

Rebuild through Aseprite's batch scripting with `../Scripts/draw-concept-08-32.lua`.
