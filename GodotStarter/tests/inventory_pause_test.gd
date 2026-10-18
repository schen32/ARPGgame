extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func press(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run_checks() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var player = scene.get_node("Player")
	var enemy = scene.get_node("Enemy")
	var hud = scene.get_node("HUD/Interface")
	var inventory = hud.inventory
	var spawn = scene.get_node("EnemySpawnTimer")
	enemy.target = null
	enemy.apply_knockback(Vector2.RIGHT, 150, 0.5)
	player.sweep_timer = 0.4
	var palm = player.try_palm(player.global_position + Vector2(100, 0))
	var orb = load("res://scenes/experience_orb.tscn").instantiate()
	orb.target = player
	orb.position = player.position + Vector2(25, 0)
	scene.add_child(orb)
	press(KEY_E)
	await process_frame
	check(paused and inventory.visible and player.inventory_open, "E must pause the world and open inventory")
	check(inventory.can_process() and hud.slots[0].can_process(), "Inventory and HUD slots must remain interactive while paused")
	var positions := [player.position, enemy.position, orb.position]
	var cooldown: float = player.sweep_timer
	var spawn_time: float = spawn.time_left
	var launch_time: float = enemy.knockback_timer
	Input.action_press("move_right")
	await create_timer(0.2, true).timeout
	check([player.position, enemy.position, orb.position] == positions, "Player, enemies and EXP orbs must freeze with inventory open")
	check(player.sweep_timer == cooldown and enemy.knockback_timer == launch_time, "Cooldown and knockback timers must freeze")
	check(spawn.time_left == spawn_time, "Enemy spawning must pause")
	check(not palm.resolved and palm.age == 0.0, "Attack windup must not resolve during inventory pause")
	check(player.move_skill("equipped", 0, "inventory", 0), "Skills must still move between slots while paused")
	press(KEY_ESCAPE)
	await create_timer(0.15, true).timeout
	check(not paused and not inventory.visible, "Escape must close inventory and unpause")
	check(player.position.x > positions[0].x and enemy.position != positions[1], "Movement and knockback must resume")
	check(player.sweep_timer < cooldown and spawn.time_left < spawn_time, "Cooldowns and spawning must resume")
	Input.action_release("move_right")
	press(KEY_E)
	await process_frame
	check(paused, "E must reopen inventory after resuming")
	var close = inventory.find_children("*", "Button", false, false)[0]
	close.pressed.emit()
	check(not paused and not inventory.visible, "Close button must resume the world")
	paused = true
	inventory.show()
	inventory.hide()
	check(paused, "Closing inventory must preserve a pause it did not own")
	paused = false
	inventory.show()
	scene.free()
	check(not paused, "Removing an open inventory must not leave the next scene paused")
	await create_timer(0.25, true).timeout
	print("PASS: inventory pauses world, attacks, movement, cooldowns and spawns; UI remains active; E/Escape/X resume; teardown releases pause")
	quit()
