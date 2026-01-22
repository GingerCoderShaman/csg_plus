@tool
extends Node3D

enum AXIS {INVALID, X, Y, Z, XY, XZ, YZ}

const NORMAL_SELECTED_TEXTURE = preload("res://addons/csg_plus/resources/texture/movegizmocolors.png")
const RED_SELECTED_TEXTURE = preload("res://addons/csg_plus/resources/texture/movegizmocolorsRedSelected.png")
const BLUE_SELECTED_TEXTURE = preload("res://addons/csg_plus/resources/texture/movegizmocolorsBlueSelected.png")
const GREEN_SELECTED_TEXTURE = preload("res://addons/csg_plus/resources/texture/movegizmocolorsGreenSelected.png")

var camera:Camera3D
var node_display
var rotation_offset = Quaternion.IDENTITY
var reflected_points = []

@onready var plane_gizmo = %"Planes"
@onready var gizmo_mesh = %"MainGIzmo"

func _ready():
	camera = CSGPlusGlobals.controller.editor_camera
	update_rotation_and_scale()


func _process(_delta: float) -> void:
	update_rotation_and_scale()

func update_rotation_and_scale():
	var scale_test = Vector3.ONE * -Plane.PLANE_XY.distance_to(camera.to_local(position)) / 25
	if scale_test.x < .01:
		scale = Vector3.ONE * .01
	else:
		scale = scale_test

	var center_area = Vector3.ZERO
	if node_display == null:
		return
	for target_point in reflected_points:
		if !is_instance_valid(target_point):
			reflected_points.erase(target_point)
			break
		center_area += target_point.global_position;
	if(reflected_points.size()):
		position = center_area / reflected_points.size()
	else:
		get_parent().remove_child(self);
		position = Vector3.ZERO
	rotation = rotation_offset.get_euler()

func calculate_mouse_hover(origin:Vector3, normal:Vector3):
	if !is_inside_tree():
		return false
	var type = get_intersection_segment(origin, normal)[0]
	match(type):
		AXIS.X:
			gizmo_mesh.get_surface_override_material(0).albedo_texture = BLUE_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(0).albedo_texture = NORMAL_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(1).albedo_texture = NORMAL_SELECTED_TEXTURE
		AXIS.Y:
			gizmo_mesh.get_surface_override_material(0).albedo_texture = GREEN_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(0).albedo_texture = NORMAL_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(1).albedo_texture = NORMAL_SELECTED_TEXTURE
		AXIS.Z:
			gizmo_mesh.get_surface_override_material(0).albedo_texture = RED_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(0).albedo_texture = NORMAL_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(1).albedo_texture = NORMAL_SELECTED_TEXTURE
		AXIS.XY:
			gizmo_mesh.get_surface_override_material(0).albedo_texture = NORMAL_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(0).albedo_texture = RED_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(1).albedo_texture = RED_SELECTED_TEXTURE
		AXIS.XZ:
			gizmo_mesh.get_surface_override_material(0).albedo_texture = NORMAL_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(0).albedo_texture = GREEN_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(1).albedo_texture = GREEN_SELECTED_TEXTURE
		AXIS.YZ:
			gizmo_mesh.get_surface_override_material(0).albedo_texture = NORMAL_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(0).albedo_texture = BLUE_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(1).albedo_texture = BLUE_SELECTED_TEXTURE
		AXIS.INVALID:
			gizmo_mesh.get_surface_override_material(0).albedo_texture = NORMAL_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(0).albedo_texture = NORMAL_SELECTED_TEXTURE
			plane_gizmo.get_surface_override_material(1).albedo_texture = NORMAL_SELECTED_TEXTURE
	return type != AXIS.INVALID

func get_offset_among_axis(axis:AXIS, origin:Vector3, normal:Vector3):
	origin = (origin-global_position)*rotation_offset
	normal = normal*rotation_offset
	match(axis):
		AXIS.X:
			if Plane.PLANE_XZ.distance_to(origin) > Plane.PLANE_XY.distance_to(origin):
				var plane_intersect = Plane.PLANE_XZ.intersects_ray(origin, normal)
				if plane_intersect == null:
					plane_intersect = Plane.PLANE_XY.intersects_ray(origin, normal)
				if plane_intersect != null:
					return Vector3(plane_intersect.x + position.x, 0, 0)
			else:
				var plane_intersect = Plane.PLANE_XY.intersects_ray(origin, normal)
				if plane_intersect == null:
					plane_intersect = Plane.PLANE_XZ.intersects_ray(origin, normal)
				if plane_intersect != null:
					return Vector3(plane_intersect.x + position.x, 0, 0)
		AXIS.Y:
			if Plane.PLANE_XY.distance_to(origin) > Plane.PLANE_YZ.distance_to(origin):
				var plane_intersect = Plane.PLANE_XY.intersects_ray(origin, normal)
				if plane_intersect == null:
					plane_intersect = Plane.PLANE_YZ.intersects_ray(origin, normal)
				if plane_intersect != null:
					return Vector3(0, plane_intersect.y + position.y, 0)
			else:
				var plane_intersect = Plane.PLANE_YZ.intersects_ray(origin, normal)
				if plane_intersect == null:
					plane_intersect = Plane.PLANE_XY.intersects_ray(origin, normal)
				if plane_intersect != null:
					return Vector3(0, plane_intersect.y + position.y, 0)
		AXIS.Z:
			if Plane.PLANE_XZ.distance_to(origin) > Plane.PLANE_YZ.distance_to(origin):
				var plane_intersect = Plane.PLANE_XZ.intersects_ray(origin, normal)
				if plane_intersect == null:
					plane_intersect = Plane.PLANE_YZ.intersects_ray(origin, normal)
				if plane_intersect != null:
					return Vector3(0, 0, plane_intersect.z + position.z)
			else:
				var plane_intersect = Plane.PLANE_YZ.intersects_ray(origin, normal)
				if plane_intersect == null:
					plane_intersect = Plane.PLANE_XZ.intersects_ray(origin, normal)
				if plane_intersect != null:
					return Vector3(0, 0, plane_intersect.z + position.z)
		AXIS.XY:
			var plane_intersect = Plane.PLANE_XY.intersects_ray(origin, normal)
			if plane_intersect != null:
				return plane_intersect + position
		AXIS.XZ:
			var plane_intersect = Plane.PLANE_XZ.intersects_ray(origin, normal)
			if plane_intersect != null:
				return plane_intersect + position
		AXIS.YZ:
			var plane_intersect = Plane.PLANE_YZ.intersects_ray(origin, normal)
			if plane_intersect != null:
				return plane_intersect + position
	return null

func get_intersection_segment(origin:Vector3, normal:Vector3):
	origin = (origin-position)*rotation_offset + position
	normal = normal*rotation_offset

	var expected = [AXIS.INVALID, null]
	var localized_origin = origin-position
	var x_axis = line_intersects_vectors(Vector3(1,0,0) * scale * 8, origin, normal)
	if x_axis != null:
		expected = [AXIS.X, x_axis - position]
	var y_axis = line_intersects_vectors(Vector3(0,1,0) * scale * 8, origin, normal)
	if y_axis != null && (expected[1] == null || localized_origin.distance_to(y_axis - position) < localized_origin.distance_to(expected[1])):
		expected = [AXIS.Y, y_axis - position]
	var z_axis = line_intersects_vectors(Vector3(0,0,1) * scale * 8, origin, normal)
	if z_axis != null && (expected[1] == null || localized_origin.distance_to(z_axis - position) < localized_origin.distance_to(expected[1])):
		expected = [AXIS.Z, z_axis - position]
	var intersecting_point_xy = Plane.PLANE_XY.intersects_ray(localized_origin, normal)
	if intersecting_point_xy != null \
		&& 1 * scale.x < intersecting_point_xy.x && intersecting_point_xy.x < 3 * scale.x \
		&& 1 * scale.y < intersecting_point_xy.y && intersecting_point_xy.y < 3 * scale.y \
		&& (expected[1] == null || localized_origin.distance_to(intersecting_point_xy) < localized_origin.distance_to(expected[1])):
		expected = [AXIS.XY, intersecting_point_xy]
	var intersecting_point_xz = Plane.PLANE_XZ.intersects_ray(localized_origin, normal)
	if intersecting_point_xz != null \
		&& 1 * scale.x < intersecting_point_xz.x && intersecting_point_xz.x < 3 * scale.x \
		&& 1 * scale.z < intersecting_point_xz.z && intersecting_point_xz.z < 3 * scale.z \
		&& (expected[1] == null || localized_origin.distance_to(intersecting_point_xz) < localized_origin.distance_to(expected[1])):
		expected = [AXIS.XZ, intersecting_point_xz]
	var intersecting_point_yz = Plane.PLANE_YZ.intersects_ray(localized_origin, normal)
	if intersecting_point_yz != null \
		&& 1 * scale.y < intersecting_point_yz.y && intersecting_point_yz.y < 3 * scale.y \
		&& 1 * scale.z < intersecting_point_yz.z && intersecting_point_yz.z < 3 * scale.z \
		&& (expected[1] == null || localized_origin.distance_to(intersecting_point_yz) < localized_origin.distance_to(expected[1])):
		expected = [AXIS.YZ, intersecting_point_yz]
	return expected

func line_intersects_vectors(dicersion:Vector3, line_point:Vector3, line_vec:Vector3):
	var result = SpaceUtils.vectors_intersects_vectors(
		position,
		dicersion,
		line_point,
		line_vec,
		scale.x / 5
	)
	if(result != null):
		var line_sqrt_magnitude = dicersion.length_squared()
		if (result - position).length_squared() <= line_sqrt_magnitude\
			&& (result - (dicersion+position)).length_squared() <= line_sqrt_magnitude:
			return result
	return null
