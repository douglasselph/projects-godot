extends Node

class_name TerrainBase

var params: TerrainParams # :
	get:
		return params # TODOConverter40 Copy here content of _get_params
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of _set_params
var instance: MeshInstance3D
var material: Material

func _init(p: TerrainParams):
	self.params = p
	self.material = _setup_material(p.material)


func _setup_material(material: Material) -> Material:
	if material:
		return material
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.0)
	return mat


func _set_params(params: TerrainParams):
	self.params = params


func _get_params() -> TerrainParams:
	return params
	

func modify():
	pass
