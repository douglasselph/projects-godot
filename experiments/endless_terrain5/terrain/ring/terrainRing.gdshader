shader_type spatial;

uniform sampler2D albedo;
uniform sampler2D noise;
uniform sampler2D heightmap;

uniform float NoiseAmplitude = 1.0;
uniform float HeightmapLandAmplitude = 1.0;
uniform float HeightmapWaterAmplitude = 1.0;

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
}

void vertex() {
	float noiseHeight = texture(noise, UV).y * NoiseAmplitude;
	vec3 heightmapColorValue = texture(heightmap, UV).rgb;
	float heightmapHeight;
	if (heightmapColorValue.r == heightmapColorValue.g && heightmapColorValue.g == heightmapColorValue.b) {
		// Land
		heightmapHeight = heightmapColorValue.r * HeightmapLandAmplitude;
	} else {
		// Water
		heightmapHeight = -heightmapColorValue.b * HeightmapWaterAmplitude;
	}
	float height = noiseHeight + heightmapHeight;
	
	VERTEX.y = height;
}