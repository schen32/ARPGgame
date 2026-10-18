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
	await physics_frame
	var player = scene.get_node("Player")
	var enemy = scene.get_node("Enemy")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	check(player.health.current == 100.0 and enemy.health.current == 60.0, "Health should start full")
	enemy.position = Vector2(20, 0)
	enemy._physics_process(0.01)
	check(player.health.current == 90.0, "Enemy contact should damage player")
	enemy._physics_process(0.01)
	check(player.health.current == 90.0, "Contact cooldown must prevent damage every frame")
	check(enemy.health.current == 59.0, "New contact should cost enemy 1 HP, with no repeated cost while touching")
	check(player.knockback_velocity.x < 0.0, "Contact must knock the player away from the enemy")
	var contact_position: Vector2 = player.position
	Input.action_press("move_right")
	player._physics_process(0.05)
	check(player.position.x < contact_position.x, "Knockback must move player away even against movement input")
	player._physics_process(0.2)
	player._physics_process(0.016)
	check(player.velocity.x > 0.0, "Movement control must return after knockback")
	# Repeated hits must blend back into movement without a stationary final tick.
	enemy.position = Vector2(100, 0)
	for hit in range(3):
		player.apply_knockback(Vector2.LEFT)
		player._physics_process(1.0 / 60.0)
		check(player.velocity.x < 0.0, "Each consecutive impact should still push the player")
		player.knockback_timer = 0.000001
		player.knockback_velocity = Vector2.ZERO
		player._physics_process(1.0 / 60.0)
		check(player.velocity.x > player.move_speed * 0.99, "Player must regain movement in the frame knockback ends")
	enemy.apply_knockback(Vector2.RIGHT)
	enemy.knockback_timer = 0.000001
	enemy.knockback_velocity = Vector2.ZERO
	enemy._physics_process(1.0 / 60.0)
	check(enemy.velocity.x < 0.0, "Enemy must resume chasing in the frame knockback ends")
	Input.action_release("move_right")
	player.take_damage(40.0)
	enemy.take_damage(29.0)
	check(player.get_node("Geometry").fill_ratio == 0.5, "Player fill should match health")
	check(enemy.get_node("Geometry").fill_ratio == 0.5, "Enemy fill should match health")
	var material = enemy.get_node("Geometry").surface.material
	check(material.get_shader_parameter("fill_ratio") == 0.5, "Health should reach shader")
	enemy.take_damage(-20.0)
	check(enemy.health.current == 30.0, "Negative damage must not heal")
	if "--capture" in OS.get_cmdline_user_args():
		enemy.position = Vector2(40, 0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/health-preview.png")
	player.take_damage(1000.0)
	check(player.health.current == 0.0, "Health must clamp at zero")
	check(player.get_node("Geometry").fill_ratio == 0.0, "Dead player should be an empty outline")
	player._physics_process(0.1)
	check(player.velocity == Vector2.ZERO, "Dead player must stop moving")
	check(player.try_sweep(Vector2(100, 0)) == null, "Dead player must stop attacking")
	enemy._physics_process(1.0)
	check(enemy.velocity == Vector2.ZERO, "Enemy must stop chasing a dead player")
	enemy.take_damage(1000.0)
	check(enemy.is_queued_for_deletion(), "Enemy should disappear at zero HP")
	if "--capture" in OS.get_cmdline_user_args():
		await create_timer(0.12).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/death-burst-preview.png")
	print("PASS: health, contact damage/cooldown, player knockback and control recovery, fill updates, player defeat, enemy death")
	quit()
