# Game Prototype Lab

Open `GodotStarter/project.godot` in Godot 4.6 and press **F5**. On this machine, `GodotStarter/Open-Godot.cmd` opens the editor with a writable local cache.

Press **backtick (`)** to cycle between Tower Defense and ARPG, including while an ARPG menu is paused. Switching starts a fresh run. Add future scene entries to `GodotStarter/scripts/prototype_switcher.gd`.

## Tower defense

Tower Defense uses a separate copy of the ARPG's geometric combat. There is no player-controlled character, inventory, or passive menu. Red enemies follow the winding green corridor from the top entrance to the bottom exit. Solid walls and 38-pixel gaps leave room for towers between path sections.

Select **Strike** in the right-side tower palette (or press **1**), then **left-click** clear ground to place a square tower for **40 gold**. Start with **120 gold**. The preview is blue for valid placement and red for blocked placement. Placement cannot overlap paths or existing towers, and invalid placement never spends gold. **Right-click** or **Escape** cancels selection; **R** restarts the run. The palette shows the current balance and disables unaffordable towers.

Towers automatically use a 100-degree Strike every 0.4 seconds at nearby enemies (48-pixel reach, 4 direct damage, 330 knockback impulse). Knockback wall slams deal heavy momentum-based damage once per launch; ordinary and glancing contacts cause no damage. Kills award **10 gold** for regular enemies, **20 gold** for large splitters, and **5 gold** for each small split enemy, including wall and collision kills. Escaped enemies award nothing. Currency is awarded immediately; there are no player EXP pickups or HP/skill HUD.

The copied scenes, scripts, and shaders are isolated in `GodotStarter/prototypes/tower_defense/` so future changes can be made independently of the ARPG. Audio assets are shared. The entry scene is `scenes/main.tscn` within that directory.

Run the arena and switching integration check with:

```powershell
godot --headless --fixed-fps 60 --path GodotStarter --script res://tests/tower_defense_test.gd
```

## ARPG

Move with **WASD** or the **arrow keys**, aim with the mouse, use **LMB** for Sweeping Strike, **RMB** for Heavy Palm, and **Space** to dash. **E** opens inventory; **T** opens the passive tree. Defeat enemies, collect EXP, and spend passive points. Player death restarts the ARPG run.

See `GodotStarter/README.md` for combat, loadouts, passive progression, and test instructions. The original scene remains `GodotStarter/scenes/main.tscn`.

## Unity starter

The original minimal Unity starter is retained. Open this folder in Unity 6, open `Assets/Scenes/Main.unity`, and press **Play**. Move the capsule with **WASD** or the **arrow keys**.

## Asset Workshop

`Tools/AssetWorkshop` remains available as a separate tool for future asset creation. Its previous local image library has been cleared from the repository.
