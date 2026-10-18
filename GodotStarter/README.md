# ARPG Godot Starter

A tiny Godot 4 top-down action RPG movement sandbox with a four-direction 32 × 32 cleric character.

## Run

Double-click `Open-Godot.cmd`, then press **F6** to run the main scene or **F5** to run the project. The launcher gives Godot a writable cache in the repository's ignored `.godot-local` folder because the Windows Godot cache folder currently blocks user writes. The environment override applies only to this editor and its child processes.

Move with **WASD** or the **arrow keys**. The cleric uses the supplied `Art/Characters/ClericImported/cleric-directions.png` sheet: four 64 × 64 cells displayed at 32 × 32 with nearest-neighbor filtering. Order: front/right above back/left. Diagonal movement uses a cardinal facing (vertical on equal input). The camera follows the player through a simple grid test room, with the supplied `Art/UI/cleric-portrait-new.png` portrait in a compact bottom-left frame and the Moonlit Silver HUD along the bottom.

One goblin spawns every five seconds, starting five seconds after launch, at a random point 240 pixels from the player's current position. Goblins move directly toward the player at 65 pixels/second, use four 32 × 32 facing poses, and attack on contact for 8 damage every 0.8 seconds. Spawn timing is set on `GoblinSpawnTimer` in `scenes/main.tscn`; chase speed is exported by `scripts/goblin.gd`.

The Moonlit Silver HUD shows live health and mana orbs, enemy health bars, and a north-up local minimap. Cyan marks the player; red dots mark nearby goblins. The map covers 600 pixels in each horizontal direction. Press **Space** to cast a nova within 100 pixels (20 damage, 15 mana, 0.4-second cooldown); press **H** to heal 35 HP for 25 mana. Mana regenerates at 6 per second. At zero health the player returns to the origin with full resources and existing enemies are cleared. The compact portrait replaces the previous oversized portrait.

Run the HUD integration check: `godot --headless --path GodotStarter --script res://tests/hud_test.gd`. Run without `--headless` and add `-- --capture` to save an in-game review image in `output/ui-variants-2026-10-16`.

Run the enemy integration check with Godot: `godot --headless --path GodotStarter --script res://tests/goblin_test.gd`.
