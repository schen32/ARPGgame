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
	var player = scene.get_node("Player")
	player.set_physics_process(false)
	scene.get_node("Enemy").set_physics_process(false)
	check(get_nodes_in_group("enemies").size() == 1, "Keep the initial enemy")
	await create_timer(1.8).timeout
	check(get_nodes_in_group("enemies").size() == 1, "Do not spawn before two seconds")
	await create_timer(0.3).timeout
	check(get_nodes_in_group("enemies").size() == 2, "Spawn one enemy after two seconds")
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	player.position = Vector2(600, 300)
	await create_timer(2.0).timeout
	check(get_nodes_in_group("enemies").size() == 3, "Spawn again after eight seconds")
	var latest = get_nodes_in_group("enemies").back()
	latest.set_physics_process(false)
	check(absf(latest.global_position.distance_to(player.global_position) - scene.spawn_radius) < 10.0, "Spawn around the player's current position")
	check(latest.target == player, "Spawned enemy should chase the player")
	check(latest.health.current == 60.0, "Spawned enemy should start with full HP")
	latest.take_damage(1000.0)
	check(get_nodes_in_group("death_bursts").size() == 1, "Death should create a particle burst")
	var burst = get_nodes_in_group("death_bursts")[0]
	check(burst.global_position == latest.global_position, "Burst should originate at enemy death position")
	check(burst.get_child_count() == 18, "Burst should contain geometric particles")
	latest.take_damage(1000.0)
	check(get_nodes_in_group("death_bursts").size() == 1, "Death must not emit twice")
	await create_timer(0.1).timeout
	check(get_nodes_in_group("enemies").size() == 2, "Dead enemy must be removed")
	check(burst.get_child(0).position.length() > 0.0, "Particles should spread outward")
	check(burst.get_child(0).modulate.a < 1.0, "Particles should fade")
	await create_timer(0.6).timeout
	check(get_nodes_in_group("death_bursts").is_empty(), "Burst must clean up after finishing")
	player.take_damage(1000.0)
	scene._on_enemy_spawn_timer_timeout()
	check(scene.get_node("EnemySpawnTimer").is_stopped(), "Stop spawning after player defeat")
	check(get_nodes_in_group("enemies").size() == 2, "Do not spawn while player is defeated")
	print("PASS: two-second repeating spawns, player-relative spawn location, death burst, particle movement/fade/cleanup")
	quit()
