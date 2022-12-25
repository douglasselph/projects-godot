class_name FocusRing
extends MeshInstance3D

@tool

@export var albedo: CompressedTexture2D:
	set(value):
		set_albedo(value)


@export var size: Vector2 = Vector2(1, 1):
	set(value):
		_recreate()


func _ready():
	_recreate()
	
	
func _recreate():
	_createEvolve1()


func set_albedo(value: CompressedTexture2D):
	var count = get_surface_override_material_count()
	var material = get_surface_override_material(0)
	if material != null:
		material.set_shader_parameter("albedo", value)


func _createEvolve1():
	
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0, 0, 0))
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(1, 1, 0))
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(1, 0, 0))
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0, 0, 0))
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(0, 1, 0))
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(1, 1, 0))
	
	st.index()
	st.generate_normals()
	st.generate_tangents()

	mesh = st.commit()
	
	set_albedo(albedo)
	

func _createSimple2():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0, 0, 0))
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(1, 1, 0))
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(1, 0, 0))
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0, 0, 0))
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(0, 1, 0))
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(1, 1, 0))
	
	st.index()
	st.generate_normals()
	st.generate_tangents()

	mesh = st.commit()


func _createSimple1():
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
