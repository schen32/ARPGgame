shader_type canvas_item;
render_mode unshaded;

uniform vec2 canvas_size = vec2(56.0);
uniform float radius = 25.0;
uniform float thickness = 2.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fill_color : source_color;
uniform vec4 track_color : source_color = vec4(0.141, 0.2, 0.251, 1.0);

void fragment() {
	vec2 p = (UV - vec2(0.5)) * canvas_size;
	// Only the right half of the ring, from twelve to six o'clock.
	float d = max(abs(length(p) - radius) - thickness * 0.5, -p.x);
	float pixel = max(length(vec2(dFdx(d), dFdy(d))), 0.0001);
	float coverage = 1.0 - smoothstep(-pixel * 0.5, pixel * 0.5, d);
	float angle_progress = (atan(p.y, p.x) + PI * 0.5) / PI;
	float angle_pixel = max(fwidth(angle_progress), 0.0001);
	float filled = 1.0 - smoothstep(progress - angle_pixel * 0.5, progress + angle_pixel * 0.5, angle_progress);
	if (progress <= 0.0) { filled = 0.0; }
	if (progress >= 1.0) { filled = 1.0; }
	vec4 color = mix(track_color, fill_color, filled);
	COLOR = vec4(color.rgb, color.a * coverage);
}
