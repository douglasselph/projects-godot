class_name BlockFunnelTest
extends Node



func run():
	_queryBlocks_verifyNumCenterBlocksCorrect()
	for blockFactor in [2, 3, 4]:
		for pointSizeFactor in [4, 6, 8]:
			_queryBlocks_verifyCenterBlocksSizeAsExpected(blockFactor, pointSizeFactor, 0)
			_queryBlocks_verifyCenterBlockWorldPositions(blockFactor, pointSizeFactor, 0)
			_queryBlocks_verifyCenterBlocksSizeAsExpected(blockFactor, pointSizeFactor, 1)
			_queryBlocks_verifyCenterBlockWorldPositions(blockFactor, pointSizeFactor, 1)
	
	_queryBlocks_verifyRing1BlockWithExpectedPositions()
	_queryBlocks_verifyRing1BlocksWithExpectedWorldPositions()
	_queryBlocks_verifyRing2BlocksWithExpectedPositions()
	_queryBlocks_verifyRing2BlocksWithExpectedWorldPositions()
	_computeCenterPoint_verifyComputeCenterPointRoundsToExistingCenterAsExpected()



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
	assert(blocks.size == expectedNumBlocks)
	

func _queryBlocks_verifyCenterBlocksSizeAsExpected(blockFactor: int, pointSizeFactor: int, ringDepth: int):
	# Arrange
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = blockFactor # Should produce 4 x 4 center blocks
	params.ringDepth = ringDepth
	params.blockPointSizeFactor = pointSizeFactor # Should generate a point size of 2^4 = 16
	var expectedBlockSize = pow(2, params.blockPointSizeFactor)
	var blockFunnel = BlockFunnel.new(params)
	# Act
	var blocks = blockFunnel.queryBlocks(0)
	# Assert
	for block in blocks:
		assert(block.size.x == expectedBlockSize)
		assert(block.size.y == expectedBlockSize)
		
		
func _queryBlocks_verifyCenterBlockWorldPositions(blockFactor: int, pointSizeFactor: int, ringDepth: int):
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = blockFactor # Should produce 4 x 4 center blocks
	params.ringDepth = ringDepth
	params.blockPointSizeFactor = pointSizeFactor # Should generate a point size of 2^4 = 16
	params.blockCenterWorldSize = 50
	var expectedSideLen = pow(2, params.baseBlockFactor)
	var expectedBlockSize = pow(2, params.blockPointSizeFactor)
	var expectedNumBlocks = expectedSideLen * expectedSideLen
	var blockFunnel = BlockFunnel.new(params)
	var blocks = blockFunnel.queryBlocks(0)
	var expectedStartPos = -expectedSideLen/2 * expectedBlockSize * params.blockCenterWorldSize
	var expectedEndPos = -expectedStartPos
	var posy = expectedStartPos
	var posx = expectedStartPos
	for block in blocks:
		assert(block.worldUL.y == posy)
		assert(block.worldUL.x == posx)
		assert(block.worldLR.y == posy + params.blockCenterWorldSize)
		assert(block.worldLR.x == posx + params.blockCenterWorldSize)
		posx += params.blockCenterWorldSize
		if posx >= expectedEndPos:
			posx = expectedStartPos
			posy += params.blockCenterWorldSize
			
	
func _queryBlocks_verifyRing1BlockSizeAsExpected(blockFactor: int, pointSizeFactor: int):
	# Arrange
	var params = BlockFunnel.Params.new()
	params.baseBlockFactor = blockFactor # Should produce 4 x 4 center blocks
	params.ringDepth = 1
	params.blockPointSizeFactor = pointSizeFactor # Should generate a point size of 2^4 = 16
	var expectedBlockSize = pow(2, params.blockPointSizeFactor)
	var blockFunnel = BlockFunnel.new(params)
	# Act
	var blocks = blockFunnel.queryBlocks(1)
	# Assert
	for block in blocks:
		assert(block.size.x == expectedBlockSize)
		assert(block.size.y == expectedBlockSize)
	

func _queryBlocks_verifyRing1BlocksWithExpectedWorldPositions():
	pass
	
	
func _queryBlocks_verifyRing2BlocksWithExpectedPositions():
	pass
	
	
func _queryBlocks_verifyRing2BlocksWithExpectedWorldPositions():
	pass
	
	
func _computeCenterPoint_verifyComputeCenterPointRoundsToExistingCenterAsExpected():
	pass
	
