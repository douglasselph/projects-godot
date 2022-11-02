extends Spatial

onready var build = preload("res://GUIDisplay.gd")
onready var guiDisplay = build.new(self, $Viewport, $Quad, $Quad/Area)

func _unhandled_input(event):
	guiDisplay.unhandled_input(event)
