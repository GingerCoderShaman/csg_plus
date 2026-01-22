@tool
extends MeshInstance3D

static var resource:SphereMesh = preload('res://addons/csg_plus/resources/mesh/PointMesh.tres')
static var material:Material = preload('res://addons/csg_plus/resources/material/PointsMesh/Hover.tres')

func _init():
	var new_resource = resource.duplicate()
	new_resource.material = material
	mesh = new_resource
	set_meta("_edit_lock_", true)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func update_visuals(camera:Camera3D):
	scale = (Vector3.ONE * Plane.PLANE_XY.distance_to(camera.to_local(global_position)) / 2.0)
