extends Control
## Screen-fixed geometric HUD with left mouse, right mouse, and Space skill slots.

const SHAPE = preload("res://scripts/prototype_shape.gd")
const EXPERIENCE_BAR = preload("res://scripts/experience_bar.gd")
const INVENTORY = preload("res://scripts/inventory.gd")
const SKILL_SLOT = preload("res://scripts/skill_slot.gd")
const BLUE = Color("80c8ef")

@onready var player = get_node("../../Player")

var hp_gauge
var exp_bar
var slots: Array[Panel] = []
var input_indicators: Array[Label] = []
var dock: Control
var sweep_icon
var cooldown_overlay: Panel
var cooldown_overlays: Array[Panel] = []
var inventory

func panel_style(background: Color, border: Color, radius: int = 5) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock = Control.new()
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dock)
	dock.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dock.offset_left = -76
	dock.offset_right = 76
	dock.offset_top = -66
	dock.offset_bottom = -14
	hp_gauge = SHAPE.new()
	hp_gauge.position = Vector2(26, 26)
	hp_gauge.shape_size = Vector2(44, 44)
	hp_gauge.fill_color = BLUE
	hp_gauge.border_color = Color("d3ecff")
	dock.add_child(hp_gauge)
	for i in range(3):
		var slot = SKILL_SLOT.new()
		slot.player = player
		slot.zone = "equipped"
		slot.slot_index = i
		slot.position = Vector2(64 + i * 28, 18)
		slot.size = Vector2(22, 22)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_theme_stylebox_override("panel", panel_style(Color.TRANSPARENT, Color("d3ecff"), 3))
		dock.add_child(slot)
		slots.append(slot)
		var indicator := Label.new()
		indicator.text = ["LMB", "RMB", "SPACE"][i]
		indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		indicator.add_theme_font_size_override("font_size", 6)
		indicator.add_theme_color_override("font_color", Color("b0c4d0"))
		indicator.position = Vector2(0, 24)
		indicator.size = Vector2(22, 10)
		indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(indicator)
		# Apply final bounds after the theme's minimum-size update.
		indicator.set_deferred("size", Vector2(22, 10))
		input_indicators.append(indicator)
	sweep_icon = slots[0].icon_root
	for slot in slots:
		cooldown_overlays.append(slot.overlay)
	cooldown_overlay = cooldown_overlays[0]
	exp_bar = EXPERIENCE_BAR.new()
	exp_bar.position = Vector2(-2, -2)
	exp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exp_bar.size = Vector2(56, 56)
	dock.add_child(exp_bar)
	player.health.changed.connect(_on_health_changed)
	player.experience_changed.connect(_on_experience_changed)
	_on_health_changed(player.health.current, player.health.max_health)
	_on_experience_changed(player.experience, player.experience_per_level, player.level)
	inventory = INVENTORY.new()
	inventory.player = player
	add_child(inventory)
	inventory.visibility_changed.connect(_on_inventory_visibility_changed)
	_on_inventory_visibility_changed()

func _on_inventory_visibility_changed() -> void:
	if is_instance_valid(player):
		player.inventory_open = inventory.visible

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(cooldown_overlay):
		return
	for slot in slots:
		slot.update_display()

func _on_health_changed(current: float, maximum: float) -> void:
	hp_gauge.fill_ratio = current / maximum

func _on_experience_changed(current: int, required: int, _player_level: int) -> void:
	exp_bar.max_value = required
	exp_bar.value = current
