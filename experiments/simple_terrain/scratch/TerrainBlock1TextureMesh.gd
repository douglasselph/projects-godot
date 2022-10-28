extends MeshInstance


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var noise = OpenSimplexNoise.new()
	# Configure
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20.0
	noise.persistence = 0.8
	# Sample
	print("Values:")
	for xoff in range(0, 64):
		var x = 1.0 + xoff / 64.0
		print(x, "=", noise.get_noise_2d(x, 1.0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
