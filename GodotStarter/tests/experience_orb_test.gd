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
	var enemy = scene.get_node("Enemy")
	enemy.position = Vector2(80, 0)
	enemy.take_damage(1000.0)
	enemy.take_damage(1000.0)
	check(get_nodes_in_group("experience_orbs").size() == 1, "Enemy death should drop exactly one orb")
	var orb = get_nodes_in_group("experience_orbs")[0]
	var exp_display = scene.get_node("HUD/Interface").exp_bar
	check(orb.get_node("Geometry").fill_color == exp_display.surface.material.get_shader_parameter("fill_color"), "Orb green should match EXP arc exactly")
	orb.set_physics_process(false)
	check(orb.position == enemy.position and orb.experience_value == 25, "Orb must drop at death position with enemy EXP reward")
	check(player.get_exp_attract_radius() == 32.0, "Two-meter radius must equal twice the 16-pixel player width")
	orb.position = Vector2(32.1, 0)
	orb._physics_process(0.1)
	check(not orb.attracted and orb.position == Vector2(32.1, 0), "Orb should remain still beyond 2m")
	check(player.experience == 0, "Uncollected orbs must not grant EXP")
	orb.position = Vector2(32, 0)
	orb._physics_process(0.01)
	check(orb.attracted and orb.position.x < 32.0, "Orb should move toward player at exactly 2m")
	player.position = Vector2(-80, 0)
	var previous_x: float = orb.position.x
	orb._physics_process(0.01)
	check(orb.position.x < previous_x, "Attracted orb should keep following a player who moves away")
	orb._physics_process(1.0)
	check(orb.collected and orb.is_queued_for_deletion(), "Orb should collect without overshooting player")
	check(player.experience == 25, "Collection should grant the stored EXP")
	check(get_nodes_in_group("pickup_bursts").size() == 1, "Pickup should create one green burst")
	var burst = get_nodes_in_group("pickup_bursts")[0]
	check(burst.global_position == player.global_position, "Pickup effect should originate at player")
	check(burst.get_child(0).fill_color == orb.get_node("Geometry").fill_color, "Pickup particles should match orb green")
	orb._physics_process(1.0)
	check(player.experience == 25, "Orb must not grant EXP twice")
	check(get_nodes_in_group("pickup_bursts").size() == 1, "Orb must not emit pickup effects twice")
	# The base range can be increased later through the player Inspector property.
	var extra = load("res://scenes/experience_orb.tscn").instantiate()
	extra.target = player
	extra.position = player.position + Vector2(40, 0)
	scene.add_child(extra)
	extra.set_physics_process(false)
	extra._physics_process(0.01)
	check(not extra.attracted, "Orb outside base radius should wait")
	player.exp_attract_range_meters = 3.0
	extra._physics_process(0.01)
	check(extra.attracted, "Increasing range should attract more distant orbs")
	await create_timer(0.35).timeout
	check(get_nodes_in_group("pickup_bursts").is_empty(), "Pickup effects should clean themselves up")
	if "--capture" in OS.get_cmdline_user_args():
		player.position = Vector2.ZERO
		extra.position = Vector2(45, 10)
		for drop_position in [Vector2(62, -8), Vector2(75, 14)]:
			var preview_orb = load("res://scenes/experience_orb.tscn").instantiate()
			preview_orb.position = drop_position
			preview_orb.target = player
			scene.add_child(preview_orb)
			preview_orb.set_physics_process(false)
		await create_timer(0.6).timeout
		var collected_orb = load("res://scenes/experience_orb.tscn").instantiate()
		collected_orb.target = player
		scene.add_child(collected_orb)
		collected_orb._physics_process(1.0 / 60.0)
		await create_timer(0.08).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/exp-orbs-preview.png")
	print("PASS: death drops, 2m attraction boundary, homing, pickup, one-time EXP award, adjustable range")
	quit()
