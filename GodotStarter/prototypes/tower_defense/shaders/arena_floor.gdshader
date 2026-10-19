shader_type canvas_item;
render_mode unshaded;

uniform vec2 boundary[128];
uniform int point_count = 0;
uniform vec2 entry_center;
uniform vec2 exit_center;

void fragment() {
	vec2 p = UV * vec2(640.0, 360.0) - vec2(320.0, 180.0);
	float distance_to_edge = 10000.0;
	bool inside = false;
	for (int i = 0; i < point_count; i++) {
		vec2 a = boundary[i];
		vec2 b = boundary[(i + 1) % point_count];
		vec2 edge = b - a;
		float t = clamp(dot(p - a, edge) / max(dot(edge, edge), 0.0001), 0.0, 1.0);
		distance_to_edge = min(distance_to_edge, length(p - a - edge * t));
		if ((a.y > p.y) != (b.y > p.y)) {
			if (p.x < a.x + (p.y - a.y) * edge.x / edge.y) { inside = !inside; }
		}
	}
	float sdf = inside ? -distance_to_edge : distance_to_edge;
	// Smooth over one display pixel, independent of window size or integer scaling.
	float pixel = max(length(vec2(dFdx(sdf), dFdy(sdf))), 0.0001);
	float floor_coverage = 1.0 - smoothstep(-0.5 * pixel, 0.5 * pixel, sdf);
	vec3 color = mix(vec3(0.149, 0.227, 0.2), vec3(0.204, 0.298, 0.263), floor_coverage);
	float border = 1.0 - smoothstep(0.65 - 0.5 * pixel, 0.65 + 0.5 * pixel, abs(sdf));
	color = mix(color, vec3(0.420, 0.533, 0.451), border);
	if (inside && abs(p.x - entry_center.x) < 23.0 && p.y > entry_center.y - 23.0 && p.y < entry_center.y - 12.0) {
		color = mix(color, vec3(0.87, 0.42, 0.40), 0.25);
	}
	if (inside && abs(p.x - exit_center.x) < 23.0 && p.y > exit_center.y + 6.0 && p.y < exit_center.y + 19.0) {
		color = mix(color, vec3(0.50, 0.78, 0.94), 0.25);
	}
	COLOR = vec4(color, 1.0);
}
