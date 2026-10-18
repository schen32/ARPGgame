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
	var enemies: Array[Node2D] = []
	for angle in [-8.0, 0.0, 8.0]:
		var enemy = scene.get_node("Enemy") if angle == 0.0 else load("res://scenes/enemy.tscn").instantiate()
		if enemy.get_parent() == null:
			scene.add_child(enemy)
		enemy.position = Vector2.RIGHT.rotated(deg_to_rad(angle)) * 160.0
		enemy.set_physics_process(false)
		enemies.append(enemy)
	await physics_frame
	var shots = player.try_spread(Vector2(100, 0))
	check(shots.size() == 3, "Spread should fire exactly three projectiles")
	check(shots[0].direction.y < 0.0 and shots[1].direction == Vector2.RIGHT and shots[2].direction.y > 0.0, "Pellets should fan out around the aim direction")
	check(is_equal_approx(shots[0].direction.y, -shots[2].direction.y), "Spread should be symmetrical")
	check(player.try_spread(Vector2(100, 0)).is_empty(), "Spread cooldown should block repeated firing")
	check(get_nodes_in_group("shotgun_bursts").size() == 1, "Shotgun should emit particles only on successful use")
	var muzzle_burst = get_nodes_in_group("shotgun_bursts")[0]
	check(muzzle_burst.position.x > player.position.x and muzzle_burst.get_child_count() == 10, "Shotgun burst should emit ahead of the player")
	check(absf(rad_to_deg(shots[0].direction.angle())) < 10.0, "Shotgun spread should be tighter than ten degrees per side")
	var single = player.try_shoot(Vector2(0, -100))
	check(single != null, "Single shot should have an independent cooldown")
	single.queue_free()
	await create_timer(0.65).timeout
	check(get_nodes_in_group("shotgun_bursts").is_empty(), "Shotgun particles should clean up after fading")
	for enemy in enemies:
		check(enemy.health.current == 35.0, "Each pellet should hit and deal normal damage")
	# A short dash should travel exactly its configured distance without input.
	var start: Vector2 = player.position
	check(player.try_dash(Vector2.RIGHT), "Dash should activate")
	check(not player.try_dash(Vector2.UP), "Dash cooldown should block another dash")
	check(get_nodes_in_group("dash_bursts").size() == 1, "Dash should emit particles only on successful use")
	var dash_burst = get_nodes_in_group("dash_bursts")[0]
	check(dash_burst.position == player.position and dash_burst.velocities[0].x < 0.0, "Dash particles should scatter behind the player")
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
	player.spread_timer = 0.0
	check(player.try_spread(player.position).is_empty(), "Zero-length aim should not fire or consume cooldown")
	print("PASS: three-pellet spread, hits/damage, independent cooldowns, dash distance/wall collision, Space input, knockback immunity")
	quit()
