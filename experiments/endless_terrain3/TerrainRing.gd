extends Spatial
#
# BASE STRUCTURE
# --------------
# There is fixed number of terrain blocks with the center point of the camera always in one of the middle blocks.
# That is, there is a central 4 blocks, 2x2, with the finest detail and with the center point within on of the these 4.
# Call this level of detail zero or LOD-0.
#
# Surrouding these 4 blocks is a ring of 12 blocks, of the same width/height. Call this LOD-1.
# The actual world size of one of these blocks can vary. For starters the actual size will be 2.
#
# Surrounding LOD-1 16 blocks is a ring of 12 LOD-2 blocks, where each block is twice the size of the LOD-1 blocks.
#
# Surrounding the LOD-2 is another ring of 12 LOD-3 blocks, each block being twice the size of the LOD-2 blocks.
#
# This pattern can continue indefinately. To see how that is true, a graph pattern representation can be made,
# or perhaps an electronic equivalent. But here is how levels LOD-0, LOD-1, LOD-2, and LOD-3 would map out:
#      +-------+-------+-------+-------+
#      |   3   |   3   |   3   |   3   |
#      |       |       |       |       |
#      +-------+---+---+---+---+-------+
#      |   3   | 2 | 2 | 2 | 2 |   3   |
#      |       |   |   |   |   |       |
#      |       +---+-+-+-+-+---+       |
#      |       | 2 |1|1|1|1| 2 |       |
#      |       +   +-+-+-+-+   |       |
#      |       |   |1|0|0|1|   |       |
#      +-------+---+-+-+-+-+---+-------+
#      |   3   | 2 |1|0|0|1| 2 |   3   |
#      |       +   +-+-+-+-+   +       |
# 	   |       |   |1|1|1|1|   |       |
#      |       +---+-+-+-+-+---+       |
#      |       | 2 | 2 | 2 | 2 |       |
#      |       |   |   |   |   |       |
#      +-------+---+-+-+-+-+---+-------+
#      |   3   |   3   |   3   |   3   |
#      |       |       |       |       |
#      +-------+-------+-------+-------+
#
# ALGORITHM
# ---------
#
# THe alogorithm works as follows:
#   1. CP is the central Vector3 point, which represents where the player is.
#   2. Given CP, we first compute the X,Y coordinate of the upper-left box of the central
#      4 at LOD-0. Call this UL LOD-0. Computing this value is one of the most
#      complicated bits of this algorith because CP can live anywhere within the 
#      the central 4 without causig a seismic shift X,Y's. More on this later.
#   3. Given UL LOD-0 the coordinates of the remaining 3 for LOD-0 can be computed.
#      Note that the perlin parameters for all the blocks are always the same, except
#      the location and size of the blocks
#   4. Each ring then can be computed, for whatever LOD is desired based on the 
#      computrd value of UL LOD-0
#   5. Once the coordinate are all computed, the actual terrain meshes can be built.
#      Note that during movement the net-effect will be that a row or column
#      lost and another gained across the central 16 and rings.The rest of the terrains
#      will remain as they are. Because of this there is always exactly the same number
#      of blocks as the camera moves about. The only change will be the coordinates and 
#      size of each block. The other perlin parameters remain constant.
#
class_name TerrainRing

var _params: TerrainRingParams
var _textureNumPts: int
var _box4size: float
var _terrains = {}
var _coordiate_UL_16: Vector2 = Vector2.INF
var _globalSize: Vector2 = Vector2.ZERO
var _globalMin: Vector2 = Vector2.INF

class TerrainBase:
	var position: Vector2
	var size: Vector2
	var subDivide: int
	var globalSize: Vector2
	var globalMin: Vector2
	var textureEdgeNumPts: int
	var octaves: int
	var amplitude: float
	var lucanarity: float
	var exponentiation: float
	var period: float
	
class TerrainRingParams:
	var create_terrain: FuncRef
	var maxLOD: int
	var maxSubDivide: int = 256
	var boxUnitSize: float = 2.0
	var octaves: int
	var amplitude: float
	var lucanarity: float
	var exponentiation: float
	var period: float
	
func _init(params: TerrainRingParams):
	_params = params
	_textureNumPts = 512 * int(pow(2, params.maxLOD))
	_box4size = params.boxUnitSize * 2
	
class Coordinate:
	var position: Vector2
	var lod: int
	
	func _init(pos: Vector2, ld: int):
		position = pos
		lod = ld

func clear():
	for key in _terrains.keys():
		var terrain = _terrains[key]
		remove_child(terrain)
	_terrains.clear()

func reapply():
	clear()
	_apply(_coordiate_UL_16)
	
func apply(centerPosition: Vector3):
	# Compute the upper left box coordinate of the central 4 boxes.
	var UL_coordinate = _compute_UL_coordinate(centerPosition)
	
	# If it didn't change, nothing to do
	if UL_coordinate == _coordiate_UL_16:
		return
	
	_apply(UL_coordinate)
	
func _apply(ul_coordinate: Vector2):
	
	_coordiate_UL_16 = ul_coordinate
	
	# Generate the coordinates for the 16 (LOD-1)
	var coordinates = []
	coordinates.append_array(_compute_coordinates_central4(ul_coordinate))
	
	# Generate the ring coordinates for each level of detail (LOD-X)
	for lod in range(1, _params.maxLOD+1):
		coordinates.append_array(_compute_coordinates_ring_lod(lod, ul_coordinate))
	
	# Compute full range and first position
	_compute_global_bounds(coordinates)
	
	if _terrains.size() == 0:
		# Nothing yet built, so build it all
		for coordinate in coordinates:
			var terrain = _params.create_terrain.call_func("create_terrain") as TerrainBase
			_assignParams(terrain, coordinate)
			add_child(terrain)
			_terrains[_keyOf(coordinate)] = terrain
	else:
		# Compute what is already built, what is needed, and what can be repurposed
		var neededCoordinates = _compute_needed_coordinates(coordinates)
		var unusedTerrainKeys = _compute_unused_keys(coordinates)
		for coordinate in neededCoordinates:
			var repurposedKey = unusedTerrainKeys[0]
			var terrain = _terrains[repurposedKey]
			unusedTerrainKeys.remove(0)
			_assignParams(terrain, coordinate)
			terrain.applyParams()

# Given a central coordinate compute the coordinate of the upper-left box of the central 4 boxes.
# This computation needs to be such that while the camera (or CP) moves within the 4, it should 
# not change what the computed UL is. It only changes as soon as the CP moves outside one of 
# the central 4. At this point, the central 4 shifts to be a new central 4, and all the surrounging
# rings will follow accordingly.
func _compute_UL_coordinate(centralPos: Vector3) -> Vector2:
	# Treat the unit 4 as a single unit cell. Compute it's upper-left and pass it back.
	var box4x = floor(centralPos.x / _box4size)
	var box4z = floor(centralPos.y / _box4size)
	var ul_x = box4x * _box4size
	var ul_z = box4z * _box4size
	return Vector2(ul_x, ul_z)

# Given the UL coordinate of the central 4, produce all the coordinates of the 4 central boxes.
func _compute_coordinates_central4(ul_coordinate: Vector2) -> Array:
	var startx = ul_coordinate.x
	var startz = ul_coordinate.y
	var z = startz
	var result = []
	for zi in range(0, 2):
		var x = startx
		for xi in range(0, 2):
			result.append(Coordinate.new(Vector2(x, z), 0))
			x += _params.boxUnitSize
		z += _params.boxUnitSize
	return result

func _compute_global_bounds(coordinates: Array):
	_globalMin = Vector2.INF
	var globalMax: Vector2 = -Vector2.INF
	for coordinate in coordinates:
		var minx = coordinate.position.x
		var miny = coordinate.position.y
		if minx < _globalMin.x:
			_globalMin.x = minx
		if miny < _globalMin.y:
			_globalMin.y = miny
		var sizeOfBox = _sizeOfBox(coordinate)
		var maxx = coordinate.position.x + sizeOfBox
		var maxy = coordinate.position.y + sizeOfBox
		if maxx > globalMax.x:
			globalMax.x = maxx
		if maxy > globalMax.y:
			globalMax.y = maxy
	_globalSize.x = globalMax.x - _globalMin.x
	_globalSize.y = globalMax.y - _globalMin.y
	
# Given the central UL coordinate, compute the coordinates for the ring at the 
# indicated level of detail (LOD). Returned is an array of 12 Coordinate's.
# Each ring grows in size by a factor of 2 for each increasing LOD.
func _compute_coordinates_ring_lod(lod: int, ul_coordinate: Vector2) -> Array:
	var startx: float = ul_coordinate.x - _params.boxUnitSize
	var startz: float = ul_coordinate.y - _params.boxUnitSize
	var step = _params.boxUnitSize
	for s in range(1, lod):
		step *= 2
		startx -= step
		startz -= step
	var result = []
	var z: float = startz
	var x: float
	for zi in range(0, 4):
		x = startx
		for xi in range(0, 4):
			if zi == 0 or zi == 3 or xi == 0 or xi == 3:
				result.append(Coordinate.new(Vector2(x, z), lod))
			x += step
		z += step
	return result

func _compute_needed_coordinates(coordinates: Array) -> Array:
	var needed = []
	for coordinate in coordinates:
		var key = _keyOf(coordinate)
		if not _terrains.has(key):
			needed.append(coordinate)
	return needed

func _compute_unused_keys(coordinates: Array) -> Array:
	var used = []
	for coord in coordinates:
		used.append(_keyOf(coord))
	var unused = []
	for key in _terrains.keys:
		if not used.has(key):
			unused.append(key)
	return unused

func _assignParams(terrain: TerrainBase, coordinate: Coordinate):
	var subDivide: float = _params.subDivide
	var size: float = _params.boxUnitSize
	if coordinate.lod > 1:
		var factor = pow(2, coordinate.lod-1)
		subDivide /= factor
		size *= factor
	
	terrain.subDivide = int(subDivide)
	terrain.size = Vector2(size, size)
	terrain.position = coordinate.position
	
	terrain.globalSize = _globalSize
	terrain.globalMin = _globalMin
	terrain.textureEdgeNumPts = _textureNumPts
	
	terrain.octaves = _params.octaves
	terrain.amplitude = _params.amplitude
	terrain.lucanarity = _params.lucanarity
	terrain.exponentiation = _params.exponentiation
	terrain.period = _params.period
	
func _keyOf(coordinate: Coordinate) -> String:
	return "%f,%f,%d" % [coordinate.position.x, coordinate.position.y, coordinate.lod]
	
func _sizeOfBox(coordinate: Coordinate) -> float:
	if coordinate.lod <= 1:
		return _params.boxUnitSize
	return pow(2, coordinate.lod-1) * _params.boxUnitSize
	
