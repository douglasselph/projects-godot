class_name CreateBlock
extends CreateBase

func create(params: TerrainParams) -> TerrainBase:
	return TerrainPerlin.new(params)
