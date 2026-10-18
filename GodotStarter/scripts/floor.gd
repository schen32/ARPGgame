extends Node2D

const ROOM_SIZE := Vector2(4000, 4000)
const GRID_STEP := 64.0

func _draw() -> void:
	draw_rect(Rect2(-ROOM_SIZE / 2.0, ROOM_SIZE), Color("344c43"))

	var half := ROOM_SIZE / 2.0
	var grid_color := Color("3b564a")
	var accent_color := Color("425e50")
	var x := -half.x
	while x <= half.x:
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), grid_color, 1.0)
		x += GRID_STEP
	var y := -half.y
	while y <= half.y:
		draw_line(Vector2(-half.x, y), Vector2(half.x, y), grid_color, 1.0)
		y += GRID_STEP

	# A few quiet floor markings make the movement space easier to read.
	draw_rect(Rect2(-192.0, -128.0, 384.0, 256.0), Color(0.22, 0.31, 0.27, 0.35), false, 3.0)
	draw_line(Vector2(-160.0, 0.0), Vector2(160.0, 0.0), accent_color, 2.0)
	draw_line(Vector2(0.0, -96.0), Vector2(0.0, 96.0), accent_color, 2.0)
