#
# STORAGE STRUCTURE
# -----------------
# This class is intended to whole the entire world mesh structure that holds the terrain the player can see.
# As the player moves, eventually they move out of their central box, in which case the entire mesh is reset
# effectively moving the world to the player, rather than the player moving through the world.
#
# Doing it this way means there is never any need to allocate new meshes, or deallocate any meshes. Once the entire mesh
# structure has been created, it will be reused to display whatever the user can see by constantly updating the points
# within the mesh. 
#
# There is fixed number of terrain blocks with the center point of the camera always in one of the middle blocks.
# That is, there is a central 4 blocks, 2x2, with the finest detail and with the center point within checked of the these 4.
# Call this level of detail zero or LOD-0.
#
# Surrounding the 4 blocks of LOD-0 is a ring of 12 LOD-1 blocks of the same width and height size of the LOD-0 blocks. 
# These blocks can have a different level of detail (less vertices), than LOD-0, though each block has the same width and height as LOD-0.
#
# Surrounding LOD-1 is a ring of another 12 blocks at LOD-2, yet each width and height is exactly twice the size of the LOD-1 blocks.
# Again, rurrounding the LOD-2 block ring is another ring of 12 LOD-3 blocks, each block being twice the size of the LOD-2 blocks.
#
# This pattern can continue indefinately. To see how that is true, a graph pattern representation can be made,
# or perhaps an electronic equivalent. But here is how levels LOD-0, LOD-1, LOD-2, and LOD-3 would map out:
#
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
# INPUT PARAMETERS
# ---------------
# Height Generator: 
#   A function, that given an (X,Z) vertex will return the height (Y). The supplied
#   height generator can generate the height in any fashion it wishes, whether it be from Perlin noise,
#   Diamond/Square, or a Stitch.
# Level Of Detail (LOD) Query:
#   A function, that given a level of detail, will return the number of subDivisions the associated
#   mesh should have.
# Central Point:
#   A variable that indicates what the central point is. This is effectively where the player or camera
#   is within the system. Based checked the central point (CP), the entire query of meshes can commence.
#
# DATA 
# ----
# Unit Size - holds the core unit size of both width and height of the LOD-0 boxes. It also is used
#             to determine the size of the LOD other boxes greater than 0. Specifically if > 0, then
#		      		pow(2, LOD-1) * unitSize.
# Central 4 - An array that holds the central four LOD-0 boxes, which all have the same width/height
#             as well as having the same subDivide (or number of vertices).
#
#
# MOVEMENT ALGORITHM
# ------------------
# As the central point moves, nothing will happen until the CP moves outside one of the central 4.
# When this occurs, a seismic shift occurs. The changes are intentionally done in order of importance
# with the first being closest to what the player will be able to see. The last changes would be all 
# those vertexes that would be behind the player and thus will be done last. This will allow the whole
# process to be handled by a series of threads for a smoother felt transition.
#
# In order to accomplish this pattern additional vertex boxes, other than the mesh boxes actually seen,
# will be needed. The are referred to as transitionary boxes.
#
#
# The algorithm is ordered as follows:
#
#  1. Two of the central 4 remain as they are. The first is the LOD-0 box the player just moved out of.
#     The other kept LOD-0 box is one the adjacent relative to the direction moved. These two LOD-0 boxes 
#     are left untouched.
#  3. The other 2 LOD-0 boxes that are being left behind will be repurposed to hold the incoming LOD-1 meshes. 
#     But before that happens, their vertex values will be saved into transitionary boxes 
#     so that later they can be referenced to help build the LOD-1 boxes behind the player.
#     Since that is happening outside the field of view of the camera, it will be done later.
#     For now these two LOD-0 will take checked the meshes of two immediately incoming LOD-1 boxes that the 
#     player is moving into.
# 
#     If the subDivide is the same, the incoming LOD-1 meshes can be used as is. If the subDivide 
#     is increasing, then queries to the Height Generator is done to get the heights of the new vertices.
#  4. Now we have the new central 4 LOD-0 boxes and can move in order of the field of view into the rings.
#     The The first seen is he four LOD-1 boxes behind the player to hold half the vertices of the approaching
#     2 LOD-2 boxes. The LOD-2 boxes are twice the size of the LOD-1 boxes, as well as having fewer
#     vertices of their decreasing LOD (Note: LOD-1 -> LOD-2 means a lower level of detail).
#     Before overwriting the values of the 4 LOD-1 meshes, the existing meshes are saved morph into the 4 LOD-1 that are behind the player, which are being repurposed.
#     of by the previous step. Of the remaining 10, 6 can be left as they as the LOD is the same.
#     For the remaining 4 
#  3. Now the outer rings shift, starting with the LOD-1 ring. 4 LOD-1 blocks will move into the LOD-2
#     ring, and another 4 will 
# 
class_name WorldTerrainRing
extends Node3D


class RingParams:
	var maxLOD: int
	var boxUnitSize: float
	var create: CreateBase
	var initialSubDivide = 128


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


var _numLOD: int
var _textureNumPts: int
var _boxUnitSize: float
var _box4size: float
# An array of arrays holding boxes at each LOD.
var _boxes = [] 
var _create: CreateBase
var _initialSubDivide: int


func _init(params: RingParams):
	_numLOD = params.maxLOD + 1
	_boxUnitSize = params.boxUnitSize
	_box4size = _boxUnitSize * 2
	_textureNumPts = 256 * int(pow(2, _numLOD))
	_create = params.create
	_initialSubDivide = params.initialSubDivide
	
	_setup_boxes()
	
	print("SETUP:")
	for array in _boxes:
		for box in array:
			box.display()


func apply(centerPosition: Vector3):
	# Compute the upper left box coordinate of the central 4 boxes.
	var UL_coordinate = _compute_UL_coordinate(centerPosition)
	
	print("UL_coordinate=", UL_coordinate)
	
	_compute_coordinates(UL_coordinate)
	
	print("BUILDING")
	
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
				box.terrain = _create.create(params)
				add_child(box.terrain.instance)
			else:
				box.terrain.params = params
				box.terrain.modify()
			box.state = State.READY


func _setup_boxes():
	# Center 4
	var boxes: Array = []
	for x in range(0, 4):
		var box = Box.new(0)
		_setupBox(box)
		boxes.append(box)
	_boxes.append(boxes)
	
	# All the rings
	for lod in range(1, _numLOD):
		boxes = Array()
		for x in range(0, 12):
			var box = Box.new(lod)
			_setupBox(box)
			boxes.append(box)
		_boxes.append(boxes)
		

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


func _setupBox(box: Box):
	var subDivide = _initialSubDivide
	var size = _boxUnitSize
	if box.lod > 1:
		var factor = pow(2, box.lod-1)
		subDivide /= factor
		size *= factor
	box.subDivide = subDivide
	box.size = size
