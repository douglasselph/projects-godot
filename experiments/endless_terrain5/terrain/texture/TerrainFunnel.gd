class_name TerrainFunnel
extends Node
#
# BASE STRUCTURE
# --------------
# There is grid of terrain blocks with the player in very center.
#
# A base side length, where N and M are both powers of 2 which determines the size 
# of the square. So for example, if N is 2 and M is 3, then the size would be 4x9.
# For simplicity though the N and M are usually the same value. In this example,
# I will just have a single value of N of 1, which represents each side, making
# a 2x2 central grid for a total of 4 blocks.
#
# Surrouding these NxN blocks is a ring of blocks where each side matches the value of N,
# but covering twice the distance. With the last square of each side being shared as corners.
# So for example, if N is 2, making a central square of 4, the surrounding tiles would
# be 12.
#
# As so:
#
#      +-------+-------+-------+-------+
#      |   3   |   3   |   3   |   3   |
#      |       |       |       |       |
#      +-------+---+---+---+---+-------+
#      |   3   | 2 | 2 | 2 | 2 |   3   |
#      |       |   |   |   |   |       |
#      |       +---+-+-+-+-+---+       |
#      |       | 2 |1|1|1|1| 2 |       |
#      |       +   +-+-+-+-+   |       |
#      |       |   |1|0|0|1|   |       |
#      +-------+---+-+-+-+-+---+-------+
#      |   3   | 2 |1|0|0|1| 2 |   3   |
#      |       +   +-+-+-+-+   +       |
# 	   |       |   |1|1|1|1|   |       |
#      |       +---+-+-+-+-+---+       |
#      |       | 2 | 2 | 2 | 2 |       |
#      |       |   |   |   |   |       |
#      +-------+---+-+-+-+-+---+-------+
#      |   3   |   3   |   3   |   3   |
#      |       |       |       |       |
#      +-------+-------+-------+-------+
#
# So with N as 1, there would be a ring of 12 blocks followed by another ring of 12 blocks 
# and continuing this pattern potentially indefinately. Thus the depth of the funnel determines
# the total number of surround rings. Thus a depth of 0 means there is just the central squares.
# A value of 1 means there is 1 ring surrounding this. A value of 2 means 2 rings, and so on.
#
# GENERATION ALGORITHM:
# ---------------------
#
# THe alogorithm works as follows:
#
#   1. CP is the central Vector3 point, which represents where the player is.
#   2. Given CP, we first compute the X,Y coordinate of the upper-left box of the central
#      4 at LOD-0. Call this UL LOD-0. Computing this value is one of the most
#      complicated bits of this algorith because CP can live anywhere within the 
#      the central 4 without causig a seismic shift X,Y's. More on this later.
#   3. Given UL LOD-0 the coordinates of the remaining 3 for LOD-0 can be computed.
#      Note that the perlin parameters for all the blocks are always the same, except
#      the location and size of the blocks
#   4. Each ring then can be computed, for whatever LOD is desired based on the 
#      computrd value of UL LOD-0
#   5. Once the coordinate are all computed, the actual terrain meshes can be built.
#      Note that during movement the net-effect will be that a row or column
#      lost and another gained across the central 16 and rings  The rest of the terrains
#      will remain as they are. Because of this there is always exactly the same number
#      of blocks as the camera moves about. The only change will be the coordinates and 
#      size of each block. The other perlin parameters remain constant.
#



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
