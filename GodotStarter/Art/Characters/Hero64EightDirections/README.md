# Concept 8 heroine: eight 64x64 directions

An editable Aseprite redraw based on the eight references in `../Concept08References8/` and the earlier four-direction 64x64 experiment.

- `hero-64-8-directions.aseprite`: an editable 64x64 canvas with eight tagged static frames, clockwise from up. The `hero-ground-pivot` slice uses pivot (32, 59).
- `hero-64-8-directions-sheet.aseprite`: editable 256x128 overview, laid out 4 columns by 2 rows, with eight named slices and pivot (32, 59) in each cell.
- `hero-64-8-directions-sheet.png`: transparent 256x128 spritesheet, row-major order: up, up-right, right, down-right, down, down-left, left, up-left.
- `hero-64-up.png`, `hero-64-up-right.png`, `hero-64-right.png`, `hero-64-down-right.png`, `hero-64-down.png`, `hero-64-down-left.png`, `hero-64-left.png`, `hero-64-up-left.png`: separate transparent 64x64 exports.
- `hero-64-8-directions-preview.png`: nearest-neighbor 6x preview of the 4x2 sheet.

These are single static facings, not walk-cycle animations. The source script `../Scripts/draw-hero-64-8dir.lua` recreates the files through Aseprite batch mode.
