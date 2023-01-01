extends Node3D

@export var continentAlbedo: CompressedTexture2D
@export var contintentHeightmap: CompressedTexture2D

func _ready():
	var unitTest = BlockFunnelTest.new()
	unitTest.run()
