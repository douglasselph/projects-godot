extends Node

#
# Maintains the list of coordinates for all the boxes within the WorldRing
# and their positions within the world.
#
class_name Coordinates

var _boxUnitSize: float
var _maxLOD: int
var _boxes = {}

#
#  Maintains just the position of the box within the ring.
#
class Coordinate:
	var position: Vector2
	var lod: int
	
	func _init(lod: int):
		self.lod = lod
		
func _init(boxUnitSize: float, maxLOD: int):
	_boxUnitSize = boxUnitSize
	_maxLOD = maxLOD
	
	# Center 4
	for zi in range(0, 2):
		for xi in range(0, 2): 
			_boxes[_keyOf(0, zi, xi)] = Coordinate.new(0)
			
	# All the rings
	for lod in range(1, maxLOD):
		var boxes = Array()
		for zi in range(0, 4):
			for xi in range(0, 4):
				if zi == 0 or zi == 3 or xi == 0 or xi == 3:
					_boxes[_keyOf(lod, zi, xi)] = Coordinate.new(lod)

func compute(ul_coordinate: Vector2):
	
	_compute_coordinates_central4(ul_coordinate)
	
	for lod in range(1, _maxLOD+1):
		_compute_coordinates_ring_lod(lod, ul_coordinate)
	
# Given the UL coordinate of the central 4, compute all the positions of the 4 central boxes.
func _compute_coordinates_central4(ul_coordinate: Vector2):
	var startx = ul_coordinate.x
	var startz = ul_coordinate.y
	var z = startz
	for zi in range(0, 2):
		var x = startx
		for xi in range(0, 2):
			_boxes[_keyOf(0, zi, xi)].position = Vector2(x, z)
			x += _boxUnitSize
		z += _boxUnitSize

# Given the central UL coordinate, compute the coordinates for the ring at the 
# indicated level of detail (LOD). Returned is an array of 12 Coordinate's.
# Each ring grows in size by a factor of 2 for each increasing LOD.
func _compute_coordinates_ring_lod(lod: int, ul_coordinate: Vector2):
	var startx: float = ul_coordinate.x - _boxUnitSize
	var startz: float = ul_coordinate.y - _boxUnitSize
	var step = _boxUnitSize
	for s in range(1, lod):
		step *= 2
		startx -= step
		startz -= step
	var result = []
	var z: float = startz
	var x: float
	for zi in range(0, 4):
		x = startx
		for xi in range(0, 4):
			if zi == 0 or zi == 3 or xi == 0 or xi == 3:
				_boxes[_keyOf(lod, zi, xi)].position = Vector2(x, z)
			x += step
		z += step

func _keyOf(lod: int, zi: int, xi: int) -> String:
	return "%d,%d,%d" % [lod, zi, xi]
