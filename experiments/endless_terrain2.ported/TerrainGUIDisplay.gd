extends Node3D

@onready var build = preload("res://GUIDisplay.gd")
@onready var guiDisplay = build.new(self, $SubViewport, $Quad, $Quad/Area3D)

func _unhandled_input(event):
	guiDisplay.unhandled_input(event)
