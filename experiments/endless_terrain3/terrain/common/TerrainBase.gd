extends Node

class_name TerrainBase

var params: TerrainParams setget _set_params, _get_params
var instance: MeshInstance

func _init(params: TerrainParams):
	self.params = params

func _set_params(params: TerrainParams):
	self.params = params
	pass


func _get_params() -> TerrainParams:
	return params
