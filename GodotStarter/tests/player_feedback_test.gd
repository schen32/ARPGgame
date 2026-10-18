extends SceneTree
var damage_events: Array[float] = []
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
	var hud = scene.get_node("HUD/Interface")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	player.damaged.connect(func(amount): damage_events.append(amount))
	check(not hud.damage_overlay.visible and player.damage_flash_timer == 0, "Damage feedback should start inactive")
	player.take_damage(10)
	check(damage_events.size() == 1 and damage_events[0] == 10 and player.health.current == 90, "Successful damage must notify once with actual HP loss")
	check(player.get_node("Geometry").fill_color != player.base_fill, "Player should flash immediately when hit")
	check(hud.damage_overlay.visible and hud.damage_timer > 0 and hud.hp_gauge.border_color.is_equal_approx(Color("ff645e")), "Hit must show red screen edges and pulse the HP gauge")
	check(hud.damage_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Damage overlay must not block attacks or inventory")
	check(is_equal_approx(player.get_node("Geometry").fill_ratio, 0.9) and is_equal_approx(hud.hp_gauge.fill_ratio, 0.9), "Damage flash must preserve actual health fill")
	player._process(0.12)
	hud._process(0.12)
	player.take_damage(5)
	check(player.health.current == 85 and damage_events.size() == 2 and player.damage_flash_timer == player.DAMAGE_FLASH_DURATION, "Repeated hits must apply damage and refresh feedback without new invincibility")
	player._process(0.4)
	hud._process(0.4)
	check(player.get_node("Geometry").fill_color == player.base_fill and player.get_node("Geometry").border_color == player.base_border, "Flash must restore the original player colors")
	check(not hud.damage_overlay.visible and hud.hp_gauge.fill_color == hud.BLUE, "Screen and HP notification must clear cleanly")
	player.take_damage(0)
	player.take_damage(-10)
	check(damage_events.size() == 2 and not hud.damage_overlay.visible, "Zero or negative damage must not trigger feedback")
	player.try_dash(Vector2.RIGHT)
	player.take_damage(10)
	check(damage_events.size() == 2 and not hud.damage_overlay.visible, "Invincible dash hits must not flash or show false damage notices")
	player.dash_timer = 0
	player.dash_active_this_frame = false
	# Exercise actual enemy contact, rather than only direct calls to damage.
	enemy.position = Vector2(20, 0)
	enemy._physics_process(1.0 / 60.0)
	check(damage_events.size() == 3 and hud.damage_overlay.visible and player.health.current == 75, "Enemy contact must give clear damage feedback")
	check(player.knockback_timer > 0, "Damage notification must preserve existing contact knockback")
	if "--capture" in OS.get_cmdline_user_args():
		hud.inventory.show()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/player-feedback-preview.png")
	print("PASS: immediate damage flash, red screen edges, HP pulse, repeat hits, fade/restoration, health fill, input passthrough, dash immunity, real enemy contact")
	quit()

