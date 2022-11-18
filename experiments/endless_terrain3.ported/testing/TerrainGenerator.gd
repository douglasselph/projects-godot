extends Node3D

var threads : Array

var chunks := {}
var chunks_being_generated := {}

var noise : OpenSimplexNoise

@export var material: Material

@onready var player: Player = Globals.player

var player_chunk_grid_position : Vector2

func _ready():
	randomize()
	noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 7.0
	noise.persistence = 0.2
	
	var chunk = Chunk.new(Vector2(0, 0), noise, material)
	chunk.generate()
	
	add_child(chunk)
