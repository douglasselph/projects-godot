class_name Chunk
extends MeshInstance3D

var position : Vector2
var grid_position : Vector2
var key : String
var noise : OpenSimplexNoise
var material : Material

var vertices = []
var uvs = []


func _init(grid_pos: Vector2,n : OpenSimplexNoise,mat: Material):
	self.grid_position = grid_pos
	self.position = Vector2(
		grid_pos.x * Globals.CHUNK_SIZE - Globals.CHUNK_SIZE / 2.0,
		grid_pos.y * Globals.CHUNK_SIZE - Globals.CHUNK_SIZE / 2.0
	)
	self.key = "TerrainChunk_%d_%d" % [grid_pos.x, grid_pos.y]
	self.noise = n
	self.material = _setup_material(mat)


func _setup_material(material: Material) -> Material:
	if material:
		return material
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.0)
	return mat
	
	
func generate():
	var st = SurfaceTool.new()
	
	for x in range(Globals.CHUNK_QUAD_COUNT):
		for z in range(Globals.CHUNK_QUAD_COUNT):
			_generate_quad(
				Vector3(position.x + x * Globals.QUAD_SIZE, 0, position.y + z * Globals.QUAD_SIZE),
				Vector2(Globals.QUAD_SIZE, Globals.QUAD_SIZE)
			)

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	for i in range(vertices.size()):
		st.add_uv(uvs[i]) # Must be added first
		st.add_vertex(vertices[i])
	
	st.generate_normals()
	var mesh = st.commit()
	
	self.set_name(key)
	self.mesh = mesh
	self.cast_shadow = 1


func _generate_quad(pos: Vector3, size: Vector2):
	vertices.push_back(_create_vertex(pos.x, pos.z + size.y))
	vertices.push_back(_create_vertex(pos.x, pos.z))
	vertices.push_back(_create_vertex(pos.x + size.x, pos.z))
	
	vertices.push_back(_create_vertex(pos.x, pos.z + size.y))
	vertices.push_back(_create_vertex(pos.x + size.x, pos.z))
	vertices.push_back(_create_vertex(pos.x + size.x, pos.z + size.y))
	
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(0, 1))
	uvs.push_back(Vector2(1, 1))
	
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(1, 1))
	uvs.push_back(Vector2(1, 0))


func _create_vertex(x: float, z: float) -> Vector3:
	var y = noise.get_noise_2d(x, z) * Globals.AMPLITUDE
	return Vector3(x, y, z)
