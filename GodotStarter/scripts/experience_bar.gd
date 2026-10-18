extends Control
## Screen-pixel antialiased EXP semicircle around the HP gauge's right side.

const PALETTE = preload("res://scripts/prototype_palette.gd")
const ARC_SHADER = preload("res://shaders/experience_arc.gdshader")

var surface: ColorRect

var max_value: float = 100.0:
	set(amount):
		max_value = maxf(1.0, amount)
		refresh()
var value: float = 0.0:
	set(amount):
		value = clampf(amount, 0.0, max_value)
		refresh()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface = ColorRect.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var arc_material := ShaderMaterial.new()
	arc_material.shader = ARC_SHADER
	arc_material.set_shader_parameter("fill_color", PALETTE.EXPERIENCE)
	surface.material = arc_material
	add_child(surface)
	resized.connect(refresh)
	refresh()

func refresh() -> void:
	if not is_instance_valid(surface):
		return
	surface.size = size
	var arc_material := surface.material as ShaderMaterial
	arc_material.set_shader_parameter("canvas_size", size)
	arc_material.set_shader_parameter("progress", value / max_value)
