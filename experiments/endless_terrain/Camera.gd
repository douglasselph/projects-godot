class_name MovableCamera extends Camera

enum Moving {NONE, TRANSLATE, ZOOM, ROTATE}

var _moving = Moving.NONE
var _movingFrom = Vector2(0, 0)
var _movingFromValid = false
var _movingTrigger = 5
var _movingScale = 0.1

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
			var direction_facing = global_transform.basis.z.normalized()
			var direction_up = global_transform.basis.y.normalized()
			var center = get_viewport().get_visible_rect().size / 2
			var normal = project_local_ray_normal(center)
			
			var angle_y = _movingScale * dirx
			rotate_object_local(direction_facing,  angle_y)
			
			# rotate_x(_movingScale * diry)
			# rotate_y(_movingScale * dirx)
			pass
