# Godot Prototype Lab

F5 starts Tower Defense. Press **backtick (`)** to cycle between Tower Defense and ARPG, including while menus pause gameplay. Switching starts a fresh run. Add future scenes to `scripts/prototype_switcher.gd`.

Tower Defense uses a separate copy of the ARPG's geometric combat. There is no player-controlled character, inventory, or passive menu. Red enemies follow the winding green corridor from the top entrance to the bottom exit. Solid walls and 38-pixel gaps leave room for towers between path sections.

Select **Strike** in the right-side tower palette (or press **1**), then **left-click** clear ground to place a square tower for **40 gold**. Start with **120 gold**. The preview is blue for valid placement and red for blocked placement. Placement cannot overlap paths or existing towers, and invalid placement never spends gold. **Right-click** or **Escape** cancels selection; **R** restarts the run. The palette shows the current balance and disables unaffordable towers.

Towers automatically use a 100-degree Strike every 0.4 seconds at nearby enemies (48-pixel reach, 4 direct damage, 330 knockback impulse). Knockback wall slams deal heavy momentum-based damage once per launch; ordinary and glancing contacts cause no damage. Kills award **10 gold** for regular enemies, **20 gold** for large splitters, and **5 gold** for each small split enemy, including wall and collision kills. Escaped enemies award nothing. Currency is awarded immediately; there are no player EXP pickups or HP/skill HUD.

Its scenes, scripts, and shaders are isolated in `prototypes/tower_defense/`; audio assets are shared. Run `godot --headless --fixed-fps 60 --path GodotStarter --script res://tests/tower_defense_test.gd` to check placement, economy, combat, path traversal, restart, and switching.

## ARPG

The ARPG scene remains `scenes/main.tscn` for direct scene runs and existing tests.

An art-free Godot 4.6 top-down movement sandbox.

The logical play area uses a 640 by 360 reference size with integer scaling. Canvas items render at the window's resolution. Both characters use `scripts/prototype_shape.gd` and a shared signed-distance shader: circles and squares have solid fills, configurable borders, and about one screen pixel of edge smoothing regardless of zoom or window scale. Use this component for future prototype shapes instead of scaled primitive antialiasing.

Open `project.godot` and press **F5**, or use `Open-Godot.cmd` on the original development machine. If the launcher path does not match your Godot installation, open the project directly in Godot instead.

Move the blue square with **WASD** or the **arrow keys** at 180 pixels per second. Diagonal movement is normalized. The camera follows the player across a 4000 by 4000 grid floor.

One red circle starts near the player, and another spawns every two seconds at a random point 260 pixels from the player's current location. At full health each moves directly toward the player at 40 pixels per second, stops beside them, and resumes following when the player moves away. Spawn interval is set on `EnemySpawnTimer` in the main scene; radius is exported by `scripts/main.gd`. Enemy settings live in `scenes/enemy.tscn`. Every fourth timed spawn (eight seconds at the default cadence) is a large splitter: a 36px-diameter red enemy with 120 HP, twice the base mass, 32px/s base speed and 15 base contact damage. When killed, it splits into exactly four 12px-diameter enemies with 20 HP, 48px/s base speed and 5 base contact damage. The smaller enemies chase the player, drop 10 EXP each, and never split again. The parent drops its usual 25 EXP. Offspring placement is deferred until the hit callback ends and searches for space clear of other enemies, the player and walls. Melee, dash, spawn spacing, and hit particles account for each enemy size. Player defeat resets the scene, spawn cadence, and offspring, and starts a fresh two-second spawn cycle.

Aim with the mouse and click or hold **LMB** for Sweeping Strike: a 100-degree arc with 2.25m (36px) reach, 4 direct damage, moderate 330 launch force, and a 0.4-second cooldown. It hits each enemy once and pushes the group in the aimed direction. **RMB** uses Heavy Palm: a broader 2.7m (43.2px) strike with a 16px-wide lane with a 0.15-second windup, 6 direct damage, strong 975 launch force, and a 1-second cooldown. Palm selects the nearest enemy along its lane. Reach describes the rendered attack shape; collision checks add a 3px forgiving margin beyond it, including the sweep edges and palm lane. Enemy circles can intersect this expanded edge. Both attacks respect solid walls and use the existing mass and impact-chain system. Direct damage softens enemies so collision damage can do most of the work.

Attack effects use analytic distance shaders with a single screen-pixel antialiasing fringe, so curves and diagonal strokes remain sharp at any window scale. A blue arc marks the sweep. Palm shows a narrow blue windup indicator that flashes on release. Aim is captured when an attack begins; both attack shapes remain centered on the player throughout windup and the 0.18-second active effect, checking for hits as the player moves. Each attack damages a given enemy only once; the palm can strike only one enemy per use. Successful melee and dash hits emit eight tiny blue-white particles at the enemy contact edge. They spread, shrink, fade and clean up after 0.22 seconds, including on lethal hits.

The player starts with 100 HP and each enemy with 60 HP. Remaining health is shown by the shape's colored fill: it drains downward as HP falls, revealing the floor through the empty area while preserving the outline. Each new enemy contact also costs that enemy 1 HP and deals up to 10 damage to the player immediately; sustained contact repeats damage every 0.8 seconds. Enemies explode into 18 red geometric particles at zero HP; particles spread, shrink, fade, and clean themselves up after 0.55 seconds. At zero player HP, the game automatically restarts with full health, the initial enemy, and a fresh spawn timer. Health and damage values are adjustable in the Inspector.

Each new enemy contact immediately knocks the player away at an initial 320 pixels per second, slowing over 0.18 seconds. Separating and touching again always applies damage and knockback immediately. During sustained contact, damage repeats on a 0.8-second cooldown and the push is not restarted every frame. Steering returns progressively as the push fades, with full movement restored in the frame knockback ends. Enemies resume chasing when their launch motion ends; chase steering is disabled during the launch so it cannot add energy to an impact. Aiming and attacking remain available during knockback. Player knockback speed and duration are adjustable on the Player node. Actual player damage immediately flashes the cube pale with a red outline for 0.22 seconds, pulses the HP gauge, and shows a red screen-edge vignette that fades over 0.32 seconds. The effects preserve the health fill and do not block input or grant extra invincibility. Repeated hits refresh the notification; blocked dash hits and zero damage do not trigger it.

The scene is `scenes/main.tscn`. Player movement is in `scripts/player.gd`, pursuit is in `scripts/enemy.gd`, health pools are in `scripts/health.gd`, death particles are in `scripts/death_burst.gd`, the HUD is in `scripts/hud.gd`, and the floor is drawn by `scripts/floor.gd`. Use code-drawn geometric shapes for prototype assets going forward. There are no imported textures.

The bottom-center geometric HUD floats directly over the game without a background panel. It has a 44-pixel blue circular health gauge, three compact 22-pixel outline slots with transparent backgrounds and no numbers, and a thin green EXP semicircle around the right half of the HP gauge, filling clockwise from top to bottom. HP and EXP have no text or numbers; skill slots have no plus signs. The circle drains downward with player HP. The first slot holds Sweeping Strike; the second holds Heavy Palm. A translucent gray overlay recedes downward during each skill cooldown and disappears when ready. The slots show LMB, RMB, and SPACE indicators beneath them, respectively. LMB sweeps (0.4-second cooldown). RMB uses Heavy Palm (1-second cooldown). Space dashes 80 pixels, or five player-widths (5m), over 0.2 seconds (1.2-second cooldown). Dash follows movement input, or mouse aim when stationary. Dash respects solid world geometry, makes the player invincible to damage and knockback for its duration, and deals 8 damage plus strong knockback (975 pixels/second initially, decaying over 0.35 seconds) to each crossed enemy once per dash. A pale blue aura follows the player for the full dash, marking its contact area (17px enemy-center reach for a regular enemy); damage checks adjust for each enemy size. The aura disappears when dash invincibility ends. The dash visual is a single thin ring plus up to three faint square afterimages along the actual traveled path. Each afterimage fades within 0.1 seconds; blocked movement never paints a false trail beyond a wall. A short original whoosh plays once when dash activates, with slight pitch variation. Rejected dash attempts are silent. The skill icons use simple analytic glyphs: an arc for sweep, an arrow meeting a bar for palm, and two chevrons for dash. Their edges are smoothed over one display pixel rather than scaling a bitmap or primitive antialiasing fringe. The same sharp icons appear in the HUD, inventory and drag previews. Each skill has its own independently draining gray cooldown overlay. Enemy deaths drop a green orb worth 25 EXP; EXP is awarded only when the orb reaches the player. Every 100 EXP increases the level, grants one passive-tree point, and carries remaining EXP forward. Stats change when points are spent. Death resets level, EXP, passive points and ranks, and uncollected orbs along with the rest of the game. The HUD stays fixed while the camera moves and passes mouse input through to aiming/attacking.

World scale: the player's 16-pixel side is 1 meter. The player starts with Attract EXP equipped in the first of three passive slots. It grants a 2-meter (32-pixel) EXP attraction radius, measured from their center. Drag the passive into storage to disable attraction immediately, including for already-homing orbs. Without it, orbs remain still and are collected when the player square physically overlaps them. Re-equipping restores attraction. Orbs remain on the floor outside this radius. Once attracted they follow the player at 240 pixels per second, including if the player moves away, and disappear on collection. Adjust `exp_attract_range_meters` on the Player node to change the base range. Orb visuals use the same geometric shape shader as the actors. Orbs and the EXP arc share the same green palette color. Collection emits eight small green particles at the player that spread, shrink, and fade over 0.3 seconds.

Red circles collide with each other while chasing or being knocked back. Spawning checks for a clear position, trying a wider ring when crowded, so new enemies do not appear inside existing ones.

Player and enemy bodies use floating top-down motion with platform carrying disabled, so contact from above cannot attach an enemy to the player's knockback movement.

Press **E** to toggle the inventory: three active skill boxes and three passive skill boxes above 18 storage slots arranged in six columns and three rows. Drag skills between storage, the equipped row, and the HUD skill boxes while the inventory is open. Dropping onto an occupied slot swaps the skills; canceled drops leave the loadout intact. LMB, RMB, and Space activate whichever skill is equipped in the corresponding position; empty slots do nothing. Cooldowns follow the ability and cannot be reset by rearranging it. Close with **E**, **Escape**, or **X**. Opening inventory pauses the world: movement, enemy spawning, attacks, knockback, EXP orbs and cooldowns freeze. Inventory hover, drag-and-drop, and E/Escape/X remain active. Closing resumes from the same state. Active skills fit only active equipment slots; Attract EXP fits only passive equipment slots. Both can be stored and rearranged through the same drag-and-drop inventory. Hovering any part of a skill box immediately shows a compact, wrapped card with a single opaque background, anchored beside the slot. Moving within the box keeps the card visible. The card shows its name, skill type, description, current stats including Force for all three active skills, and equip/unequip hint. Icons and cooldown masks pass hover through to the full slot. HUD tooltips also work with the inventory closed while preserving gameplay input. The HUD shows three small passive slots above the active skills, with a green magnet icon for Attract EXP. Restart restores the default three active skills, Attract EXP, and empty inventory storage.

Enemy health also controls weight: mass scales from 1.0 at full HP to 0.45 near empty, movement rises from 40 toward 64 pixels per second, and contact damage falls from 10 toward 4. Launch speed is divided by current mass, so softening a target makes it easier to throw into a crowd. These stats are always derived from the base settings.

Launched enemies striking other enemies above 30 pixels per second of normal closing speed trigger impact chains. Attacks apply an impulse: change in velocity = impulse / mass, using mass immediately before contact damage. Further attacks add their impulse to existing launch motion. Strike, Palm and Dash deal only 4, 6 and 8 direct damage. Enemy collisions resolve an impulse using both pre-hit masses, relative normal velocity, and restitution 0.55. Damage to each body equals mass times contact acceleration times 0.003, where contact acceleration is the impact change in velocity over a fixed 0.05-second contact interval. This makes damage independent of the physics frame rate. For example, two full-health regular enemies colliding at 400 pixels/second deal 18.6 damage to each other. Heavier enemies at the same speed hit harder; the same attack impulse launches heavier enemies more slowly. Collision response preserves tangential motion and momentum and dissipates kinetic energy; HP loss cannot amplify the same collision impulse. Amber sparks mark each impact. A shared history limits a chain to eight bodies and prevents the same enemy from being hit again by that chain. Resting collisions do not cause chain damage.

Strike plays an original airy swipe on release; Palm plays an original heavier thump after its windup, including on misses. Rejected uses are silent. Regenerate these samples with `python Tools/generate_melee_sfx.py`. Successful melee and dash hits also play a short billiard cue-style click. Enemy-to-enemy contacts play a fuller ball clack whose volume scales with closing speed; low-speed resting contact is silent. Contacts are deduplicated across both bodies and across sustained touching. Six original synthesized WAV samples provide three variations per sound family, with small runtime pitch variation. Playback is positional, uses a reusable 12-voice pool with per-frame crowd caps, and routes through a limited `ImpactSFX` bus. Adjust `volume_db` on the `ImpactAudio` node for overall impact volume. Samples and rebuild instructions are in `audio/impacts`. Collecting EXP plays a soft, original two-tone chime, with slight pitch variation and a cap on simultaneous pickups. Rebuild it with `python Tools/generate_exp_sfx.py`.

Press **T** or click **T / PASSIVES** to open the passive tree. It pauses gameplay just like inventory. E switches to inventory; T switches back; Escape or X closes the current menu. The HUD shows available points. The tree presents only branch names, node names and ranks. Bonuses, rank details and unlock requirements appear in a single compact card only while hovering any part of a node, including locked nodes. Leaving the node or closing the tree hides the card. Each level after level 1 awards exactly one point, including multiple levels earned from a single pickup. Progression is local to the current run and resets on death.

The tree has four branches with three 3-rank nodes and one 1-rank capstone each. Spend 3, 6, and 9 points within a branch to unlock its later tiers. Every rank costs one point. Branches can be mixed freely. Free respec refunds all spent points; increasing max HP does not heal, and respeccing cannot restore HP. Bonuses are derived from unchanged base values and remain separate from the three passive equipment slots.

| Branch | Node | Bonus |
| --- | --- | --- |
| Force | Heavy Hands | +8% attack impulse/rank, for all attacks. |
| Force | Follow Through | +10% force/rank against already launched enemies. |
| Force | Giant Killer | +12% force/rank against large enemies. |
| Force | Wrecking Ball | Launched large enemies deal +30% collision damage. |
| Chains | Hard Knocks | +8% collision damage/rank. |
| Chains | Carry Through | +0.05 collision restitution/rank (base 0.55). |
| Chains | Fresh Target | +10% collision damage/rank against enemies not already in knockback. |
| Chains | Domino Effect | +10% damage per previous collision, capped at +50%. |
| Control | Extended Reach | +5% melee reach/width and dash contact area/rank. |
| Control | Driving Force | +8% enemy knockback duration/rank, preserving initial launch speed. |
| Control | Stagger | 0.1s/rank without chasing or contact attacks after knockback ends. |
| Control | Crowd Breaker | +20% force while at least three living enemies are within 3m. |
| Survival | Vitality | +10% maximum HP/rank. |
| Survival | Quick Recovery | Player knockback duration reduced by 10%/rank. |
| Survival | Second Wind | Heal 1 HP/rank for each enemy killed by a player-attributed collision. |
| Survival | Last Stand | 25% damage reduction at or below 30% HP. |

Force and damage bonuses add within their respective multipliers. Enemy collision chains retain their initiating player for bonuses and kill credit, including when the launched source dies. Resting contacts, direct kills and duplicate lethal callbacks cannot trigger Second Wind. Extended Reach changes attack visuals with collision bounds, and skill tooltips include upgraded reach and unconditional/current crowd force; target-specific bonuses depend on the enemy struck.

Headless startup check:

```powershell
godot --headless --path GodotStarter --quit-after 5
```

Combat integration checks:

```powershell
godot --headless --path GodotStarter --script res://tests/passive_tree_test.gd
godot --headless --path GodotStarter --script res://tests/force_combat_test.gd
godot --headless --path GodotStarter --script res://tests/mechanics_test.gd
godot --headless --path GodotStarter --script res://tests/passive_skills_test.gd
godot --headless --path GodotStarter --script res://tests/split_enemy_test.gd
godot --headless --path GodotStarter --script res://tests/dash_presentation_test.gd
godot --headless --path GodotStarter --script res://tests/player_feedback_test.gd
godot --headless --path GodotStarter --script res://tests/attack_feedback_test.gd
godot --headless --path GodotStarter --script res://tests/impact_audio_test.gd
godot --headless --path GodotStarter --script res://tests/melee_test.gd
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
godot --headless --path GodotStarter --script res://tests/inventory_pause_test.gd
godot --headless --path GodotStarter --script res://tests/top_down_contact_test.gd
```

The loadout drag-and-drop integration check uses a rendered Godot window:

```powershell
godot --path GodotStarter --script res://tests/loadout_test.gd
godot --path GodotStarter --script res://tests/skill_tree_ui_test.gd
```
