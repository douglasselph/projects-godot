extends MeshInstance3D

@export var focus_size: Vector2 = Vector2(1.0, 1.0)
@export var focus_subdivide_width: int = 4
@export var focus_subdivide_depth: int = 4 

const debug = 2

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
	var full_num_rows = full_depth + 2
	var full_num_cols = full_width + 2
	
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
	
	var focus_num_rows = focus_subdivide_depth + 2
	var focus_num_cols = focus_subdivide_width + 2
	var outer_num_steps_top = int(round(full_num_rows - focus_num_rows) / 2)
	var outer_num_steps_bottom = full_num_rows - outer_num_steps_top - focus_num_rows
	var focus_start_row = outer_num_steps_top
	var focus_end_row = full_num_rows - outer_num_steps_bottom - 1
	var outer_num_steps_left = int(round(full_num_cols - focus_num_cols) / 2)
	var outer_num_steps_right = full_num_cols - outer_num_steps_left - focus_num_cols
	var focus_start_col = outer_num_steps_left
	var focus_end_col = full_num_cols - outer_num_steps_right - 1
	var full_num_rows_top = int(round(float(full_num_rows) / 2))
	var full_num_rows_bottom = full_num_rows - full_num_rows_top
	var full_num_cols_left = int(round(float(full_num_cols) / 2))
	var full_num_cols_right = full_num_cols - full_num_cols_left
	
	if debug > 0:
		print("focus_size=", focus_size, ", full_size=", full_size)
		print("focus_start_pos", focus_start_pos, ", focus_end_pos=", focus_end_pos)
		print("full_num_rows=", full_num_rows, ", full_num_cols=", full_num_cols)
		print("focus_num_rows=", focus_num_rows, ", focus_num_cols=", focus_num_cols)
		print("outer_num_steps_top=", outer_num_steps_top, ", outer_num_steps_bottom=", outer_num_steps_bottom)
		print("focus_start_row=", focus_start_row, ", focus_end_row=", focus_end_row)
		print("outer_num_steps_left=", outer_num_steps_left, ", outer_num_steps_right=", outer_num_steps_right)
		print("focus_start_col=", focus_start_col, ", focus_end_col=", focus_end_col)
		print("full_num_rows_top=", full_num_rows_top, ", full_num_rows_bottom=", full_num_rows_bottom, ", full_num_cols_left=", full_num_cols_left, ", full_num_cols_right=", full_num_cols_right)
		print("start_pos=", start_pos, ", end_pos=", end_pos)
		
	var st = SurfaceTool.new()
	st.create_from(pmesh, 0)
	var arrayMesh = st.commit() as ArrayMesh

	var mdt = MeshDataTool.new()
	var error = mdt.create_from_surface(arrayMesh, 0)
	var vertex_count = mdt.get_vertex_count()
	
	var focus_block_size = Vector2(
		focus_size.x / (focus_num_cols-1),
		focus_size.y / (focus_num_rows-1)
	)
	
	if debug > 0:
		print("focus_block_size=", focus_block_size)
	
	#
	# CENTER ROW POSITIONS
	#
	
	# Build center outer row positions above the focus box
	var start = start_pos.y
	var end = focus_start_pos.y
	var use_dist = end - start
	
	var row_focus_vertex_pos = _apply_step_sizes(
		_reverse(_compute_step_sizes(focus_block_size.y, use_dist, outer_num_steps_top)),
		focus_block_size.y,
		start
	)
	
	# Append on focus box row positions
	row_focus_vertex_pos.append_array(
		_compute_uniform_interior_positions(focus_num_rows, focus_start_pos.y, focus_end_pos.y)
	)
	
	# Append center outer row positions below the focus box
	start = focus_end_pos.y
	end = end_pos.y
	use_dist = end - start
	row_focus_vertex_pos.append_array(_apply_step_sizes(
		_compute_step_sizes(focus_block_size.y, use_dist, outer_num_steps_bottom), 
		focus_block_size.y,
		start
	))
	
	if debug > 1:
		print("row_focus_vertex_pos[", row_focus_vertex_pos.size(), "]=", row_focus_vertex_pos)
	
	#
	# CENTER COL POSITIONS
	#
	
	# Build center outer col positions to the left of the focus box
	start = start_pos.x
	end = focus_start_pos.x
	use_dist = end - start
	var col_focus_vertex_pos = _apply_step_sizes(
		_reverse(_compute_step_sizes(focus_block_size.x, use_dist, outer_num_steps_left)),
		focus_block_size.x,
		start
	)
	
	# Append on focus box col positions
	col_focus_vertex_pos.append_array(
		_compute_uniform_interior_positions(focus_num_cols, focus_start_pos.x, focus_end_pos.x)
	)
	
	# Append center outer col positions to the right of the focus box
	start = focus_end_pos.x
	end = end_pos.x
	use_dist = end - start
	col_focus_vertex_pos.append_array(_apply_step_sizes(
		_compute_step_sizes(focus_block_size.x, use_dist, outer_num_steps_right), 
		focus_block_size.x,
		start
	))
	
	if debug > 1:
		print("col_focus_vertex_pos[", col_focus_vertex_pos.size(), "]=", col_focus_vertex_pos)
	
	#
	# EDGE ROW POSITIONS
	#
	
	# Build edge outer row positions above the center 
	start = start_pos.y
	end = center_pos.y
	use_dist = end - start
	var num_steps = int(floor(full_num_rows / 2))
	
	var row_edge_vertex_pos = _apply_step_sizes(
		_reverse(_compute_step_sizes(focus_block_size.y, use_dist, num_steps)),
		focus_block_size.y,
		start
	)
	
	var is_odd = (full_num_rows % 2 == 1)
	
	# Build edge outer row positions below the center
	start = center_pos.y
	end = end_pos.y
	use_dist = end - start
	
	row_edge_vertex_pos.append_array(
		_drop_first(is_odd, 
			_apply_step_sizes(
				_compute_step_sizes(focus_block_size.y, use_dist, num_steps),
				focus_block_size.y,
				start)
		)
	)

	if debug > 1:
		print("row_edge_vertex_pos[", row_edge_vertex_pos.size(), "]=", row_edge_vertex_pos)
	
	#
	# EDGE COL POSITIONS
	#
	
	# Build edge outer col positions before the center 
	start = start_pos.x
	end = center_pos.x
	use_dist = end - start
	num_steps = int(floor(full_num_cols / 2))
	
	var col_edge_vertex_pos = _apply_step_sizes(
		_reverse(_compute_step_sizes(focus_block_size.x, use_dist, num_steps)),
		focus_block_size.x,
		start
	)
	
	is_odd = (full_num_cols % 2 == 1)
	
	# Build edge outer col positions after the center
	start = center_pos.x
	end = end_pos.x
	use_dist = end - start
	
	col_edge_vertex_pos.append_array(
		_drop_first(is_odd,
			_apply_step_sizes(
				_compute_step_sizes(focus_block_size.x, use_dist, num_steps),
				focus_block_size.x,
				start
			)
		)
	)
	
	if debug > 1:
		print("col_edge_vertex_pos[", col_edge_vertex_pos.size(), "]=", col_edge_vertex_pos)

	# Ready to build the actual vertices now.
	var computeUV = ComputeUV.new(start_pos, end_pos)
	
	var vertex_i = 0
	for row in range(full_num_rows):
		for col in range(full_num_cols):
			var in_focus_row = row >= focus_start_row && row <= focus_end_row
			var in_focus_col = col >= focus_start_col && col <= focus_end_col
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


func _compute_step_sizes(block_size: float, full_dist: float, steps: int) -> Array:
	var step_size = _compute_increasing_step_size(block_size, full_dist, steps)
	var list = []
	var value = step_size
	
	for i in range(steps):
		list.append(value)
		value += step_size
	
	return list


func _compute_increasing_step_size(block_size: float, full_dist: float, steps: int) -> float:
	var total_step_blocks = (steps * (steps + 1)) / 2
	var remaining = full_dist - (block_size * steps)
	var step_size = remaining / total_step_blocks
	return step_size


func _apply_step_sizes(step_sizes: Array, block_size: float, start_pos: float) -> Array:
	var list = []
	var value = start_pos
	list.append(value)
	for step_size in step_sizes:
		value += block_size + step_size
		list.append(value)
	return list
	

func _compute_uniform_interior_positions(num_vertex: int, start_pos: float, end_pos: float) -> Array:
	var steps = num_vertex-1
	var step_size = (end_pos - start_pos) / steps
	var pos = start_pos
	var list = []
	for step in range(steps-1):
		pos += step_size
		list.append(pos)
	return list
	
	
func _reverse(incoming: Array) -> Array:
	incoming.reverse()
	return incoming


func _drop_first(flag: bool, incoming: Array) -> Array:
	if flag:
		incoming.remove_at(0)
	return incoming


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
		



