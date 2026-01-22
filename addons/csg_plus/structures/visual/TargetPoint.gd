@tool
extends MeshInstance3D

static var resource:SphereMesh = preload('res://addons/csg_plus/resources/mesh/PointMesh.tres')

var point_position: int
var target_node

func _init(target_node, point_position:int) -> void:
	mesh = resource.duplicate()
	self.target_node = target_node;
	self.point_position = point_position
	self.position = target_node.mesh.points[point_position]
	#todo, demand a better method
	set_meta("_edit_lock_", true)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(_delta: float) -> void:
	scale = (Vector3.ONE * Plane.PLANE_XY.distance_to(CSGPlusGlobals.controller.editor_camera.to_local(global_position)) / 2.0) * get_parent().get_parent().scale.inverse()
	if target_node.mesh.points.size() <= point_position || target_node.mesh.points[point_position] == null:
		queue_free()
		return
	self.position = target_node.mesh.points[point_position]

func ray_intersect(origin:Vector3, normal:Vector3):
	return Geometry3D.segment_intersects_sphere(\
		origin,\
		origin + normal*100,\
		global_position,\
		((global_position.distance_to(origin))) / (2 / resource.radius)
	)
