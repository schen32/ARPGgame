extends Control
## Screen-fixed geometric HUD with left mouse, right mouse, and Space skill slots.

const SHAPE = preload("res://scripts/prototype_shape.gd")
const EXPERIENCE_BAR = preload("res://scripts/experience_bar.gd")
const INVENTORY = preload("res://scripts/inventory.gd")
const SKILL_SLOT = preload("res://scripts/skill_slot.gd")
const DAMAGE_NOTICE = preload("res://shaders/damage_notice.gdshader")
const DAMAGE_NOTICE_DURATION: float = 0.32
const BLUE = Color("80c8ef")

@onready var player = get_node("../../Player")

var hp_gauge
var exp_bar
var slots: Array[Panel] = []
var passive_slots: Array[Panel] = []
var input_indicators: Array[Label] = []
var dock: Control
var sweep_icon
var cooldown_overlay: Panel
var cooldown_overlays: Array[Panel] = []
var inventory
var damage_overlay: ColorRect
var damage_timer: float = 0.0
var owns_inventory_pause: bool = false

func panel_style(background: Color, border: Color, radius: int = 5) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _ready() -> void:
	# Inventory input, drag/drop and hover remain live while the world is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_overlay = ColorRect.new()
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var notice := ShaderMaterial.new()
	notice.shader = DAMAGE_NOTICE
	damage_overlay.material = notice
	add_child(damage_overlay)
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_overlay.hide()
	player.damaged.connect(_on_player_damaged)
	dock = Control.new()
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dock)
	dock.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dock.offset_left = -76
	dock.offset_right = 76
	dock.offset_top = -90
	dock.offset_bottom = -14
	hp_gauge = SHAPE.new()
	hp_gauge.position = Vector2(26, 50)
	hp_gauge.shape_size = Vector2(44, 44)
	hp_gauge.fill_color = BLUE
	hp_gauge.border_color = Color("d3ecff")
	dock.add_child(hp_gauge)
	for i in range(3):
		var slot = SKILL_SLOT.new()
		slot.player = player
		slot.zone = "equipped"
		slot.slot_index = i
		slot.position = Vector2(64 + i * 28, 42)
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
	for i in range(3):
		var passive = SKILL_SLOT.new()
		passive.player = player
		passive.zone = "passive"
		passive.slot_index = i
		passive.position = Vector2(66 + i * 28, 16)
		passive.size = Vector2(18, 18)
		passive.add_theme_stylebox_override("panel", panel_style(Color.TRANSPARENT, Color("719c80"), 2))
		dock.add_child(passive)
		passive_slots.append(passive)
	sweep_icon = slots[0].icon_root
	for slot in slots:
		cooldown_overlays.append(slot.overlay)
	cooldown_overlay = cooldown_overlays[0]
	exp_bar = EXPERIENCE_BAR.new()
	exp_bar.position = Vector2(-2, 22)
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
	if inventory.visible and not get_tree().paused:
		owns_inventory_pause = true
		get_tree().paused = true
	elif not inventory.visible and owns_inventory_pause:
		get_tree().paused = false
		owns_inventory_pause = false

func _exit_tree() -> void:
	if owns_inventory_pause:
		get_tree().paused = false

func _process(delta: float) -> void:
	if damage_timer > 0.0:
		damage_timer = maxf(0.0, damage_timer - delta)
		update_damage_notice()
	if not is_instance_valid(player) or not is_instance_valid(cooldown_overlay):
		return
	for slot in slots:
		slot.update_display()

func _on_player_damaged(_amount: float) -> void:
	damage_timer = DAMAGE_NOTICE_DURATION
	update_damage_notice()

func update_damage_notice() -> void:
	var intensity := damage_timer / DAMAGE_NOTICE_DURATION
	damage_overlay.visible = damage_timer > 0.0
	(damage_overlay.material as ShaderMaterial).set_shader_parameter("strength", intensity)
	hp_gauge.fill_color = BLUE.lerp(Color("ffd0bd"), intensity * 0.65)
	hp_gauge.border_color = Color("d3ecff").lerp(Color("ff645e"), intensity)

func _on_health_changed(current: float, maximum: float) -> void:
	hp_gauge.fill_ratio = current / maximum

func _on_experience_changed(current: int, required: int, _player_level: int) -> void:
	exp_bar.max_value = required
	exp_bar.value = current
