class_name TerrainRing
extends MeshInstance3D


@export var focus_size: Vector2 = Vector2(1.0, 1.0)
@export var focus_subdivide_width: int = 4
@export var focus_subdivide_depth: int = 4


@export var albedo: CompressedTexture2D:
	set(value):
		set_albedo(value)


@export var heightmaps: Array[CompressedTexture2D]:
	set(value):
		set_heightmaps(value)


@export var offsetUV: Vector2 = Vector2.ZERO:
	set(value):
		set_offset_uv(value)


const debug = 0

var _collisionShape: HeightMapShape3D:
	get:
		return $StaticBody3D/CollisionShape3D.shape as HeightMapShape3D


# Called when the node enters the scene tree for the first time.
func _ready():
	_applyFocus()


func _applyFocus():
	
	var pmesh = self.mesh as PlaneMesh
	var full_width = pmesh.subdivide_width
	var full_depth = pmesh.subdivide_depth
	var full_size = Vector2(pmesh.size.x, pmesh.size.y)
	var half_full_size = full_size / 2
	var center_pos = Vector2(position.x, position.z)
	var full_num_vertex_z = full_depth + 2
	var full_num_vertex_x = full_width + 2
	
	var half_focus_size = focus_size / 2
	var focus_start_pos = Vector2(
		center_pos.x - half_focus_size.x,
		center_pos.y - half_focus_size.y
	)
	var focus_end_pos = Vector2(
		center_pos.x + half_focus_size.x,
		center_pos.y + half_focus_size.y
	)
	var start_pos = Vector2(
		center_pos.x - half_full_size.x,
		center_pos.y - half_full_size.y
	)
	var end_pos = Vector2(
		center_pos.x + half_full_size.x,
		center_pos.y + half_full_size.y
	)
	var focus_num_vertex_z = focus_subdivide_depth + 2
	var focus_num_vertex_x = focus_subdivide_width + 2
	
	if debug > 0:
		print("focus_size=", focus_size, ", full_size=", full_size)
		print("focus_start_pos", focus_start_pos, ", focus_end_pos=", focus_end_pos)
		print("full_num_vertex_z=", full_num_vertex_z, ", full_num_vertex_x=", full_num_vertex_x)
		print("focus_num_vertex_z=", focus_num_vertex_z, ", focus_num_vertex_x=", focus_num_vertex_x)
		print("start_pos=", start_pos, ", end_pos=", end_pos)
		
	var st = SurfaceTool.new()
	st.create_from(pmesh, 0)
	var arrayMesh = st.commit() as ArrayMesh

	var mdt = MeshDataTool.new()
	var error = mdt.create_from_surface(arrayMesh, 0)
	var vertex_count = mdt.get_vertex_count()
	
	var focus_block_size = Vector2(
		focus_size.x / (focus_num_vertex_x-1),
		focus_size.y / (focus_num_vertex_z-1)
	)
	if debug > 0:
		print("focus_block_size=", focus_block_size)
	
	#
	# CENTER/FOCUS ROW POSITIONS
	#
	var computeFocusLine = ComputeFocusLine.new()
	computeFocusLine.start = start_pos.y
	computeFocusLine.end = end_pos.y
	computeFocusLine.focus_start = focus_start_pos.y
	computeFocusLine.focus_end = focus_end_pos.y
	computeFocusLine.total_num_vertex = full_num_vertex_z
	computeFocusLine.focus_num_vertex = focus_num_vertex_z
	
	var row_focus_vertex_pos = computeFocusLine.compute()
	
	var focus_start_vertex_z = computeFocusLine.num_vertex_before_focus + 1
	var focus_end_vertex_z = focus_start_vertex_z + focus_num_vertex_z - 1
	
	if debug > 1:
		print("row_focus_vertex_pos[", row_focus_vertex_pos.size(), "]=", row_focus_vertex_pos)
	
	#
	# CENTER/FOCUS COL POSITIONS
	#
	computeFocusLine.start = start_pos.x
	computeFocusLine.end = end_pos.x
	computeFocusLine.focus_start = focus_start_pos.x
	computeFocusLine.focus_end = focus_end_pos.x
	computeFocusLine.total_num_vertex = full_num_vertex_x
	computeFocusLine.focus_num_vertex = focus_num_vertex_x
	
	var col_focus_vertex_pos = computeFocusLine.compute()
	
	var focus_start_vertex_x = computeFocusLine.num_vertex_before_focus + 1
	var focus_end_vertex_x = focus_start_vertex_x + focus_num_vertex_x - 1
	
	if debug > 1:
		print("col_focus_vertex_pos[", col_focus_vertex_pos.size(), "]=", col_focus_vertex_pos)
	
	#
	# EDGE ROW POSITIONS
	#
	var computeEdgeLine = ComputeEdgeLine.new()
	computeEdgeLine.block_size = focus_block_size.y
	computeEdgeLine.start = start_pos.y
	computeEdgeLine.end = end_pos.y
	computeEdgeLine.total_num_vertex = full_num_vertex_z

	var row_edge_vertex_pos = computeEdgeLine.compute()
	
	if debug > 1:
		print("row_edge_vertex_pos[", row_edge_vertex_pos.size(), "]=", row_edge_vertex_pos)
	
	#
	# EDGE COL POSITIONS
	#
	computeEdgeLine.block_size = focus_block_size.x
	computeEdgeLine.start = start_pos.x
	computeEdgeLine.end = end_pos.x
	computeEdgeLine.total_num_vertex = full_num_vertex_x
	
	var col_edge_vertex_pos = computeEdgeLine.compute()
	
	if debug > 1:
		print("col_edge_vertex_pos[", col_edge_vertex_pos.size(), "]=", col_edge_vertex_pos)

	# Ready to build the actual vertices now.
	var computeUV = ComputeUV.new(start_pos, end_pos)
	
	var vertex_i = 0
	for row in range(full_num_vertex_z):
		for col in range(full_num_vertex_x):
			var in_focus_row = row >= focus_start_vertex_z && row <= focus_end_vertex_z
			var in_focus_col = col >= focus_start_vertex_x && col <= focus_end_vertex_x
			var vertex = mdt.get_vertex(vertex_i)

			if in_focus_row:
				if in_focus_col:
					vertex.z = row_focus_vertex_pos[row]
				else:
					vertex.z = row_edge_vertex_pos[row]
				vertex.x = col_focus_vertex_pos[col]
			elif in_focus_col:
				vertex.z = row_focus_vertex_pos[row]
				vertex.x = col_edge_vertex_pos[col]
			else:
				vertex.z = row_edge_vertex_pos[row]
				vertex.x = col_edge_vertex_pos[col]
				
			var uv_remapped = computeUV.map(vertex.x, vertex.z)
		
			if debug > 2:
				print(vertex_i, ": (", row, ", ", col, ")=", vertex.x, ", ", vertex.z, " -- UV=", uv_remapped)
			
			mdt.set_vertex(vertex_i, vertex)
			mdt.set_vertex_uv(vertex_i, uv_remapped)

			vertex_i += 1

	arrayMesh.clear_surfaces()
	mdt.commit_to_surface(arrayMesh)
	st.create_from(arrayMesh, 0)
	st.generate_normals()
	
	self.mesh = st.commit()


func set_albedo(value: CompressedTexture2D):
	var pmesh = self.mesh as PlaneMesh
	var shader: ShaderMaterial = pmesh.material as ShaderMaterial
	shader.set_shader_parameter("albedo", value)


func set_heightmaps(value: Array[CompressedTexture2D]):
	heightmaps = value
	var pmesh = self.mesh as PlaneMesh
	var shader: ShaderMaterial = pmesh.material as ShaderMaterial
	shader.set_shader_parameter("heightmaps", value)


func set_offset_uv(value: Vector2):
	offsetUV = value
	var pmesh = self.mesh as PlaneMesh
	var shader: ShaderMaterial = pmesh.material as ShaderMaterial
	shader.set_shader_parameter("OffsetUV", value)


func _updateCollisionShape():
	var center_pos = Vector2(position.x, position.z)
	var half_focus_size = focus_size / 2
	var focus_start_pos = Vector2(
		center_pos.x - half_focus_size.x,
		center_pos.y - half_focus_size.y
	)
	var focus_end_pos = Vector2(
		center_pos.x + half_focus_size.x,
		center_pos.y + half_focus_size.y
	)
	
	
	var pmesh = self.mesh as PlaneMesh
	var full_size = Vector2(pmesh.size.x, pmesh.size.y)
	var half_full_size = full_size / 2
	var start_pos = Vector2(
		center_pos.x - half_full_size.x,
		center_pos.y - half_full_size.y
	)
	var end_pos = Vector2(
		center_pos.x + half_full_size.x,
		center_pos.y + half_full_size.y
	)
	var computeUV = ComputeUV.new(start_pos, end_pos)
	var vertex = Vector3()
	var uv_remapped = computeUV.map(vertex.x, vertex.z)
	
	var size = Vector2(2, 2)
	var data = PackedFloat32Array()
	data.resize(size.x * size.y)
	var index = 0
	for y in range(size.y):
		for x in range(size.x):
			data.set(index, 0)
			index += 1
	
	_collisionShape.map_width = size.x
	_collisionShape.map_height = size.y
	_collisionShape.map_data = data



enum Direction { Forward, Reverse }

class ComputeLine:
	
	func _compute_step_sizes(block_size: float, full_dist: float, steps: int) -> Array:
		var inc = _compute_increasing_step_size(block_size, full_dist, steps)
		var list = []
		var step_size = 0
		
		for i in range(steps):
			step_size += inc
			list.append(step_size)
		
		list.reverse()
		list.remove_at(list.size()-1)
			
		return list


	func _compute_increasing_step_size(block_size: float, full_dist: float, steps: int) -> float:
		var total_step_blocks = (steps * (steps + 1)) / 2
		var remaining = full_dist - (block_size * steps)
		var step_size = remaining / total_step_blocks
		return step_size


	func _apply_step_sizes(step_sizes: Array, block_size: float, start_pos: float, dir: Direction) -> Array:
		var list = []
		var value = start_pos
		var step: float
		list.append(value)
		for step_size in step_sizes:
			step = block_size + step_size
			if dir == Direction.Reverse:
				value -= step
			else:
				value += step
			list.append(value)
		return list


	func _reverse(incoming: Array) -> Array:
		incoming.reverse()
		return incoming

	
class ComputeFocusLine:
	# Incoming
	var start: float
	var end: float
	var focus_start: float
	var focus_end: float
	var total_num_vertex: int
	var focus_num_vertex: int
	
	# Outgoing
	var num_vertex_before_focus: int
	
	# Private
	var _tool: ComputeLine
	
	
	func _init():
		_tool = ComputeLine.new()


	func compute() -> Array:
		var coords = []
		
		var focus_size = focus_end - focus_start
		var block_size = focus_size / (focus_num_vertex-1)
		var num_vertex_outside_of_focus = total_num_vertex - focus_num_vertex
		num_vertex_before_focus = int(round(num_vertex_outside_of_focus / 2))
		var num_vertex_after_focus = num_vertex_outside_of_focus - num_vertex_before_focus
		
		# Build coords before focus
		var use_end = focus_start
		var use_dist = use_end - start
		var num_steps = num_vertex_before_focus
		var step_sizes = _tool._compute_step_sizes(block_size, use_dist, num_steps)
		
		coords = _tool._apply_step_sizes(step_sizes, block_size, start, Direction.Forward)
		
		# Append on focus coords
		coords.append_array(
			_compute_uniform_interior_positions(focus_num_vertex, focus_start, focus_end)
		)
		
		# Append coords after focus
		use_dist = end - focus_end
		num_steps = num_vertex_after_focus
		step_sizes = _tool._compute_step_sizes(block_size, use_dist, num_steps)
		
		var more_coords = _tool._apply_step_sizes(step_sizes, block_size, end, Direction.Reverse)
		coords.append_array(_tool._reverse(more_coords))
	
		return coords


	func _compute_uniform_interior_positions(num_vertex: int, start_pos: float, end_pos: float) -> Array:
		var steps = num_vertex-1
		var step_size = (end_pos - start_pos) / steps
		var pos = start_pos
		var list = []
		list.append(start_pos)
		for step in range(steps-1):
			pos += step_size
			list.append(pos)
		list.append(end_pos)
		return list


class ComputeEdgeLine:
	# Incoming
	var start: float
	var end: float
	var block_size: float
	var total_num_vertex: int
	
	# Private
	var _tool: ComputeLine
	
	
	func _init():
		_tool = ComputeLine.new()


	func compute() -> Array:
		var coords = []
		
		var center_pos = (start + end) / 2
		
		# Build coordinates before center position
		var use_dist = center_pos - start
		var is_even = total_num_vertex % 2 == 0
		var num_steps = int(floor(total_num_vertex / 2))
		
		if is_even:
			use_dist -= block_size / 2
		
		var step_sizes = _tool._compute_step_sizes(block_size, use_dist, num_steps)
		
		coords = _tool._apply_step_sizes(step_sizes, block_size, start, Direction.Forward)
		
		# If odd number of points, add in center position.
		if not is_even:
			coords.append(center_pos)

		# Build coordinates after center position
		var more_coords = _tool._apply_step_sizes(step_sizes, block_size, end, Direction.Reverse)
		coords.append_array(_tool._reverse(more_coords))

		return coords


class ComputeUV:
	
	var ul: Vector2
	var lr: Vector2
	var size: Vector2
	
	func _init(ul: Vector2, lr: Vector2):
		self.ul = ul
		self.lr = lr
		size = Vector2(
			lr.x - ul.x,
			lr.y - ul.y
		)
		
	func map(x: float, z: float) -> Vector2:
		return Vector2(
			(x - ul.x) / size.x,
			(z - ul.y) / size.y
		)
		
