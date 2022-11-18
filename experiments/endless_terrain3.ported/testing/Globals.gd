extends Node

var player: Player

const QUAD_SIZE := 2
const CHUNK_QUAD_COUNT := 50
const CHUNK_SIZE = QUAD_SIZE * CHUNK_QUAD_COUNT

const AMPLITUDE := 3

func _ready():
	player = get_tree().get_root().find_child("Player", true, false)
