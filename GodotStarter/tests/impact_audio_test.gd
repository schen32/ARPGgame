extends SceneTree
var events: Array = []
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
	enemy.position = Vector2(25, 0)
	var audio = scene.get_node("ImpactAudio")
	audio.sound_played.connect(func(kind, at, strength):
		if kind in [&"attack", &"collision", &"dash"]: # Use/pickup sounds have separate coverage.
			events.append({"kind": kind, "at": at, "strength": strength}))
	check(audio.voices.size() == 12, "SFX must use a bounded reusable voice pool")
	check(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(&"ImpactSFX")) == 1, "Impact bus should have one limiter")
	for stream in audio.CUE_SOUNDS + audio.BALL_SOUNDS:
		check(stream is AudioStreamWAV and not stream.stereo and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Impact samples should be non-looping mono WAV")
		check(stream.get_length() > 0.09 and stream.get_length() < 0.2, "Billiard contacts must be brief")
	var swing = player.try_sweep(Vector2(100, 0))
	check(events.size() == 1 and events[0].kind == &"attack" and events[0].at == enemy.global_position, "Sweep hit should play a positional cue click")
	swing.resolve()
	swing._physics_process(0.01)
	check(events.size() == 1, "Repeated checks of one melee hit must be silent")
	await physics_frame
	events.clear()
	var palm = player.try_palm(Vector2(100, 0))
	check(events.is_empty(), "Palm windup must not play a hit before contact")
	palm.resolve()
	check(events.size() == 1 and events[0].strength == player.palm_knockback, "Palm hit should use the stronger cue sound")
	await physics_frame
	events.clear()
	player.try_dash(Vector2.RIGHT)
	player.damage_dash_enemies(Vector2.ZERO, Vector2(48, 0))
	player.damage_dash_enemies(Vector2.ZERO, Vector2(48, 0))
	check(events.filter(func(event): return event.kind == &"attack").size() == 1 and events.filter(func(event): return event.kind == &"dash").size() == 1, "Dash should play its whoosh once and one cue click per struck enemy")
	enemy.queue_free()
	for attack in get_nodes_in_group("melee_attacks"):
		attack.queue_free()
	player.dash_timer = 0
	player.dash_active_this_frame = false
	await process_frame
	await physics_frame
	events.clear()
	enemy = load("res://scenes/enemy.tscn").instantiate()
	enemy.position = Vector2(25, 0)
	scene.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.take_damage(59)
	player.sweep_timer = 0
	player.try_sweep(Vector2(100, 0))
	check(enemy.is_queued_for_deletion() and events.size() == 1, "Lethal attacks must still play their impact sound")
	await physics_frame
	events.clear()
	audio.report_collision(101, 102, Vector2(50, 0), 450)
	audio.report_collision(102, 101, Vector2(50, 0), 450)
	check(events.size() == 1 and events[0].kind == &"collision", "Two colliders must report one ball clack per pair")
	for frame in range(4):
		await physics_frame
		audio.report_collision(101, 102, Vector2(50, 0), 40)
	check(events.size() == 1, "Sustained contact must not repeatedly clatter")
	for frame in range(4):
		await physics_frame
	audio.report_collision(102, 101, Vector2(50, 0), 450)
	check(events.size() == 2, "A separated pair can play a new contact")
	audio.report_collision(103, 104, Vector2.ZERO, 0)
	check(events.size() == 2, "Resting zero-speed collisions must be silent")
	await physics_frame
	events.clear()
	var bodies: Array = []
	for i in range(3):
		var body = load("res://scenes/enemy.tscn").instantiate()
		body.position = Vector2(120 + i * 22, 0)
		scene.add_child(body)
		body.target = null
		bodies.append(body)
	bodies[0].apply_knockback(Vector2.RIGHT, 975, 0.35)
	for frame in range(15):
		await physics_frame
	check(events.any(func(event): return event.kind == &"collision"), "Real enemy collision chains must play ball impacts")
	for body in bodies:
		if is_instance_valid(body):
			body.queue_free()
	# Repeated same-frame requests are bounded, with varied samples and levels.
	await physics_frame
	events.clear()
	for i in range(50):
		audio.play_sound(&"attack", Vector2.ZERO, 975)
		audio.play_sound(&"collision", Vector2.ZERO, 975)
	check(events.size() == 7 and audio.get_child_count() == 12, "Crowd sounds must be capped without allocating more players")
	check(audio.voices.any(func(voice): return voice.stream != null and voice.playing), "Impact events must start actual audio playback")
	await create_timer(0.35).timeout
	check(audio.voices.all(func(voice): return not voice.playing), "One-shot sound voices must finish without loops")
	print("PASS: billiard WAV samples, melee/palm/dash/lethal hit hooks, real chain clacks, contact deduplication, resting silence, bounded voices, playback cleanup")
	quit()
