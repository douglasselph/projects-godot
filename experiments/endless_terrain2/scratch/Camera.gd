class_name MovableCamera extends Camera

enum Moving {NONE, TRANSLATE, ZOOM, ROTATE}

var _moving = Moving.NONE
var _movingFrom = Vector2(0, 0)
var _movingFromValid = false
var _movingTrigger = 5
var _movingScale = 0.1
var _forwardLook = 3.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	if Input.is_action_just_pressed("ui_shift"):
		_moving = Moving.TRANSLATE
	elif Input.is_action_just_pressed("ui_zoom"):
		_moving = Moving.ZOOM
	elif Input.is_action_just_pressed("ui_rotate"):
		_moving = Moving.ROTATE
	elif Input.is_action_just_released("ui_shift") || \
		 Input.is_action_just_released("ui_zoom") || \
		 Input.is_action_just_released("ui_rotate"):
		_moving = Moving.NONE
		_movingFromValid = false
	
func _input(event):
	if _moving != Moving.NONE:
		if event is InputEventMouseMotion:
			update_movement(event.position)

func update_movement(position):
	if !_movingFromValid: 
		_movingFrom = position
		_movingFromValid = true
		return
	
	# Left and Right
	var dirx: int
	var diffx = position.x - _movingFrom.x

	if diffx > _movingTrigger:
		dirx = -1
	elif diffx < -_movingTrigger:
		dirx = 1
	else:
		dirx = 0
		
	# Backward and Forward
	var diry: int
	var diffy = position.y - _movingFrom.y
	if diffy > _movingTrigger:
		diry = 1
	elif diffy < -_movingTrigger:
		diry = -1
	else:
		diry = 0
		
	if dirx == 0 && diry == 0:
		return
		
	_movingFrom = position
	
	match _moving:
		Moving.TRANSLATE:
			var direction = Vector3(dirx * _movingScale, diry * _movingScale, 0)
			translate(direction)
		Moving.ZOOM:
			pass
		Moving.ROTATE:
			# Strategy: Projecting forward from the direction the camera is facing,
			#  find a point a little distance out. Then using that point, with a normal
			#  doing directly upward from the perspective of the camera locate an axis.
			#  Using this axis, rotate the camera according to the dirx amount.
			# For diry do the same kind of rotation, but on an x-aligned axis. 
			var direction_facing = global_transform.basis.z.normalized()
			var direction_up = global_transform.basis.y.normalized()
			
			var center = get_viewport().get_visible_rect().size / 2
			var projected_center_normal = project_local_ray_normal(center)
			var projected_center_point = project_position(center, 3.0)
			
			var shift_position = direction_facing * _forwardLook
			translate(shift_position)
			
			var angle_y = _movingScale * dirx
			var amount = direction_up * _movingScale

			rotate(direction_up,  angle_y)
			
			translate(-shift_position)
			# rotate_x(_movingScale * diry)
			# rotate_y(_movingScale * dirx)
			pass
