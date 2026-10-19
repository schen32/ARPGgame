extends Panel
## Equipped skills plus 18 storage slots, toggled with E.

const SKILL_SLOT = preload("res://prototypes/tower_defense/scripts/skill_slot.gd")

var slots: Array[Panel] = []
var equipped_slots: Array[Panel] = []
var passive_slots: Array[Panel] = []
var player

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	offset_left = -262
	offset_right = -12
	offset_top = -172
	offset_bottom = 104
	var background := StyleBoxFlat.new()
	background.bg_color = Color("0e1d27")
	background.border_color = Color("7295ac")
	background.set_border_width_all(1)
	background.set_corner_radius_all(5)
	add_theme_stylebox_override("panel", background)
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color("d3ecff"))
	title.text = "INVENTORY"
	title.position = Vector2(14, 10)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var close := Button.new()
	close.text = "X"
	close.flat = true
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 10)
	add_child(close)
	close.position = Vector2(218, 7)
	close.set_deferred("size", Vector2(20, 20))
	close.pressed.connect(hide)
	for row in [{"text": "ACTIVE", "y": 29.0}, {"text": "PASSIVE", "y": 94.0}]:
		var label := Label.new()
		label.text = row.text
		label.position = Vector2(14, row.y)
		label.add_theme_font_size_override("font_size", 7)
		label.add_theme_color_override("font_color", Color("b0c4d0"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	for i in range(3):
		var equipped = SKILL_SLOT.new()
		equipped.player = player
		equipped.zone = "equipped"
		equipped.slot_index = i
		equipped.position = Vector2(71 + i * 38, 43)
		equipped.size = Vector2(32, 32)
		equipped.add_theme_stylebox_override("panel", slot_style())
		add_child(equipped)
		equipped_slots.append(equipped)
		var binding := Label.new()
		binding.add_theme_font_size_override("font_size", 6)
		binding.text = ["LMB", "RMB", "SPACE"][i]
		binding.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		binding.mouse_filter = Control.MOUSE_FILTER_IGNORE
		binding.position = Vector2(0, 34)
		equipped.add_child(binding)
		binding.set_deferred("size", Vector2(32, 10))
	for i in range(3):
		var passive = SKILL_SLOT.new()
		passive.player = player
		passive.zone = "passive"
		passive.slot_index = i
		passive.position = Vector2(71 + i * 38, 108)
		passive.size = Vector2(32, 32)
		var style := slot_style()
		style.border_color = Color("719c80")
		passive.add_theme_stylebox_override("panel", style)
		add_child(passive)
		passive_slots.append(passive)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.position = Vector2(14, 156)
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	for i in range(18):
		var slot = SKILL_SLOT.new()
		slot.player = player
		slot.zone = "inventory"
		slot.slot_index = i
		slot.custom_minimum_size = Vector2(32, 32)
		slot.add_theme_stylebox_override("panel", slot_style())
		grid.add_child(slot)
		slots.append(slot)
	hide()

func slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172e3c")
	style.border_color = Color("68899e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			visible = not visible
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ESCAPE and visible:
			hide()
			get_viewport().set_input_as_handled()
