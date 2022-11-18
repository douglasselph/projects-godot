extends MeshInstance3D

enum Moving {NONE, TRANSLATE, ZOOM, ROTATE}

var _moving = Moving.NONE
var _movingFrom = Vector2(0, 0)
var _movingFromValid = false
var _movingTrigger = 5
var _translateScale = 0.6
var _rotateScale = 0.1
var _zoomScale = 0.4
var _lastEmittedTranslation = Vector3.ZERO
var _resetTransform = Transform3D.IDENTITY

@onready var poleMesh: MeshInstance3D = $Pole

signal camera_moved(position)

func _ready():
	_resetTransform = transform

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
	elif Input.is_action_just_released("ui_reset"):
		_reset()
		
func _input(event):
	if _moving != Moving.NONE:
		if event is InputEventMouseMotion:
			_update_movement(event.position)

func _update_movement(position):
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
			var direction = Vector3(dirx * _translateScale, diry * _translateScale, 0)
			translate(direction)
			emit_position()
		Moving.ZOOM:
			var direction = Vector3(0, diry * _zoomScale, 0)
			poleMesh.translate(direction) 
			emit_position()
		Moving.ROTATE:
			var direction_y = global_transform.basis.y.normalized()
			var angle_x = _rotateScale * dirx
			rotate(direction_y,  angle_x)
			
			var direction_x = global_transform.basis.x.normalized()
			var angle_y = _rotateScale * diry
			rotate(direction_x, angle_y)
			emit_position()

func emit_position():
	var position = $Pole/Camera3D.global_translation
	if position != _lastEmittedTranslation:
		emit_signal("camera_moved", position)
		_lastEmittedTranslation = position

func _reset():
	transform = _resetTransform
