extends Node2D
## Compact vector glyphs shared by HUD slots, inventory slots and drag previews.
var kind: StringName = &"sweep"
const BLUE = Color("80c8ef")
const EDGE = Color("d3ecff")

func _draw() -> void:
	if kind == &"sweep":
		var center := Vector2(-2, 0)
		var half := deg_to_rad(50.0)
		var sector := PackedVector2Array([center])
		for i in range(25):
			sector.append(center + Vector2.RIGHT.rotated(lerpf(-half, half, i / 24.0)) * 8.0)
		draw_colored_polygon(sector, Color(BLUE, 0.25))
		draw_arc(center, 8.0, -half, half, 32, BLUE, 2.0, true)
		draw_arc(center, 5.2, -half * 0.8, half * 0.65, 24, Color(EDGE, 0.65), 0.8, true)
		var tip := center + Vector2.RIGHT.rotated(half) * 8.0
		draw_line(center + Vector2(1, 0), tip, EDGE, 1.2, true)
		draw_rect(Rect2(-7, -1.5, 3, 3), BLUE)
	elif kind == &"dash":
		var center := Vector2(2, 0)
		draw_arc(center, 7.0, -1.1, 1.1, 24, EDGE, 1.4, true)
		draw_arc(center, 7.0, 1.45, TAU - 1.45, 24, Color(BLUE, 0.6), 1.0, true)
		draw_rect(Rect2(center - Vector2(2.5, 2.5), Vector2(5, 5)), BLUE)
		for y in [-4.0, 0.0, 4.0]:
			draw_line(Vector2(-9, y), Vector2(-3 if y == 0 else -5, y), BLUE, 1.3, true)
		draw_polyline(PackedVector2Array([Vector2(4.5, -2.5), Vector2(7, 0), Vector2(4.5, 2.5)]), EDGE, 1.2, true)
	else:
		# Open hand rotated toward the right, with motion behind and impact ahead.
		var hand := PackedVector2Array([
			Vector2(-3, 6), Vector2(-3, 2), Vector2(-5, -1), Vector2(-5, -3),
			Vector2(-4, -3), Vector2(-2, 0), Vector2(-2, -5), Vector2(-1, -5),
			Vector2(-1, -1), Vector2(0, -1), Vector2(0, -7), Vector2(1, -7),
			Vector2(1, -1), Vector2(2, -1), Vector2(2, -6), Vector2(3, -6),
			Vector2(3, -1), Vector2(4, -1), Vector2(4, -4), Vector2(5, -4),
			Vector2(5, 2), Vector2(3, 5), Vector2(3, 6)
		])
		for i in range(hand.size()):
			hand[i] = hand[i].rotated(PI * 0.5) * 0.8
		draw_colored_polygon(hand, BLUE)
		hand.append(hand[0])
		draw_polyline(hand, Color(EDGE, 0.8), 0.65, true)
		for y in [-3.0, 3.0]:
			draw_line(Vector2(-9, y), Vector2(-6, y), BLUE, 1.2, true)
		draw_line(Vector2(8, -3), Vector2(8, 3), EDGE, 1.2, true)
		draw_line(Vector2(6.5, -5), Vector2(8, -6.5), BLUE, 1.0, true)
		draw_line(Vector2(6.5, 5), Vector2(8, 6.5), BLUE, 1.0, true)
