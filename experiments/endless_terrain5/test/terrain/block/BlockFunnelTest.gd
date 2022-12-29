class_name BlockFunnelTest
extends Node


func run():
	_queryBlocks_verifyNumCenterBlocksCorrect()
	
	for pointSizeFactor in [4, 6, 8]:
		_queryBlocks_verifyCenterBlocksSizeAsExpected(pointSizeFactor)
	
	for ringPos in [0, 1, 2]:
		for blockFactor in [2, 3, 4]:
			for pointSizeFactor in [4, 6, 8]:
				_queryBlocks_verifyBlockWorldPositions(ringPos, blockFactor, pointSizeFactor)

	_computeCenterPoint_verifyRounding()


func _queryBlocks_verifyNumCenterBlocksCorrect():
	# Arrange
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = 2 # Should produce 4 x 4 center blocks
	params.ringDepth = 0
	params.blockPointSizeFactor = 4 # Should generate a point size of 2^4 = 16
	var expectedNumBlocks = pow(2,2)*pow(2,2)
	var blockFunnel = BlockFunnel.new(params)
	# Act
	var blocks = blockFunnel.queryBlocks(0)
	# Assert
	assert(blocks.size() == expectedNumBlocks)
	

func _queryBlocks_verifyCenterBlocksSizeAsExpected(pointSizeFactor: int):
	# Arrange
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = 4
	params.ringDepth = 3
	params.blockPointSizeFactor = pointSizeFactor
	var expectedBlockSize = pow(2, params.blockPointSizeFactor)
	var blockFunnel = BlockFunnel.new(params)
	# Act
	for ring in range(params.ringDepth+1):
		var blocks = blockFunnel.queryBlocks(ring)
		# Assert
		for block in blocks:
			assert(block.pointSize.x == expectedBlockSize)
			assert(block.pointSize.y == expectedBlockSize)


func _queryBlocks_verifyBlockWorldPositions(ringPos: int, blockFactor: int, pointSizeFactor: int):
	# Arrange
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = blockFactor
	params.ringDepth = ringPos + 1
	params.blockPointSizeFactor = pointSizeFactor
	params.blockCenterWorldSize = 50
	var expectedNumBlocksPerSide = pow(2, params.baseBlockFactor)
	var expectedBlockSize = pow(2, params.blockPointSizeFactor)
	var expectedWorldSizeOfEachBlock = params.blockCenterWorldSize * pow(2, ringPos)
	var expectedStartPos = -expectedNumBlocksPerSide/2 * expectedWorldSizeOfEachBlock
	var expectedEndPos = -expectedStartPos
	var expectedEndPos2 = expectedEndPos - expectedWorldSizeOfEachBlock
	# Warning: for the outer rings, the blocks skip over interior ring blocks
	var expectedNumBlocks: int
	if ringPos == 0:
		expectedNumBlocks = expectedNumBlocksPerSide * expectedNumBlocksPerSide
	else:
		expectedNumBlocks = expectedNumBlocksPerSide * 4 - 4
	# Act
	var blockFunnel = BlockFunnel.new(params)
	var blocks = blockFunnel.queryBlocks(ringPos)
	# Assert
	var pos = Vector2(expectedStartPos, expectedStartPos)
	for block in blocks:
		var worldUL = block.worldUL
		var worldLR = block.worldLR
		var expectedLR = Vector2(pos.x + expectedWorldSizeOfEachBlock, pos.y + expectedWorldSizeOfEachBlock)
		assert(worldUL.y == pos.y)
		assert(worldUL.x == pos.x)
		assert(worldLR.y == expectedLR.y)
		assert(worldLR.x == expectedLR.x)
		# Compute next block position. This is kind of complicated.
		# If on the inner blocks then there is a steady pattern of increase since we check all of them. Simple.
		# But if we are on a ring, we only want the blocks along the edge.
		var doSkip = true
		while doSkip:
			pos.x += expectedWorldSizeOfEachBlock
			if pos.x >= expectedEndPos:
				pos.x = expectedStartPos
				pos.y += expectedWorldSizeOfEachBlock

			if ringPos == 0:
				# Inner blocks
				doSkip = false
			elif pos.x == expectedStartPos or pos.x == expectedEndPos2 or pos.y == expectedStartPos or pos.y == expectedEndPos2:
				# On a ring, but on the edge, so this is okay.
				doSkip = false


func _computeCenterPoint_verifyRounding():
	for centerPoint in [Vector2(0, 0), Vector2(30, 30), Vector2(60, 60)]:
		for playerPush in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			_computeCenterPoint_verifyRoundingToCenter(centerPoint, playerPush)
	
	for bouncex in [1, 2, 3]:
		for bouncey in [1, 2, 3]:
			var bounce = Vector2i(bouncex, bouncey)
			_computeCenterPoint_verifyRoundingToLRIfOnOutsideUL(bounce)
			_computeCenterPoint_verifyRoundingToLLIfOnOutsideUR(bounce)
			_computeCenterPoint_verifyRoundingToURIfOnOutsideLL(bounce)
			_computeCenterPoint_verifyRoundingToULIfOnOutsideLR(bounce)


func _computeCenterPoint_verifyRoundingToCenter(centerPoint: Vector2, playerPush: Vector2i):
	# Arrange
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = 2
	params.ringDepth = 2
	params.blockPointSizeFactor = 8
	params.blockCenterWorldSize = 50
	var step = params.blockCenterWorldSize/5-1
	# Loop
	for value in range(0, params.blockCenterWorldSize-1, step):
		# Arrange
		var playerPos = Vector2(value*playerPush.x, value*playerPush.y) + centerPoint
		# Act
		var blockFunnel = BlockFunnel.new(params)
		blockFunnel.setGridWorldCenter(centerPoint)
		var computedPoint = blockFunnel.computeCenterPoint(playerPos)
		# Assert
		assert(computedPoint == centerPoint)


func _computeCenterPoint_verifyRoundingToLRIfOnOutsideUL(bounce: Vector2i):
	# Arrange
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = 2
	params.ringDepth = 2
	params.blockPointSizeFactor = 8
	params.blockCenterWorldSize = 50
	var blockWorldSize = params.blockCenterWorldSize
	var playerPos = Vector2(-blockWorldSize*(bounce.x+0.5), -blockWorldSize*(bounce.y+0.5))
	var expectedCenterPos = Vector2(-blockWorldSize*bounce.x, -blockWorldSize*bounce.y)
	# Act
	var blockFunnel = BlockFunnel.new(params)
	var computedPoint = blockFunnel.computeCenterPoint(playerPos)
	# Assert
	assert(computedPoint == expectedCenterPos)
	
	
func _computeCenterPoint_verifyRoundingToLLIfOnOutsideUR(bounce: Vector2i):
	# Arrange
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = 2
	params.ringDepth = 2
	params.blockPointSizeFactor = 8
	params.blockCenterWorldSize = 50
	var blockWorldSize = params.blockCenterWorldSize
	var playerPos = Vector2(blockWorldSize*(bounce.x+0.5), -blockWorldSize*(bounce.y+0.5))
	var expectedCenterPos = Vector2(blockWorldSize*bounce.x, -blockWorldSize*bounce.y)
	# Act
	var blockFunnel = BlockFunnel.new(params)
	var computedPoint = blockFunnel.computeCenterPoint(playerPos)
	# Assert
	assert(computedPoint == expectedCenterPos)
	

func _computeCenterPoint_verifyRoundingToURIfOnOutsideLL(bounce: Vector2i):
	# Arrange
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = 2
	params.ringDepth = 2
	params.blockPointSizeFactor = 8
	params.blockCenterWorldSize = 50
	var blockWorldSize = params.blockCenterWorldSize
	var playerPos = Vector2(-blockWorldSize*(bounce.x+0.5), blockWorldSize*(bounce.y+0.5))
	var expectedCenterPos = Vector2(-blockWorldSize*bounce.x, blockWorldSize*bounce.y)
	# Act
	var blockFunnel = BlockFunnel.new(params)
	var computedPoint = blockFunnel.computeCenterPoint(playerPos)
	# Assert
	assert(computedPoint == expectedCenterPos)
	
	
func _computeCenterPoint_verifyRoundingToULIfOnOutsideLR(bounce: Vector2i):
	# Arrange
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = 2
	params.ringDepth = 2
	params.blockPointSizeFactor = 8
	params.blockCenterWorldSize = 50
	var blockWorldSize = params.blockCenterWorldSize
	var playerPos = Vector2(blockWorldSize*(bounce.x+0.5), blockWorldSize*(bounce.y+0.5))
	var expectedCenterPos = Vector2(blockWorldSize*bounce.x, blockWorldSize*bounce.y)
	# Act
	var blockFunnel = BlockFunnel.new(params)
	var computedPoint = blockFunnel.computeCenterPoint(playerPos)
	# Assert
	assert(computedPoint == expectedCenterPos)