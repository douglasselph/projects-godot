class_name TerrainMap

extends TerrainBase

func _init(params: TerrainParams).(params):
	var planeMesh = PlaneMesh.new()
	planeMesh.size = params.size
	planeMesh.subdivide_width = params.subDivide
	planeMesh.subdivide_depth = params.subDivide
