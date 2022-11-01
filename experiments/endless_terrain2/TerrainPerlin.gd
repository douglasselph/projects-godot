extends Spatial
	
export var TerrainX:float = 0
export var TerrainY:float = 0
export var TerrainWidth:float = 2
export var TerrainHeight:float = 2
export var SubDivide:int = 256
export var Octaves:int = 4
	
func _ready():
	translate(Vector3(TerrainX, 0, TerrainY))
	print("subdivide = ", SubDivide)
	$TerrainPerlinMesh.OffsetX = TerrainX
	$TerrainPerlinMesh.OffsetY = TerrainY
	$TerrainPerlinMesh.SubDivide = SubDivide
	$TerrainPerlinMesh.Octaves = Octaves
	$TerrainPerlinMesh.TerrainWidth = TerrainWidth
	$TerrainPerlinMesh.TerrainHeight = TerrainHeight
	
func vertexArray():
	var mesh = $TerrainPerlinMesh.mesh as PlaneMesh
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func edgeOf(edge: Edge):
	var material = $TerrainPerlinMesh.get_active_material(0) as ShaderMaterial
	var texture = material.get_shader_param("noise") as NoiseTexture
	var noise = texture.noise as OpenSimplexNoise
	var startx: int
	var endx: int
	var starty: int
	var endy: int
	var numpoints = pow(2, SubDivide)
	match(edge):
		Edge.TOP:
			startx = 0
			endx = TerrainX + TerrainWidth
			starty = 0
			endy = 0
			noise.get_noise_2d()
			pass
		Edge.BOTTOM:
			pass
		Edge.LEFT:
			pass
		Edge.RIGHT:
			pass
			
	var result: Array = Array()
	for y in range(starty, endy):
		for x in range(startx, endx):
			pass
