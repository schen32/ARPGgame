extends Control
## Moonlit Silver HUD, drawn at the project's 640 x 360 logical resolution.

const SLOT = preload("res://Art/UI/MoonlitSilver/slot.png")
const HEALTH_ORB = preload("res://Art/UI/MoonlitSilver/health-orb.png")
const MANA_ORB = preload("res://Art/UI/MoonlitSilver/mana-orb.png")
const PORTRAIT = preload("res://Art/UI/cleric-portrait-new.png")
const SILVER = Color("c8d9ee")
const CYAN = Color("78d9ff")
const MAP_RANGE: float = 600.0

@onready var player = get_node("../../Player")
var panel: StyleBoxTexture

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel = StyleBoxTexture.new()
	panel.texture = SLOT
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		panel.set_texture_margin(side, 22.0)
		panel.set_expand_margin(side, 0.0)
	panel.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	panel.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	panel.set_content_margin_all(8.0)
	# Keep the source's corner decorations small at the game's pixel resolution.
	panel.region_rect = Rect2(0, 0, 139, 141)

func _process(_delta: float) -> void:
	queue_redraw()

func text_at(at: Vector2, value: String, color: Color = SILVER, font_size: int = 10) -> void:
	draw_string(ThemeDB.fallback_font, at + Vector2(1, 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("080c17"))
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func resource_orb(rect: Rect2, texture: Texture2D, ratio: float) -> void:
	draw_texture_rect(texture, rect, false)
	# Cover the spent portion inside the glass; leave the silver frame intact.
	var center := rect.position + Vector2(rect.size.x * 0.63, rect.size.y * 0.49)
	if texture == MANA_ORB:
		center = rect.position + Vector2(rect.size.x * 0.37, rect.size.y * 0.49)
	var radius := rect.size.y * 0.325
	var waterline := center.y + radius - 2.0 * radius * clampf(ratio, 0.0, 1.0)
	var points := PackedVector2Array()
	# Convex circular cap above the waterline, with a flat lower edge.
	for i in range(65):
		var angle := TAU * float(i) / 64.0
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		if point.y <= waterline:
			points.append(point)
	if points.size() >= 3:
		draw_colored_polygon(points, Color(0.025, 0.045, 0.09, 0.9))

func _draw() -> void:
	if not is_instance_valid(player) or panel == null:
		return
	var view := get_viewport_rect().size
	var base := Vector2(view.x * 0.5 - 150.0, view.y - 86.0)
	resource_orb(Rect2(base, Vector2(96, 83)), HEALTH_ORB, player.health / player.max_health)
	resource_orb(Rect2(base + Vector2(204, 0), Vector2(96, 83)), MANA_ORB, player.mana / player.max_mana)
	draw_style_box(panel, Rect2(base + Vector2(92, 22), Vector2(116, 58)))
	text_at(base + Vector2(111, 45), "CLERIC", CYAN, 12)
	text_at(base + Vector2(109, 60), "SPACE  Nova", SILVER, 9)
	text_at(base + Vector2(109, 72), "H  Heal", SILVER, 9)
	text_at(base + Vector2(40, 47), "%d/%d" % [player.health, player.max_health], Color.WHITE, 10)
	text_at(base + Vector2(220, 47), "%d/%d" % [player.mana, player.max_mana], Color.WHITE, 10)
	text_at(base + Vector2(40, 70), "HEALTH", SILVER, 8)
	text_at(base + Vector2(220, 70), "MANA", SILVER, 8)
	# Compact cleric portrait leaves the play area visible.
	draw_style_box(panel, Rect2(10, view.y - 63, 46, 53))
	draw_texture_rect(PORTRAIT, Rect2(16, view.y - 55, 34, 40), false)
	text_at(Vector2(12, 19), "MOONLIT GROUNDS", SILVER, 10)
	draw_minimap(Rect2(view.x - 126, 10, 116, 116))

func draw_minimap(rect: Rect2) -> void:
	draw_style_box(panel, rect)
	var inner := Rect2(rect.position + Vector2(13, 15), rect.size - Vector2(26, 29))
	draw_rect(inner, Color("101b29"))
	# A local, north-up map of the actual floor; grid scrolls with world position.
	var center := inner.get_center()
	var scale_factor := inner.size.x / (MAP_RANGE * 2.0)
	var grid_step := 256.0 * scale_factor
	var offset := Vector2(fposmod(-player.global_position.x * scale_factor, grid_step), fposmod(-player.global_position.y * scale_factor, grid_step))
	var x := inner.position.x + offset.x
	while x < inner.end.x:
		draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), Color("263847"))
		x += grid_step
	var y := inner.position.y + offset.y
	while y < inner.end.y:
		draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), Color("263847"))
		y += grid_step
	# The room is finite even though the movement sandbox allows leaving it.
	var room := Rect2(center + (Vector2(-2000, -2000) - player.global_position) * scale_factor, Vector2(4000, 4000) * scale_factor)
	var visible_room := room.intersection(inner)
	if visible_room.has_area():
		draw_rect(visible_room, Color(0.25, 0.42, 0.39, 0.22))
	for enemy in get_tree().get_nodes_in_group("goblins"):
		if enemy.is_queued_for_deletion():
			continue
		var point: Vector2 = center + (enemy.global_position - player.global_position) * scale_factor
		if inner.grow(-3).has_point(point):
			draw_rect(Rect2(point.round() - Vector2(2, 2), Vector2(4, 4)), Color("fa5974"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -4), center + Vector2(3, 3), center, center + Vector2(-3, 3)]), CYAN)
	text_at(rect.position + Vector2(53, 12), "N", CYAN, 8)
	text_at(rect.position + Vector2(17, 126), "600px  |  Enemies: %d" % get_tree().get_nodes_in_group("goblins").size(), SILVER, 8)
