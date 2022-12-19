extends CharacterBody3D

class_name Player

var _velocity := Vector3.ZERO
var _direction := Vector3.ZERO
var _facingDirection := 0.0

const MAX_SPEED := 20
const ACCEL := 5.0
const DECEL := 15.0
const JUMP_SPEED := 15
const GRAVITY := -45

signal moved(amount: Vector2)


func _process(delta: float):
	_move(delta)
	_face_forward()


func _move(delta: float):
	var movementDir := _get_2d_movement()
	var camera_xform := ($Camera3D as Camera3D).get_global_transform()
	
	_direction = Vector3.ZERO
	
	_direction += camera_xform.basis.x.normalized() * movementDir.y
	_direction += camera_xform.basis.z.normalized() * movementDir.x
	
	_direction = _move_vertically(_direction, delta)
	_velocity = _h_accel(_direction, delta)
	
	set_velocity(_velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()
	
	_notify_of_movement()
	_reposition_at_zero()


func _move_vertically(dir: Vector3, delta: float) -> Vector3:
	_velocity.y += GRAVITY * delta
	if is_on_floor():
		if Input.is_action_pressed("ui_jump") && is_on_floor():
			_velocity.y = JUMP_SPEED
		else:
			_velocity.y = 0
	dir.y = 0
	dir = dir.normalized()
	
	return dir


func _face_forward():
	($Body as MeshInstance3D).rotation.y = _facingDirection


func _get_2d_movement() -> Vector2:
	var movement_vector := Vector2()
	
	if Input.is_action_pressed("ui_forward"):
		movement_vector.x = -1
		_facingDirection = 0
	elif Input.is_action_pressed("ui_back"):
		movement_vector.x = 1
		_facingDirection = PI
	elif Input.is_action_pressed("ui_left"):
		movement_vector.y = -1
		_facingDirection = PI * 0.5
	elif Input.is_action_pressed("ui_right"):
		movement_vector.y = 1
		_facingDirection = PI * 1.5
	
	return movement_vector.normalized()


func _h_accel(dir: Vector3, delta: float) -> Vector3:
	var vel_2d := _velocity
	vel_2d.y = 0
	
	var target := dir
	target *= MAX_SPEED
	
	var accel : float
	if dir.dot(vel_2d) > 0:
		accel = ACCEL
	else:
		accel = DECEL
		
	vel_2d = vel_2d.lerp(target, accel * delta)
	
	_velocity.x = vel_2d.x 
	_velocity.z = vel_2d.z
	
	return _velocity


func _notify_of_movement():
	moved.emit(Vector2(position.x, position.z))
	

func _reposition_at_zero():
	position = Vector3(0, position.y, 0)
