extends Spatial
	
export var TerrainX = 0
export var TerrainZ = 0
export var TerrainWidth = 2
export var TerrainHeight = 2
export var SubDivide = 256
export var Octaves = 4

func _ready():
	$TerrainPerlinMesh.translation = Vector3(TerrainX, 0, TerrainZ)
	var mesh = $TerrainPerlinMesh.mesh as PlaneMesh
	mesh.size = Vector2(TerrainWidth, TerrainHeight)
	mesh.subdivide_width = SubDivide
	mesh.subdivide_depth = SubDivide
	var material = $TerrainPerlinMesh.get_active_material(0) as ShaderMaterial
	var texture = material.get_shader_param("noise") as NoiseTexture
	texture.noise_offset = Vector2(TerrainX, TerrainZ)
	var noise = texture.noise as OpenSimplexNoise
	noise.octaves = Octaves

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
