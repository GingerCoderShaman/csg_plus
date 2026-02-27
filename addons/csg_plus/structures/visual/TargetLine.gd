@tool
extends MeshInstance3D

static var resource:CylinderMesh = preload('res://addons/csg_plus/resources/mesh/LineMesh.tres')
static var locked:Material = preload('res://addons/csg_plus/resources/material/Generic/Locked.tres')

var target_node
var line

func _init(target_node, line) -> void:
	self.target_node = target_node;
	self.line = line
	#todo, demand a better method
	set_meta("_edit_lock_", true)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	refresh_mesh()

func refresh_mesh():
	mesh = resource.duplicate()
	if target_node.mesh.is_point_in_disabled_face(line.vertex1) && target_node.mesh.is_point_in_disabled_face(line.vertex2):
		mesh.material = locked

func _process(_delta: float) -> void:
	if target_node.mesh.points.size() <= line.vertex1 || target_node.mesh.points[line.vertex1] == null \
			|| target_node.mesh.points.size() <= line.vertex2 || target_node.mesh.points[line.vertex2] == null:
		queue_free()
		return
	var vertex1:Vector3 = target_node.mesh.points[line.vertex1]
	var vertex2:Vector3 = target_node.mesh.points[line.vertex2]
	var diff = vertex1.direction_to(vertex2)
	self.position = (vertex1+vertex2)/2

	var lookat_basis
	if(diff.is_equal_approx(Vector3.DOWN) || diff.is_equal_approx(Vector3.UP)):
		lookat_basis = Basis.looking_at(diff, Vector3.FORWARD)
	else:
		lookat_basis = Basis.looking_at(diff)
	basis = lookat_basis
	rotate_object_local(Vector3(1,0, 0), PI/2)
	
	scale = (Vector3.ONE * Plane.PLANE_XY.distance_to(CSGPlusGlobals.controller.editor_camera.to_local(global_position)) / 128.0) * get_parent().get_parent().global_basis.inverse()
	self.scale.y = vertex1.distance_to(vertex2)/2
