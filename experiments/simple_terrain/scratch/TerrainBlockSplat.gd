extends MeshInstance

func _ready():
	mesh.material.set_shader_param("height_scale", 0.5)
	
#	var texture = ImageTexture.new()
#	var image = Image.new()
#	image.load("res://icon.png")
#	texture.create_from_image(image)
	
#	var texture = mesh.material.get_shader_param("heightmap")
#	var width = texture.get_width()
#	var height = texture.get_height()
#	var image = texture.get_data()
#
#	var array = PoolByteArray()
#	array.resize(width*height)
#	print("SIZE=", array.size())
#	var count = max(100, array.size())
#	image.load_png_from_buffer(array)
#	for i in range(0, count):
#		print("VALUEA[", i, "]=", array[i])
#	var image2 = image.create_from_data(width, height, false, Image.Format.FORMAT_RGBA8, array)
#	image2.lock()
#	for i in range(0, count):
#		print("VALUEB[", i, "]=", image2.get_pixel(i, 0))
#	image2.unlock()
#	image2.lock()
#	for y in range(0, width):
#		for x in range(0, height):
#			var pixel = image2.get_pixel(x, y)
#			var red = pixel.r
#			var blue = pixel.b
#			var green = pixel.g
#			if (red != 0 || blue != 0 || green != 0):
#				print("RED=", red, ", BLUE=", blue, ", GREEN=", green)
#	image2.unlock()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
