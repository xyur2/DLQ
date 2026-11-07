shader_type canvas_item;
// 뒤 화면을 흐리고 어둡게 한다. 일시 정지 배경용.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur : hint_range(0.0, 6.0) = 3.0;
uniform vec4 tint = vec4(0.03, 0.02, 0.1, 0.74);

void fragment() {
    vec3 behind = textureLod(screen_texture, SCREEN_UV, blur).rgb;
    COLOR = vec4(mix(behind, tint.rgb, tint.a), 1.0);
}
