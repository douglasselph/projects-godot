extends Node3D
#
# BASE STRUCTURE
# --------------
# There is fixed number of terrain blocks with the center point of the camera always in one of the middle blocks.
# That is, there is a central 4 blocks, 2x2, with the finest detail and with the center point within checked of the these 4.
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
#      the central 4 without causig a seismic shift X,Y's. More checked this later.
#   3. Given UL LOD-0 the coordinates of the remaining 3 for LOD-0 can be computed.
#      Note that the perlin parameters for all the blocks are always the same, except
#      the location and size of the blocks
#   4. Each ring then can be computed, for whatever LOD is desired based checked the 
#      computrd value of UL LOD-0
#   5. Once the coordinate are all computed, the actual terrain meshes can be built.
#      Note that during movement the net-effect will be that a row or column
#      lost and another gained across the central 16 and rings.The rest of the terrains
#      will remain as they are. Because of this there is always exactly the same number
#      of blocks as the camera moves about. The only change will be the coordinates and 
#      size of each block. The other perlin parameters remain constant.
#
class_name TerrainBlock

var _terrains = {} 
var _coordiate_UL_16: Vector2 = Vector2.INF

var _globalSize: Vector2 = Vector2.ZERO
var _globalMin: Vector2 = Vector2.INF

const _boxUnitSize: float = 2.0
const _box4size: float = _boxUnitSize * 2
const _max_LOD: int = TerrainInfo.MaxLOD
const _subDivide: int = 256
const _textureNumPts: int = 512 * int(pow(2, TerrainInfo.MaxLOD))

class Coordinate:
	var position: Vector2
	var lod: int
	
	func _init(pos: Vector2,ld: int):
		position = pos
		lod = ld

# Called when the node enters the scene tree for the first time.
func _ready():
	TerrainInfo.connect("terrain_values_changed",Callable(self,"_terrain_values_changed"))
	apply(Vector3.ZERO)
	
func clear():
	for key in _terrains.keys():
		var terrain = _terrains[key]
		remove_child(terrain)
	_terrains.clear()
	
func apply(centerPosition: Vector3):
	# Compute the upper left box coordinate of the central 4 boxes.
	var UL_coordinate = _compute_UL_coordinate(centerPosition)
	
	# If it didn't change, nothing to do
	if UL_coordinate == _coordiate_UL_16:
		return
	
	_apply(UL_coordinate)
	
func _apply(ul_coordinate: Vector2):
	
	_coordiate_UL_16 = ul_coordinate
	
	print("Computed ", ul_coordinate)
	
	# Generate the coordinates for the 16 (LOD-1)
	var coordinates = []
	coordinates.append_array(_compute_coordinates_central4(ul_coordinate))
	
	# Generate the ring coordinates for each level of detail (LOD-X)
	for lod in range(1, _max_LOD+1):
		coordinates.append_array(_compute_coordinates_ring_lod(lod, ul_coordinate))
	
	# Compute full range and first position
	_compute_global_bounds(coordinates)
	
	print("Computed global min ", _globalMin, " and global size ", _globalSize)
	
	if _terrains.size() == 0:
		# Nothing yet built, so build it all
		for coordinate in coordinates:
			var terrain = preload("res://TerrainPerlin.tscn").instantiate() as TerrainPerlin
			_assignParams(terrain, coordinate)
			add_child(terrain)
			_terrains[_keyOf(coordinate)] = terrain
			_show_size(terrain)
	else:
		# Compute what is already built, what is needed, and what can be repurposed
		var neededCoordinates = _compute_needed_coordinates(coordinates)
		var unusedTerrainKeys = _compute_unused_keys(coordinates)
		for coordinate in neededCoordinates:
			var repurposedKey = unusedTerrainKeys[0]
			var terrain = _terrains[repurposedKey]
			unusedTerrainKeys.remove_at(0)
			_assignParams(terrain, coordinate)
			terrain.applyParams()
			_show_size(terrain)

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
			print("coordinate(", x, ",", z, ")")
			x += _boxUnitSize
		z += _boxUnitSize
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
	var startx: float = ul_coordinate.x - _boxUnitSize
	var startz: float = ul_coordinate.y - _boxUnitSize
	var step = _boxUnitSize
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
				print("coordinate(", x, ",", z, ", ", lod, ")")
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

func _assignParams(terrain: TerrainPerlin, coordinate: Coordinate):
	var subDivide: float = _subDivide
	var size: float = _boxUnitSize
	if coordinate.lod > 1:
		var factor = pow(2, coordinate.lod-1)
		subDivide /= factor
		size *= factor
	
	terrain.SubDivide = int(subDivide)
	terrain.TerrainSize = Vector2(size, size)
	terrain.TerrainPos = coordinate.position
	
	terrain.TerrainGlobalSize = _globalSize
	terrain.TerrainGlobalMin = _globalMin
	terrain.TextureEdgeNumPts = _textureNumPts
	
	terrain.Octaves = TerrainInfo.Octaves
	terrain.Amplitude = TerrainInfo.Amplitude
	terrain.Lucanarity = TerrainInfo.Lucanarity
	terrain.Exponentiation = TerrainInfo.Exponentiation
	terrain.Period = TerrainInfo.Period
	
func _keyOf(coordinate: Coordinate) -> String:
	return "%f,%f,%d" % [coordinate.position.x, coordinate.position.y, coordinate.lod]
	
func _show_size(terrain: TerrainPerlin):
	terrain.displayInfo()

func _sizeOfBox(coordinate: Coordinate) -> float:
	if coordinate.lod <= 1:
		return _boxUnitSize
	return pow(2, coordinate.lod-1) * _boxUnitSize
	
func _terrain_values_changed():
	print("Terrain Values Changed")
	clear()
	_apply(_coordiate_UL_16)

#func _process(delta):
#	if Input.is_action_just_pressed("ui_select"):
#		show_values(acquire(Vector2(2, 0)))
#
#func show_values(terrain: TerrainPerlin):
#	print("{", keyOf(terrain), "} SHOW_VALUES: ")
#	var array2 = terrain.vertexArray()
#	print("Number of points=", array2.size())
#	var arraySize = array2.size()
#	for index in range(arraySize):
#		print("ARRAY[", index, "]=", array2[index])
#
#	var array3 = terrain.heightArray()
#	print("Number of points=", array3.size())
#	arraySize = array3.size()
#	for index in range(arraySize):
#		print("ARRAY[", index, "]=", array3[index])
#
#func analyze(params: TerrainParams):
#	analyze2(acquire(Vector2(params.x, params.y)))
#
#func analyze2(terrain: TerrainPerlin):
#	var noise = OpenSimplexNoise.new()
#	noise.octaves = terrain.Octaves
#	noise.period = terrain.Period
#	noise.persistence = terrain.Persistence
#	noise.lacunarity = 2
#	var startx = terrain.TerrainX
#	var starty = terrain.TerrainY
#	var width: float = terrain.TerrainWidth
#	var height: float = terrain.TerrainHeight
#	var vh: float = terrain.vertexHeight()
#	var vw: float = terrain.vertexWidth()
#	var dict = {}
#	for yi in range(vh):
#		for xi in range(vw):
#			var x: float = xi / vw * width + startx
#			var y: float = yi / vh * height + starty
#			print("[", x, ",", y, "]=", noise.get_noise_2d(x, y))
#
#	#var image = noise.get_image(512, 512)	
#	#var data = image.get_data()
#	#for x in range(10):
#	#	if x < data.size():
#	#		print("DATA ", x, "=", data[x])
