extends Node3D
	
func _ready():
	var terrain = preload("res://TerrainPerlin.tscn").instantiate()
	terrain.TerrainX = 1
	terrain.TerrainZ = 0
	terrain.TerrainHeight = 2
	terrain.TerrainWidth = 2
	terrain.Octaves = 4
	add_child(terrain)
