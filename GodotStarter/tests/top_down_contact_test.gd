extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var scene = load("res://scenes/main.tscn").instantiate()
		root.add_child(scene)
		scene.get_node("EnemySpawnTimer").stop()
		var player = scene.get_node("Player")
		var enemy = scene.get_node("Enemy")
		enemy.position = direction * 16.8
		# Use live physics for both bodies so platform carrying is exercised.
		var greatest_separation: float = 0.0
		for frame in range(20):
			await physics_frame
			greatest_separation = maxf(greatest_separation, player.global_position.distance_to(enemy.global_position))
		if greatest_separation < 26.0:
			push_error("Enemy sticks to player after contact from %s; greatest separation %.2f" % [direction, greatest_separation])
			quit(1)
			return
		if player.health.current != 90.0:
			push_error("Contact from %s should cause one hit before separating, got HP %.0f" % [direction, player.health.current])
			quit(1)
			return
		var contact_frames := 0
		var longest_contact := 0
		for frame in range(90):
			await physics_frame
			if player.global_position.distance_to(enemy.global_position) <= enemy.stop_distance + 0.5:
				contact_frames += 1
				longest_contact = maxi(longest_contact, contact_frames)
			else:
				contact_frames = 0
		if longest_contact > 6:
			push_error("Repeated contact from %s remained stuck for %d ticks" % [direction, longest_contact])
			quit(1)
			return
		scene.queue_free()
		await process_frame
	print("PASS: close contact separates in all four directions without platform carrying or repeated damage")
	quit()
