class_name DiamondSquareGridTest
extends Node

var _continentImage: Image

func run():
	_detectOverlap()
	_run_byN(2)
	_run_byN(3)
	_run_byN(5)


func _run_byN(N: int):
	_loadYValues_byN_valuesLoadedAsExpected(N)
	_compute_byN_imageSizeReturnAsExpected(N)
	_compute_byN_centerComputedCorrectly(N)
	_compute_byN_leftEdgeComputedCorrectly(N)
	_compute_byN_topEdgeComputedCorrectly(N)
	_compute_byN_rightEdgeComputedCorrectly(N)
	_compute_byN_bottomEdgeComputedCorrectly(N)


func _detectOverlap():
	_detectOverlap_true()
	_detectOverlap_false_leftSide()
	_detectOverlap_false_rightSide()
	_detectOverlap_false_topSide()
	_detectOverlap_false_bottomSide()


func _detectOverlap_true():
	print("_detectOverlap_true()")
	var centerSquare = DiamondSquareGrid.Square.new(Vector2i(8, 8), Vector2i(16, 16))
	for y in range(6, 18, 2):
		for x in range(6, 18, 2):
			var flag = _detectOverlap_with(x, y, centerSquare)
			assert(flag == true)
	

func _detectOverlap_false_leftSide():
	print("_detectOverlap_false_leftSide()")
	var centerSquare = DiamondSquareGrid.Square.new(Vector2i(8, 8), Vector2i(16, 16))
	for y in range(0, 6, 2):
		for x in range(0, 6, 2):
			var flag = _detectOverlap_with(x, y, centerSquare)
			assert(flag == false)


func _detectOverlap_false_rightSide():
	print("_detectOverlap_false_rightSide()")
	var centerSquare = DiamondSquareGrid.Square.new(Vector2i(8, 8), Vector2i(16, 16))
	for y in range(20, 32, 2):
		for x in range(20, 32, 2):
			var flag = _detectOverlap_with(x, y, centerSquare)
			assert(flag == false)


func _detectOverlap_false_topSide():
	print("_detectOverlap_false_topSide()")
	var centerSquare = DiamondSquareGrid.Square.new(Vector2i(8, 8), Vector2i(16, 16))
	for y in range(0, 6, 2):
		for x in range(0, 32, 2):
			var flag = _detectOverlap_with(x, y, centerSquare)
			assert(flag == false)


func _detectOverlap_false_bottomSide():
	print("_detectOverlap_false_bottomSide()")
	var centerSquare = DiamondSquareGrid.Square.new(Vector2i(8, 8), Vector2i(16, 16))
	for y in range(20, 32, 2):
		for x in range(0, 32, 2):
			var flag = _detectOverlap_with(x, y, centerSquare)
			assert(flag == false)


func _loadYValues_byN_valuesLoadedAsExpected(N: int):
	print("_loadYValues_byN_valuesLoadedAsExpected(", N, ")")
	# Arrange
	var size = Vector2i(N, N)
	# Act
	var sut = _createSUT(N)
	# Assert
	var sideLen = sut._sideLength
	var start = Vector2i(0, 0)
	var end = Vector2i(sideLen*2, sideLen*2)
	var skip = sideLen
	print("range ", start, "->", end, " with skip ", skip)
	for y in range(start.y, end.y+1, skip):
			for x in range(start.x, end.x+1, skip):
				assert(sut._hasHeightXY(x, y))


func _compute_byN_imageSizeReturnAsExpected(N : int):
	print("_compute_byN_imageSizeReturnAsExpected(", N, ")")
	# Arrange
	var size = Vector2i(N, N)
	var expectedNumPtsPerEdge = pow(2, N)+1
	var sut = _createSUT(N)
	sut.printInfo()
	# Act
	var image = sut.compute()
	# Assert
	var imageWidth = image.get_width()
	var imageHeight = image.get_height()
	assert(expectedNumPtsPerEdge == imageWidth)
	assert(expectedNumPtsPerEdge == imageHeight)


func _compute_byN_centerComputedCorrectly(N: int):
	print("_compute_byN_centerComputedCorrectly(", N, ")")
	# Arrange
	var size = Vector2i(N, N)
	var expectedNumPtsPerEdge = int(pow(2, N)+1)
	var sut = _createSUT(N)
	var expectedValue = _computeAverageOf(size, size)
	# Act
	var image = sut.compute()
	# Assert
	var centerXY = int(floor(image.get_width()/2))
	var centerPos = Vector2i(centerXY, centerXY)
	var centerValue = image.get_pixelv(centerPos).r
	assert(expectedValue == centerValue)


func _compute_byN_leftEdgeComputedCorrectly(N: int):
	print("_compute_byN_leftEdgeComputedCorrectly(", N, ")")
	# Arrange
	var size = Vector2i(N, N)
	var sut = _createSUT(N)
	var ul = size
	var lr = Vector2i(ul.x + size.x, ul.y + size.y)
	var centerValue = _computeAverageOf(ul, size)
	var leftCenterValue = _computeAverageOf(Vector2i(0, size.y), size)
	var valueUL = _continentImage.get_pixel(ul.x, ul.y).r
	var valueLL = _continentImage.get_pixel(ul.x, lr.y).r
	var expectedValue = (centerValue + leftCenterValue + valueUL + valueLL) / 4
	# Act
	var image = sut.compute()
	# Assert
	var centerXY = int(floor(image.get_width()/2))
	var leftPos = Vector2i(0, centerXY)
	var leftValue = image.get_pixelv(leftPos).r
	assert(expectedValue == leftValue)


func _compute_byN_topEdgeComputedCorrectly(N: int):
	print("_compute_byN_topEdgeComputedCorrectly(", N, ")")
	# Arrange
	var size = Vector2i(N, N)
	var sut = _createSUT(N)
	var ul = size
	var lr = Vector2i(size.x*2, size.y*2)
	var centerValue = _computeAverageOf(ul, size)
	var topCenterValue = _computeAverageOf(Vector2i(size.x, 0), size)
	var valueUL = _continentImage.get_pixel(ul.x, ul.y).r
	var valueUR = _continentImage.get_pixel(lr.x, ul.y).r
	var expectedValue = (centerValue + topCenterValue + valueUL + valueUR) / 4
	# Act
	var image = sut.compute()
	# Assert
	var centerXY = int(floor(image.get_width()/2))
	var topPos = Vector2i(centerXY, 0)
	var topValue = image.get_pixelv(topPos).r
	assert(expectedValue == topValue)


func _compute_byN_rightEdgeComputedCorrectly(N: int):
	print("_compute_byN_rightEdgeComputedCorrectly(", N, ")")
	# Arrange
	var size = Vector2i(N, N)
	var sut = _createSUT(N)
	var ul = size
	var lr = Vector2i(size.x*2, size.y*2)
	var centerValue = _computeAverageOf(ul, size)
	var rightCenterValue = _computeAverageOf(Vector2i(size.x*2, size.y), size)
	var valueUR = _continentImage.get_pixel(lr.x, ul.y).r
	var valueLR = _continentImage.get_pixel(lr.x, lr.y).r
	var expectedValue = (centerValue + rightCenterValue + valueUR + valueLR) / 4
	# Act
	var image = sut.compute()
	# Assert
	var centerXY = int(floor(image.get_width()/2))
	var rightPos = Vector2i(image.get_width()-1, centerXY)
	var rightValue = image.get_pixelv(rightPos).r
	assert(expectedValue == rightValue)


func _compute_byN_bottomEdgeComputedCorrectly(N: int):
	print("_compute_byN_bottomEdgeComputedCorrectly(", N, ")")
	# Arrange
	var size = Vector2i(N, N)
	var sut = _createSUT(N)
	var ul = size
	var lr = Vector2i(size.x*2, size.y*2)
	var centerValue = _computeAverageOf(ul, size)
	var bottomCenterValue = _computeAverageOf(Vector2i(size.x, size.y*2), size)
	var valueLL = _continentImage.get_pixel(ul.x, lr.y).r
	var valueLR = _continentImage.get_pixel(lr.x, lr.y).r
	var expectedValue = (centerValue + bottomCenterValue + valueLL + valueLR) / 4
	# Act
	var image = sut.compute()
	# Assert
	var centerXY = int(floor(image.get_width()/2))
	var bottomPos = Vector2i(centerXY, image.get_height()-1)
	var bottomValue = image.get_pixelv(bottomPos).r
	assert(expectedValue == bottomValue)


func runContinentUnitTests(continentHeightmapImage: Image):
	_runSimpleLoadAndProcessUnitTest(continentHeightmapImage)
	_runComparisonUnitTest(continentHeightmapImage)


func _runSimpleLoadAndProcessUnitTest(continentHeightmapImage: Image):
	print("_runSimpleLoadAndProcessUnitTest()")
	print("CONTINENT SIZE=", continentHeightmapImage.get_width(), "x", continentHeightmapImage.get_height())
	
	var diamondSquare: DiamondSquareGrid = DiamondSquareGrid.new()

	var sideN = 4
	var imageMetersPerPixelN = 10

	diamondSquare.sideN = sideN
	diamondSquare.setWorldUL(Vector2i(500, 500), imageMetersPerPixelN)
	diamondSquare.metersPerPixelN = 7
	
	var params = DiamondSquareGrid.LoadYValuesParams.new()
	params.image = continentHeightmapImage
	params.imageMetersPerPixelN = imageMetersPerPixelN
	diamondSquare.loadYValues(params)
	

func _runComparisonUnitTest(continentHeightmapImage: Image):
	print("runComparisonUnitTest()")
	var diamondSquare: DiamondSquareGrid = DiamondSquareGrid.new()
	var imageMetersPerPixelN = 10
	diamondSquare.sideN = 9
	diamondSquare.setWorldUL(Vector2i(500, 500), imageMetersPerPixelN)
	diamondSquare.metersPerPixelN = 6
	
	diamondSquare.printInfo()
	var image1 = diamondSquare.compute()
	
	var params = DiamondSquareGrid.LoadYValuesParams.new()
	params.image = continentHeightmapImage
	params.imageMetersPerPixelN = imageMetersPerPixelN
	diamondSquare.loadYValues(params)
	
	var diamondSquare2: DiamondSquareGrid = DiamondSquareGrid.new()
	diamondSquare2.sideN = diamondSquare.sideN
	diamondSquare2.worldUpperLeft = Vector2(
		diamondSquare.worldUpperLeft.x,
		diamondSquare._worldGridUL.y
	)
	diamondSquare2.metersPerPixelN = diamondSquare.metersPerPixelN
	diamondSquare2.loadYValues(params)
	var image2 = diamondSquare2.compute()
	
	diamondSquare.detectMismatch(diamondSquare2)

#
# Helper functions and classes
#
func _createSUT(N: int) -> DiamondSquareGrid:
	var size = Vector2i(N, N)
	var continentSize = Vector2i(size.x*3, size.y*3)
	var sideLength = pow(2, N)
	var sut = DiamondSquareGrid.new(RandomValueZero.new())
	sut.worldUpperLeft = Vector2(sideLength, sideLength)
	sut.metersPerPixelN = 0
	sut.sideN = N
	var params = DiamondSquareGrid.LoadYValuesParams.new()
	params.image = _prepareTestImage(continentSize)
	params.imageMetersPerPixelN = N
	params.imageWorldUL = Vector2(0, 0)
	sut.loadYValues(params)
	_continentImage = params.image
	return sut


func _prepareTestImage(size: Vector2i) -> Image:
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RF)
	var inc = 1 / (size.x * size.y)
	var value = 0
	for y in range(size.y):
		for x in range(size.x):
			image.set_pixel(x, y, Color(value, 0, 0))
			value += inc
	assert(image.get_width() == size.x)
	assert(image.get_height() == size.y)
	return image


func _computeAverageOf(ul: Vector2i, size: Vector2i) -> float:
	var lr = Vector2i(ul.x + size.x, ul.y + size.y)
	var valueUL = _continentImage.get_pixel(ul.x, ul.y).r
	var valueUR = _continentImage.get_pixel(lr.x, ul.y).r
	var valueLL = _continentImage.get_pixel(ul.x, lr.y).r
	var valueLR = _continentImage.get_pixel(lr.x, lr.y).r
	var average = (valueUL + valueUR + valueLL + valueLR) / 4
	return average

class RandomValueZero extends DiamondRandomValue:
	
	func randomValue(ul: Vector2, lr: Vector2) -> float:
		return 0.0


func _detectOverlap_with(x: int, y: int, centerSquare: DiamondSquareGrid.Square):
	var ul = Vector2i(x, y)
	var lr = Vector2i(x+2, y+2)
	var square = DiamondSquareGrid.Square.new(ul, lr)
	return square.overlaps(centerSquare.upperLeft, centerSquare.lowerRight)


