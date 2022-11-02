extends MeshInstance

export var TerrainX:float = 0
export var TerrainY:float = 0
export var TerrainWidth:float = 512
export var TerrainHeight:float = 512
export var SubDivide:int = 128
export var Octaves:int = 4

func _init():
	print("TerrainPerlin._init() SubDivide=", SubDivide)
	
func _ready():
	print("TerrainPerlin._ready() Octaves=", Octaves, ", SubDivide=", SubDivide)
	translate(Vector3(TerrainX, 0, TerrainY))
	#mesh.size = Vector2(TerrainWidth, TerrainHeight)
	mesh.subdivide_width = SubDivide
	mesh.subdivide_depth = SubDivide
	var material = get_active_material(0) as ShaderMaterial
	var texture = material.get_shader_param("noise") as NoiseTexture
	texture.noise_offset = Vector2(TerrainX, TerrainY)
	texture.width = TerrainWidth
	texture.height = TerrainHeight
	var noise = texture.noise as OpenSimplexNoise
	noise.octaves = Octaves
