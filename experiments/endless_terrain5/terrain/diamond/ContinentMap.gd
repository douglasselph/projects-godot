class_name ContinentMap
extends Node
#
# PUBLIC VARIABLES
#
var metersPerPixelN: int: # metersPerPixel must be a power of 2. Using this computes the value as per pow(2,N)
	get:
		return int(floor(log(float(_metersPerPixel)) / log(2)))
	set(value):
		_metersPerPixel = int(pow(2,value))

var scaleHeightsBy: float = 1.0

#
# PRIVATE VARIABLES
#
var _metersPerPixel: int # Must be power of 2. Distance between each pixel on the continentMap.
var _heights = {} # Key: grid x,y ref.  Value: height in world
var _continentMap: Image
var _random: DiamondRandomValue
const debug: int = 0

#
# PUBLIC FUNCTIONS
#
func _init(continentMap: Image, random: DiamondRandomValue = DiamondRandomValue.new()):
	_continentMap = continentMap
	_random = random
	

#
# Convert a grid map position on the continent, i.e. a pixel position, into a world position
# according to the continent's metersPerPixel value.
#
func worldPosOf(mapPos: Vector2i) -> Vector2:
	return Vector2(
		mapPos.x * _metersPerPixel,
		mapPos.y * _metersPerPixel
	)
	

class Params:
	# The upper left corner of the image in CONTINENT units, i.e. refers to a pixel on the main continent image.
	var mapUL: Vector2i
	# The size on the map of the area to extract in power of 2 units. That is, the size to gather must
	#  be 2, 4, 8, 16 pixels, etc.
	var sizeN: Vector2i
	# How much additional detail to acquire in the specified area from sizeN. For example a value of 2, means to drill a factor of
	#  two more. So if sizeN is 4, which is pow(2,4)==16x16, the returned area would be pow(2,6)==64x64. This represents
	#  more detail for the size same area specified by sizeN.
	var depthN: int
	
#
# Extract a height map from the continent image
#
func computeHeightmap(params: Params) -> Image:
	
	print("computeHeightmap()")
	
	var mapUL = params.mapUL
	var sizeN = params.sizeN
	var depthN = params.depthN
	
	var computing = Computing.new()
	computing.continentUL = mapUL
	computing.continentSideLen = Vector2i(
		pow(2, sizeN.x),
		pow(2, sizeN.y)
	)
	computing.imageSideLen = Vector2i(
		pow(2, sizeN.x + depthN),
		pow(2, sizeN.y + depthN)
	)
	computing.contintentMax = Vector2i(
		_continentMap.get_width(),
		_continentMap.get_height()
	)
	computing.setImageMPP(_metersPerPixel)
	computing.worldUL = _worldMapPos(mapUL)
	computing.initialSquareSize = pow(2, depthN)
	
	computing.verify()

	print("_metersPerPixel=", _metersPerPixel)
	
	computing.printInfo()
	
	print("_loadInitialYValue:")
	_loadInitialYValues(computing)
	print("_loadInitialSquares:")
	_loadInitialSquares(computing)
	
	if debug > 0:
		computing.display()
	
	var numCycles = depthN
	for cycle in range(numCycles):
		_computeSquareSteps(computing)
		_computeDiamondSteps(computing)
		computing.splitSquares()
		print("cycle ", cycle, ": ", computing.squares.size(), " SQUARES COMPUTED")
	
	var image = _buildImage(computing)
	
	return image
	

#
# PRIVATE FUNCTIONS
#

#
# Three different coordinate systems make this class complicated:
#  - WORLD: A unit system based on the continent map, where 1 meter = 1 unit. This is effectively
#    the world position as seen in the meshes of the game.
#  - CONTINENT: A unit system based on the continent map image, where 1 pixel = 1 unit. 
#    _metersPerPixel is used to translate from the system to the WORLD system.
#  - IMAGE: A unit system based on the image in question being generated. Ultimately 1 unit = 1 pixel
#    on the target image. (0,0) is  the upper left of the image. However, the gathered values
#    will be from (-1, -1) to one past the size of the image, because of how the diamond-square algorith 
#    works -- it depends on a square or diamond shape of values.


#
# Transfer the initial y values from the continent map to the _heights dictionary that 
# we know we will need. This includes the central area we are capturing, i.e. the pixels
# on the map and the squares or pixels, forming a ring around it that area.
#
func _loadInitialYValues(computing: Computing):
	
	var source_start_world = computing.sourceStart
	var source_end_world = computing.sourceEnd
	
	for source_y in range(source_start_world.y-1, source_end_world.y+2):
		for source_x in range(source_start_world.x-1, source_end_world.x+2):
			var mapPos = Vector2i(source_x, source_y) * _metersPerPixel
			if not _hasHeight(mapPos):
				var yValue = _mapHeight(source_x, source_y)
				_setHeight(mapPos, yValue * scaleHeightsBy)


func _loadInitialSquares(computing: Computing):
	
	var source_start_world = computing.sourceStart
	var source_end_world = computing.sourceEnd
	var image_squareSize = computing.initialSquareSize
	var image_x: int
	var image_y = -image_squareSize
	
	for source_y in range(source_start_world.y-1, source_end_world.y+1):
		image_x = -image_squareSize
		for source_x in range(source_start_world.x-1, source_end_world.x+1):
			computing.squares.append(
				Square.new(
					Vector2i(image_x, image_y),
					Vector2i(image_x + image_squareSize, image_y + image_squareSize)
				)
			)
			image_x += image_squareSize
		image_y += image_squareSize
		


func _computeSquareSteps(computing: Computing):

	for square in computing.squares:
		var center_world = computing.imageToWorldPos(square.center)
		if not _hasHeight(center_world):
			if debug > 0:
				print("_computeSquareSteps->", square.display(), "->", center_world)
			var ul_world = computing.imageToWorldPos(square.upperLeft)
			var lr_world = computing.imageToWorldPos(square.lowerRight)
			var ul_value = _heightOf(ul_world)
			var lr_value = _heightOf(lr_world)
			var ur_value = _heightOf(computing.imageToWorldPos(square.upperRight))
			var ll_value = _heightOf(computing.imageToWorldPos(square.lowerLeft))
			var random_value = _random.randomValue(ul_world, lr_world)
			var center_value = _average(ul_value, lr_value, ur_value, ll_value) + random_value
			_setHeight(center_world, center_value)


func _computeDiamondSteps(computing: Computing):
	
	print("_computeDiamondSteps()")
	
	for square in computing.squares:
		var ul_world = computing.imageToWorldPos(square.upperLeft)
		var lr_world = computing.imageToWorldPos(square.lowerRight)
		var ur_world = computing.imageToWorldPos(square.upperRight)
		var ll_world = computing.imageToWorldPos(square.lowerLeft)
		var ul_value = _heightOf(ul_world)
		var lr_value = _heightOf(lr_world)
		var ur_value = _heightOf(ur_world)
		var ll_value = _heightOf(ll_world)
		var center = square.center
		var center_world = computing.imageToWorldPos(center)
		var center_value = _heightOf(center_world)
		var diamond_center: Vector2i
		var diamond_center_world: Vector2i
		var diamond_value: float
		var dist_y: int
		var dist_x: int
		
		# Top diamond
		diamond_center = Vector2i(
			(square.upperLeft.x + square.lowerRight.x) / 2,
			square.upperLeft.y
		)
		diamond_center_world = computing.imageToWorldPos(diamond_center)
		if not _hasHeight(diamond_center_world):
			dist_y = center.y - square.upperLeft.y
			var top_y = square.upperLeft.y - dist_y
			var top_xy = Vector2i(center.x, top_y)
			var top_xy_world = computing.imageToWorldPos(top_xy)
			
			if _hasHeight(top_xy_world):
				var top_value = _heightOf(top_xy_world)
				var random_value = _random.randomValue(top_xy_world, center_world)
				diamond_value = _average(ul_value, ur_value, center_value, top_value) + random_value
				_setHeight(diamond_center_world, diamond_value)

		# Bottom diamond:
		diamond_center.y = square.lowerRight.y
		diamond_center_world = computing.imageToWorldPos(diamond_center)
		if not _hasHeight(diamond_center_world):
			dist_y = square.lowerRight.y - center.y
			var bottom_y = square.lowerRight.y + dist_y
			var bottom_xy = Vector2i(center.x, bottom_y)
			var bottom_xy_world = computing.imageToWorldPos(bottom_xy)
			
			if _hasHeight(bottom_xy_world):
				var bottom_value = _heightOf(bottom_xy_world)
				var random_value = _random.randomValue(center_world, bottom_xy_world)
				diamond_value = _average(ll_value, lr_value, center_value, bottom_value) + random_value
				_setHeight(diamond_center_world, diamond_value)

		# Left diamond:
		diamond_center = Vector2i(
			square.upperLeft.x,
			(square.upperLeft.y + square.lowerRight.y) / 2
		)
		diamond_center_world = computing.imageToWorldPos(diamond_center)
		if not _hasHeight(diamond_center_world):
			dist_x = center.x - square.upperLeft.x
			var left_x = square.upperLeft.y - dist_x
			var left_xy = Vector2i(left_x, center.y)
			var left_xy_world = computing.imageToWorldPos(left_xy)
			
			if _hasHeight(left_xy_world):
				var left_value = _heightOf(left_xy_world)
				var random_value = _random.randomValue(left_xy_world, center_world)
				diamond_value = _average(ul_value, ll_value, center_value, left_value) + random_value
				_setHeight(diamond_center_world, diamond_value)


		# Right diamond:
		diamond_center.x = square.lowerRight.x
		diamond_center_world = computing.imageToWorldPos(diamond_center)
		if not _hasHeight(diamond_center_world):
			dist_x = square.lowerRight.x - center.x
			var right_x = square.lowerRight.x + dist_x
			var right_xy = Vector2i(right_x, center.y)
			var right_xy_world = computing.imageToWorldPos(right_xy)
			
			if _hasHeight(right_xy_world):
				var right_value = _heightOf(right_xy_world)
				var random_value = _random.randomValue(center_world, right_xy_world)
				diamond_value = _average(ur_value, lr_value, center_value, right_value) + random_value
				_setHeight(diamond_center_world, diamond_value)


func _buildImage(computing: Computing) -> Image:
	var imageNumPts = Vector2i(
		computing.imageSideLen.x+1, 
		computing.imageSideLen.y+1
	)
	var target = Image.create(imageNumPts.x, imageNumPts.y, false, Image.Format.FORMAT_RF)
	var worldLoc: Vector2i = computing.worldUL
	var imageMetersPerPixel = computing.imageMetersPerPixel
	for y in range(imageNumPts.y):
		worldLoc.x = computing.worldUL.x
		for x in range(imageNumPts.x):
			worldLoc.x = computing.imageToWorldX(x)
			var value = _heightOf(worldLoc)
			target.set_pixel(x, y, Color(value, 0, 0))
			worldLoc.x += imageMetersPerPixel
		worldLoc.y += imageMetersPerPixel
	return target

#
# SUPPORTING CLASSES
#
class Computing:
	var squares: Array = []         # The complete list of squares that are currently in process of being computed.
	var imageSideLen: Vector2i      # The size of the image we are to compute which will define the IMAGE grid units. Each side is a power of 2.
	var continentUL: Vector2i       # The CONTINENT UL position on the continent image of the area being computed
	var continentSideLen: Vector2i  # Number of pixel points per side on the continent map we are extracting from, i.e. that will become the image.
	var contintentMax: Vector2i     # The size of the continent image in pixels.
	var worldUL: Vector2i           # The WORLD map position equivalent of continentUL.
	var imageMetersPerPixel: int    # The image meters per pixel value. That is, how many WORLD units per IMAGE unit.
	var initialSquareSize: int      # In IMAGE coordinates or units, how many units each square is initially, where 1 square == 1 pixel on the continent map.
	
	var continentLR: Vector2i:
		get:
			return Vector2i(
				continentUL.x + continentSideLen.x,
				continentUL.y + continentSideLen.y
			)
	
	#
	# Return the source start position of the image to capture along the edge of the
	# area to capture. Returned in CONTINENT grid units, where 1 pixel = 1 unit.
	#
	var sourceStart: Vector2i:
		get:
			var source_start = Vector2i(
				continentUL.x,
				continentUL.y
			)
			if source_start.x < 0:
				source_start.x = 0
			if source_start.y < 0:
				source_start.y = 0
			return source_start
	
	#
	# Return the source end position of the image to capture. 
	# Returned in CONTINENT grid units, where 1 pixel = 1 unit.
	#
	var sourceEnd: Vector2i:
		get:
			var source_end = Vector2i(
				continentLR.x,
				continentLR.y
			)
			if source_end.x >= contintentMax.x:
				source_end.x = contintentMax.x-1
			if source_end.y >= contintentMax.y:
				source_end.y = contintentMax.y-1
			return source_end


	func setImageMPP(continentMPP: float):
		imageMetersPerPixel = continentSideLen.x * continentMPP / imageSideLen.x
		assert((continentSideLen.y * continentMPP / imageSideLen.y) == imageMetersPerPixel)


	#
	# Convert from an IMAGE position into the WORLD position
	#
	func imageToWorldPos(pos: Vector2i) -> Vector2i:
		return Vector2i(
			worldUL.x + pos.x * imageMetersPerPixel,
			worldUL.y + pos.y * imageMetersPerPixel
		)
	
	
	#
	# Convert from an IMAGE X position into the WORLD X position
	#
	func imageToWorldX(x: int) -> int:
		return worldUL.x + x * imageMetersPerPixel
	
	
	#
	# Convert from an IMAGE X position into the WORLD X position
	#
	func imageToWorldY(y: int) -> int:
		return worldUL.y + y * imageMetersPerPixel
		
	
	# Given the CONTINENT position, return the IMAGE pos.
	func continentToImagePos(pos: Vector2i) -> Vector2i:
		return Vector2i(
			(pos.x - continentUL.x) * initialSquareSize,
			(pos.y - continentUL.y) * initialSquareSize
		)


	# Return the upper left of the central area (image) we are capturing in IMAGE units
	var _centerUL: Vector2i:
		get:
			return Vector2i(0, 0)
	
	
	# Return the lower right of central area (image) we are capturing in IMAGE units
	var _centerLR: Vector2i:
		get:
			return _centerUL + imageSideLen
	
	
	func splitSquares():
		var centerUpperLeft = _centerUL
		var centerLowerRight = _centerLR
		var newsquares = []
		for square in squares:
			var split = square.split4()
			for subsquare in split:
				if subsquare.overlaps(centerUpperLeft, centerLowerRight):
					newsquares.append(subsquare)
		squares = newsquares


	func printInfo():
		print("COMPUTING imageSideLen=", imageSideLen, ", continentUL=", continentUL, ", continentSideLen=", continentSideLen, ", continentMax=", contintentMax)
		print("COMPUTING worldUL=", worldUL, ", imageMetersPerPixel=", imageMetersPerPixel, ", initialSquareSize=", initialSquareSize, ", sourceStart=", sourceStart, ", sourceEnd=", sourceEnd)
	
	
	func display():
		print("COMPUTING SQUARES=", squares.size())
		for square in squares:
			print(square.display())


	func verify():
		print("verify(): contintentLR=", continentLR, ", continentSideLen=", continentSideLen, ", contintentMax=", contintentMax)
		assert(continentLR.x < contintentMax.x)
		assert(continentLR.y < contintentMax.y)
		assert(imageSideLen.x > continentSideLen.x)
		assert(imageSideLen.y > continentSideLen.y)
		assert(fmod(imageSideLen.x, continentSideLen.x) == 0)
		assert(fmod(imageSideLen.y, continentSideLen.y) == 0)


class Square:

	var upperLeft: Vector2i   # IMAGE coordinates
	var lowerRight: Vector2i  # IMAGE coordinates
	
	func _init(ul: Vector2i, lr: Vector2i):
		self.upperLeft = ul
		self.lowerRight = lr
		

	# Computed
	var upperRight: Vector2i:
		get:
			return Vector2i(lowerRight.x, upperLeft.y)
	
	var lowerLeft: Vector2i:
		get:
			return Vector2i(upperLeft.x, lowerRight.y)
	
	var center: Vector2i:
		get:
			return Vector2i(
				(upperLeft.x + lowerRight.x)/2,
				(upperLeft.y + lowerRight.y)/2
			)
	
	
	# Return true if the square overlaps at all the passed in box.
	# ul and lr in IMAGE coordinates
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

#
# SUPPORTING FUNCTIONS
#

#
# Convert from the CONTINENT grid's position (1 pixel = 1 unit)
# into the WORLD grid position, where 1 meter == 1 unit.
#
func _worldMapPos(continentPos: Vector2i) -> Vector2i:
	return continentPos * _metersPerPixel


# Vector in WORLD coordinates
func _keyFor(worldPos: Vector2i) -> int:
	return worldPos.y * _continentMap.get_width() * _metersPerPixel + worldPos.x


# Debug:
func _keyForv(worldPos: Vector2i) -> String:
	return "%d,%d" % [worldPos.x, worldPos.y]


# Vector in WORLD coordinates
func _setHeight(worldPos: Vector2i, value: float):
	_heights[_keyForv(worldPos)] = value


# Vector in WORLD coordinates
func _hasHeight(worldPos: Vector2i) -> bool:
	return _heights.has(_keyForv(worldPos))


# Vector in WORLD coordinates
func _heightOf(worldPos: Vector2i) -> float:
	return _heights[_keyForv(worldPos)]


# world_x, world_y: CONTINENT units
func _mapHeight(world_x: int, world_y: int) -> float:
	var color = _continentMap.get_pixel(world_x, world_y)
	return _parseHeight(color)


func _parseHeight(color: Color) -> float:
	if color.r == color.g and color.g == color.b:
		return color.r
	else:
		return -color.b


func _average(v1: float, v2: float, v3: float, v4: float) -> float:
	return (v1 + v2 + v3 + v4) / 4


	

