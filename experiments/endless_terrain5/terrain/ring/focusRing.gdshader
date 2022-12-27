shader_type spatial;

uniform sampler2D albedo;
uniform sampler2D heightmap;

void fragment() {
	vec2 uv = vec2(UV);
	uv.x = uv.x - floor(uv.x);
	uv.y = uv.y - floor(uv.y);
	ALBEDO = texture(albedo, uv).rgb;
}