extends Spatial

func _ready():
	var terrain1 = preload("res://TerrainPerlin.tscn").instance()
	#var terrain1 = TerrainPerlinMesh.new()
	#terrain1.init(4)
	terrain1.SubDivide = 512
	#terrain1.TerrainX = 0
	#terrain1.TerrainY = 0
	#terrain1.TerrainHeight = 1
	#terrain1.TerrainWidth = 1
	terrain1.Octaves = 4
	add_child(terrain1)
	
	var terrain2 = preload("res://TerrainPerlin.tscn").instance()
	#var terrain2 = TerrainPerlinMesh.new()
	terrain2.SubDivide = 2
	terrain2.TerrainX = 2
	terrain2.TerrainY = 0
	#terrain2.TerrainHeight = 2
	#terrain2.TerrainWidth = 2
	terrain2.Octaves = 1
	add_child(terrain2)
	
	var noise = OpenSimplexNoise.new()
	noise.octaves = 4
	noise.period = 128
	noise.persistence = 0.5
	noise.lacunarity = 2
	
	var image = noise.get_image(512, 512)
	
	#for y in range(10):
	#	for x in range(10):
	#		print("[", x, ",", y, "]=", noise.get_noise_2d(x, y))
			
	#var data = image.get_data()
	#for x in range(10):
	#	if x < data.size():
	#		print("DATA ", x, "=", data[x])
