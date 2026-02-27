@tool
extends Node3D

static var locked:Material = preload('res://addons/csg_plus/resources/material/Generic/Locked.tres')

var target_mesh = null;

var lines = Node3D.new()
var line_cache = {}
var points = Node3D.new()

func _init(target_mesh = null) -> void:
	if target_mesh == null:
		return
	self.target_mesh = target_mesh
	global_transform = target_mesh.global_transform

	set_meta("_edit_lock_", true)
	sync()

func refresh_mesh():
	for child in lines.get_children():
		child.refresh_mesh()
	for child in points.get_children():
		child.refresh_mesh()

func sync():
	for child in lines.get_children():
		child.queue_free()
	for child in points.get_children():
		child.queue_free()
	line_cache = {}

	var instance_mesh = target_mesh.mesh
	for line in instance_mesh.line_cache.keys():
		var model_line = CSGPlusGlobals.TargetLine.new(target_mesh, line)
		lines.add_child(model_line)
		line_cache[line] = model_line
	for i in instance_mesh.points.size():
		if instance_mesh.points[i] == null:
			continue
		points.add_child(CSGPlusGlobals.TargetPoint.new(target_mesh, i))

func _ready() -> void:
	add_child(lines)
	add_child(points)

func _process(_delta: float) -> void:
	if !target_mesh.is_inside_tree():
		queue_free()
		return
	global_transform = target_mesh.global_transform

func is_parent_of(other_reflected_node):
	return check_is_node_child(target_mesh, other_reflected_node.target_mesh)

func check_is_node_child(node, check_node):
	for child in node.get_children():
		if child.get_instance_id() == check_node.get_instance_id() || check_is_node_child(child, check_node):
			return true
	return false

func seek_point(origin:Vector3, normal: Vector3):
	if(global_transform.is_finite()):
		var instance_mesh = target_mesh.mesh
		var local_transform = global_transform.affine_inverse()
		var local_origin = local_transform * origin;
		var local_normal = local_transform.basis * normal;
		var target = target_mesh.mesh.find_point(local_origin, local_normal)
		if target.valid:
			target.reflected_point = points.get_child(target.point_index)
			return target;
			#return [target[0], target[1], target[2], points.get_child(target[2])]
	return DataResult.invalid_result()

func seek_line(origin:Vector3, normal: Vector3):
	if(global_transform.is_finite()):
		var local_transform = global_transform.affine_inverse()
		var local_origin = local_transform * origin;
		var local_normal = local_transform.basis * normal;
		var target = target_mesh.mesh.get_point_on_line(local_origin, local_normal,origin.distance_to(global_position) * .01)
		if target.valid && line_cache.has(target.cached_line):
			target.reflected_line = line_cache[target.cached_line]
			target.vertex_indexes = [points.get_child(target.cached_line.vertex1), points.get_child(target.cached_line.vertex2)]
			return target
			#return [target[0], target[1], target[2], line_cache[target[2]], [points.get_child(target[2].vertex1), points.get_child(target[2].vertex2)]]
	return DataResult.invalid_result()

func seek_line_with_connected_singletons(origin: Vector3, normal: Vector3):
	if(global_transform.is_finite()):
		var local_transform = global_transform
		var local_origin = origin * local_transform;
		var local_normal = normal * local_transform.basis;
		var target = target_mesh.mesh.get_point_on_line(local_origin, local_normal,origin.distance_to(global_position) * .01)
		if target.valid && line_cache.has(target.cached_line):
			var lines = target_mesh.mesh.find_connected_singleton_lines(target.cached_line)
			var line_models = []
			for line in lines:
				line_models.append(line_cache[line])
			target.connected_cache_lines = lines;
			target.connected_reflected_lines = line_models;
			target.reflected_line = line_cache[target.cached_line]
			target.vertex_indexes = [points.get_child(target.cached_line.vertex1), points.get_child(target.cached_line.vertex2)]
			return target
			#return [target[0], target[1], lines, line_models, [points.get_child(target.cached_line.vertex1), points.get_child(target.cached_line.vertex2)]]
	return DataResult.invalid_result()

func seek_face(origin:Vector3, normal: Vector3):
	if(global_transform.is_finite()):
		var local_transform = global_transform.affine_inverse()
		var local_origin = local_transform * origin;
		var local_normal = local_transform.basis * normal;
		var target_plane = target_mesh.mesh.get_point_on_plane(local_origin, local_normal)
		if target_plane.valid:
			var reflected_lines = []
			var reflected_points = []
			var prev_point = target_plane.face.vertexes[target_plane.face.vertexes.size()-1]
			for point in target_plane.face.vertexes:
				reflected_points.append(points.get_child(point))
				for reflected_line in lines.get_children():
					if (point == reflected_line.line.vertex1 && prev_point == reflected_line.line.vertex2) || (point == reflected_line.line.vertex2 && prev_point == reflected_line.line.vertex1):
						reflected_lines.append(reflected_line)
						break
				prev_point = point

			target_plane.connected_reflected_lines = reflected_lines
			target_plane.connected_reflected_points = reflected_points
			return target_plane;
	return DataResult.invalid_result()
