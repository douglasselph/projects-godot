extends Spatial

# var _ring: WorldTerrainRing

func _ready():
	var params = WorldTerrainRing.RingParams.new()
	params.create = CreateBlock.new()
	params.maxLOD = 1
	params.boxUnitSize = 2.0
	var ring = WorldTerrainRing.new(params)
	ring.apply(Vector3(0, 0, 0))
	
	add_child(ring)
