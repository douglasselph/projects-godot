extends KinematicBody

# Emitted when the player jumped on the mob.
signal squashed
# Minimum speed of the mob in meters per second.
export var min_speed = 10
# Maximum speed of the mob in meters per second.
export var max_speed = 18

var velocity = Vector3.ZERO

func _physics_process(_delta):
	move_and_slide(velocity)

# We will call this function from the Main scene.
func initialize(start_position, player_position):
	# We position the mob and turn it so that it looks at the player.
	look_at_from_position(start_position, player_position, Vector3.UP)
	# And rotate it randomly so it doesn't move exactly toward the player.
	rotate_y(rand_range(-PI / 4, PI / 4))
	# We calculate a random speed.
	var random_speed = rand_range(min_speed, max_speed)
	# We calculate a forward velocity that represents the speed.
	velocity = Vector3.FORWARD * random_speed
	# We then rotate the vector based on the mob's Y rotation to move in the direction it's looking.
	velocity = velocity.rotated(Vector3.UP, rotation.y)
	$AnimationPlayer.playback_speed = random_speed / min_speed


func _on_VisibilityNotifier_screen_exited():
	queue_free()

func squash():
	emit_signal("squashed")
	queue_free()
