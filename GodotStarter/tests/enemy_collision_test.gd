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
	scene.get_node("EnemySpawnTimer").stop()
	scene.get_node("Player").set_physics_process(false)
	var front = scene.get_node("Enemy")
	front.position = Vector2(80, 0)
	front.set_physics_process(false)
	var rear = load("res://scenes/enemy.tscn").instantiate()
	rear.position = Vector2(110, 0)
	scene.add_child(rear)
	for frame in range(90):
		await physics_frame
		check(front.position.distance_to(rear.position) >= 17.9, "Chasing enemies must not overlap")
	check(rear.position.x >= front.position.x + 17.9, "Rear enemy must not walk through the front one")
	rear.set_physics_process(false)
	front.apply_knockback(Vector2.RIGHT)
	front.set_physics_process(true)
	for frame in range(20):
		await physics_frame
		check(front.position.distance_to(rear.position) >= 17.9, "Knockback must respect enemy collisions")
	front.set_physics_process(false)
	# Populate the spawn ring and ensure every newly added enemy has clearance.
	for i in range(30):
		scene._on_enemy_spawn_timer_timeout()
		var enemies = get_nodes_in_group("enemies")
		var latest = enemies.back()
		latest.set_physics_process(false)
		for other in enemies:
			if other != latest:
				check(other.position.distance_to(latest.position) >= 17.9, "New enemies must not spawn overlapping")
	print("PASS: enemy collisions while chasing and knocked back, clear spawn positions")
	quit()
