class_name TerrainPerlin

extends TerrainBase


var _noise: OpenSimplexNoise
var _uvs = []
var _vertices = []
var _size: Vector2


func _init(params: TerrainParams,params):
	_noise = OpenSimplexNoise.new()
	_noise.octaves = TerrainInfo.Octaves
	_noise.period = TerrainInfo.Period
	_noise.persistence = TerrainInfo.Persistence
	_noise.lacunarity = TerrainInfo.Lucanarity

	build()


func build():
	var params = self.params
	
	_size = params.size
	
	var position = params.position
	var num_pts_per_side = params.subDivide
	var step_x = _size.x / num_pts_per_side
	var step_z = _size.y / num_pts_per_side
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	
	var pos_x = position.x
	var pos_z = position.y
	
	_uvs.clear()
	_vertices.clear()
	
	for x in range(_size.x):
		pos_x = position.x
		for z in range(_size.y):
			_generate_quad(pos_x, pos_z)
			pos_z += step_z
		pos_x += step_x
	
	for i in range(_vertices.size()):
		st.add_uv(_uvs[i]) 				# Must be added first
		st.add_vertex(_vertices[i])
	
	st.generate_normals()
	
	var instance = MeshInstance3D.new()
	self.instance = instance
	
	instance.mesh = st.commit()
	
	var key = "TerrainPerlin_%d_%d" % [position.x, position.y]
	instance.set_name(key)
	instance.cast_shadow = 1


func _generate_quad(pos_x: float, pos_z: float):
	_vertices.push_back(_create_vertex(pos_x, pos_z + _size.y))
	_vertices.push_back(_create_vertex(pos_x, pos_z))
	_vertices.push_back(_create_vertex(pos_x + _size.x, pos_z))
	
	_vertices.push_back(_create_vertex(pos_x, pos_z + _size.y))
	_vertices.push_back(_create_vertex(pos_x + _size.x, pos_z))
	_vertices.push_back(_create_vertex(pos_x + _size.x, pos_z + _size.y))
	
	_uvs.push_back(Vector2(0, 0))
	_uvs.push_back(Vector2(0, 1))
	_uvs.push_back(Vector2(1, 1))
	
	_uvs.push_back(Vector2(0, 0))
	_uvs.push_back(Vector2(1, 1))
	_uvs.push_back(Vector2(1, 0))


func _create_vertex(x: float, z: float) -> Vector3:
	var y = _noise.get_noise_2d(x, z) * TerrainInfo.Amplitude
	return Vector3(x, y, z)


func build2():
	var planeMesh = PlaneMesh.new()
	var params = self.params
	planeMesh.size = params.size
	planeMesh.subdivide_width = params.subDivide
	planeMesh.subdivide_depth = params.subDivide
	
	var surfaceTool = SurfaceTool.new()	
	surfaceTool.create_from(planeMesh, 0)
	surfaceTool.set_material(material)
	
	var arrayPlane = surfaceTool.commit()
	
	var dataTool = MeshDataTool.new()
	
	dataTool.create_from_surface(arrayPlane, 0)
	
	var amplitude = TerrainInfo.Amplitude
	for i in range(dataTool.get_vertex_count()):
		var vertex = dataTool.get_vertex(i)
		vertex.y = _noise.get_noise_2d(vertex.x, vertex.z) * amplitude
		dataTool.set_vertex(i, vertex)
		
	# Cleanup
	for i in range(arrayPlane.get_surface_count()):
		arrayPlane.surface_remove(i)
		
	dataTool.commit_to_surface(arrayPlane)
	surfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surfaceTool.create_from(arrayPlane, 0)
	surfaceTool.generate_normals()
	
	self.instance = MeshInstance3D.new()
	self.instance.mesh = surfaceTool.commit()
	self.instance.create_trimesh_collision()
	self.instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func modify():
	var pmesh = self.instance.mesh as PlaneMesh
	var arrays = pmesh.get_mesh_arrays()
	var varray = arrays[Mesh.ARRAY_VERTEX]
	for i in varray.size():
		var value = varray[i]
		print("VALUE ", i, "=", value)
	
