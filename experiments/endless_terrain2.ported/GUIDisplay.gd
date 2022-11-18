extends Node3D

class_name GUIDisplay

var _source: Node3D
var _viewport: SubViewport
var _quadArea: MeshInstance3D
var _touchArea: Area3D

func _init(source: Node3D,viewport: SubViewport,quadArea: MeshInstance3D,touchArea: Area3D):
	_source = source
	_viewport = viewport
	_quadArea = quadArea
	_touchArea = touchArea
	_touchArea.connect("mouse_entered",Callable(self,"_mouse_entered_touch_area"))
	_touchArea.connect("mouse_exited",Callable(self,"_mouse_exited_touch_area"))
	
var quadMeshSize: Vector2
var isMouseHeld: bool = false
var isMouseInsideArea: bool = false
var lastMousePosition3D = Vector3.ZERO 	# Used when dragging outide of the box
var lastMousePosition2D = null 			# Last processed touch/mouse event. Used to calculate relative movement.

func _mouse_entered_touch_area():
	isMouseInsideArea = true
	
func _mouse_exited_touch_area():
	isMouseInsideArea = false
	
func unhandled_input(event):
	# If the event is a mouse/touch event and/or the mouse is either held or inside the area, then
	# we need to do some additional processing in the handle_mouse function before passing the event to the _viewport.
	# If the event is not a mouse/touch event, then we can just pass the event directly to the _viewport.
	if _shouldHandleMouseEvent(event) and (isMouseInsideArea or isMouseHeld):
		_handleMouseEvent(event)
	else:
		_viewport.input(event)

func _handleMouseEvent(event: InputEvent):
	
	quadMeshSize = (_quadArea.mesh as QuadMesh).size
	
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		isMouseHeld = event.pressed
	
	# Convert the relative event position from 3D to 2D
	var mousePos3D = _findMousePosInArea(event.global_position)
	var mousePos2D = Vector2(mousePos3D.x, -mousePos3D.y)
	
	# Right now the event position's range is the following: (-quadMeshSize/2) -> (quadMeshSize/2)
	# Convert to the following range: 0 -> quadMeshSize
	mousePos2D.x += quadMeshSize.x / 2
	mousePos2D.y += quadMeshSize.y / 2
	# Convert it into the following range: 0 -> 1
	mousePos2D.x = mousePos2D.x / quadMeshSize.x
	mousePos2D.y = mousePos2D.y / quadMeshSize.y
	# Convert the position to the following range: 0 -> _viewport.size
	mousePos2D.x = mousePos2D.x * _viewport.size.x
	mousePos2D.y = mousePos2D.y * _viewport.size.y
	# Now the event position is in the _viewport's coordinate system.
	event.position = mousePos2D
	event.global_position = mousePos2D
	
	if event is InputEventMouseMotion:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if lastMousePosition2D == null:
			event.relative = Vector2.ZERO
		else:
			# Calulate the distance the event traveled from the previous position
			event.relative = mousePos2D - lastMousePosition2D
			
	lastMousePosition2D = mousePos2D
	
	# Send the processed input event into the _viewport
	_viewport.input(event)
	
func _findMousePosInArea(global_position: Vector2) -> Vector3:
	var camera = _source.get_viewport().get_camera_3d()
	# From camera center to the mouse position in the Area3D
	var from = camera.project_ray_origin(global_position)
	var dist = _findFurtherDistanceTo(camera.transform.origin)
	var to = from + camera.project_ray_normal(global_position) * dist

	# Manually raycasts the are to find the mouse position
	var result = _source.get_world_3d().direct_space_state.intersect_ray(from, to, [], _touchArea.collision_layer,false,true) #for 3.1 changes

	if result.size() > 0:
		return _touchArea.global_transform.affine_inverse() * result.position
	else:
		return lastMousePosition3D

func _findFurtherDistanceTo(origin: Vector3) -> float:
	# Find edges of collision and change to global positions
	var edges = []
	edges.append(_touchArea.to_global(Vector3(quadMeshSize.x / 2, quadMeshSize.y / 2, 0)))
	edges.append(_touchArea.to_global(Vector3(quadMeshSize.x / 2, -quadMeshSize.y / 2, 0)))
	edges.append(_touchArea.to_global(Vector3(-quadMeshSize.x / 2, quadMeshSize.y / 2, 0)))
	edges.append(_touchArea.to_global(Vector3(-quadMeshSize.x / 2, -quadMeshSize.y / 2, 0)))

	# Get the furthest distance between the camera and collision to avoid raycasting too far or too short
	var far_dist: float = 0
	var temp_dist: float
	for edge in edges:
		temp_dist = origin.distance_to(edge)
		if temp_dist > far_dist:
			far_dist = temp_dist
	return far_dist

func _shouldHandleMouseEvent(event: InputEvent) -> bool:
	for c in [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]:
		if event is c:
			return true
	return false
