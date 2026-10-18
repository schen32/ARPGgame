extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)

func run_checks() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("EnemySpawnTimer").stop()
	var player = scene.get_node("Player")
	player.set_physics_process(false)
	scene.get_node("Enemy").set_physics_process(false)
	var hud = scene.get_node("HUD/Interface")
	var inventory = hud.inventory
	check(inventory.slots.size() == 18 and not inventory.visible, "Inventory should start closed with 18 slots")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	inventory._input(key)
	check(inventory.visible and player.inventory_open, "E should open inventory")
	check(Rect2(Vector2.ZERO, hud.size).encloses(inventory.get_rect()), "Inventory must fit the visible screen")
	check(player.try_sweep(player.position + Vector2.RIGHT * 100.0) == null, "Inventory clicks must not sweep")
	check(player.try_palm(player.position + Vector2.RIGHT * 100.0) == null, "Inventory clicks must not use Heavy Palm")
	check(not player.try_dash(Vector2.RIGHT), "Space must not dash while inventory is open")
	key.echo = true
	inventory._input(key)
	check(inventory.visible, "Holding E must not repeatedly toggle inventory")
	key.echo = false
	inventory._input(key)
	check(not inventory.visible and not player.inventory_open, "E should close inventory")
	inventory.show()
	key.physical_keycode = KEY_ESCAPE
	inventory._input(key)
	check(not inventory.visible, "Escape should close inventory")
	check(player.try_sweep(player.position + Vector2.RIGHT * 100.0) != null, "Closing inventory should restore skill input")
	if "--capture" in OS.get_cmdline_user_args():
		inventory.show()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/inventory-preview.png")
	print("PASS: 18-slot inventory, E toggle, key repeat, Escape close, screen bounds, combat input blocking and recovery")
	quit()
