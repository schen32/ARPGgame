extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func run_checks() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.get_node("EnemySpawnTimer").stop()
	var player = scene.get_node("Player")
	var enemy = scene.get_node("Enemy")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	enemy.position = Vector2(28, 0)
	var sweep = player.try_sweep(Vector2(100, 0))
	check(get_nodes_in_group("hit_bursts").size() == 1, "Successful sweep should emit one small impact burst")
	var burst = get_nodes_in_group("hit_bursts")[0]
	burst.set_process(false)
	check(burst.get_child_count() == 8, "Hit burst should be a small eight-particle effect")
	check(burst.global_position == enemy.global_position - Vector2(7, 0), "Hit particles should originate at the contact edge")
	sweep.resolve()
	sweep._physics_process(0.02)
	check(get_nodes_in_group("hit_bursts").size() == 1, "Repeated hit checks must not emit extra particles")
	burst._process(0.06)
	check(burst.get_child(0).position.length() > 0 and burst.get_child(0).modulate.a < 1, "Hit particles must disperse and fade")
	burst._process(0.3)
	await process_frame
	check(get_nodes_in_group("hit_bursts").is_empty(), "Impact bursts must clean themselves up")
	var palm = player.try_palm(Vector2(100, 0))
	check(get_nodes_in_group("hit_bursts").is_empty(), "Palm windup must not emit impact particles before contact")
	palm.resolve()
	check(get_nodes_in_group("hit_bursts").size() == 1, "Heavy palm hit should emit impact particles")
	player.try_dash(Vector2.RIGHT)
	player.damage_dash_enemies(Vector2.ZERO, Vector2(48, 0))
	player.damage_dash_enemies(Vector2.ZERO, Vector2(48, 0))
	check(get_nodes_in_group("hit_bursts").size() == 2, "Dash should emit only one burst per enemy")
	for attack in get_nodes_in_group("melee_attacks"):
		attack.queue_free()
	enemy.queue_free()
	player.dash_timer = 0
	player.dash_active_this_frame = false
	await process_frame
	enemy = load("res://scenes/enemy.tscn").instantiate()
	enemy.position = Vector2(-100, 0)
	scene.add_child(enemy)
	enemy.set_physics_process(false)
	player.sweep_timer = 0
	var before: int = get_nodes_in_group("hit_bursts").size()
	player.try_sweep(Vector2(100, 0))
	check(get_nodes_in_group("hit_bursts").size() == before, "Missed attacks must not emit hit particles")
	enemy.position = Vector2(28, 0)
	enemy.take_damage(59)
	player.sweep_timer = 0
	sweep = player.try_sweep(Vector2(100, 0))
	check(enemy.is_queued_for_deletion() and get_nodes_in_group("hit_bursts").size() == before + 1, "Lethal hits must retain their impact burst")
	if "--capture" in OS.get_cmdline_user_args():
		# Render the new analytic effects at a diagonal to expose edge artifacts.
		player.sweep_timer = 0
		player.palm_timer = 0
		player.dash_cooldown_timer = 0
		sweep = player.try_sweep(Vector2(100, -60))
		sweep.set_physics_process(false)
		sweep._physics_process(0.07)
		palm = player.try_palm(Vector2(100, 40))
		palm.set_physics_process(false)
		palm._physics_process(0.16)
		player.try_dash(Vector2.RIGHT)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/attack-feedback-preview.png")
	await create_timer(0.3).timeout
	check(get_nodes_in_group("hit_bursts").is_empty(), "All attack particles should finish quickly")
	# Allow one-shot audio playback to drain before engine shutdown.
	await create_timer(0.3).timeout
	print("PASS: sweep/palm/dash hit particles, one burst per hit, contact origin, motion/fade, cleanup, missed attacks, lethal hits")
	quit()
