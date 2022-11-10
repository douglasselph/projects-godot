extends Spatial
#
# STORAGE STRUCTURE
# -----------------
# This class is intended to whole the entire world mesh structure
# There is fixed number of terrain blocks with the center point of the camera always in one of the middle blocks.
# That is, there is a central 4 blocks, 2x2, with the finest detail and with the center point within on of the these 4.
# Call this level of detail zero or LOD-0.
#
# Surrouding these 4 blocks is a ring of 12 blocks, of the same width/height. Call this LOD-1.
# The actual world size of one of these blocks can vary. For starters the actual size will be 2.
#
# Surrounding LOD-1 16 blocks is a ring of 12 LOD-2 blocks, where each block is twice the size of the LOD-1 blocks.
#
# Surrounding the LOD-2 is another ring of 12 LOD-3 blocks, each block being twice the size of the LOD-2 blocks.
#
# This pattern can continue indefinately. To see how that is true, a graph pattern representation can be made,
# or perhaps an electronic equivalent. But here is how levels LOD-0, LOD-1, LOD-2, and LOD-3 would map out:
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
# ALGORITHM
# ---------
#
# THe alogorithm works as follows:
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
#      lost and another gained across the central 16 and rings.The rest of the terrains
#      will remain as they are. Because of this there is always exactly the same number
#      of blocks as the camera moves about. The only change will be the coordinates and 
#      size of each block. The other perlin parameters remain constant.
#
