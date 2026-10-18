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
	scene.get_node("EnemySpawnTimer").stop()
	await physics_frame
	var player = scene.get_node("Player")
	player.set_physics_process(false)
	scene.get_node("Enemy").set_physics_process(false)
	scene.get_node("Enemy").position = Vector2(300, 0)
	var palm = player.try_palm(Vector2(100, 0))
	check(palm != null and not palm.resolved, "Palm should start its windup")
	check(player.try_palm(Vector2(100, 0)) == null, "Palm cooldown must block repeated use")
	check(player.try_sweep(Vector2(0, -100)) != null, "Sweep should have an independent cooldown")
	await create_timer(0.4).timeout
	check(get_nodes_in_group("melee_attacks").is_empty(), "Melee effects should clean up after fading")
	# A short dash should travel exactly its configured distance without input.
	var start: Vector2 = player.position
	check(player.try_dash(Vector2.RIGHT), "Dash should activate")
	check(not player.try_dash(Vector2.UP), "Dash cooldown should block another dash")
	check(get_nodes_in_group("dash_trails").size() == 1, "Only a successful dash should create an afterimage trail")
	for frame in range(15):
		await physics_frame
		player._physics_process(1.0 / 60.0)
	var expected_distance: float = player.dash_speed * player.dash_duration
	check(absf(player.position.x - start.x - expected_distance) < 0.2, "Dash should travel its configured short distance")
	check(player.dash_timer == 0.0 and player.velocity == Vector2.ZERO, "Dash should end and restore normal movement")
	# Dash uses swept CharacterBody movement and must not cross solid geometry.
	var wall := StaticBody2D.new()
	wall.position = player.position + Vector2(24, 0)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(4, 100)
	collision.shape = rectangle
	wall.add_child(collision)
	scene.add_child(wall)
	await physics_frame
	player.dash_cooldown_timer = 0.0
	check(player.try_dash(Vector2.RIGHT), "Dash should activate after cooldown reset")
	for frame in range(15):
		await physics_frame
		player._physics_process(1.0 / 60.0)
	check(player.position.x <= wall.position.x - 9.8, "Dash must not pass through walls")
	# Space should choose the held movement direction and ignore key repeats.
	player.dash_cooldown_timer = 0.0
	Input.action_press("move_up")
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	player._unhandled_key_input(space)
	Input.action_release("move_up")
	check(player.dash_direction == Vector2.UP, "Space dash should follow movement input")
	player.apply_knockback(Vector2.LEFT)
	check(player.dash_timer > 0.0 and player.knockback_timer == 0.0, "Dash should ignore enemy knockback")
	player.palm_timer = 0.0
	check(player.try_palm(player.position) == null, "Zero-length aim should not attack or consume cooldown")
	# Allow one-shot audio playback to drain before engine shutdown.
	await create_timer(0.3).timeout
	print("PASS: melee windup, independent cooldowns, effect cleanup, dash distance/wall collision, Space input, knockback immunity")
	quit()
