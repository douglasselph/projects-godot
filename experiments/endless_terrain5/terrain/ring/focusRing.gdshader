shader_type spatial;

uniform sampler2D albedo;
uniform sampler2D heightmap;

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
}
