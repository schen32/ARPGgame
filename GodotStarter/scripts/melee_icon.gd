extends Node2D
## Minimal analytic glyphs shared by HUD, inventory and drag previews.
const SHADER = preload("res://shaders/skill_icon.gdshader")
var kind: StringName = &"sweep"
var surface: ColorRect
func _ready() -> void:
	surface = ColorRect.new()
	surface.position = Vector2(-10, -10)
	surface.size = Vector2(20, 20)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := ShaderMaterial.new()
	icon.shader = SHADER
	icon.set_shader_parameter("icon_kind", {&"sweep": 0, &"palm": 1, &"dash": 2, &"attract_exp": 3}.get(kind, 0))
	surface.material = icon
	add_child(surface)
