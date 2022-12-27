class_name BlockFunnel
extends Node
#
# BASE STRUCTURE
# --------------
# There is grid of terrain blocks with a center point representing where the player will be situated.
#
# BASE BLOCK FACTOR: The base block factor is what power of 2 should be used to compute the number 
# of blocks per side. For example, a value of 2 means that the number of blocks per side is 4, which 
# in turn means that there will be a 4x4 grid as the center blocks. Each block in the center is the 
# same size.
#
# Surrouding these center blocks is a ring of blocks where the number of blocks on each side matches 
# the computed number of blocks per side, but covering twice the distance. This means that there will 
# be shared corners where the sides overlap.
#
# For example, if the base block factor is 2, the number of blocks per side is 4, which in turn would
# mean that for the surrounding ring there will be 12 blocks.
#
# As so:
#
#      +-------+-------+-------+-------+
#      |   2   |   2   |   2   |   2   |
#      |       |       |       |       |
#      +-------+---+---+---+---+-------+
#      |   2   | 1 | 1 | 1 | 1 |   2   |
#      |       |   |   |   |   |       |
#      |       +---+-+-+-+-+---+       |
#      |       | 1 |0|0|0|0| 1 |       |
#      |       +   +-+-+-+-+   |       |
#      |       |   |0|0|0|0|   |       |
#      +-------+---+-+-+-+-+---+-------+
#      |   2   | 1 |0|0|0|0| 1 |   2   |
#      |       +   +-+-+-+-+   +       |
# 	   |       |   |0|0|0|0|   |       |
#      |       +---+-+-+-+-+---+       |
#      |       | 1 | 1 | 1 | 1 |       |
#      |       |   |   |   |   |       |
#      +-------+---+-+-+-+-+---+-------+
#      |   2   |   2   |   2   |   2   |
#      |       |       |       |       |
#      +-------+-------+-------+-------+
#
# RING DEPTH: This pattern of adding rings can be continued indefinately. Therefore there a ring 
# depth which indicates how many rings surrounding the core blocks there are. A value of 0 means 
# no rings, a value of 1 means one ring of 12 blocks. A value of 2 means two rings, etc.
#
# BLOCK POINTS SIZE FACTOR: The block points size factor, represents the power of 2 used to compute 
# the size of each block in points. For example a block size factor of 8 means each block would have
# a size of 256 ponits, no matter if it is in the center or in one of the rings. This value will
# be used as the dimension for images created for the block.
#
# BLOCK CENTER WORLD SIZE : The block center world size is world size of each center block. 
# For example, if the block center world size is 50, and the base block factor is 2, this would
# mean the center group would have a size of 200. Which in turn means the first ring would
# have a side length of 1000.
#
# GRID WORLD CENTER: Set the world center coordinate that will be used to compute the world
# positions of all the blocks.
# 
# FUNCTIONS:
#
# QUERY BLOCKS: Using the Grid World Center, return a list of blocks, where each block shows:
#   
#   - WorldUL : The upper left world coordinate of the block
#   - WorldLR : The lower right world coordinate of the block.
#   - PointSize : The point size of the blok which can be used to construct an image.
#
# COMPUTE CENTER POINT: Given the current GRID WORLD CENTER point, round the given point to the
# existing system. That means, if the point is within the central 4, it will round to the current
# center point. Otherwise it will round to what the new center point should be assuming that 
# this point reflects player movement. The computation will use the BLOCK CENTER WORLD SIZE, and
# round to the corner nearest to the existing center point.
#

var _numBlocksPerSide: int
var _blockPointSize: int
var _ringDepth: int
var _blockCenterWorldSize: float
var _pixelsPerPoint: float
var _gridWorldCenter: Vector2 = Vector2(0, 0)
var _blocks: Array[_Block] = []


class Block:
	var worldUL: Vector2	# The world upper left of this block
	var worldLR: Vector2	# The world lower right of this block
	var size: Vector2i		# The size of this block in points (useful for image generation)


class _Block:
	var position: Vector2i  # The position of this block relative to the other blocks
	var factor: int

	func _init(pos: Vector2i, factor: int):
		position = pos
		self.factor = factor
		
	
	func computeWorldPosition(worldCenter: Vector2, pixelsPerPoint: float) -> Vector2:
		return position * pixelsPerPoint


	func computeWorldSize(centerBlockSize: float) -> Vector2:
		return Vector2(centerBlockSize, centerBlockSize) * factor
		


class Params:
	var baseBlockFactor: int = 2			# Power of 2 used to determine the number of blocks per side
	var ringDepth: int = 2		    		# How many rings around the center blocks
	var blockPointSizeFactor: int = 8   	# The number of points per block
	var blockCenterWorldSize: float = 250 	# The world side length of each center block.


func _init(params: Params):
	_numBlocksPerSide = pow(2, params.baseBlockFactor)
	_blockPointSize = pow(2, params.blockPointSizeFactor)
	_ringDepth = params.ringDepth
	_blockCenterWorldSize = params.blockCenterWorldSize
	_pixelsPerPoint = _blockCenterWorldSize / _blockPointSize
	_computeBlockPositions()


#
# Set the world center point for the grid.
#
func setGridWorldCenter(point: Vector2):
	_gridWorldCenter = point
	

#
# Given the ring position query the list of blocks based on the current world center point.
# RingPos of 0 refers to the central blocks.
# RingPos of 1 refers to the blocks of the first ring.
# RingPos of 2 refers to the blocks of the second outer ring, etc.
#
func queryBlocks(ringPos: int) -> Array[Block]:
	var factor = pow(2, ringPos+1)
	var blocks: Array[Block] = []

	for block in _blocks:
		if block.factor == factor:
			var create = Block.new()
			create.worldUL = block.computeWorldPosition(_gridWorldCenter, _pixelsPerPoint)
			var blockSize = block.computeWorldSize(_blockCenterWorldSize)
			create.worldLR = create.worldUL + Vector2(blockSize)
			create.size = Vector2i(_blockPointSize, _blockPointSize)
			blocks.append(create)

	return blocks

#
# Compute the new center point based on a specialized rounding effect from the given 
# input point, which is assumed to be the current layer position.
#
func computeCenterPoint(playerPos: Vector2) -> Vector2:
	var deltaPos = playerPos - _gridWorldCenter
	var normalizedPos = deltaPos / _blockCenterWorldSize
	var sign = normalizedPos.sign()
	var roundedPos = Vector2(
		floor(abs(normalizedPos.x)) * sign.x,
		floor(abs(normalizedPos.y)) * sign.y
	)
	return roundedPos


func _computeBlockPositions():
	_blocks.clear()
	for ringpos in range(_ringDepth+1):
		var factor = pow(2, ringpos+1)
		var start_posx = -_blockPointSize * _numBlocksPerSide/2 * factor
		var start_posy = start_posx
		var posx: int
		var posy = start_posy
		for y in range(_numBlocksPerSide):
			posx = start_posx
			for x in range(_numBlocksPerSide):
				if ringpos == 0 or y == 0 or y == _numBlocksPerSide-1 or x == 0 or x == _numBlocksPerSide-1:
					_blocks.append(_Block.new(Vector2i(posx, posy), factor))
				posx += _blockPointSize
			posy += _blockPointSize
