extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	assert(get_nodes_in_group("goblins").is_empty(), "Goblin spawned before five seconds")
	await create_timer(5.1).timeout
	assert(get_nodes_in_group("goblins").size() == 1, "Expected one goblin after five seconds")
	var first = get_nodes_in_group("goblins")[0]
	var first_distance: float = first.position.distance_to(scene.player.position)
	await create_timer(5.0).timeout
	assert(get_nodes_in_group("goblins").size() == 2, "Expected two goblins after ten seconds")
	assert(first.position.distance_to(scene.player.position) < first_distance, "Goblin did not approach player")
	scene.get_node("GoblinSpawnTimer").stop()
	for enemy in get_nodes_in_group("goblins"):
		enemy.queue_free()
	await process_frame
	var goblin = load("res://scenes/goblin.tscn").instantiate()
	goblin.target = scene.player
	scene.add_child(goblin)
	assert(goblin.get_node("Sprite2D").get_rect().size == Vector2(32, 32))
	# Positions relative to the target should face front, right, back, left.
	var positions = [Vector2(0, -100), Vector2(-100, 0), Vector2(0, 100), Vector2(100, 0)]
	for frame in range(4):
		goblin.position = positions[frame]
		await physics_frame
		await physics_frame
		assert(goblin.get_node("Sprite2D").frame == frame, "Incorrect goblin facing")
		assert(goblin.position.length() < 100.0, "Goblin moved away from target")
	goblin.position = Vector2(60, 80)
	await physics_frame
	await physics_frame
	assert(absf(goblin.position.cross(Vector2(60, 80))) < 0.01, "Chase deviates from a straight line")
	# A final short step must stop at the target without overshooting.
	goblin.position = Vector2(12.1, 0)
	await physics_frame
	await physics_frame
	await physics_frame
	assert(is_equal_approx(goblin.position.length(), goblin.stop_distance))
	assert(goblin.velocity.is_zero_approx())
	# Changing the player's position must change the pursuit direction.
	scene.player.position = Vector2(12.1, 100)
	await physics_frame
	await physics_frame
	assert(goblin.velocity.y > 0.0)
	goblin.target = null
	await physics_frame
	await physics_frame
	assert(goblin.velocity.is_zero_approx())
	print("PASS: 5-second repeating spawns, pursuit, four facings, straight line, arrival and missing target")
	quit()
