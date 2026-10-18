# ARPG Movement Starter

A basic top-down movement prototype with geometric assets and a slow chasing enemy.

## Godot (active prototype)

Open `GodotStarter/project.godot` in Godot 4.6 and press **F5**. On this machine, `GodotStarter/Open-Godot.cmd` also opens the editor with a writable local cache.

Move the blue square with **WASD** or the **arrow keys**. A red circle slowly follows the player directly and stops beside them. The camera follows the player over a simple grid. Diagonal input is normalized. Use code-drawn geometric shapes for prototype assets going forward.

Aim with the mouse and click or hold **left mouse** to shoot blue dots with a short cooldown. Shots travel straight, disappear on enemy contact, and knock the enemy back briefly before it resumes chasing.

**Right mouse** fires a tight three-shot spread with a 1.8-second cooldown. Shotgun and dash uses emit brief blue particle bursts. **Space** performs a short dash with a 1.2-second cooldown, following movement input or mouse aim when stationary. The three HUD slots show skill icons and independent gray cooldown masks.

The player is invincible during dash, which deals 25 damage to each enemy crossed once. Press **E** to toggle an 18-slot inventory; **Escape** or **X** also closes it.

Dash hits send enemies flying with stronger knockback. The inventory displays the equipped skill boxes above storage; drag and drop skills between these or the HUD slots to remap LMB, RMB, and Space. Occupied slots swap, and skill cooldowns are preserved.

Shape fill represents health and drains downward as damage is taken. The player has 100 HP; enemies have 60 HP. Projectiles deal 25 damage, and each new enemy contact costs the enemy 1 HP and deals 10 damage to the player (every 0.8 seconds during sustained contact). Enemies disappear at zero HP; player death automatically restarts the game.

A new red enemy spawns around the player every four seconds. Defeated enemies explode into red geometric particles that scatter and fade away.

The bottom HUD shows a draining circular HP gauge, three skill slots with LMB, RMB, and SPACE indicators, and an EXP bar. Enemies drop green orbs worth 25 EXP, collected when they reach the player. The base attraction radius is 2 meters (32 pixels), with the player's 16-pixel side representing 1 meter. Every 100 EXP increases the level. Player death resets progress and clears uncollected orbs.

See `GodotStarter/README.md` for details.

## Unity starter

The original minimal Unity starter is also retained. Open this folder in Unity 6, open `Assets/Scenes/Main.unity`, and press **Play**. Move the capsule with **WASD** or the **arrow keys**.

## Asset Workshop

`Tools/AssetWorkshop` remains available as a separate tool for future asset creation. Its previous local image library has been cleared from the repository.
