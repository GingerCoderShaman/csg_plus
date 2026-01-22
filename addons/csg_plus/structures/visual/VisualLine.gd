@tool
extends MeshInstance3D

static var resource:CylinderMesh = preload('res://addons/csg_plus/resources/mesh/LineMesh.tres')
static var material:Material = preload('res://addons/csg_plus/resources/material/LineMesh/Hover.tres')

func _init():
	var new_resource = resource.duplicate()
	new_resource.material = material
	mesh = new_resource
	set_meta("_edit_lock_", true)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func update_position(point1:Vector3, point2:Vector3):
	var diff = point1.direction_to(point2)
	position = (point1+point2)/2

	var lookat_basis
	if(diff.is_equal_approx(Vector3.DOWN) || diff.is_equal_approx(Vector3.UP)):
		lookat_basis = Basis.looking_at(diff, Vector3.FORWARD)
	else:
		lookat_basis = Basis.looking_at(diff)
	basis = lookat_basis
	rotate_object_local(Vector3(1,0, 0), PI/2)
	scale = (Vector3.ONE * Plane.PLANE_XY.distance_to(CSGPlusGlobals.controller.editor_camera.to_local(global_position)) / 128.0)
	scale.y = point1.distance_to(point2)/2
