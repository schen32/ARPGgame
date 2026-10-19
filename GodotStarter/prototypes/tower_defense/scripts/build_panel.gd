extends Control

@onready var world = get_node("../..")
var gold_label: Label
var tower_button: Button
var selection_hint: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.name = "TowerPalette"
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -120
	var background := StyleBoxFlat.new()
	background.bg_color = Color("263a33")
	background.border_color = Color("425e50")
	background.border_width_left = 1
	background.content_margin_left = 12
	background.content_margin_right = 12
	background.content_margin_top = 36
	background.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", background)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var title := Label.new()
	title.text = "TOWERS"
	title.add_theme_font_size_override("font_size", 13)
	column.add_child(title)
	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 15)
	gold_label.add_theme_color_override("font_color", Color("e8cb83"))
	column.add_child(gold_label)
	tower_button = Button.new()
	tower_button.name = "StrikeTower"
	tower_button.text = "Strike\n%d gold" % world.TOWER_COST
	tower_button.toggle_mode = true
	tower_button.focus_mode = Control.FOCUS_NONE
	tower_button.custom_minimum_size = Vector2(96, 84)
	tower_button.add_theme_font_size_override("font_size", 12)
	tower_button.tooltip_text = "Select Strike (1), then click clear ground. Right-click or Escape cancels."
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("344c43") if state != "pressed" else Color("3d6155")
		style.border_color = Color("80c8ef") if state == "pressed" else Color("6b8873")
		style.set_border_width_all(1)
		style.content_margin_top = 34
		style.content_margin_bottom = 8
		tower_button.add_theme_stylebox_override(state, style)
	column.add_child(tower_button)
	var icon = world.TOWER.SHAPE.new()
	icon.shape = 1
	icon.shape_size = Vector2(18, 18)
	icon.fill_color = Color("80c8ef")
	icon.border_color = Color("d3ecff")
	icon.position = Vector2(48, 18)
	tower_button.add_child(icon)
	tower_button.toggled.connect(func(selected: bool): world.select_tower(&"strike" if selected else &""))
	selection_hint = Label.new()
	selection_hint.custom_minimum_size.x = 96
	selection_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_hint.add_theme_font_size_override("font_size", 11)
	column.add_child(selection_hint)
	var shortcuts := Label.new()
	shortcuts.text = "1  Select tower\nRMB  Cancel\nR  Restart"
	shortcuts.add_theme_font_size_override("font_size", 10)
	shortcuts.add_theme_color_override("font_color", Color("a5b9aa"))
	column.add_child(shortcuts)
	world.currency_changed.connect(func(_gold: int): refresh())
	world.selection_changed.connect(refresh)
	refresh()

func refresh() -> void:
	gold_label.text = "Gold  %d" % world.gold
	tower_button.disabled = world.gold < world.TOWER_COST
	tower_button.set_pressed_no_signal(world.selected_tower == &"strike")
	if world.selected_tower == &"":
		selection_hint.text = "Select a tower to build."
	elif world.gold < world.TOWER_COST:
		selection_hint.text = "Need %d gold. Defeat enemies to earn more." % world.TOWER_COST
	else:
		selection_hint.text = "Click clear ground to place."
