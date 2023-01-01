class_name TerrainMap
extends Node

#
# Joins together a ContinentMap and a BlockFunnel producing a set of related terrains.
# The BlockFunnel determines the arrangement the terrains will have to one another in 
# so far as their locations and sizes. The ContinentMap will be used to actually acquire the images
# for each terrain block needed.
#
# Will also manage the adjustment of the terrains when the player moves, determining what
# new terrains will need to be created as well as which ones will have moved.
#

var _continentMap: ContinentMap
var _blockFunnel: BlockFunnel


class Params:
	var continentMap: Image
	var baseBlockFactor: int = 2	# Power of 2 used to determine the number of blocks per side
	var numRings: int				# The number of rings surrounding the central terrain blocks
	var terrainFactor: int			# Power of 2 used to determine the number of points per side in a terrain image.
	var baseBlockWorldSize: float	# The size in world unit of one central block edge.


func _init(params: Params):
	_continentMap = ContinentMap.new(params.continentMap)
	
	var blockParams = BlockFunnel.Params.new()
	blockParams.baseBlockFactor = params.baseBlockFactor
	blockParams.ringDepth = params.numRings
	blockParams.blockPointSizeFactor = params.terrainFactor
	blockParams.blockCenterWorldSize = params.baseBlockWorldSize
	
	_blockFunnel = BlockFunnel.new(blockParams)

