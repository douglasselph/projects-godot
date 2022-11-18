extends Node3D

@onready var block = $TerrainBlock
@onready var cameraFoci = $CameraFoci

func _ready():
	cameraFoci.connect("camera_moved",Callable(self,"_camera_moved"))

func _camera_moved(position: Vector3):
	#print("Camera3D now at ", position)
	pass
