extends Node2D
## Player-centered aura marks the same enemy-center contact radius used by dash hits.
const SHAPE = preload("res://scripts/prototype_shape.gd")
var player
var ring: Node2D
var radius: float = 17.0

func _ready() -> void:
	z_index = 3
	ring = SHAPE.new()
	ring.fill_color = Color(0.5, 0.8, 1.0, 0.08)
	ring.border_color = Color("a9e7ff")
	ring.border_width = 1.0
	add_child(ring)
	update_display()

func _process(_delta: float) -> void:
	update_display()

func update_display() -> void:
	visible = is_instance_valid(player) and player.is_alive() and player.is_dashing()
	if not visible or not is_instance_valid(ring):
		return
	radius = player.dash_hit_radius()
	ring.shape_size = Vector2.ONE * radius * 2.0
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var aim: Vector2 = player.dash_direction
	var angle := aim.angle()
	var progress: float = 1.0 - player.dash_timer / maxf(player.dash_duration, 0.001)
	var white := Color("e4f7ff")
	# Directional brackets and a moving inner arc make the shield read as a dash.
	draw_arc(Vector2.ZERO, radius - 2.0, angle - 0.65, angle + 0.65, 24, white, 1.5, true)
	draw_arc(Vector2.ZERO, radius - 4.0, angle + PI - 0.5 + progress * 0.6, angle + PI + 0.5 + progress * 0.6, 24, Color(0.5, 0.8, 1.0, 0.65), 1.0, true)
	var tip := aim * (radius - 4.0)
	var side := aim.orthogonal() * 3.0
	draw_polyline(PackedVector2Array([tip - aim * 3.0 + side, tip, tip - aim * 3.0 - side]), white, 1.2, true)
