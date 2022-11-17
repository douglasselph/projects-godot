extends Node

class_name TerrainBase

var params: TerrainParams # setget _set_params, _get_params
var instance: MeshInstance
var material: Material

func _init(p: TerrainParams):
	self.params = p
	self.material = _setup_material(p.material)


func _setup_material(material: Material) -> Material:
	if material:
		return material
	
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(1.0, 1.0, 0.0)
	return mat


func _set_params(params: TerrainParams):
	self.params = params


func _get_params() -> TerrainParams:
	return params
	

func modify():
	pass
