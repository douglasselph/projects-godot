extends Spatial
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
# That is, there is a central 4 blocks, 2x2, with the finest detail and with the center point within on of the these 4.
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
#   is within the system. Based on the central point (CP), the entire query of meshes can commence.
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
#     For now these two LOD-0 will take on the meshes of two immediately incoming LOD-1 boxes that the 
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
	
class CreateBase:
	func create(params: TerrainParams) -> TerrainBase:
		return TerrainBase.new()
	
class Params:
	var maxLOD: int
	var boxUnitSize: float


enum State { UNSET, TRANSITIONING, READY }

class Box:
	var state = State.UNSET
	var position: Vector2
	var lod: int
	var terrain: TerrainBase
	
	func _init(lod: int):
		self.lod = lod
		
var _maxLOD: int
var _textureNumPts: int
var _boxUnitSize: float
var _box4size: float
var _initialized = false
# Fixed dictionary of all the boxes in the ring
var _boxes = {}
# Dictionary keyed by the current world positions being helf in the ring
var _positionsUsed = {}
# Transiting positions used
var _positionsUsedTransition = {}

func _init(params: Params):
	_maxLOD = params.maxLOD
	_boxUnitSize - params.boxUnitSize
	_box4size = _boxUnitSize * 2
	_textureNumPts = 512 * int(pow(2, _maxLOD))

	_setup_boxes()

func apply(centerPosition: Vector3):
	# Compute the upper left box coordinate of the central 4 boxes.
	var UL_coordinate = _compute_UL_coordinate(centerPosition)
	
	_compute_coordinates(UL_coordinate)
	
	# Prepare LOD-0: Only set positions of what the boxes will hold.
	if not _initialized:
		# First time
		pass
	
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

func _setup_boxes():
	
	# Center 4
	for zi in range(0, 2):
		for xi in range(0, 2): 
			_boxes[_keyOf(0, zi, xi)] = Box.new(0)
			
	# All the rings
	for lod in range(1, _maxLOD):
		var boxes = Array()
		for zi in range(0, 4):
			for xi in range(0, 4):
				if zi == 0 or zi == 3 or xi == 0 or xi == 3:
					_boxes[_keyOf(lod, zi, xi)] = Box.new(lod)

func _compute_coordinates(ul_coordinate: Vector2):
	
	_compute_coordinates_central4(ul_coordinate)
	
	for lod in range(1, _maxLOD+1):
		_compute_coordinates_ring_lod(lod, ul_coordinate)
	
# Given the UL coordinate of the central 4, compute all the positions of the 4 central boxes.
func _compute_coordinates_central4(ul_coordinate: Vector2):
	var startx = ul_coordinate.x
	var startz = ul_coordinate.y
	var z = startz
	var position: Vector2
	var key: String
	var newPositionsUsed = {}
	var box: Box
	for zi in range(0, 2):
		var x = startx
		for xi in range(0, 2):
			position = Vector2(x, z)
			_assignPosition(0, zi, xi, position)
			key = _keyOf(0, zi, xi)
			box = _boxes[key]
			if (_positionsUsed.containsKey(position)):
				newPositionsUsed[position] = key
			else:
				box.position = position
				box.state = State.TRANSITIONING
				newPositionsUsed[position] = key
			x += _boxUnitSize
		z += _boxUnitSize

# Given the central UL coordinate, compute the coordinates for the ring at the 
# indicated level of detail (LOD). Returned is an array of 12 Coordinate's.
# Each ring grows in size by a factor of 2 for each increasing LOD.
func _compute_coordinates_ring_lod(lod: int, ul_coordinate: Vector2):
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
				_boxes[_keyOf(lod, zi, xi)].position = Vector2(x, z)
			x += step
		z += step

func _assign_box_position(lod: int, zi: int, xi: int, position: Vector2):
	pass
	
func _keyOf(lod: int, zi: int, xi: int) -> String:
	return "%d,%d,%d" % [lod, zi, xi]
