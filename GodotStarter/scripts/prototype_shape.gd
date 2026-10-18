@tool
extends Node2D
## Reusable art-free shape with a screen-pixel antialiasing fringe.

const SHADER = preload("res://shaders/prototype_shape.gdshader")

@export_enum("Circle", "Square") var shape: int = 0:
	set(value):
		shape = value
		refresh()
@export var shape_size: Vector2 = Vector2(18, 18):
	set(value):
		shape_size = value.max(Vector2.ONE)
		refresh()
@export var fill_color: Color = Color("de6b67"):
	set(value):
		fill_color = value
		refresh()
@export var border_color: Color = Color("ffd0bd"):
	set(value):
		border_color = value
		refresh()
@export_range(0.0, 8.0) var border_width: float = 1.0:
	set(value):
		border_width = value
		refresh()

var surface: ColorRect

@export_range(0.0, 1.0) var fill_ratio: float = 1.0:
	set(value):
		fill_ratio = clampf(value, 0.0, 1.0)
		if is_instance_valid(surface):
			(surface.material as ShaderMaterial).set_shader_parameter("fill_ratio", fill_ratio)

func _ready() -> void:
	surface = ColorRect.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shape_material := ShaderMaterial.new()
	shape_material.shader = SHADER
	surface.material = shape_material
	add_child(surface)
	refresh()

func refresh() -> void:
	if not is_instance_valid(surface):
		return
	surface.size = shape_size + Vector2(4, 4)
	surface.position = -surface.size * 0.5
	var shape_material := surface.material as ShaderMaterial
	shape_material.set_shader_parameter("shape_size", shape_size)
	shape_material.set_shader_parameter("circle", shape == 0)
	shape_material.set_shader_parameter("fill_color", fill_color)
	shape_material.set_shader_parameter("border_color", border_color)
	shape_material.set_shader_parameter("border_width", border_width)
	shape_material.set_shader_parameter("fill_ratio", fill_ratio)
