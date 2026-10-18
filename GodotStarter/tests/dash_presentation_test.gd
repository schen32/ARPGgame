extends SceneTree
var dash_sounds: int = 0
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
	player.set_physics_process(false)
	scene.get_node("Enemy").set_physics_process(false)
	var audio = scene.get_node("ImpactAudio")
	audio.sound_played.connect(func(kind, _at, _strength):
		if kind == &"dash": dash_sounds += 1)
	check(audio.DASH_SOUND.get_length() > 0.2 and audio.DASH_SOUND.get_length() < 0.25, "Dash whoosh should match the short dash duration")
	check(player.try_dash(Vector2.RIGHT), "Dash should activate")
	check(dash_sounds == 1, "Successful dash should play exactly one whoosh immediately")
	check(not player.try_dash(Vector2.RIGHT) and dash_sounds == 1, "Cooldown-blocked dash must remain silent")
	check(player.dash_visual.visible and player.dash_visual.get_child_count() == 1, "Dash visual should be just one clean ring")
	var trail = get_nodes_in_group("dash_trails")[0]
	check(trail.ghosts.size() == 1, "Trail should start at the actual dash origin")
	player.set_physics_process(true)
	var peak_ghosts := 1
	for frame in range(16):
		await physics_frame
		if is_instance_valid(trail):
			peak_ghosts = maxi(peak_ghosts, trail.ghosts.size())
			for ghost in trail.ghosts:
				check(ghost.shape.global_position.x <= player.global_position.x + 0.01 and absf(ghost.shape.global_position.y) < 0.01, "Afterimages must stay on the traveled path behind the player")
		if frame == 5 and "--capture" in OS.get_cmdline_user_args():
			player.set_physics_process(false)
			trail.set_process(false)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../.codex/dash-simple-preview.png")
			player.set_physics_process(true)
			trail.set_process(true)
	player.set_physics_process(false)
	check(peak_ghosts >= 2 and peak_ghosts <= 3, "Dash should leave a short bounded trail")
	check(absf(player.position.x - 80) < 0.2 and not player.dash_visual.visible, "Simpler visuals must preserve dash distance and ring timing")
	await create_timer(0.18).timeout
	check(get_nodes_in_group("dash_trails").is_empty(), "Trail must fade quickly after dash ends")
	check(audio.voices.all(func(voice): return not voice.playing), "Dash whoosh must finish as a one-shot")
	player.dash_cooldown_timer = 0
	player.inventory_open = true
	check(not player.try_dash(Vector2.RIGHT) and dash_sounds == 1, "Inventory-blocked dash must not play a sound")
	player.inventory_open = false
	check(not player.try_dash(Vector2.ZERO) and dash_sounds == 1, "Invalid dash direction must remain silent")
	print("PASS: single-ring dash, bounded afterimages on traveled path, fade/cleanup, unchanged distance, one-shot whoosh, silent rejected casts")
	quit()
