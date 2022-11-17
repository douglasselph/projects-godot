class_name CreateBlock

extends CreateBase


func _init().():
	pass
	
func create(params: TerrainParams) -> TerrainBase:
	return TerrainPerlin.new(params)
