extends RefCounted

# simple code snippet for mirroring a vector along a given plane
# put it into a class of its own, make it global, etc.
func mirror_along_normal(vector, normal):
	return -vector + 2 * -normal * vector.dot(normal)

