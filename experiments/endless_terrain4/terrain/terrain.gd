extends MeshInstance3D

@onready var colShape = $StaticBody3d/CollisionShape3d

@export var chunk_size = 2.0
@export var height_ratio = 1.0
@export var colShape_size_ratio = 0.1

var _image = Image.new()
var _shape = HeightMapShape3D.new()


func _ready():
	_update_terrain()


func _update_terrain():
	material_override.set("shader_param/height_ratio", height_ratio)
	_addCollisionShape()
	

func _addCollisionShape():
	# Collision Shape
	_image.load("res://height_map.png")
	_image.convert(Image.FORMAT_RF)
	_image.resize(_image.get_width()*colShape_size_ratio, _image.get_height()*colShape_size_ratio)
	var data = _image.get_data().to_float32_array()
	for i in range(data.size()):
		data[i] *= height_ratio
	_shape.map_width = _image.get_width()
	_shape.map_depth = _image.get_height()
	_shape.map_data = data
	var pmesh = mesh as PlaneMesh
	var scale_ratio_x = pmesh.size.x / float(_image.get_width())
	var scale_ratio_z = pmesh.size.y / float(_image.get_height())

	colShape.scale = Vector3(scale_ratio_x, 1, scale_ratio_z)
	colShape.shape = _shape

func _process(delta):
	pass
