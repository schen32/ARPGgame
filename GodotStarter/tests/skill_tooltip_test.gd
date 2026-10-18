extends SceneTree
var scene
var player
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func move_mouse(at: Vector2) -> void:
	root.warp_mouse(root.get_stretch_transform().affine_inverse() * at)
	var motion := InputEventMouseMotion.new()
	motion.position = at
	Input.parse_input_event(motion)
func hover(slot: Control, local: Vector2, expected: String) -> void:
	move_mouse(Vector2(40, 40))
	await create_timer(0.1).timeout
	var point: Vector2 = root.get_stretch_transform() * slot.get_global_transform_with_canvas() * local
	for frame in range(8):
		move_mouse(point)
		await process_frame
	var cards := get_nodes_in_group("skill_tooltips").filter(func(card): return card.is_visible_in_tree())
	check(cards.size() == 1, "Hover should show one card for %s at %s; got %d, hovered %s, mouse %s, local %s" % [expected, local, cards.size(), root.gui_get_hovered_control(), root.get_mouse_position(), slot.get_local_mouse_position()])
	if cards.size() == 1:
		check(cards[0].title_label.text == expected, "Hover should describe the skill under the pointer")
		check(cards[0].size.y <= 180, "Tooltip height must fit its content without a tall empty panel")
		check(cards[0].size.x <= 180, "Tooltip must keep its compact wrapped width")
		check(cards[0].get_theme_stylebox("panel").bg_color.a == 1.0, "Card background should be opaque")
		check(cards[0].get_parent() is CanvasLayer, "Card should have one background, without a native tooltip wrapper")
		var values: Array = cards[0].find_children("*", "Label", true, false).map(func(item): return item.text)
		var force_values := {&"sweep": player.sweep_knockback, &"palm": player.palm_knockback, &"dash": player.dash_knockback_speed}
		if force_values.has(cards[0].skill):
			check("Force" in values and cards[0].number(force_values[cards[0].skill]) in values, "Active tooltip must show its current force")
func run_checks() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.get_node("EnemySpawnTimer").stop()
	player = scene.get_node("Player")
	player.set_physics_process(false)
	scene.get_node("Enemy").set_physics_process(false)
	var hud = scene.get_node("HUD/Interface")
	var inventory = hud.inventory
	await process_frame
	inventory.show()
	player.sweep_timer = player.sweep_cooldown
	var slot = inventory.equipped_slots[0]
	for point in [Vector2(2, 2), Vector2(30, 2), Vector2(2, 30), Vector2(30, 30), Vector2(16, 16)]:
		await hover(slot, point, "Sweeping Strike")
	await hover(inventory.equipped_slots[1], Vector2(16, 16), "Heavy Palm")
	await hover(inventory.equipped_slots[2], Vector2(16, 16), "Dash")
	await hover(inventory.passive_slots[0], Vector2(2, 30), "Attract EXP")
	# Stay beyond the native tooltip delay: it must never create a second popup.
	for frame in range(75):
		var passive = inventory.passive_slots[0]
		move_mouse(root.get_stretch_transform() * passive.get_global_transform_with_canvas() * Vector2(2, 30))
		await process_frame
		# Keep native mouse polling from overriding the synthetic hover before the assertion.
		move_mouse(root.get_stretch_transform() * passive.get_global_transform_with_canvas() * Vector2(2, 30))
		passive.update_tooltip()
		check(get_nodes_in_group("skill_tooltips").size() == 1, "Long hover must keep exactly one tooltip; got %d, mouse %s" % [get_nodes_in_group("skill_tooltips").size(), passive.get_local_mouse_position()])
		check(root.get_embedded_subwindows().is_empty(), "Native tooltip popups must be disabled")
	check(inventory.passive_slots[0].tooltip_text.is_empty(), "Skill slots must not request a second native tooltip")
	# Rapidly alternate slots without leaving a gap between pointer events.
	for target_slot in [inventory.equipped_slots[0], inventory.passive_slots[0], inventory.equipped_slots[2]]:
		move_mouse(root.get_stretch_transform() * target_slot.get_global_transform_with_canvas() * Vector2(16, 16))
		for other in [inventory.equipped_slots[0], inventory.passive_slots[0], inventory.equipped_slots[2]]:
			other.update_tooltip()
			check(get_nodes_in_group("skill_tooltips").size() <= 1, "Slot transitions must never leave two cards alive")
		await process_frame
	await hover(inventory.passive_slots[0], Vector2(2, 30), "Attract EXP")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/tooltip-preview.png")
	var persistent = inventory.passive_slots[0].hover_card
	for point in [Vector2(5, 5), Vector2(12, 18), Vector2(28, 28)]:
		move_mouse(root.get_stretch_transform() * inventory.passive_slots[0].get_global_transform_with_canvas() * point)
		await process_frame
		check(inventory.passive_slots[0].hover_card == persistent, "Moving inside a skill box must keep its tooltip visible")
	for empty_slot in [inventory.slots[0], inventory.passive_slots[1], hud.passive_slots[1]]:
		for frame in range(8):
			move_mouse(root.get_stretch_transform() * empty_slot.get_global_transform_with_canvas() * Vector2(5, 5))
			await process_frame
		check(get_nodes_in_group("skill_tooltips").is_empty(), "Empty storage and equipment slots must not show tooltips")
	inventory.hide()
	await process_frame
	await hover(hud.slots[0], Vector2(2, 2), "Sweeping Strike")
	await hover(hud.passive_slots[0], Vector2(16, 16), "Attract EXP")
	check(hud.slots[0].mouse_filter == Control.MOUSE_FILTER_PASS, "Closed-inventory HUD hover must preserve event passthrough")
	check(player.try_sweep(Vector2(100, 0)) == null, "Hover should not reset active cooldown")
	player.sweep_timer = 0
	check(player.try_sweep(Vector2(100, 0)) != null, "HUD hover must not block normal attacks")
	print("PASS: compact cards, full-slot hover, passive cards, no empty-slot tooltips, closed-HUD hover, input passthrough")
	quit()
