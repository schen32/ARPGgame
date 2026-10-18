shader_type canvas_item;
render_mode unshaded;
uniform int icon_kind = 0;
float segment(vec2 p, vec2 a, vec2 b) {
	vec2 line = b - a;
	return length(p - a - line * clamp(dot(p - a, line) / dot(line, line), 0.0, 1.0));
}
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 20.0;
	float d;
	if (icon_kind == 0) {
		// One broad arc: sweeping strike.
		vec2 q = p + vec2(2.5, 0.0);
		float angle = clamp(atan(q.y, q.x), -1.15, 1.15);
		d = length(q - vec2(cos(angle), sin(angle)) * 7.0) - 1.4;
	} else if (icon_kind == 1) {
		// A single thrust arrow meeting a flat impact bar: heavy palm.
		d = segment(p, vec2(-7.0, 0.0), vec2(3.0, 0.0)) - 1.0;
		d = min(d, segment(p, vec2(-0.5, -4.0), vec2(3.5, 0.0)) - 1.0);
		d = min(d, segment(p, vec2(3.5, 0.0), vec2(-0.5, 4.0)) - 1.0);
		d = min(d, segment(p, vec2(7.0, -5.0), vec2(7.0, 5.0)) - 0.85);
	} else if (icon_kind == 2) {
		// Two clean chevrons: dash.
		d = segment(p, vec2(-6.5, -5.0), vec2(-1.5, 0.0)) - 1.1;
		d = min(d, segment(p, vec2(-1.5, 0.0), vec2(-6.5, 5.0)) - 1.1);
		d = min(d, segment(p, vec2(0.5, -5.0), vec2(5.5, 0.0)) - 1.1);
		d = min(d, segment(p, vec2(5.5, 0.0), vec2(0.5, 5.0)) - 1.1);
	} else {
		// Simple horseshoe magnet for EXP attraction.
		vec2 q = p - vec2(0.0, -1.0);
		float angle = clamp(atan(q.y, q.x), 0.0, 3.1415927);
		d = length(q - vec2(cos(angle), sin(angle)) * 5.0) - 1.1;
		d = min(d, segment(p, vec2(-5.0, -1.0), vec2(-5.0, -6.0)) - 1.1);
		d = min(d, segment(p, vec2(5.0, -1.0), vec2(5.0, -6.0)) - 1.1);
	}
	float pixel = max(length(vec2(dFdx(d), dFdy(d))), 0.0001);
	float alpha = 1.0 - smoothstep(-pixel * 0.5, pixel * 0.5, d);
	vec3 tint = icon_kind == 3 ? vec3(0.545, 0.835, 0.631) : vec3(0.64, 0.87, 1.0);
	COLOR = vec4(tint, alpha) * COLOR;
}
