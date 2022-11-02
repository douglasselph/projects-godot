extends MeshInstance

class_name TerrainPerlinMesh

export var TerrainX: float = 0
export var TerrainY: float = 0
export var TerrainWidth:float = 2
export var TerrainHeight:float = 2
export var SubDivide:int = 256
export var Octaves:int = 4

func _init():
	print("TerrainPerlinMesh.init()")
	
func _ready():
	# translate(Vector3(TerrainX, 0, TerrainY))
	print("TerrainPerlinMesh.ready().SubDivide = ", SubDivide)
	mesh.size = Vector2(TerrainWidth, TerrainHeight)
	mesh.subdivide_width = SubDivide
	mesh.subdivide_depth = SubDivide
	var material = get_active_material(0) as ShaderMaterial
	var texture = material.get_shader_param("noise") as NoiseTexture
	texture.noise_offset = Vector2(TerrainX, TerrainY)
	var noise = texture.noise as OpenSimplexNoise
	noise.octaves = Octaves
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
