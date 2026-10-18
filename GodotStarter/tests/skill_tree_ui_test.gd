extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func press(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func click(button: Control) -> void:
	var logical: Vector2 = button.get_global_transform_with_canvas() * (button.size * 0.5)
	root.warp_mouse(logical)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = root.get_stretch_transform() * logical
		Input.parse_input_event(event)
		await process_frame
func move_to(at: Vector2) -> void:
	root.warp_mouse(at)
	var event := InputEventMouseMotion.new()
	event.position = root.get_stretch_transform() * at
	Input.parse_input_event(event)
func hover_node(panel: Control, id: StringName, point: Vector2) -> void:
	var button: Control = panel.buttons[id]
	for frame in range(5):
		move_to(button.get_global_transform_with_canvas() * point)
		await process_frame
	move_to(button.get_global_transform_with_canvas() * point)
	panel._process(0)
	check(panel.described_node.get("id") == id, "Hover must describe the node under the pointer, including locked nodes")
	check(get_nodes_in_group("passive_node_tooltips").size() == 1, "Only one node tooltip may be visible")
	check(Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(Rect2(panel.hover_card.position, panel.hover_card.size)), "Node tooltip must fit the viewport")
func run_checks() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.get_node("EnemySpawnTimer").stop()
	var player = scene.get_node("Player")
	var hud = scene.get_node("HUD/Interface")
	var panel = hud.tree_panel
	await process_frame
	check(not panel.visible and not paused, "Tree starts closed")
	player.add_experience(1200)
	check("+12" in hud.tree_button.text, "HUD must advertise available points after leveling")
	press(KEY_T)
	await process_frame
	check(panel.visible and paused and player.inventory_open, "T must open tree, pause world and block combat")
	move_to(Vector2(30, 30))
	panel._process(0)
	check(not is_instance_valid(panel.hover_card), "No description should appear without hovering a node")
	for node in player.passive_tree.NODES:
		var visible_text = panel.buttons[node.id].find_children("*", "Label", false, false).map(func(item): return item.text)
		check(not node.text in visible_text and visible_text.size() == 2, "Nodes should display only name and rank")
	check(panel.buttons.size() == 16 and Rect2(Vector2.ZERO, hud.size).encloses(panel.get_rect()), "All nodes must fit the reference viewport")
	for button in panel.find_children("*", "Button", false, false):
		check(Rect2(Vector2.ZERO, panel.size).encloses(button.get_rect()), "Every tree button must fit inside its panel")
	var enemy = scene.get_node("Enemy")
	var position_before: Vector2 = enemy.position
	await create_timer(0.1, true).timeout
	check(enemy.position == position_before, "Tree must pause enemies")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/skill-tree-simple.png")
	await hover_node(panel, &"follow_through", Vector2(2, 2))
	var hover_text = panel.hover_card.find_children("*", "Label", true, false).map(func(item): return item.text)
	check(hover_text.any(func(value): return "Requires 3 points" in value), "Locked hover must show the unlock requirement")
	await click(panel.buttons[&"follow_through"])
	check(player.passive_tree.points == 12, "Locked node must reject a GUI click")
	for rank in range(3):
		await click(panel.buttons[&"heavy_hands"])
	check(player.passive_tree.rank(&"heavy_hands") == 3 and player.passive_tree.points == 9, "Actual GUI clicks must buy one rank per point")
	check(not panel.buttons[&"follow_through"].disabled, "Spending three points must unlock the next tier visually")
	await click(panel.buttons[&"follow_through"])
	for rank in range(3):
		await click(panel.buttons[&"extended_reach"])
	check("5 POINTS" in panel.point_label.text, "Point counter must update after purchases")
	await hover_node(panel, &"driving_force", Vector2(124, 26))
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/skill-tree-preview.png")
	move_to(panel.get_global_transform_with_canvas() * Vector2(250, 235))
	panel._process(0)
	check(not is_instance_valid(panel.hover_card), "Leaving a node must immediately hide its description")
	press(KEY_E)
	await process_frame
	check(hud.inventory.visible and not panel.visible and paused, "E must switch from tree to inventory without unpausing")
	press(KEY_T)
	await process_frame
	check(panel.visible and not hud.inventory.visible and paused, "T must switch back from inventory to tree")
	var reset = panel.find_children("*", "Button", false, false).filter(func(item): return item.text == "RESPEC")[0]
	await click(reset)
	check(player.passive_tree.points == 12 and player.passive_tree.ranks.is_empty(), "Respec button must refund the full point budget")
	press(KEY_ESCAPE)
	await process_frame
	check(not panel.visible and not paused and not player.inventory_open, "Escape must close tree and resume gameplay")
	check(get_nodes_in_group("passive_node_tooltips").is_empty(), "Closing the tree must remove its tooltip")
	await click(hud.tree_button)
	check(panel.visible and paused, "HUD button must open tree")
	var close = panel.find_children("*", "Button", false, false).filter(func(item): return item.text == "X")[0]
	await click(close)
	check(not panel.visible and not paused, "X must resume gameplay")
	scene.free()
	await create_timer(0.2).timeout
	print("PASS: T/HUD open, 16 nodes fit, actual rank/locked/respec clicks, live point counter, tree/inventory pause handoff, Escape/X close")
	quit()
