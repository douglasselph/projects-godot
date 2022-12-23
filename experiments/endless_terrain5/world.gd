extends Node3D

@export var contintentHeightmap: CompressedTexture2D

var _continentMap: ContinentMap


func _ready():
	_continentMap = ContinentMap.new(contintentHeightmap.get_image())
	
	var heightmaps: Array[CompressedTexture2D] = Array()
	heightmaps.append(_continentMap)
	heightmaps.append(_continentMap)
	heightmaps.append(_continentMap)
	heightmaps.append(_continentMap)
	heightmaps.append(_continentMap)
	heightmaps.append(_continentMap)
	heightmaps.append(_continentMap)
	heightmaps.append(_continentMap)
	heightmaps.append(_continentMap)
	$terrainRing.heightmaps = heightmaps


# Unit tests
func _runUnitTests1():
	var tester = DiamondSquareGridTest.new()
	tester.run()
	tester.runContinentUnitTests(contintentHeightmap.get_image())
	print("DIAMOND SQUARE UNIT TESTS COMPLETE")


func _runUnitTests2():
	var tester = ContinentMapTest.new()
	tester.run()
	tester.runRealImageUnitTests(contintentHeightmap.get_image())
	print("CONTINENT MAP UNIT TESTS COMPLETE")
