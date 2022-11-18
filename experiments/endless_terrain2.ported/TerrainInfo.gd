extends Node

@export var MaxLOD: int = 2
@export var Octaves: int = 4
@export var Period: int = 138 - MaxLOD * 15
@export var Persistence: float = 0.5
@export var Amplitude: float = 1.0
@export var Exponentiation: float = 1.0
@export var Lucanarity: float = 2.0

signal terrain_values_changed

func emit_values_changed():
	emit_signal("terrain_values_changed")
