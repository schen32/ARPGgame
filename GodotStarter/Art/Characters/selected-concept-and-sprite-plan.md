# Selected protagonist concept

Selected: **Concept 8** (row 2, column 4, reading left to right). This is the blonde female healer/adventurer in a blue mantle, cream outfit, and small charm.

The complete generated comparison sheet is saved as `female-hero-concepts-10.png`. Use concept 8 as the Aseprite reference. The image is a visual concept sheet, not an exact 32x32 sprite sheet.

## Aseprite production plan

### Pass 1: movement prototype
- Canvas: 32x32 pixels per frame, transparent background.
- Facing views: 4 — front/down, back/up, left, and right. Keep diagonals as movement directions but face the nearest cardinal view at first.
- Idle: 2 frames per view (8 frames).
- Walk: 6 frames per view (24 frames).
- Pass 1 total: 32 frames.

### Pass 2: combat readability
- Attack: 5 frames per view (20 frames).
- Hurt: 2 frames per view (8 frames).
- Dodge: 4 frames per view (16 frames).
- Pass 2 adds: 44 frames; cumulative total: 76.

### Optional later
- Cast: 5 frames per view (20 frames).
- Defeat: 4 frames, front view only.
- Add diagonal facing views only if combat aiming needs them; that expands the directional art from 4 views to 8.

### Eight-direction 64x64 static redraw

- Editable tagged Aseprite source: `Hero64EightDirections/hero-64-8-directions.aseprite`.
- Eight 64x64 static facings, clockwise from up, based on the references in `Concept08References8/`.
- Transparent per-direction PNGs plus a transparent 256x128 overview sheet in `Hero64EightDirections/`.
- Shared ground pivot at (32, 59). One reference pose per direction; no movement animation.

Keep the head, mantle, charm, and long blonde hair readable at 32x32. The hair and mantle need a clear silhouette in side and back views.

## Completed static facing sprites

### 64x64 experiment

- Editable source: `Hero64/hero-64-facing-views.aseprite`.
- Four 64x64 views, redrawn at the larger size on one 256x64 sheet, ordered down, up, left, right.
- One static frame; no animations.
- Named layers and slices for each direction. Slice pivots are at (32, 59).
- Character silhouette is approximately 52 pixels tall.
- Transparent individual exports: `Hero64/hero-64-down.png`, `Hero64/hero-64-up.png`, `Hero64/hero-64-left.png`, `Hero64/hero-64-right.png`.
- Combined export: `Hero64/hero-64-facing-views.png`.
- The five Alabaster Dawn screenshots are saved in `Art/References/AlabasterDawn/`.

### Current 32x32 sprites with plain faces

- Editable source: `Hero/hero-facing-views.aseprite`.
- Eyes and facial-detail pixels are replaced with the base skin color in the front and side views.
- Earlier source with facial details: `Hero/hero-facing-views-with-features.aseprite`.
- One static frame on a 128x32 canvas, containing four 32x32 views in this order: down, up, left, right.
- Each view has its own named layer and slice. Slice pivots are at (16, 29).
- Transparent exports: `Hero/hero-down.png`, `Hero/hero-up.png`, `Hero/hero-left.png`, and `Hero/hero-right.png`.
- Combined export: `Hero/hero-facing-views.png`.
- No animation frames have been added.
