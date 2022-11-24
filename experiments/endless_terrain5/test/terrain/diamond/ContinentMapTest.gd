class_name ContinentMapTest
extends Node

func run():
	print("ContinentMapTest.run()")
	_detectOverlap()
	
	_run_simple()
	_run_byN(2)
	_run_byN(3)
	_run_byN(5)


func _run_simple():
	print("_run_simple():")
	_compute_byN_initialSquareCornerValuesLoadedAsExpected(1, 3, 0)


func _run_byN(N: int):
	print("_run_byN(", N, "):")
	_compute_byN_initialSquareCornerValuesLoadedAsExpected(N)
	_compute_byN_imageSizeReturnAsExpected(N)
	_compute_byN_centerComputedCorrectly(N)
	_compute_byN_leftEdgeComputedCorrectly(N)
	_compute_byN_topEdgeComputedCorrectly(N)


func _detectOverlap():
	_detectOverlap_true()
	_detectOverlap_false_leftSide()
	_detectOverlap_false_rightSide()
	_detectOverlap_false_topSide()
	_detectOverlap_false_bottomSide()


func _detectOverlap_true():
	print("_detectOverlap_true()")
	var centerSquare = ContinentMap.Square.new(Vector2i(8, 8), Vector2i(16, 16))
	for y in range(6, 18, 2):
		for x in range(6, 18, 2):
			var flag = _detectOverlap_with(x, y, centerSquare)
			assert(flag == true)
	

func _detectOverlap_false_leftSide():
	print("_detectOverlap_false_leftSide()")
	var centerSquare = ContinentMap.Square.new(Vector2i(8, 8), Vector2i(16, 16))
	for y in range(0, 6, 2):
		for x in range(0, 6, 2):
			var flag = _detectOverlap_with(x, y, centerSquare)
			assert(flag == false)


func _detectOverlap_false_rightSide():
	print("_detectOverlap_false_rightSide()")
	var centerSquare = ContinentMap.Square.new(Vector2i(8, 8), Vector2i(16, 16))
	for y in range(20, 32, 2):
		for x in range(20, 32, 2):
			var flag = _detectOverlap_with(x, y, centerSquare)
			assert(flag == false)


func _detectOverlap_false_topSide():
	print("_detectOverlap_false_topSide()")
	var centerSquare = ContinentMap.Square.new(Vector2i(8, 8), Vector2i(16, 16))
	for y in range(0, 6, 2):
		for x in range(0, 32, 2):
			var flag = _detectOverlap_with(x, y, centerSquare)
			assert(flag == false)


func _detectOverlap_false_bottomSide():
	print("_detectOverlap_false_bottomSide()")
	var centerSquare = ContinentMap.Square.new(Vector2i(8, 8), Vector2i(16, 16))
	for y in range(20, 32, 2):
		for x in range(0, 32, 2):
			var flag = _detectOverlap_with(x, y, centerSquare)
			assert(flag == false)


func _compute_byN_initialSquareCornerValuesLoadedAsExpected(N: int, C: int = 6, S: int = 1):
	print("*** _compute_byN_initialSquareCornerValuesLoadedAsExpected(", N, ")")
	# Arrange
	var continentSideLen = C
	var continentMetersPerPixelN = 10 # 1024
	var params = ContinentMap.Params.new()
	params.mapUL = Vector2i(continentSideLen/3, continentSideLen/3) # 2,2
	params.sizeN = Vector2i(S, S) # 2
	params.depthN = N
	var squareSize = pow(2, N)
	# Act
	var sut = _createSUT(continentSideLen)
	
	print("INPUT CONTINENT MAP:")
	_displayImage(sut._continentMap)
	
	sut.metersPerPixelN = continentMetersPerPixelN
	var image = sut.computeHeightmap(params)
	
	# Assert
	var start = Vector2i(0, 0)
	var end = Vector2i(image.get_width(), image.get_height())
	var skip = squareSize
	var continentPos = params.mapUL
	print("range ", start, "->", end, " with skip ", skip, ", mapUL=", continentPos)
	for y in range(start.y, end.y, skip):
		continentPos.x = params.mapUL.x
		for x in range(start.x, end.x, skip):
			var image_value = image.get_pixel(x, y).r
			var continent_value = sut._mapHeight(continentPos.x, continentPos.y)
			assert(image_value == continent_value)
			continentPos.x += 1
		continentPos.y += 1


func _compute_byN_imageSizeReturnAsExpected(N : int):
	print("*** _compute_byN_imageSizeReturnAsExpected(", N, ")")
	# Arrange
	var continentSideLen = 12
	var continentMetersPerPixelN = 8 # 256
	var params = ContinentMap.Params.new()
	params.mapUL = Vector2i(continentSideLen/3, continentSideLen/3) # 4
	params.sizeN = Vector2i(2, 2) # 4
	params.depthN = N
	var expectedNumPtsPerEdge = pow(2, 2+N)+1
	# Act
	var sut = _createSUT(continentSideLen)
	var image = sut.computeHeightmap(params)
	# Assert
	var imageWidth = image.get_width()
	var imageHeight = image.get_height()
	assert(expectedNumPtsPerEdge == imageWidth)
	assert(expectedNumPtsPerEdge == imageHeight)


func _compute_byN_centerComputedCorrectly(N: int):
	print("*** _compute_byN_centerComputedCorrectly(", N, ")")
	# Arrange
	var continentSideLen = 6
	var continentMetersPerPixelN = 10 # 1024
	var params = ContinentMap.Params.new()
	params.mapUL = Vector2i(continentSideLen/3, continentSideLen/3) # 2,2
	params.sizeN = Vector2i(1, 1) # 2
	params.depthN = N
	var squareSize = pow(2, N)
	# Act
	var sut = _createSUT(continentSideLen)
	sut.metersPerPixelN = continentMetersPerPixelN
	var image = sut.computeHeightmap(params)
	# Assert
	var start = Vector2i(0, 0)
	var end = Vector2i(image.get_width(), image.get_height())
	var skip = squareSize
	var continentPos = params.mapUL
	var continentImage = sut._continentMap
	print("range ", start, "->", end, " with skip ", skip)
	for y in range(start.y, end.y-1, skip):
		continentPos.x = params.mapUL.x
		for x in range(start.x, end.x-1, skip):
			var image_center_y = y + skip / 2
			var image_center_x = x + skip / 2
			var expectedValue = _round(_computeCenterValue(continentImage, continentPos))
			var image_value = _round(image.get_pixel(image_center_x, image_center_y).r)
			assert(expectedValue == image_value)
			continentPos.x += 1
		continentPos.y += 1


func _compute_byN_leftEdgeComputedCorrectly(N: int):
	print("*** _compute_byN_leftEdgeComputedCorrectly(", N, ")")
	# Arrange
	var continentSideLen = 6
	var continentMetersPerPixelN = 10 # 1024
	var params = ContinentMap.Params.new()
	params.mapUL = Vector2i(continentSideLen/3, continentSideLen/3) # 2,2
	params.sizeN = Vector2i(1, 1) # 2
	params.depthN = N
	var squareSize = pow(2, N)
	# Act
	var sut = _createSUT(continentSideLen)
	sut.metersPerPixelN = continentMetersPerPixelN
	var image = sut.computeHeightmap(params)
	# Assert
	var start = Vector2i(0, 0)
	var end = Vector2i(image.get_width(), image.get_height())
	var skip = squareSize
	var continentPos = params.mapUL
	var continentImage = sut._continentMap
	print("range ", start, "->", end, " with skip ", skip)
	for y in range(start.y, end.y-1, skip):
		continentPos.x = params.mapUL.x
		for x in range(start.x, end.x, skip):
			var top_value = _continentValue(continentImage, continentPos)
			var bottom_value = _continentValue(continentImage, Vector2i(continentPos.x, continentPos.y+1))
			var center_value = _computeCenterValue(continentImage, continentPos)
			var left_center_value = _computeCenterValue(continentImage, Vector2i(continentPos.x-1, continentPos.y))
			var expected_value = _round((top_value + bottom_value + center_value + left_center_value) / 4.0)
			var image_left_y = y + skip/2
			var image_value = _round(image.get_pixel(x, image_left_y).r)
			assert(expected_value == image_value)
			continentPos.x += 1
		continentPos.y += 1



func _compute_byN_topEdgeComputedCorrectly(N: int):
	print("*** _compute_byN_topEdgeComputedCorrectly(", N, ")")
	# Arrange
	var continentSideLen = 6
	var continentMetersPerPixelN = 10 # 1024
	var params = ContinentMap.Params.new()
	params.mapUL = Vector2i(continentSideLen/3, continentSideLen/3) # 2,2
	params.sizeN = Vector2i(1, 1) # 2
	params.depthN = N
	var squareSize = pow(2, N)
	# Act
	var sut = _createSUT(continentSideLen)
	sut.metersPerPixelN = continentMetersPerPixelN
	var image = sut.computeHeightmap(params)
	# Assert
	var start = Vector2i(0, 0)
	var end = Vector2i(image.get_width(), image.get_height())
	var skip = squareSize
	var continentPos = params.mapUL
	var continentImage = sut._continentMap
	print("range ", start, "->", end, " with skip ", skip)
	for y in range(start.y, end.y-1, skip):
		continentPos.x = params.mapUL.x
		for x in range(start.x, end.x-1, skip):
			var top_value = _continentValue(continentImage, continentPos)
			var right_value = _continentValue(continentImage, Vector2i(continentPos.x+1, continentPos.y))
			var center_value = _computeCenterValue(continentImage, continentPos)
			var top_center_value = _computeCenterValue(continentImage, Vector2i(continentPos.x, continentPos.y-1))
			var expected_value = _round((top_value + right_value + center_value + top_center_value) / 4.0)
			var image_top_x = x + skip/2
			var image_value = _round(image.get_pixel(image_top_x, y).r)
			assert(expected_value == image_value)
			continentPos.x += 1
		continentPos.y += 1


func runRealImageUnitTests(continentHeightmapImage: Image):
	_runSimpleLoadAndProcessUnitTest(continentHeightmapImage)
	_runComparisonUnitTest(continentHeightmapImage)


func _runSimpleLoadAndProcessUnitTest(continentHeightmapImage: Image):
	print("*** _runSimpleLoadAndProcessUnitTest()")
	print("CONTINENT SIZE=", continentHeightmapImage.get_width(), "x", continentHeightmapImage.get_height())
	var continentMap: ContinentMap = ContinentMap.new(continentHeightmapImage)
	continentMap.metersPerPixelN = 10
	var params = ContinentMap.Params.new()
	params.mapUL = Vector2i(500, 500)
	params.sizeN = Vector2i(2, 2)
	params.depthN = 2
	var image = continentMap.computeHeightmap(params)
	

func _runComparisonUnitTest(continentHeightmapImage: Image):
	print("*** _runComparisonUnitTest()")
	var continentMap: ContinentMap = ContinentMap.new(continentHeightmapImage)
	continentMap.metersPerPixelN = 10
	
	var params = ContinentMap.Params.new()
	params.mapUL = Vector2i(500, 500)
	params.sizeN = Vector2i(1, 1)
	params.depthN = 6
	var image1 = continentMap.computeHeightmap(params)
	
	params.mapUL = Vector2(499, 500)
	var image2 = continentMap.computeHeightmap(params)


#
# Helper functions and classes
#
func _createSUT(totalSize: int) -> ContinentMap:
	var continentSize = Vector2i(totalSize, totalSize)
	var continentMap = _prepareTestImage(continentSize)
	var sut = ContinentMap.new(continentMap, RandomValueZero.new())
	return sut


func _prepareTestImage(size: Vector2i) -> Image:
	var numPts = Vector2i(size.x + 1, size.y + 1)
	var image = Image.create(numPts.x, numPts.y, false, Image.FORMAT_RGB8)
	var total = (numPts.x * numPts.y) - 1
	var inc: float = 0
	for y in range(numPts.y):
		for x in range(numPts.x):
			var value = inc / total
			image.set_pixel(x, y, Color(value, value, value))
			inc += 1
	assert(image.get_width() == numPts.x)
	assert(image.get_height() == numPts.y)
	return image


func _displayImage(image: Image):
	for y in image.get_height():
		for x in image.get_width():
			var color = image.get_pixel(x, y)
			print("Image(", x, ", ", y, ")=", color)


# Vector in CONTINENT units
func _computeCenterValue(image: Image, ul: Vector2i) -> float:
	var lr = Vector2i(ul.x + 1, ul.y + 1)
	return _computeAverageOf(
		image,
		Vector2i(ul.x, ul.y), 
		Vector2i(lr.x, ul.y),
		Vector2i(ul.x, lr.y),
		Vector2i(lr.x, lr.y)
	)


# Vectors in CONTINENT units
func _computeAverageOf(image: Image, v1: Vector2i, v2: Vector2i, v3: Vector2i, v4: Vector2i) -> float:
	var value1 = _continentValue(image, v1)
	var value2 = _continentValue(image, v2)
	var value3 = _continentValue(image, v3)
	var value4 = _continentValue(image, v4)
	var average = (value1 + value2 + value3 + value4) / 4
	return average


# pos in CONTINENT units
func _continentValue(image: Image, pos: Vector2i) -> float:
	return image.get_pixel(pos.x, pos.y).r


class RandomValueZero extends DiamondRandomValue:
	
	func randomValue(ul: Vector2, lr: Vector2) -> float:
		return 0.0


func _detectOverlap_with(x: int, y: int, centerSquare: ContinentMap.Square):
	var ul = Vector2i(x, y)
	var lr = Vector2i(x+2, y+2)
	var square = ContinentMap.Square.new(ul, lr)
	return square.overlaps(centerSquare.upperLeft, centerSquare.lowerRight)


func _round(value: float) -> int:
	return int(floor(value * 10000))
