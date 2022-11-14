class_name TerrainPerlin

extends TerrainBase

var _noise: OpenSimplexNoise


func _init(params: TerrainParams).(params):
	_noise = OpenSimplexNoise.new()
	_noise.octaves = TerrainInfo.Octaves
	_noise.period = TerrainInfo.Period
	_noise.persistence = TerrainInfo.Persistence
	_noise.lacunarity = TerrainInfo.Lucanarity

	create()

func create():
	var planeMesh = PlaneMesh.new()
	var params = self.params
	planeMesh.size = params.size
	planeMesh.subdivide_width = params.subDivide
	planeMesh.subdivide_depth = params.subDivide
	
	var surfaceTool = SurfaceTool.new()	
	surfaceTool.create_from(planeMesh, 0)
	
	var arrayPlane = surfaceTool.commit()
	
	var dataTool = MeshDataTool.new()
	
	dataTool.create_from_surface(arrayPlane, 0)
	
	var amplitude = TerrainInfo.Amplitude
	for i in range(dataTool.get_vertex_count()):
		var vertex = dataTool.get_vertex(i)
		vertex.y = _noise.get_noise_3d(vertex.x, vertex.y, vertex.z) * amplitude
		dataTool.set_vertex(i, vertex)
		
	# Cleanup
	for i in range(arrayPlane.get_surface_count()):
		arrayPlane.surface_remove()
		
	dataTool.commit_to_surface(arrayPlane)
	surfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surfaceTool.create_from(arrayPlane, 0)
	surfaceTool.generate_normals()
	
	self.instance = MeshInstance.new()
	self.instance.mesh = surfaceTool.commit()
	self.instance.create_trimesh_collision()
	self.instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF

func modify():
		
	pass
