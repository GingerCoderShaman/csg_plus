@tool
class_name CSGPlusMesh
extends CSGMesh3D

func _ready():
	if mesh == null:
		mesh = CSGPlusGlobals.DynamicMesh.from_cube(Vector3(1, 1, 1))
	else:
		mesh = mesh.verify_parent(self)
