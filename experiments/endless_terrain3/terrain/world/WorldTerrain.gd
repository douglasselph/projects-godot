extends Spatial

var _ring: WorldTerrainRing

func _ready():
	var params = WorldTerrainRing.RingParams.new()
	params.create = CreateBlock.new()
	params.maxLOD = 0
	params.boxUnitSize = 2.0
	_ring = WorldTerrainRing.new(params)
	_ring.apply(Vector3(0, 0, 0))
	
	add_child(_ring)
