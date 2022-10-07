extends Sprite

var speed_pixels_per_second = 400
var angular_speed_radians_per_second = PI


func _process(delta):
	rotation += angular_speed_radians_per_second * delta
	var velocity = Vector2.UP.rotated(rotation) * speed_pixels_per_second
	position += velocity * delta
