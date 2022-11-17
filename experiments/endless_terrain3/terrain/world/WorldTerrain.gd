extends Spatial

# Try#2:
var _numLOD: int
var _textureNumPts: int
var _boxUnitSize: float
var _box4size: float
var _boxes = [] 
var _initialSubDivide: int

enum State { UNSET, AVAILABLE, TRANSITIONING, READY }

class Box:
	var state = State.UNSET
	var position: Vector2
	var lod: int
	var terrain: TerrainBase
	var subDivide: int
	var size: int
	
	func _init(lod: int):
		self.lod = lod


	func display():
		var hasTerrain = false
		if terrain != null: 
			hasTerrain = true
		print("Lod:", lod, ", position=", position, ", subDivide=", subDivide, ", size=", size, ", state=", state, ", hasTerrain=", hasTerrain)


# Try#1:
var _ring: WorldTerrainRing


func _ready():
	_buildTry2()


func _buildTry2():
	_numLOD = 1
	_boxUnitSize = 2.0
	_box4size = _boxUnitSize * 2
	_textureNumPts = 256 * int(pow(2, _numLOD))
	_initialSubDivide = 128

	_setup_boxes()
	
	var centerPosition = Vector3.ZERO
	var UL_coordinate = _compute_UL_coordinate(centerPosition)
	_compute_coordinates(UL_coordinate)
	
	for array in _boxes:
		for box in array:
			box.display()
			if box.state == State.READY:
				continue
			var params = TerrainParams.new()
			params.position = box.position
			params.subDivide = box.subDivide
			params.size = Vector2(box.size, box.size)

			if box.terrain == null:
				box.terrain = TerrainPerlin.new(params)
				add_child(box.terrain.instance)
			else:
				box.terrain.params = params
				box.terrain.modify()
			box.state = State.READY


func _compute_UL_coordinate(centralPos: Vector3) -> Vector2:
	# Treat the unit 4 as a single unit cell. Compute it's upper-left and pass it back.
	var box4x = floor(centralPos.x / _box4size)
	var box4z = floor(centralPos.y / _box4size)
	var ul_x = box4x * _box4size
	var ul_z = box4z * _box4size
	return Vector2(ul_x, ul_z)


func _setup_boxes():
	# Center 4
	var boxes: Array = []
	for x in range(0, 4):
		var box = Box.new(0)
		_setup_box(box)
		boxes.append(box)
	_boxes.append(boxes)
	
	# All the rings
	for lod in range(1, _numLOD):
		boxes = Array()
		for x in range(0, 12):
			var box = Box.new(lod)
			_setup_box(box)
			boxes.append(box)
		_boxes.append(boxes)


func _setup_box(box: Box):
	var subDivide = _initialSubDivide
	var size = _boxUnitSize
	if box.lod > 1:
		var factor = pow(2, box.lod-1)
		subDivide /= factor
		size *= factor
	box.subDivide = subDivide
	box.size = size


func _compute_coordinates(ul_coordinate: Vector2):
	
	var positions = _compute_coordinates_central4(ul_coordinate)
	_assignPositions(0, positions)
	
	for lod in range(1, _numLOD):
		positions = _compute_coordinates_ring_lod(lod, ul_coordinate)
		_assignPositions(lod, positions)


# Given the UL coordinate of the central 4, compute positions for the central 4.
func _compute_coordinates_central4(ul_coordinate: Vector2) -> Array:
	var startx = ul_coordinate.x
	var startz = ul_coordinate.y
	var z = startz
	var positions = []
	for zi in range(0, 2):
		var x = startx
		for xi in range(0, 2):
			positions.append(Vector2(x, z))
			x += _boxUnitSize
		z += _boxUnitSize
	return positions


# Given the central UL coordinate, compute and return the coordinates for the ring at the 
# indicated level of detail (LOD)s.
func _compute_coordinates_ring_lod(lod: int, ul_coordinate: Vector2) -> Array:
	var startx: float = ul_coordinate.x - _boxUnitSize
	var startz: float = ul_coordinate.y - _boxUnitSize
	var step = _boxUnitSize
	for s in range(1, lod):
		step *= 2
		startx -= step
		startz -= step

	var positions = []
	var z: float = startz
	var x: float
	for zi in range(0, 4):
		x = startx
		for xi in range(0, 4):
			if zi == 0 or zi == 3 or xi == 0 or xi == 3:
				positions.append(Vector2(x, z))
			x += step
		z += step
	
	return positions


# For the  given LOD, assign boxes to be placed at the given world positions.
# Reuse boxes that are already at a desired position.
func _assignPositions(lod: int, positions: Array):

	for box in _boxes[0]:
		box.state = State.AVAILABLE
	
	var positionsLeft = []
	for position in positions:
		var box = _boxAtPosition(lod, position)
		if box != null:
			box.state = State.READY
		else:
			positionsLeft.append(position)
	
	for position in positionsLeft:
		var box = _boxQueryAvailable(lod)
		if box != null:
			box.position = position
			box.state = State.TRANSITIONING


func _boxAtPosition(lod: int, position: Vector2) -> Box:
	for box in _boxes[lod]:
		if box.position == position:
			return box
	return null


func _boxQueryAvailable(lod: int) -> Box:
	for box in _boxes[lod]:
		if box.state == State.AVAILABLE:
			return box
	return null



#
# FAILED TRY#1
#
func _buildTry1():
	var params = WorldTerrainRing.RingParams.new()
	params.create = CreateBlock.new()
	params.maxLOD = 0
	params.boxUnitSize = 2.0
	_ring = WorldTerrainRing.new(params)
	_ring.apply(Vector3(0, 0, 0))
	
	add_child(_ring)
	
