class_name DiamondSquareGrid
extends Node

#
# Maintains a 3x3 grid of 9 squares, where the central square is the grid of interest that is to 
# be generated. When the computations are complete, the central square can be mapped directly into
# a height map image. The surround 8 squares are only needed to help compute the diamond step.
#
# One grid unit is equivalent to one pixel wtih the final result.
#
# The 3x3 grid has a unit scale where 0,0 is the upper left of the upper left corner square.
# The number of meters per pixel is designated below.

# Incoming (Must set these before calling load() or compute()
var _random: DiamondRandomValue
var metersPerPixelN: int: # metersPerPixel must be a power of 2. Using this computes the value as per pow(2,N)
	get:
		return int(floor(log(float(_metersPerPixel)) / log(2)))
	set(value):
		_metersPerPixel = int(pow(2,value))
		
var worldUpperLeft: Vector2 # The computed square's upper left position in the world (where 1 meter = 1 unit)
var sideN: int: # Side length (number of pixel points) == pow(2,sideN)
	get:
		return int(floor(log(float(_sideLength)) / log(2))) # log(2, _sideLength) = log(_sideLength) / log(2)
	set(value):
		_sideLength = int(pow(2,value))
		_totalGridSize = Vector2i(_sideLength*3, _sideLength*3)

# Private
var _heights = {} # Key: grid x,y ref.  Value: height in world
var _squares: Array   # The complete list of squares that are currently in process of being computed.
var _sideLength: int  # Number of pixel points per side of the central square that we are to compute.
var _totalGridSize: Vector2i
var _metersPerPixel: int

# The upper left of the 9x9 in world coordinates
var _worldGridUL: Vector2:
	get:
		var worldLen = _sideLength * _metersPerPixel
		return Vector2(
			worldUpperLeft.x - worldLen,
			worldUpperLeft.y - worldLen
		)
# The lower right of the 9x9 in world coordinates
var _worldGridLR: Vector2:
	get:
		var worldLen = _sideLength * _metersPerPixel * 2
		return Vector2(
			worldUpperLeft.x + worldLen,
			worldUpperLeft.y + worldLen
		)

var _centerUL: Vector2i:
	get:
		return Vector2i(_sideLength, _sideLength)
		
var _centerLR: Vector2i:
	get:
		return Vector2i(_sideLength*2, _sideLength*2)
		

const DEBUG = true

class Square:
	# Incoming
	var upperLeft: Vector2i    # In grid units
	var lowerRight: Vector2i   # In grid units
	
	func _init(ul: Vector2i, lr: Vector2i):
		self.upperLeft = ul
		self.lowerRight = lr


	# Computed
	var upperRight: Vector2i:   # In grid units
		get:
			return Vector2i(lowerRight.x, upperLeft.y)
	
	var lowerLeft: Vector2i:   # In grid units
		get:
			return Vector2i(upperLeft.x, lowerRight.y)
	
	var center: Vector2i:
		get:
			return Vector2i(
				(upperLeft.x + lowerRight.x)/2,
				(upperLeft.y + lowerRight.y)/2
			)


	# Return true if the square overlaps at all the passed in box.
	func overlaps(ul: Vector2i, lr: Vector2i) -> bool:
		if lowerRight.x < ul.x:
			return false
		if upperLeft.x > lr.x:
			return false
		if lowerRight.y < ul.y:
			return false
		if upperLeft.y > lr.y:
			return false
		return true
			
	
	# Split the square into 4 sub-squares.
	func split4() -> Array:
		var result = []
		var cc = center
		var lc = Vector2i(upperLeft.x, cc.y)
		var uc = Vector2i(cc.x, upperLeft.y)
		var bc = Vector2i(cc.x, lowerRight.y)
		var rc = Vector2i(lowerRight.x, cc.y)
		result.append(Square.new(upperLeft, cc))
		result.append(Square.new(uc, rc))
		result.append(Square.new(lc, bc))
		result.append(Square.new(cc, lowerRight))
		return result
		
	
	func display() -> String:
		return "SQUARE[%s -> %s]" % [str(upperLeft), str(lowerRight)]


func _init(random: DiamondRandomValue = DiamondRandomValue.new()):
	_random = random


class LoadYValuesParams:
	var image: Image
	var imageMetersPerPixelN: int # Computes metersPerPixel as per pow(2,N)
	var scaleHeightValuesBy: float = 1.0
	var imageWorldUL: Vector2 = Vector2(0,0)


#
# Preload the Y values from the image into the grid. 
# Note: depending on the the placement of the image it could be only some of the values will overlay
#  onto the grid. Those points that fall outside of the grid will be ignored.
# Be sure self.worldUL and self.metersPerPixel is set as desired before calling this function.
#
# image - the image of heightmap values to load.
# imageMetersPerPixel - How many meters per pixel the image represents. 
# scaleHeightValuesBy - How much to scale the height values by after acquiring them from the image.
# imageWorldUL - The upper left of the image in world coordinates. 
#
func loadYValues(params: LoadYValuesParams):
	# Incoming
	var image = params.image
	var imageMetersPerPixel = int(pow(2,params.imageMetersPerPixelN))
	var scaleHeightValuesBy = params.scaleHeightValuesBy
	var imageWorldUL = params.imageWorldUL
	#
	var worldUL = _worldGridUL
	var worldLR = _worldGridLR
	var imageWorldLen = Vector2(
		image.get_width() * imageMetersPerPixel, 
		image.get_height() * imageMetersPerPixel 
	)
	var imageWorldLR = Vector2(
		imageWorldUL.x + imageWorldLen.x,
		imageWorldUL.y + imageWorldLen.y 
	)
	if imageWorldUL.x >= worldLR.x or imageWorldUL.y >= worldLR.y or imageWorldLR.x < worldUL.x or imageWorldLR.y < worldUL.y:
		return

	# Compute source image copy starts
	var source_start = Vector2i(0, 0) # Grid units
	if imageWorldUL.x < worldUL.x:
		source_start.x = int(round((worldUL.x - imageWorldUL.x) / imageMetersPerPixel))
		assert(fmod((worldUL.x - imageWorldUL.x), imageMetersPerPixel) == 0)
	if imageWorldUL.y < worldUL.y:
		source_start.y = int(round((worldUL.y - imageWorldUL.y) / imageMetersPerPixel))
		assert(fmod((worldUL.y - imageWorldUL.y), imageMetersPerPixel) == 0)
	
	assert(image.get_width() > 0)
	assert(image.get_height() > 0)
	assert(imageMetersPerPixel > _metersPerPixel)
	
	# Compute source image copy end
	var source_end = Vector2i(
		image.get_width(),
		image.get_height()
	)
	if imageWorldLR.x > worldLR.x:
		source_end.x -= int(round((imageWorldLR.x - worldLR.x) / imageMetersPerPixel))
		assert(fmod((imageWorldLR.x - worldLR.x), imageMetersPerPixel) == 0)
	if imageWorldLR.y > worldLR.y:
		source_end.y -= int(round((imageWorldLR.y - worldLR.y) / imageMetersPerPixel))
		assert(fmod((imageWorldLR.y - worldLR.y), imageMetersPerPixel) == 0)

	assert(source_start.x < source_end.x)
	assert(source_start.y < source_end.y)
	assert(source_end.x - source_start.x <= _sideLength*3)
	assert(source_end.y - source_start.y <= _sideLength*3)
	assert(source_end.x <= image.get_width())
	assert(source_end.y <= image.get_height())
	
	# Compute target destination copy start
	var target_start = Vector2i(0, 0) # Grid units
	if imageWorldUL.x > worldUL.x:
		target_start.x = int(round(imageWorldUL.x - worldUL.x) / _metersPerPixel)
		assert(fmod((imageWorldUL.x - worldUL.x), _metersPerPixel) == 0)
	if imageWorldUL.y > worldUL.y:
		target_start.y = int(round(imageWorldUL.y - worldUL.y) / _metersPerPixel)
		assert(fmod((imageWorldUL.y - worldUL.y), _metersPerPixel) == 0)
	
	assert(imageMetersPerPixel >= _metersPerPixel)
	
	var skip = imageMetersPerPixel / _metersPerPixel
	var target = target_start
	
	for source_y in range(source_start.y, source_end.y+1):
		target.x = target_start.x
		for source_x in range(source_start.x, source_end.x+1):
			var color = image.get_pixel(source_x, source_y)
			var yValue = _parseHeight(color)
			_setHeight(target, yValue * scaleHeightValuesBy)
			target.x += skip
		target.y += skip
	
	assert(target.x - skip <= _totalGridSize.x)
	assert(target.y - skip <= _totalGridSize.y)

	if DEBUG:

		print("LOADED from ", source_start, " to ", source_end, ", which is ", 
			source_end.x - source_start.x + 1, " elements/row and ",
			source_end.y - source_start.y + 1, " rows, yielding ",
			(source_end.x - source_start.x + 1) * (source_end.y - source_start.y + 1), " sets.")
	
		# Compute target destination copy end
		var target_end = _totalGridSize
		if worldLR.x > imageWorldLR.x:
			target_end.x = int(round(worldLR.x - imageWorldLR.x) / _metersPerPixel)
			assert(fmod((worldLR.x - imageWorldLR.x), _metersPerPixel) == 0)
		if worldLR.y > imageWorldLR.y:
			target_end.y = int(round(worldLR.y - imageWorldLR.y) / _metersPerPixel)
			assert(fmod((worldLR.y - imageWorldLR.y), _metersPerPixel) == 0)

		assert(target_start.x <= target_end.x)
		assert(target_start.y <= target_end.y)
		assert(_heights.size() > 0)
		
		print("LOADED into ", target_start, " to ", target_end, ", which is, skipping every ", skip, ", ",
			(target_end.x - target_start.x + skip) / skip, " elements/row and ",
			(target_end.y - target_start.y + skip) / skip, " rows, yielding ",
			(target_end.x - target_start.x + skip) / skip * (target_end.y - target_start.y + skip) / skip, " sets.")
			
		print("NUMBER OF LOADED HEIGHTS=", _heights.size())
		
		for y in range(target_start.y, target_end.y+1, skip):
			for x in range(target_start.x, target_end.x+1, skip):
				assert(_hasHeightXY(x, y))

#
# Set the upper left corner of the square to the world coordinate (1 meter = 1 pixel),
# using the point at the given metersPerPixel value, computed from metersPerPixelN,
# where metersPerPixel = pow(2,metersPerPixelN)
#
func setWorldUL(point: Vector2i, metersPerPixelN: int):
	var pointMPP = pow(2, metersPerPixelN)
	worldUpperLeft = point * pointMPP 


func compute() -> Image:
	
	_squares.clear()
	
	for y in range(0, _sideLength*3, _sideLength):
		for x in range(0, _sideLength*3, _sideLength):
			_squares.append(
				Square.new(
					Vector2i(x, y),
					Vector2i(x + _sideLength, y + _sideLength)
				)
			)
			

	var numCycles = sideN
	for cycle in range(numCycles):
		_computeSquareSteps()
		_computeDiamondSteps()
		_splitSquares()
		print(cycle, ":", _squares.size(), " SQUARES COMPUTED")
	
	var image = _buildImage()
	
	_squares.clear()
	
	return image


func _buildImage() -> Image:
	var imageLen = _sideLength + 1
	var target = Image.create(imageLen, imageLen, false, Image.Format.FORMAT_RF)
	for y in range(imageLen):
		for x in range(imageLen):
			var value = _heightOfXY(x + _sideLength, y + _sideLength)
			target.set_pixel(x, y, Color(value, 0, 0))
	return target


func _computeSquareSteps():
	for square in _squares:
		var center = square.center
		if not _hasHeight(center):
			var ul_value = _heightOf(square.upperLeft)
			var lr_value = _heightOf(square.lowerRight)
			var ur_value = _heightOf(square.upperRight)
			var ll_value = _heightOf(square.lowerLeft)
			var random_value = _random.randomValue(_worldOf(square.upperLeft), _worldOf(square.lowerRight))
			var center_value = _average(ul_value, lr_value, ur_value, ll_value) + random_value
			_setHeight(center, center_value)


func _computeDiamondSteps():
	for square in _squares:
		var ul_value = _heightOf(square.upperLeft)
		var lr_value = _heightOf(square.lowerRight)
		var ur_value = _heightOf(square.upperRight)
		var ll_value = _heightOf(square.lowerLeft)
		var center = square.center
		var center_value = _heightOf(center)
		var diamond_center: Vector2i
		var diamond_value: float
		var dist_y: int
		var dist_x: int
		
		# Top diamond
		diamond_center = Vector2i(
			(square.upperLeft.x + square.lowerRight.x) / 2,
			square.upperLeft.y
		)
		if not _hasHeight(diamond_center):
			dist_y = center.y - square.upperLeft.y
			var top_y = square.upperLeft.y - dist_y
			var top_xy = Vector2i(center.x, top_y)

			if _hasHeight(top_xy):
				var top_value = _heightOf(top_xy)
				var random_value = _random.randomValue(_worldOf(top_xy), _worldOf(center))
				diamond_value = _average(ul_value, ur_value, center_value, top_value) + random_value
				_setHeight(diamond_center, diamond_value)

		# Bottom diamond:
		diamond_center.y = square.lowerRight.y
		if not _hasHeight(diamond_center):
			dist_y = square.lowerRight.y - center.y
			var bottom_y = square.lowerRight.y + dist_y
			var bottom_xy = Vector2i(center.x, bottom_y)

			if _hasHeight(bottom_xy):
				var bottom_value = _heightOf(bottom_xy)
				var random_value = _random.randomValue(_worldOf(center), _worldOf(bottom_xy))
				diamond_value = _average(ll_value, lr_value, center_value, bottom_value) + random_value
				_setHeight(diamond_center, diamond_value)

		# Left diamond:
		diamond_center = Vector2i(
			square.upperLeft.x,
			(square.upperLeft.y + square.lowerRight.y) / 2
		)
		if not _hasHeight(diamond_center):
			dist_x = center.x - square.upperLeft.x
			var left_x = square.upperLeft.y - dist_x
			var left_xy = Vector2i(left_x, center.y)

			if _hasHeight(left_xy):
				var left_value = _heightOf(left_xy)
				var random_value = _random.randomValue(_worldOf(left_xy), _worldOf(center))
				diamond_value = _average(ul_value, ll_value, center_value, left_value) + random_value
				_setHeight(diamond_center, diamond_value)


		# Right diamond:
		diamond_center.x = square.lowerRight.x
		if not _hasHeight(diamond_center):
			dist_x = square.lowerRight.x - center.x
			var right_x = square.lowerRight.x + dist_x
			var right_xy = Vector2i(right_x, center.y)

			if _hasHeight(right_xy):
				var right_value = _heightOf(right_xy)
				var random_value = _random.randomValue(_worldOf(center), _worldOf(right_xy))
				diamond_value = _average(ur_value, lr_value, center_value, right_value) + random_value
				_setHeight(diamond_center, diamond_value)


func _splitSquares():
	var centerUpperLeft = _centerUL
	var centerLowerRight = _centerLR
	var newsquares = []
	for square in _squares:
		var split = square.split4()
		for subsquare in split:
			if subsquare.overlaps(centerUpperLeft, centerLowerRight):
				newsquares.append(subsquare)
	_squares = newsquares


func _average(v1: float, v2: float, v3: float, v4: float) -> float:
	return (v1 + v2 + v3 + v4) / 4


# Convert from grid coordinates to world coordinate.
func _worldOf(vec: Vector2i) -> Vector2:
	return Vector2(
		vec.x * _metersPerPixel + _worldGridUL.x,
		vec.y * _metersPerPixel + _worldGridUL.y
	)


func _keyFor(vec: Vector2i) -> int:
	return vec.y * _totalGridSize.x + vec.x


func _keyForXY(x: int, y: int) -> int:
	return y * _totalGridSize.x + x


func _setHeightXY(x: int, y: int, value: float):
	_heights[_keyForXY(x, y)] = value


func _setHeight(vec: Vector2i, value: float):
	_heights[_keyFor(vec)] = value
	

func _heightOf(vec: Vector2i) -> float:
	return _heights[_keyFor(vec)]


func _heightOfXY(x: int, y: int) -> float:
	return _heights[_keyForXY(x, y)]


func _hasHeight(vec: Vector2i) -> bool:
	return _heights.has(_keyFor(vec))
	

func _hasHeightXY(x: int, y: int) -> bool:
	return _heights.has(_keyForXY(x, y))


func _parseHeight(color: Color) -> float:
	if color.r == color.g and color.g == color.b:
		return color.r
	else:
		return -color.b


# DEBUG
func _parseKey(key: int) -> Vector2i:
	return Vector2i(int(fmod(key, _totalGridSize.x)), int(floor(key / _totalGridSize.x)))


# DEBUG
func _showKeysForY(incoming: Array, matchY: int) -> Array:
	var result = Array()
	for key in incoming:
		var vec = _parseKey(key)
		if vec.y == matchY:
			result.append(vec)
	return result


# DEBUG
func _showSquares():
	print(_squares.size(), " SQUARES:")
	for square in _squares:
		print(square.display())


# DEBUG
func _worldPosOf(vec: Vector2i) -> Vector2:
	return Vector2(
		worldUpperLeft.x + vec.x * _metersPerPixel,
		worldUpperLeft.y + vec.y * _metersPerPixel
	)

# DEBUG
func _gridPosOf(vec: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(vec.x - worldUpperLeft.x) / _metersPerPixel),
		int(floor(vec.y - worldUpperLeft.y) / _metersPerPixel)
	)
	
# DEBUG
func printInfo():
	print("worldUL=", worldUpperLeft, ", metersPerPixel=", _metersPerPixel, ", sideLen=", _sideLength, ", sideN=", sideN)
	print("gridUL=", _worldGridUL, ", gridLR=", _worldGridLR, ", totalGridSize=", _totalGridSize)


# DEBUG (UNIT TEST SUPPORT)
func detectMismatch(other: DiamondSquareGrid):
	for key in _heights.keys():
		var gridVec = _parseKey(key)
		var worldVec = _worldOf(gridVec)
		var otherGridVec = other._gridPosOf(worldVec)
		if other._hasHeight(otherGridVec):
			var yValue = _heightOf(gridVec)
			var otherYValue = other._heightOf(otherGridVec)
			assert(yValue == otherYValue)
	
	for key in other._heights.keys():
		var otherGridVec = other._parseKey(key)
		var otherWorldVec = other._worldOf(otherGridVec)
		var gridVec = _gridPosOf(otherWorldVec)
		if _hasHeight(gridVec):
			var yValue = _heightOf(gridVec)
			var otherYValue = other._heightOf(otherGridVec)
			assert(yValue == otherYValue)
