extends Panel
const TREE = preload("res://scripts/passive_tree.gd")
var player
var buttons: Dictionary = {}
var titles: Dictionary = {}
var ranks: Dictionary = {}
var point_label: Label
var described_node: Dictionary = {}
var tooltip_layer: CanvasLayer
var hover_card: PanelContainer

func label(value: String, font: int, color: Color) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", font)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

func text(value: String, at: Vector2, bounds: Vector2, font: int, color: Color) -> Label:
	var item := label(value, font, color)
	item.position = at
	item.size = bounds
	add_child(item)
	return item

func style(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	return box

func _draw() -> void:
	for branch in range(4):
		for tier in range(3):
			var at := Vector2(79 + branch * 134, 88 + tier * 42)
			draw_line(at, at + Vector2(0, 14), Color("314b5a"), 1.0)

func compact_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "focus", "pressed"]:
		button.add_theme_stylebox_override(state, style(Color("172e3c"), Color("425d6d")))
	button.add_theme_stylebox_override("hover", style(Color("254558"), Color("a3deff")))

func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -280
	offset_right = 280
	offset_top = -140
	offset_bottom = 126
	add_theme_stylebox_override("panel", style(Color("0e1d27"), Color("68899e")))
	text("PASSIVE TREE", Vector2(16, 10), Vector2(200, 18), 11, Color("edf6fc"))
	point_label = text("", Vector2(320, 13), Vector2(190, 14), 8, Color("8bd5a1"))
	var close := Button.new()
	close.text = "X"
	close.position = Vector2(528, 9)
	close.add_theme_font_size_override("font_size", 9)
	compact_button(close)
	close.pressed.connect(hide)
	add_child(close)
	close.set_deferred("size", Vector2(18, 18))
	for branch in range(4):
		text(TREE.BRANCHES[branch].to_upper(), Vector2(16 + branch * 134, 40), Vector2(126, 13), 8, Color("90a8b9"))
	for node in TREE.NODES:
		var button := Button.new()
		button.position = Vector2(16 + node.branch * 134, 60 + node.tier * 42)
		button.size = Vector2(126, 28)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func(): player.passive_tree.buy(node.id))
		add_child(button)
		buttons[node.id] = button
		var title := label(node.name, 7, Color("c1d2df"))
		title.position = Vector2(8, 8)
		title.size = Vector2(94, 12)
		button.add_child(title)
		titles[node.id] = title
		var rank := label("", 6, Color("90a8b9"))
		rank.position = Vector2(104, 9)
		rank.size = Vector2(17, 10)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		button.add_child(rank)
		ranks[node.id] = rank
	var reset := Button.new()
	reset.text = "RESPEC"
	reset.position = Vector2(16, 238)
	reset.add_theme_font_size_override("font_size", 7)
	compact_button(reset)
	reset.pressed.connect(func(): player.passive_tree.respec())
	add_child(reset)
	reset.set_deferred("size", Vector2(60, 16))
	text("T / Close     E / Inventory", Vector2(400, 240), Vector2(150, 12), 6, Color("7d96a8"))
	player.passive_tree.changed.connect(refresh)
	visibility_changed.connect(func():
		if not is_visible_in_tree():
			clear_hover())
	refresh()
	hide()

func clear_hover() -> void:
	if is_instance_valid(tooltip_layer):
		tooltip_layer.free()
	tooltip_layer = null
	hover_card = null
	described_node = {}

func _process(_delta: float) -> void:
	if not is_visible_in_tree() or get_viewport().gui_is_dragging():
		clear_hover()
		return
	for node in TREE.NODES:
		var button: Button = buttons[node.id]
		if Rect2(Vector2.ZERO, button.size).has_point(button.get_local_mouse_position()):
			if described_node.get("id") != node.id:
				describe(node)
			position_hover(button)
			return
	clear_hover()

func describe(node: Dictionary) -> void:
	clear_hover()
	described_node = node
	tooltip_layer = CanvasLayer.new()
	tooltip_layer.layer = 101
	add_child(tooltip_layer)
	hover_card = PanelContainer.new()
	hover_card.add_to_group("passive_node_tooltips")
	hover_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := style(Color("101f2b"), Color("68899e"))
	box.set_content_margin_all(10)
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 3
	hover_card.add_theme_stylebox_override("panel", box)
	hover_card.custom_minimum_size.x = 190
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	hover_card.add_child(column)
	column.add_child(label(node.name, 9, Color("edf6fc")))
	column.add_child(label("%s  /  RANK %d OF %d" % [TREE.BRANCHES[node.branch].to_upper(), player.passive_tree.rank(node.id), node.ranks], 6, Color("8bd5a1")))
	var description := label(node.text, 7, Color("c1d2df"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 170
	description.size.x = 170
	column.add_child(description)
	var requirement := "Click to spend 1 point. Respec is free."
	if player.passive_tree.rank(node.id) == node.ranks:
		requirement = "Max rank reached."
	elif player.passive_tree.spent_in_branch(node.branch) < node.tier * 3:
		requirement = "Requires %d points spent in %s (%d / %d)." % [node.tier * 3, TREE.BRANCHES[node.branch], player.passive_tree.spent_in_branch(node.branch), node.tier * 3]
	elif player.passive_tree.points == 0:
		requirement = "Level up to earn 1 point."
	var hint := label(requirement, 7, Color("90a8b9"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 170
	hint.size.x = 170
	column.add_child(hint)
	tooltip_layer.add_child(hover_card)
	hover_card.reset_size()
	position_hover(buttons[node.id])

func position_hover(button: Control) -> void:
	var rect := button.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, button.size)
	var bounds := get_viewport_rect().size
	var at := Vector2(rect.end.x + 6, rect.position.y)
	if at.x + hover_card.size.x > bounds.x - 6:
		at.x = rect.position.x - hover_card.size.x - 6
	at.x = clampf(at.x, 6, bounds.x - hover_card.size.x - 6)
	at.y = clampf(at.y, 6, bounds.y - hover_card.size.y - 6)
	hover_card.position = at

func refresh() -> void:
	point_label.text = "%d POINTS" % player.passive_tree.points
	for node in TREE.NODES:
		var rank: int = player.passive_tree.rank(node.id)
		var available: bool = player.passive_tree.can_buy(node.id)
		var border := Color("6fa486") if rank > 0 else Color("68899e") if available else Color("314b5a")
		var button: Button = buttons[node.id]
		button.disabled = not available
		for state in ["normal", "disabled", "focus"]:
			button.add_theme_stylebox_override(state, style(Color("142936"), border))
		button.add_theme_stylebox_override("hover", style(Color("254558"), Color("a3deff")))
		button.add_theme_stylebox_override("pressed", style(Color("32586b"), border))
		titles[node.id].add_theme_color_override("font_color", Color("d3ecdf") if rank > 0 else Color("c1d2df") if available else Color("7d96a8"))
		ranks[node.id].text = "%d/%d" % [rank, node.ranks]
		ranks[node.id].add_theme_color_override("font_color", Color("8bd5a1") if rank > 0 else Color("7d96a8"))
	if not described_node.is_empty():
		describe(described_node)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			visible = not visible
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ESCAPE and visible:
			hide()
			get_viewport().set_input_as_handled()
