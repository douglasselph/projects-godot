class_name FocusRing
extends MeshInstance3D

@tool

# Called when the node enters the scene tree for the first time.
func _ready():
	var data = []
	data.resize(ArrayMesh.ARRAY_MAX)
	data[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 1, 0),
		Vector3(0, 1, 0)
	])
	data[ArrayMesh.ARRAY_INDEX] = PackedInt32Array([
		2, 1, 0,
		3, 2, 0
	])
	data[ArrayMesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1)
	])
	data[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(1, 1),
		Vector2(0, 1),
		Vector2(0, 0),
		Vector2(1, 0)
	])
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
