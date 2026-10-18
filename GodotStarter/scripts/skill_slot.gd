extends Panel
## Shared equipment/inventory slot. Dragging only commits when a valid drop occurs.

const MELEE_ICON = preload("res://scripts/melee_icon.gd")
const NAMES = {&"sweep": "Sweeping Strike", &"palm": "Heavy Palm", &"dash": "Dash"}

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

func refresh() -> void:
	for child in icon_root.get_children():
		child.free()
	var skill := current_skill()
	tooltip_text = NAMES.get(skill, "Empty slot")
	if skill == &"sweep":
		tooltip_text += "\n100-degree sweep, 2.25m reach, 8 damage. 0.4s cooldown."
	elif skill == &"palm":
		tooltip_text += "\nLaunch nearest enemy. 2.7m reach, 12 damage. 0.15s windup, 1s cooldown."
	elif skill == &"dash":
		tooltip_text += "\nDash 5m with invincibility and launch enemies. 1.2s cooldown."
	match skill:
		&"sweep", &"palm", &"dash":
			var icon := MELEE_ICON.new()
			icon.kind = skill
			icon_root.add_child(icon)
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
	return data.get("skill", &"") != &"" and player.skill_at(source_zone, source_index) == data.get("skill") and player.can_move_skill(source_zone, source_index, zone, slot_index)

func _drop_data(at: Vector2, data: Variant) -> void:
	if _can_drop_data(at, data):
		player.move_skill(data.zone, data.index, zone, slot_index)
