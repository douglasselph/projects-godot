class_name DiamondRandomValue
extends Node

const SEED_SCALE = 1000000
var randomHeightVariance: float = 1.0
var _random = RandomNumberGenerator.new()

# We always want to generate the same random value for a particular x,y no matter when or where it is computed.				
func randomValue(ul: Vector2, lr: Vector2) -> float:
	_random.seed = _seedFor(ul, lr)
	return _random.randf() * randomHeightVariance


func _seedFor(ul: Vector2, lr: Vector2) -> int:
	return int(floor((ul.x + ul.y + lr.x + lr.y) * SEED_SCALE))
