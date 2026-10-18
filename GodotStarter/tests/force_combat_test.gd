extends SceneTree
var scene
var sounds: Array = []

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func body(mass: float = 1.0):
	var enemy = load("res://scenes/enemy.tscn").instantiate()
	enemy.mass_multiplier = mass
	enemy.position = Vector2(1000, 1000)
	scene.add_child(enemy)
	enemy.target = null
	enemy.set_physics_process(false)
	return enemy

func impact_damage(mass: float, speed: float) -> float:
	var source = body(mass)
	var target = body()
	var source_mass: float = source.current_mass()
	var target_mass: float = target.current_mass()
	var before := Vector2(speed, 70)
	var momentum := source_mass * before
	var energy := source_mass * before.length_squared()
	check(source.transfer_impact(target, before, Vector2.RIGHT), "Launched contact should resolve an impact")
	var lost: float = 60.0 - target.health.current
	var delta_v: float = before.x - source.knockback_velocity.x
	check(is_equal_approx(lost, source_mass * delta_v / 0.05 * 0.003), "Damage must equal mass times contact acceleration times damage scale")
	check(is_equal_approx(source.health.current, target.health.current), "Both bodies experience the same contact force")
	check((source_mass * source.knockback_velocity + target_mass * target.knockback_velocity).is_equal_approx(momentum), "Impact should conserve momentum using pre-hit masses")
	check(source_mass * source.knockback_velocity.length_squared() + target_mass * target.knockback_velocity.length_squared() < energy, "Impacts should dissipate energy")
	check(source.knockback_velocity.y == 70, "Glancing contact should preserve tangential movement")
	check(not source.transfer_impact(target, before, Vector2.RIGHT), "Same chain must not damage a target twice")
	source.queue_free()
	target.queue_free()
	return lost

func run_checks() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.get_node("EnemySpawnTimer").stop()
	scene.get_node("Enemy").set_physics_process(false)
	scene.get_node("Enemy").position = Vector2(1000, -1000)
	var player = scene.get_node("Player")
	player.set_physics_process(false)
	var light = body()
	var heavy = body(2.0)
	light.receive_attack(Vector2.RIGHT, 330, 4, 0.22)
	heavy.receive_attack(Vector2.RIGHT, 330, 4, 0.22)
	check(light.knockback_velocity.x == 330 and heavy.knockback_velocity.x == 165, "Same impulse should launch double mass at half the speed")
	check(light.health.current == 56 and heavy.health.current == 56, "Direct damage should occur on contact independently of mass")
	var initial: float = light.knockback_velocity.x
	var mass: float = light.current_mass()
	light.receive_attack(Vector2.RIGHT, 330, 4, 0.22)
	check(is_equal_approx(light.knockback_velocity.x - initial, 330.0 / mass), "A second attack should add its impulse to existing motion")
	light.queue_free()
	heavy.queue_free()
	var regular_damage := impact_damage(1.0, 400)
	check(impact_damage(2.0, 400) > regular_damage, "Heavier projectile at the same speed must cause more collision damage")
	check(impact_damage(1.0, 600) > regular_damage, "Faster impact must cause more damage through higher contact acceleration")
	check(regular_damage > player.palm_damage, "Collision damage should exceed the light direct attack damage")
	var resting = body()
	var neighbor = body()
	check(not resting.transfer_impact(neighbor, Vector2.ZERO, Vector2.RIGHT), "Resting contact should not repeatedly damage enemies")
	neighbor.knockback_velocity = Vector2(400, 0)
	check(not resting.transfer_impact(neighbor, Vector2(400, 0), Vector2.RIGHT), "Co-moving enemies must not generate collision force")
	resting.queue_free()
	neighbor.queue_free()
	var audio = scene.get_node("ImpactAudio")
	audio.sound_played.connect(func(kind, _at, _strength): sounds.append(kind))
	var sweep = player.try_sweep(Vector2(100, 0))
	check(sounds == [&"strike"], "Missed strike should still play its use sound")
	check(audio.voices.any(func(voice): return voice.stream == audio.STRIKE_SOUND and voice.playing), "Strike should start actual sound playback")
	sweep.resolve()
	player.try_sweep(Vector2(100, 0))
	check(sounds.size() == 1, "Repeated resolve and rejected cooldown attempts must be silent")
	var palm = player.try_palm(Vector2(100, 0))
	check(sounds.size() == 1, "Palm sound should wait for release")
	palm.resolve()
	check(sounds == [&"strike", &"palm"], "Palm release should play a distinct sound even on a miss")
	check(audio.voices.any(func(voice): return voice.stream == audio.PALM_SOUND and voice.playing), "Palm should start actual sound playback")
	palm.resolve()
	check(sounds.size() == 2, "Palm sound must play once per use")
	await create_timer(0.35).timeout
	scene.free()
	await process_frame
	print("PASS: mass-based additive impulses, contact damage, force-scaled collision damage, momentum/energy, glancing hits, resting/co-moving silence, Strike/Palm use audio")
	quit()
