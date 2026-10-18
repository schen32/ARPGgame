# Godot Movement Starter

An art-free Godot 4.6 top-down movement sandbox.

The logical play area uses a 640 by 360 reference size with integer scaling. Canvas items render at the window's resolution. Both characters use `scripts/prototype_shape.gd` and a shared signed-distance shader: circles and squares have solid fills, configurable borders, and about one screen pixel of edge smoothing regardless of zoom or window scale. Use this component for future prototype shapes instead of scaled primitive antialiasing.

Open `project.godot` and press **F5**, or use `Open-Godot.cmd` on the original development machine. If the launcher path does not match your Godot installation, open the project directly in Godot instead.

Move the blue square with **WASD** or the **arrow keys** at 180 pixels per second. Diagonal movement is normalized. The camera follows the player across a 4000 by 4000 grid floor.

One red circle starts near the player, and another spawns every four seconds at a random point 260 pixels from the player's current location. Each moves directly toward the player at 40 pixels per second, stops beside them, and resumes following when the player moves away. Spawn interval is set on `EnemySpawnTimer` in the main scene; radius is exported by `scripts/main.gd`. Enemy settings live in `scenes/enemy.tscn`. Player defeat resets the scene and starts a fresh four-second spawn cycle.

Aim with the mouse and **click or hold the left mouse button** to shoot a dot matching the player's blue fill and pale outline. Shots travel at 300 pixels per second in their original direction, with a 0.5-second cooldown. Hitting an enemy deals 25 damage, consumes the shot, and pushes the enemy away; chasing resumes after the 0.2-second knockback. Missed shots are cleaned up after 12 seconds. Shots ignore the player. Projectile movement uses swept collision to avoid skipping enemies at high speed.

The player starts with 100 HP and each enemy with 60 HP. Remaining health is shown by the shape's colored fill: it drains downward as HP falls, revealing the floor through the empty area while preserving the outline. Each new enemy contact also costs that enemy 1 HP and deals 10 damage to the player immediately; sustained contact repeats damage every 0.8 seconds. Enemies explode into 18 red geometric particles at zero HP; particles spread, shrink, fade, and clean themselves up after 0.55 seconds. At zero player HP, the game automatically restarts with full health, the initial enemy, and a fresh spawn timer. Health and damage values are adjustable in the Inspector.

Each new enemy contact immediately knocks the player away at an initial 320 pixels per second, slowing over 0.18 seconds. Separating and touching again always applies damage and knockback immediately. During sustained contact, damage repeats on a 0.8-second cooldown and the push is not restarted every frame. Steering returns progressively as the push fades, with full movement restored in the frame knockback ends. Enemies blend back into chasing the same way after projectile hits. Aiming and shooting remain available during knockback. Player knockback speed and duration are adjustable on the Player node.

The scene is `scenes/main.tscn`. Player movement is in `scripts/player.gd`, pursuit is in `scripts/enemy.gd`, health pools are in `scripts/health.gd`, death particles are in `scripts/death_burst.gd`, the HUD is in `scripts/hud.gd`, and the floor is drawn by `scripts/floor.gd`. Use code-drawn geometric shapes for prototype assets going forward. There are no imported textures.

The bottom-center geometric HUD floats directly over the game without a background panel. It has a 44-pixel blue circular health gauge, three compact 22-pixel outline slots with transparent backgrounds and no numbers, and a thin green EXP semicircle around the right half of the HP gauge, filling clockwise from top to bottom. HP and EXP have no text or numbers; skill slots have no plus signs. The circle drains downward with player HP. The first slot holds the blue-dot projectile skill. A translucent gray overlay recedes downward during each skill cooldown and disappears when ready. The slots show LMB, RMB, and SPACE indicators beneath them, respectively. LMB fires a single projectile (0.5-second cooldown). RMB fires a three-shot spread at -8, 0, and +8 degrees around the mouse aim (1.8-second cooldown). Space dashes 48 pixels, or three player-widths, over 0.12 seconds (1.2-second cooldown). Dash follows movement input, or mouse aim when stationary. Dash respects solid world geometry, makes the player invincible to damage and knockback for its duration, and deals 25 damage plus strong knockback (650 pixels/second initially, decaying over 0.35 seconds) to each crossed enemy once per dash. Shotgun use emits a short directional burst of blue particles at the muzzle; dash use leaves a small backward burst of blue fragments. Both effects fade and clean themselves up. Each skill has its own icon and independently draining gray cooldown overlay. Enemy deaths drop a green orb worth 25 EXP; EXP is awarded only when the orb reaches the player. Every 100 EXP increases the level and carries remaining EXP forward, without changing combat stats. Death resets level, EXP, and uncollected orbs along with the rest of the game. The HUD stays fixed while the camera moves and passes mouse input through to aiming/shooting.

World scale: the player's 16-pixel side is 1 meter. The player starts with a 2-meter (32-pixel) EXP attraction radius, measured from their center. Orbs remain on the floor outside this radius. Once attracted they follow the player at 240 pixels per second, including if the player moves away, and disappear on collection. Adjust `exp_attract_range_meters` on the Player node to change the base range. Orb visuals use the same geometric shape shader as the actors. Orbs and the EXP arc share the same green palette color. Collection emits eight small green particles at the player that spread, shrink, and fade over 0.3 seconds.

Red circles collide with each other while chasing or being knocked back. Spawning checks for a clear position, trying a wider ring when crowded, so new enemies do not appear inside existing ones.

Player and enemy bodies use floating top-down motion with platform carrying disabled, so contact from above cannot attach an enemy to the player's knockback movement.

Press **E** to toggle the inventory: three equipped skill boxes above 18 storage slots arranged in six columns and three rows. Drag skills between storage, the equipped row, and the HUD skill boxes while the inventory is open. Dropping onto an occupied slot swaps the skills; canceled drops leave the loadout intact. LMB, RMB, and Space activate whichever skill is equipped in the corresponding position; empty slots do nothing. Cooldowns follow the ability and cannot be reset by rearranging it. Close with **E**, **Escape**, or **X**. Skills cannot activate while the inventory is open; movement and the world continue. Restart restores the default three skills and empty storage.

Headless startup check:

```powershell
godot --headless --path GodotStarter --quit-after 5
```

Projectile integration check:

```powershell
godot --headless --path GodotStarter --script res://tests/projectile_test.gd
godot --headless --path GodotStarter --script res://tests/health_test.gd
godot --headless --path GodotStarter --script res://tests/spawn_test.gd
godot --headless --path GodotStarter --script res://tests/contact_knockback_test.gd
godot --headless --path GodotStarter --script res://tests/restart_test.gd
godot --headless --path GodotStarter --script res://tests/enemy_collision_test.gd
godot --headless --path GodotStarter --script res://tests/ui_test.gd
godot --headless --path GodotStarter --script res://tests/experience_orb_test.gd
godot --headless --path GodotStarter --script res://tests/skills_test.gd
godot --headless --path GodotStarter --script res://tests/dash_combat_test.gd
godot --headless --path GodotStarter --script res://tests/inventory_test.gd
godot --headless --path GodotStarter --script res://tests/top_down_contact_test.gd
```

The loadout drag-and-drop integration check uses a rendered Godot window:

```powershell
godot --path GodotStarter --script res://tests/loadout_test.gd
```
