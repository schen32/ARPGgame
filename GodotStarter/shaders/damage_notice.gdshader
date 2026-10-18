shader_type canvas_item;
render_mode unshaded;
uniform float strength = 0.0;
void fragment() {
	vec2 edge = min(UV, vec2(1.0) - UV);
	float distance_to_edge = min(edge.x, edge.y);
	float vignette = 1.0 - smoothstep(0.0, 0.16, distance_to_edge);
	COLOR = vec4(1.0, 0.16, 0.13, vignette * strength * 0.38) * COLOR;
}
