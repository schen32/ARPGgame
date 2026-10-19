extends PanelContainer
## Compact, wrapped cards used by every active, passive and stored skill slot.
const ICON = preload("res://prototypes/tower_defense/scripts/melee_icon.gd")
var player
var skill: StringName = &""
var zone: String = "inventory"
var slot_index: int = 0
var title_label: Label
var description_label: Label
var content_width: float = 156.0

func label(text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result.custom_minimum_size.x = content_width
		result.size.x = content_width
	return result

func number(value: float) -> String:
	return String.num(value, 2)

func _ready() -> void:
	add_to_group("skill_tooltips")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var width := minf(176.0, get_viewport_rect().size.x - 16.0)
	content_width = width - 20.0
	custom_minimum_size = Vector2(width, 0)
	var passive := skill == &"attract_exp" or zone == "passive"
	var accent := Color("8bd5a1") if passive else Color("a3deff")
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101f2b")
	style.border_color = accent.darkened(0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 3
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size.x = content_width
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 7)
	column.add_child(header)
	if skill != &"":
		var host := Control.new()
		host.custom_minimum_size = Vector2(22, 22)
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(host)
		var icon := ICON.new()
		icon.kind = skill
		icon.position = Vector2(11, 11)
		host.add_child(icon)
	var heading := VBoxContainer.new()
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_theme_constant_override("separation", 1)
	header.add_child(heading)
	var names := {&"sweep": "Sweeping Strike", &"palm": "Heavy Palm", &"dash": "Dash", &"attract_exp": "Attract EXP"}
	title_label = label(names.get(skill, "Empty passive slot" if passive else "Empty slot"), 9, Color("edf6fc"))
	heading.add_child(title_label)
	var category := "PASSIVE SKILL" if passive else "ACTIVE SKILL"
	if zone == "equipped" and skill != &"":
		category += "  /  " + ["LMB", "RMB", "SPACE"][slot_index]
	heading.add_child(label(category, 6, accent))
	var description := "Drag a passive skill here." if passive else "Drag a skill here."
	var stats: Array = []
	match skill:
		&"sweep":
			description = "Sweep a wide arc, lightly damaging enemies and launching them into others."
			stats = [["Damage", number(player.sweep_damage)], ["Force", number(player.sweep_knockback * player.force_multiplier())], ["Reach", number(player.sweep_reach * player.attack_area_multiplier() / 16.0) + " m"], ["Cooldown", number(player.sweep_cooldown) + " s"]]
		&"palm":
			description = "After a short windup, launch the nearest enemy with a powerful push."
			stats = [["Damage", number(player.palm_damage)], ["Force", number(player.palm_knockback * player.force_multiplier())], ["Reach", number(player.palm_reach * player.attack_area_multiplier() / 16.0) + " m"], ["Windup", number(player.palm_windup) + " s"], ["Cooldown", number(player.palm_cooldown) + " s"]]
		&"dash":
			description = "Dash through enemies to damage and launch them. Invincible during the dash."
			stats = [["Distance", number(player.dash_speed * player.dash_duration / 16.0) + " m"], ["Damage", number(player.dash_damage)], ["Force", number(player.dash_knockback_speed * player.force_multiplier())], ["Cooldown", number(player.dash_cooldown) + " s"]]
		&"attract_exp":
			description = "Pull nearby EXP orbs toward you."
			stats = [["Attract range", number(player.exp_attract_range_meters) + " m"]]
	description_label = label(description, 7, Color("c1d2df"), true)
	description_label.custom_minimum_size.x = width - 20.0
	column.add_child(description_label)
	if not stats.is_empty():
		var line := HSeparator.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_constant_override("separation", 3)
		column.add_child(line)
		for stat in stats:
			var row := HBoxContainer.new()
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_child(row)
			var key := label(stat[0], 7, Color("90a8b9"))
			key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(key)
			row.add_child(label(stat[1], 7, Color("edf6fc")))
	if skill == &"attract_exp":
		column.add_child(label("Unequipped: walk over EXP to collect it.", 7, accent, true))
	if skill != &"":
		var hint := "E  /  Manage skills"
		if is_instance_valid(player) and player.inventory_open:
			hint = "Drag to a matching skill slot to equip" if zone == "inventory" else "Drag to inventory to unequip"
		column.add_child(label(hint, 6, Color("7d96a8"), true))
