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
	await physics_frame
	var player = scene.get_node("Player")
	var enemy = scene.get_node("Enemy")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	enemy.position = Vector2(80, 0)
	await physics_frame
	var shot = player.try_shoot(enemy.global_position)
	check(shot != null, "First shot should fire")
	check(player.try_shoot(enemy.global_position) == null, "Cooldown should block another shot")
	check(shot.collision_mask == 2, "Projectile should collide only with enemies")
	await create_timer(0.4).timeout
	check(not is_instance_valid(shot), "Shot should disappear on impact")
	check(enemy.knockback_velocity.x > 0.0, "Impact should push enemy along shot direction")
	check(enemy.health.current == 35.0, "Projectile should deal 25 damage")
	var impact_x: float = enemy.position.x
	enemy.set_physics_process(true)
	await create_timer(0.1).timeout
	check(enemy.position.x > impact_x, "Knockback should move enemy away")
	await create_timer(0.3).timeout
	check(enemy.velocity.x < 0.0, "Enemy should resume chasing after knockback")
	# A very fast shot crosses the enemy in one tick: swept collision must catch it.
	enemy.set_physics_process(false)
	enemy.position = Vector2(80, 0)
	enemy.knockback_timer = 0.0
	player.shot_timer = 0.0
	shot = player.try_shoot(enemy.global_position)
	shot.speed = 20000.0
	await create_timer(0.06).timeout
	check(not is_instance_valid(shot), "Fast shot must not tunnel through enemy")
	check(enemy.knockback_timer > 0.0, "Fast shot should apply knockback")
	check(enemy.health.current == 10.0, "Fast shot should deal damage exactly once")
	# Fire diagonally, then move the player: the projectile must keep its course.
	player.shot_timer = 0.0
	shot = player.try_shoot(Vector2(100, -100))
	var original_direction: Vector2 = shot.direction
	player.position = Vector2(-100, 100)
	await create_timer(0.06).timeout
	check(is_instance_valid(shot), "Unobstructed projectile should remain alive")
	check(shot.direction.is_equal_approx(original_direction), "Shot must not steer after firing")
	check(absf(shot.position.x + shot.position.y) < 0.01, "Shot should travel on its original straight line")
	shot.max_lifetime = 0.08
	await create_timer(0.08).timeout
	check(not is_instance_valid(shot), "Missed shots should eventually clean up")
	# Advancing the player clock should allow the next shot after cooldown.
	player._physics_process(player.shot_cooldown)
	shot = player.try_shoot(player.global_position + Vector2(0, -100))
	check(shot != null, "Shooting should resume after cooldown")
	print("PASS: shooting, cooldown, impact, swept collision, knockback, chase recovery, straight travel, cleanup")
	quit()
