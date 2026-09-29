# ARPG Starter

A tiny Unity top-down movement prototype.

## Run it

1. Open this folder in Unity 6.3 LTS (or a compatible Unity 6 editor).
2. Open `Assets/Scenes/Main.unity` if it is not already open.
3. Press **Play** and move the capsule with **WASD** or the arrow keys.

The player moves on the ground plane at 5 units per second. Diagonal movement is normalized so it is not faster than straight movement. The scene currently creates its primitive arena and camera at runtime in `StarterScene.cs`.
