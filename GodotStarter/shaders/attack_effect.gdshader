shader_type canvas_item;
render_mode unshaded;
uniform vec2 bounds_size = vec2(80.0);
uniform vec2 aim = vec2(1.0, 0.0);
uniform int effect_kind = 0;
uniform float radius = 36.0;
uniform float half_angle = 0.8726646;
uniform float half_width = 8.0;
uniform float progress = 0.0;
uniform float opacity = 1.0;
uniform bool windup = false;

float coverage(float d) {
	// Analytic edges with a one-screen-pixel fringe, regardless of window scale.
	float pixel = max(length(vec2(dFdx(d), dFdy(d))), 0.0001);
	return 1.0 - smoothstep(-pixel * 0.5, pixel * 0.5, d);
}
float segment(vec2 p, vec2 a, vec2 b) {
	vec2 edge = b - a;
	return length(p - a - edge * clamp(dot(p - a, edge) / max(dot(edge, edge), 0.0001), 0.0, 1.0));
}
float arc(vec2 p, float r, float center, float half_span, float width) {
	float angle = atan(p.y, p.x);
	float relative = atan(sin(angle - center), cos(angle - center));
	float nearest = center + clamp(relative, -half_span, half_span);
	return length(p - vec2(cos(nearest), sin(nearest)) * r) - width * 0.5;
}
float box(vec2 p, vec2 half_size) {
	vec2 q = abs(p) - half_size;
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
}
void fragment() {
	vec2 world = (UV - vec2(0.5)) * bounds_size;
	vec2 p = vec2(dot(world, aim), dot(world, vec2(-aim.y, aim.x)));
	float alpha = 0.0;
	vec3 tint = vec3(0.502, 0.784, 0.937);
	if (effect_kind == 0) {
		float angular = abs(atan(p.y, p.x)) - half_angle;
		float sector = max(length(p) - radius, sin(clamp(angular, -1.5707963, 1.5707963)) * length(p));
		alpha = coverage(sector) * 0.12;
		alpha = max(alpha, coverage(arc(p, radius, 0.0, half_angle, 2.0)));
		float angle = mix(-half_angle, half_angle, progress);
		vec2 tip = vec2(cos(angle), sin(angle)) * radius;
		alpha = max(alpha, coverage(segment(p, tip * 0.45, tip) - 1.5) * 0.8);
	} else if (effect_kind == 1) {
		float center = (8.0 + radius) * 0.5;
		alpha = coverage(box(p - vec2(center, 0.0), vec2((radius - 8.0) * 0.5, half_width))) * 0.35;
		alpha = max(alpha, coverage(segment(p, vec2(8.0, 0.0), vec2(radius, 0.0)) - (windup ? 0.5 : 1.5)));
		alpha = max(alpha, coverage(segment(p, vec2(radius, -half_width), vec2(radius, half_width)) - 1.0));
	}

	COLOR = vec4(tint, alpha * opacity) * COLOR;
}
