extends Spatial

onready var block = $TerrainBlock
onready var cameraFoci = $CameraFoci

func _ready():
	cameraFoci.connect("camera_moved", self, "_camera_moved")

func _camera_moved(position: Vector3):
	#print("Camera now at ", position)
	pass
