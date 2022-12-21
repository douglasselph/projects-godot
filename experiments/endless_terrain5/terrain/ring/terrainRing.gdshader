shader_type spatial;

uniform sampler2D albedo;
uniform sampler2D noise;
uniform sampler2D heightmaps[9];

uniform float NoiseAmplitude = 1.0;
uniform float HeightmapLandAmplitude = 1.0;
uniform float HeightmapWaterAmplitude = 1.0;
uniform vec2 OffsetUV = vec2(0, 0);


void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
}


// 0 1 2
// 3 4 5
// 6 7 8
int heightmapIndex(vec2 uv) {
	int yrow;
	if (uv.y < 0.0) {
		yrow = 0;
	} else if (uv.y > 1.0) {
		yrow = 2;
	} else {
		yrow = 1;
	}
	int xrow;
	if (uv.x< 0.0) {
		xrow = 0;
	} else if (uv.x > 1.0) {
		xrow = 2;
	} else {
		xrow = 1;
	}
	return yrow * 3 + xrow;
}


vec3 heightmapValue(vec2 uv) {
	vec2 ref = vec2(uv.x + OffsetUV.x, uv.y + OffsetUV.y);
	int hmIndex = heightmapIndex(ref);
	return texture(heightmaps[hmIndex], ref).rgb;
}


void vertex() {
	float noiseHeight = texture(noise, UV).y * NoiseAmplitude;
	vec3 heightmapColorValue = heightmapValue(UV);
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



