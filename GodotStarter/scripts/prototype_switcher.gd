extends Node
## Add future prototypes here. Each scene owns its run; switching starts a fresh run.
const PROTOTYPES = [
	{"name": "Tower Defense", "scene": "res://prototypes/tower_defense/scenes/main.tscn"},
	{"name": "ARPG", "scene": "res://scenes/main.tscn"},
]
var switching := false
var caption: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(8, 3)
	caption.add_theme_font_size_override("font_size", 10)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(caption)
	get_tree().scene_changed.connect(_update_caption)
	_update_caption()

func _update_caption() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	for prototype in PROTOTYPES:
		if prototype.scene == scene.scene_file_path:
			caption.text = "%s  /  ` next prototype" % prototype.name
			return
	caption.text = "` next prototype"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_QUOTELEFT or event.keycode == KEY_QUOTELEFT:
			get_viewport().set_input_as_handled()
			cycle_prototype()

func cycle_prototype() -> void:
	if switching:
		return
	switching = true
	_switch_next.call_deferred()

func _switch_next() -> void:
	var scene := get_tree().current_scene
	var index := -1
	if scene != null:
		for i in range(PROTOTYPES.size()):
			if PROTOTYPES[i].scene == scene.scene_file_path:
				index = i
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(PROTOTYPES[(index + 1) % PROTOTYPES.size()].scene)
	if error != OK:
		push_error("Unable to switch prototype: %s" % error_string(error))
	else:
		await get_tree().scene_changed
	switching = false
