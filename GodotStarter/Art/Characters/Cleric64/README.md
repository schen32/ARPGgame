# Cleric — native 64 × 64 pixel art

Created directly in Aseprite from Simon's supplied blonde, white-and-blue cleric reference, using the included Lua drawing script. No AI image generation or downsampling was used for these sprites.

- `cleric-64-four-directions.aseprite`: 64 × 64 canvas, four tagged static frames: front, right, back, left.
- Six editable layers: hair behind, boots/legs, robes/goldwork, face/hair, headdress, staff/hands.
- `cleric-64-front.png`, `cleric-64-right.png`, `cleric-64-back.png`, `cleric-64-left.png`: transparent 64 × 64 exports.
- `cleric-64-sheet.png`: transparent 128 × 128 sheet, front/right above back/left.
- `cleric-64-preview.png`: 6× nearest-neighbor presentation preview on a dark background. This is not a game-resolution sprite.
- `source-reference.png`: supplied visual reference.

The original four frames are facing directions, not a walk cycle. The left profile mirrors the right profile and remains independently editable in Aseprite.

## Eight-direction game version

- `cleric-64-eight-directions.aseprite`: eight tagged 64 × 64 static poses and six editable layers.
- `cleric-64-eight-directions.png`: transparent 256 × 128 game sheet. Top row: front, right, back, left. Bottom row: front-right, back-right, back-left, front-left.
- Four new individual transparent PNGs: `cleric-64-front-right.png`, `cleric-64-back-right.png`, `cleric-64-back-left.png`, `cleric-64-front-left.png`.
- `cleric-64-eight-directions-preview.png`: enlarged preview only.
- `draw-cleric-eight.lua`: Aseprite batch script to reproduce the full layered project and exports. Diagonals use newly drawn three-quarter silhouettes; left diagonals mirror the corresponding right diagonals.

The Godot player uses the eight-direction sheet at native size with nearest-neighbor filtering, selects the closest of eight facings during movement, and keeps its last facing when idle. The sprite is anchored at the feet above the existing body collision. These are static facing poses, not animated walk cycles. The original four-direction project and sheet are preserved.

`draw-cleric.lua` contains the native-resolution pixel drawing operations and layered export logic. To rebuild, run it with Aseprite's batch scripting support. It writes the filenames above.
