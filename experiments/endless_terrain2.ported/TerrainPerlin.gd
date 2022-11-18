extends MeshInstance3D

class_name TerrainPerlin

# The UL position of the mesh within the global space.
@export var TerrainPos: Vector2 = Vector2.ZERO
# The size of the local mesh
@export var TerrainSize: Vector2 = Vector2(2, 2)
# The minimum UL position of any mesh coordinate for all meshes used within the global space. 
@export var TerrainGlobalMin: Vector2 = Vector2.ZERO
# The full width and height of all meshes shared between the single noise texture.
@export var TerrainGlobalSize: Vector2 = Vector2(2, 2)

@export var TextureEdgeNumPts: float = 512
@export var SubDivide: int = 256
@export var Octaves: int = 4
@export var Period: int = 128
@export var Persistence: float = 0.5
@export var Amplitude: float = 1.0
@export var Exponentiation: float = 1.0
@export var Lucanarity: float = 2.0

func _ready():
	applyParams()

func applyParams():
	var halfSize = TerrainSize / 2
	position = Vector3(TerrainPos.x + halfSize.x, 0, TerrainPos.y + halfSize.y)
	mesh.size = Vector2(TerrainSize.x, TerrainSize.y)
	
	mesh.subdivide_width = SubDivide
	mesh.subdivide_depth = SubDivide
	
	var material = get_active_material(0) as ShaderMaterial
	var texture = material.get_shader_parameter("noise") as NoiseTexture
	
	material.set_shader_parameter("meshGlobalSize", TerrainGlobalSize)
	
	var offsetX = TerrainPos.x - TerrainGlobalMin.x + halfSize.x
	var offsetY = TerrainPos.y - TerrainGlobalMin.y + halfSize.y
	var offset = Vector2(offsetX, offsetY)
	
	material.set_shader_parameter("meshOffset", offset)
	
	print(TerrainPos, ": offset=", offset, ", position=", String(position), ", size=", String(mesh.size))
	
	material.set_shader_parameter("amplitude", Amplitude)
	material.set_shader_parameter("exponentiation", Exponentiation)
	texture.width = TextureEdgeNumPts
	texture.height = TextureEdgeNumPts
	var noise = texture.noise as OpenSimplexNoise
	noise.octaves = Octaves
	noise.period = Period
	noise.persistence = Persistence
	noise.lacunarity = Lucanarity

func displayInfo():
	var array = vertexArray()
	var width = vertexWidth()
	print(TerrainPos, ", ", TerrainSize, " Number of points=", array.size(), ", VertexWidth=", width)

func vertexArray() -> Array:
	var pmesh = mesh as PlaneMesh
	var arrays = pmesh.get_mesh_arrays()
	var varray = arrays[Mesh.ARRAY_VERTEX]
	return varray

func vertexWidth() -> int:
	return mesh.subdivide_width + 2
	
func vertexHeight() -> int:
	return mesh.subdivide_depth + 2

func heightArray() -> Array:
	var material = get_active_material(0) as ShaderMaterial
	var texture = material.get_shader_parameter("noise") as NoiseTexture
	var noise = texture.noise as OpenSimplexNoise
	var array = Array()
	var xstart: int = TerrainPos.x
	var ystart: int = TerrainPos.y
	var xend: int = xstart + vertexWidth()
	var yend: int = ystart + vertexHeight()
	for y in range(ystart, yend):
		for x in range(xstart, xend):
			var h = noise.get_noise_2d(x, y)
			var vec = Vector3(x, h, y)
			array.append(vec)
	return array
	
func edgeOf(edge: Edge):
	var material = get_active_material(0) as ShaderMaterial
	var texture = material.get_shader_parameter("noise") as NoiseTexture
	var noise = texture.noise as OpenSimplexNoise
	var startx: int
	var endx: int
	var starty: int
	var endy: int
	var numpoints = pow(2, SubDivide)
	match(edge):
		Edge.TOP:
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
