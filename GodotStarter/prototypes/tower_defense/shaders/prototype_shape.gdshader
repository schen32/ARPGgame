shader_type canvas_item;
render_mode unshaded;

uniform vec2 shape_size = vec2(18.0);
uniform bool circle = true;
uniform vec4 fill_color : source_color = vec4(0.87, 0.42, 0.40, 1.0);
uniform vec4 border_color : source_color = vec4(1.0, 0.82, 0.74, 1.0);
uniform float border_width = 1.0;
uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// The quad includes two logical pixels of padding around the silhouette.
	vec2 p = (UV - vec2(0.5)) * (shape_size + vec2(4.0));
	vec2 q = abs(p) - shape_size * 0.5;
	float distance_to_edge = circle
		? length(p) - min(shape_size.x, shape_size.y) * 0.5
		: length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
	// Derivatives measure one screen pixel, so smoothing never scales up
	// into a multi-pixel blur with camera zoom or window scaling.
	float pixel_width = max(length(vec2(dFdx(distance_to_edge), dFdy(distance_to_edge))), 0.0001);
	float coverage = 1.0 - smoothstep(-0.5 * pixel_width, 0.5 * pixel_width, distance_to_edge);
	float border = smoothstep(-border_width - 0.5 * pixel_width, -border_width + 0.5 * pixel_width, distance_to_edge);
	vec4 color = mix(fill_color, border_color, border);
	// Missing health is transparent inside the outline. The fill drains downward.
	float inner_height = max(shape_size.y - 2.0 * border_width, 0.001);
	float waterline = (0.5 - fill_ratio) * inner_height;
	float vertical_pixel = max(fwidth(p.y), 0.0001);
	float fill = smoothstep(waterline - 0.5 * vertical_pixel, waterline + 0.5 * vertical_pixel, p.y);
	if (fill_ratio >= 1.0) { fill = 1.0; }
	if (fill_ratio <= 0.0) { fill = 0.0; }
	float visible = mix(fill, 1.0, border);
	COLOR = vec4(color.rgb, color.a * coverage * visible) * COLOR;
}
