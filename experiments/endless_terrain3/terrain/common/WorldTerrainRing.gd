extends Spatial
#
# STORAGE STRUCTURE
# -----------------
# This class is intended to whole the entire world mesh structure that holds the terrain the player can see.
# As the player moves, eventually they move out of their central box, in which case the entire mesh is reset
# effectively moving the world to the player, rather than the player moving through the world.
#
# Doing it this way means there is never any need to allocate new meshes, or deallocate any meshes. Once the entire mesh
# structure has been created, it will be reused to display whatever the user can see by constantly updating the points
# within the mesh. 
#
# There is fixed number of terrain blocks with the center point of the camera always in one of the middle blocks.
# That is, there is a central 4 blocks, 2x2, with the finest detail and with the center point within on of the these 4.
# Call this level of detail zero or LOD-0.
#
# Surrounding the 4 blocks of LOD-0 is a ring of 12 LOD-1 blocks of the same width and height size of the LOD-0 blocks. 
# These blocks can have a different level of detail (less vertices), than LOD-0, though each block has the same width and height as LOD-0.
#
# Surrounding LOD-1 is a ring of another 12 blocks at LOD-2, yet each width and height is exactly twice the size of the LOD-1 blocks.
# Again, rurrounding the LOD-2 block ring is another ring of 12 LOD-3 blocks, each block being twice the size of the LOD-2 blocks.
#
# This pattern can continue indefinately. To see how that is true, a graph pattern representation can be made,
# or perhaps an electronic equivalent. But here is how levels LOD-0, LOD-1, LOD-2, and LOD-3 would map out:
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
# INPUT PARAMETERS
# ---------------
# Height Generator: 
#   A function, that given an (X,Z) vertex will return the height (Y). The supplied
#   height generator can generate the height in any fashion it wishes, whether it be from Perlin noise,
#   Diamond/Square, or a Stitch.
# Level Of Detail (LOD) Query:
#   A function, that given a level of detail, will return the number of subDivisions the associated
#   mesh should have.
# Central Point:
#   A variable that indicates what the central point is. This is effectively where the player or camera
#   is within the system. Based on the central point (CP), the entire query of meshes can commence.
#
# DATA 
# ----
# Unit Size - holds the core unit size of both width and height of the LOD-0 boxes. It also is used
#             to determine the size of the LOD other boxes greater than 0. Specifically if > 0, then
#		      		pow(2, LOD-1) * unitSize.
# Central 4 - An array that holds the central four LOD-0 boxes, which all have the same width/height
#             as well as having the same subDivide (or number of vertices).
#
#
# MOVEMENT ALGORITHM
# ------------------
# As the central point moves, nothing will happen until the CP moves outside one of the central 4.
# When this occurs, a seismic shift occurs. The changes are intentionally done in order of importance
# with the first being closest to what the player will be able to see. The last changes would be all 
# those vertexes that would be behind the player and thus will be done last. This will allow the whole
# process to be handled by a series of threads for a smoother felt transition.
#
# In order to accomplish this pattern additional vertex boxes, other than the mesh boxes actually seen,
# will be needed. The are referred to as transitionary boxes.
#
# 
#
#
# The algorithm is ordered as follows:
#
#  1. Two of the central 4 remain as they are. The first is the LOD-0 box the player just moved out of.
#     The other kept LOD-0 box is one the adjacent relative to the direction moved. These two LOD-0 boxes 
#     are left untouched.
#  3. The other 2 LOD-0 boxes that are being left behind will be repurposed to hold the incoming LOD-1 meshes. 
#     But before that happens, their vertex values will be saved into transitionary boxes 
#     so that later they can be referenced to help build the LOD-1 boxes behind the player.
#     Since that is happening outside the field of view of the camera, it will be done later.
#     For now these two LOD-0 will take on the meshes of two immediately incoming LOD-1 boxes that the 
#     player is moving into.
# 
#     If the subDivide is the same, the incoming LOD-1 meshes can be used as is. If the subDivide 
#     is increasing, then queries to the Height Generator is done to get the heights of the new vertices.
#  4. Now we have the new central 4 LOD-0 boxes and can move in order of the field of view into the rings.
#     The The first seen is he four LOD-1 boxes behind the player to hold half the vertices of the approaching
#     2 LOD-2 boxes. The LOD-2 boxes are twice the size of the LOD-1 boxes, as well as having fewer
#     vertices of their decreasing LOD (Note: LOD-1 -> LOD-2 means a lower level of detail).
#     Before overwriting the values of the 4 LOD-1 meshes, the existing meshes are saved morph into the 4 LOD-1 that are behind the player, which are being repurposed.
#     of by the previous step. Of the remaining 10, 6 can be left as they as the LOD is the same.
#     For the remaining 4 
#  3. Now the outer rings shift, starting with the LOD-1 ring. 4 LOD-1 blocks will move into the LOD-2
#     ring, and another 4 will 
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
