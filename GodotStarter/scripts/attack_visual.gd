extends Node2D
## Analytic attack geometry rasterized at native display resolution.
const SHADER = preload("res://shaders/attack_effect.gdshader")
var surface: ColorRect
func _ready() -> void:
	surface = ColorRect.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var effect := ShaderMaterial.new()
	effect.shader = SHADER
	surface.material = effect
	add_child(surface)
func update_effect(parameters: Dictionary) -> void:
	var extent: float = parameters.get("radius", 36.0) + 4.0
	var dimensions := Vector2.ONE * extent * 2.0
	surface.size = dimensions
	surface.position = -dimensions * 0.5
	var effect := surface.material as ShaderMaterial
	effect.set_shader_parameter("bounds_size", dimensions)
	for key in parameters:
		effect.set_shader_parameter(key, parameters[key])
