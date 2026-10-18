extends Panel
## Shared equipment/inventory slot. Dragging only commits when a valid drop occurs.

const TOOLTIP = preload("res://scripts/skill_tooltip.gd")
const MELEE_ICON = preload("res://scripts/melee_icon.gd")
static var tooltip_owner: WeakRef

var player
var zone: String = "equipped"
var slot_index: int = 0
var display_skill: StringName = &""
var icon_root: Node2D
var overlay: Panel
var tooltip_layer: CanvasLayer
var hover_card: Control

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
	clear_tooltip()
	for child in icon_root.get_children():
		child.free()
	var skill := current_skill()
	# Empty text disables Godot's native delayed tooltip entirely.
	tooltip_text = ""
	match skill:
		&"sweep", &"palm", &"dash", &"attract_exp":
			var icon := MELEE_ICON.new()
			icon.kind = skill
			icon_root.add_child(icon)
	update_display()

func _process(_delta: float) -> void:
	update_display()
	update_tooltip()

func _exit_tree() -> void:
	if tooltip_owner != null and tooltip_owner.get_ref() == self:
		tooltip_owner = null

func clear_tooltip() -> void:
	if is_instance_valid(tooltip_layer):
		tooltip_layer.free()
	tooltip_layer = null
	hover_card = null
	if tooltip_owner != null and tooltip_owner.get_ref() == self:
		tooltip_owner = null

func update_tooltip() -> void:
	var hovered := get_viewport().gui_get_hovered_control()
	var show_card := is_instance_valid(player) and is_visible_in_tree() and not get_viewport().gui_is_dragging()
	show_card = show_card and current_skill() != &""
	show_card = show_card and Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position())
	show_card = show_card and (not is_instance_valid(hovered) or hovered == self or is_ancestor_of(hovered))
	if not show_card:
		clear_tooltip()
		return
	var previous = tooltip_owner.get_ref() if tooltip_owner != null else null
	if is_instance_valid(previous) and previous != self:
		previous.clear_tooltip()
	tooltip_owner = weakref(self)
	if not is_instance_valid(hover_card):
		tooltip_layer = CanvasLayer.new()
		tooltip_layer.layer = 100
		add_child(tooltip_layer)
		hover_card = build_tooltip()
		tooltip_layer.add_child(hover_card)
		hover_card.reset_size()
	# Anchor beside the slot so pointer movement never interrupts the description.
	var rect := get_global_transform_with_canvas() * Rect2(Vector2.ZERO, size)
	var bounds := get_viewport_rect().size
	var card_position := Vector2(rect.end.x + 6, rect.position.y)
	if card_position.x + hover_card.size.x > bounds.x - 6:
		card_position.x = rect.position.x - hover_card.size.x - 6
	card_position.x = clampf(card_position.x, 6, maxf(6, bounds.x - hover_card.size.x - 6))
	card_position.y = clampf(card_position.y, 6, maxf(6, bounds.y - hover_card.size.y - 6))
	hover_card.position = card_position

func update_display() -> void:
	if not is_instance_valid(icon_root):
		return
	icon_root.position = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(player):
		mouse_filter = Control.MOUSE_FILTER_STOP if player.inventory_open else Control.MOUSE_FILTER_PASS
	var cooldown: Vector2 = player.skill_cooldown(current_skill()) if is_instance_valid(player) else Vector2.ZERO
	var remaining := clampf(cooldown.x / maxf(cooldown.y, 0.001), 0.0, 1.0)
	overlay.visible = remaining > 0.0
	overlay.position = Vector2(1, 1 + (size.y - 2) * (1.0 - remaining))
	overlay.size = Vector2(size.x - 2, (size.y - 2) * remaining)

func build_tooltip() -> Control:
	var card := TOOLTIP.new()
	card.player = player
	card.skill = current_skill()
	card.zone = zone
	card.slot_index = slot_index
	return card

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
