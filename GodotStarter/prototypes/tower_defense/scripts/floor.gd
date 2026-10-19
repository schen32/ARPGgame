extends Node2D

const PATH_HALF_WIDTH := 26.0
const FLOW = [
    Vector2(-210, -116), Vector2(-210, -110), Vector2(170, -110),
    Vector2(210, -70), Vector2(210, -20), Vector2(-170, -20),
    Vector2(-210, 20), Vector2(-210, 70), Vector2(170, 70),
    Vector2(210, 100), Vector2(210, 110),
]
const SPAWN_X := -210.0
const SPAWN_Y := -116.0
const EXIT_X := 210.0
const EXIT_Y := 110.0
const OUTLINE_SHADER = preload("res://prototypes/tower_defense/shaders/arena_floor.gdshader")

static func outline() -> PackedVector2Array:
    # Rounded joins keep the same navigable width through each hairpin.
    return Geometry2D.offset_polyline(PackedVector2Array(FLOW), PATH_HALF_WIDTH, Geometry2D.JOIN_ROUND, Geometry2D.END_SQUARE)[0]

static func contains_point(point: Vector2, radius: float = 0.0) -> bool:
    var boundary := outline()
    if not Geometry2D.is_point_in_polygon(point, boundary):
        return false
    for i in range(boundary.size()):
        var closest := Geometry2D.get_closest_point_to_segment(point, boundary[i], boundary[(i + 1) % boundary.size()])
        if point.distance_to(closest) < radius:
            return false
    return true

func _ready() -> void:
    var boundary := outline()
    assert(boundary.size() <= 128, "Arena outline exceeds shader capacity")
    var points := PackedVector2Array()
    points.resize(128)
    for i in range(boundary.size()):
        points[i] = boundary[i]
    var surface := ColorRect.new()
    surface.position = Vector2(-320, -180)
    surface.size = Vector2(640, 360)
    surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var appearance := ShaderMaterial.new()
    appearance.shader = OUTLINE_SHADER
    appearance.set_shader_parameter("boundary", points)
    appearance.set_shader_parameter("point_count", boundary.size())
    appearance.set_shader_parameter("entry_center", Vector2(SPAWN_X, SPAWN_Y))
    appearance.set_shader_parameter("exit_center", Vector2(EXIT_X, EXIT_Y))
    surface.material = appearance
    add_child(surface)
