extends Camera

export var mouseSensitivity := 2000

onready var Player := get_parent() as KinematicBody

func _ready():
	pass

func _process(delta):
	if Input.is_action_just_pressed("ui_escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Input.is_action_just_pressed("ui_accept"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		_mouse_move(event as InputEventMouseMotion)
		
func _mouse_move(event :InputEventMouseMotion):
	var rot := get_rotation()
	var up_down := -event.relative.y / mouseSensitivity
	var new_rotation := rot + Vector3(up_down, 0, 0)
	new_rotation.x = clamp(new_rotation.x, PI / -2, PI / 2)
	set_rotation(new_rotation)

	rot = Player.get_rotation()
	var left_right := -event.relative.x / mouseSensitivity
	new_rotation = rot + Vector3(0, left_right, 0)
	Player.set_rotation(new_rotation)
