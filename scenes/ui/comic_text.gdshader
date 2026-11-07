shader_type canvas_item;
// 만화 제목 글씨. 글자 면에 망점을 찍고, 아래로 갈수록 망점이 커진다.
// 외곽선과 그림자는 어두운 색이라 그대로 둔다. Label의 material로 쓴다.

uniform vec4 dot_color : source_color = vec4(0.16, 0.05, 0.3, 1.0);
// 망점 간격(px)
uniform float dot_spacing = 9.0;
// 망점이 가장 커지는 높이. Label 위쪽 기준(px)
uniform float gradient_top = 0.0;
uniform float gradient_bottom = 200.0;
uniform float min_radius = 0.1;
uniform float max_radius = 0.5;

const float FILL_THRESHOLD = 0.3;
const float EDGE = 0.07;
const float DIAGONAL = 0.7071;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float brightness = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	float fill = step(FILL_THRESHOLD, brightness);
	vec2 rotated = vec2(
		local_position.x + local_position.y,
		local_position.y - local_position.x
	) * DIAGONAL / dot_spacing;
	float depth = clamp((local_position.y - gradient_top) / (gradient_bottom - gradient_top), 0.0, 1.0);
	float radius = mix(min_radius, max_radius, depth);
	float dots = smoothstep(radius + EDGE, radius - EDGE, length(fract(rotated) - 0.5));
	COLOR.rgb = mix(COLOR.rgb, dot_color.rgb, dots * fill);
}
