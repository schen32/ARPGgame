extends Panel
## Shared equipment/inventory slot. Dragging only commits when a valid drop occurs.

const SHAPE = preload("res://scripts/prototype_shape.gd")
const NAMES = {&"shot": "Blue Shot", &"spread": "Shotgun", &"dash": "Dash"}

var player
var zone: String = "equipped"
var slot_index: int = 0
var display_skill: StringName = &""
var icon_root: Node2D
var overlay: Panel

func _ready() -> void:
	icon_root = Node2D.new()
	add_child(icon_root)
	overlay = Panel.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.5, 0.5, 0.65)
	style.set_corner_radius_all(2)
	overlay.add_theme_stylebox_override("panel", style)
	add_child(overlay)
	if is_instance_valid(player):
		player.loadout_changed.connect(refresh)
	resized.connect(update_display)
	refresh()

func current_skill() -> StringName:
	return player.skill_at(zone, slot_index) if is_instance_valid(player) else display_skill

func shape(at: Vector2, dimensions: Vector2, square: bool = false) -> void:
	var icon = SHAPE.new()
	icon.position = at
	icon.shape_size = dimensions
	icon.shape = 1 if square else 0
	icon.fill_color = Color("80c8ef")
	icon.border_color = Color("d3ecff")
	icon.border_width = 0.0 if square else 0.6
	icon_root.add_child(icon)

func refresh() -> void:
	for child in icon_root.get_children():
		child.free()
	var skill := current_skill()
	tooltip_text = NAMES.get(skill, "Empty slot")
	match skill:
		&"shot": shape(Vector2.ZERO, Vector2(6, 6))
		&"spread":
			for point in [Vector2(-3, -5), Vector2(3, 0), Vector2(-3, 5)]:
				shape(point, Vector2(4, 4))
		&"dash":
			shape(Vector2(3, 0), Vector2(7, 7), true)
			for y in [-3, 0, 3]:
				shape(Vector2(-5.5, y), Vector2(5, 1), true)
	update_display()

func _process(_delta: float) -> void:
	update_display()

func update_display() -> void:
	if not is_instance_valid(icon_root):
		return
	icon_root.position = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP if is_instance_valid(player) and player.inventory_open else Control.MOUSE_FILTER_IGNORE
	var cooldown: Vector2 = player.skill_cooldown(current_skill()) if is_instance_valid(player) else Vector2.ZERO
	var remaining := clampf(cooldown.x / maxf(cooldown.y, 0.001), 0.0, 1.0)
	overlay.visible = remaining > 0.0
	overlay.position = Vector2(1, 1 + (size.y - 2) * (1.0 - remaining))
	overlay.size = Vector2(size.x - 2, (size.y - 2) * remaining)

func _get_drag_data(_at: Vector2) -> Variant:
	if not is_instance_valid(player) or not player.inventory_open or current_skill() == &"":
		return null
	var preview = get_script().new()
	preview.display_skill = current_skill()
	preview.size = Vector2(32, 32)
	set_drag_preview(preview)
	return {"kind": "skill", "owner_id": player.get_instance_id(), "zone": zone, "index": slot_index, "skill": current_skill()}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if not is_instance_valid(player) or not player.inventory_open or not data is Dictionary:
		return false
	if data.get("kind") != "skill" or data.get("owner_id") != player.get_instance_id():
		return false
	var source_zone: String = data.get("zone", "")
	var source_index: int = data.get("index", -1)
	return data.get("skill", &"") != &"" and player.skill_at(source_zone, source_index) == data.get("skill") and (source_zone != zone or source_index != slot_index)

func _drop_data(at: Vector2, data: Variant) -> void:
	if _can_drop_data(at, data):
		player.move_skill(data.zone, data.index, zone, slot_index)
