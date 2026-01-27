@tool
extends Node

var nodes_per_polygon:Dictionary = {}

var targeted_points:Array = []
var editor_camera:Camera3D

func _ready() -> void:
	editor_camera = CSGPlusGlobals.controller.scene_viewport.get_camera_3d()

func _process(_delta: float) -> void:
	pass

func make_target(selected):
	nodes_per_polygon = {}
	targeted_points = []
	var children = get_children()
	for child in children:
		child.free()
	build_polygons(selected)

func build_polygons(nodes):
	for node in nodes:
		if node is CSGPlusMesh:
			var point_node = CSGPlusGlobals.ReflectedNode.new(node)
			nodes_per_polygon[node] = point_node
			add_child(point_node)
		if CSGPlusGlobals.controller.edit_children:
			build_polygons(node.get_children())

func refresh_nodes():
	targeted_points = []
	for node in get_children():
		node.sync()

func seek_point(origin:Vector3, normal:Vector3):
	var new_point = DataResult.invalid_result()
	for reflected_node in get_children():
		var target_point = reflected_node.seek_point(origin, normal)
		if target_point.valid && (!new_point.valid || new_point.reflected_node.is_parent_of(reflected_node) || (new_point.distance < target_point.distance && !reflected_node.is_parent_of(new_point.reflected_node))):
			new_point = target_point
			new_point.reflected_node = reflected_node
	return new_point

func seek_line(origin: Vector3, normal:Vector3):
	var target_line = DataResult.invalid_result()
	for reflected_node:Node3D in get_children():
		var line = reflected_node.seek_line(origin, normal)
		if line.valid && (!target_line.valid || target_line.reflected_node.is_parent_of(reflected_node) || (line.distance < target_line.distance && !reflected_node.is_parent_of(target_line.reflected_node))):
			target_line = line
			target_line.reflected_node = (reflected_node)
	return target_line

func seek_line_with_connected_singletons(origin: Vector3, normal:Vector3):
	var target_line = DataResult.invalid_result()
	for reflected_node:Node3D in get_children():
		var line = reflected_node.seek_line_with_connected_singletons(origin, normal)
		if line.valid && (!target_line.valid || target_line.reflected_node.is_parent_of(reflected_node) || (line.distance < target_line.distance && !reflected_node.is_parent_of(target_line.reflected_node))):
			target_line = line
			target_line.reflected_node = (reflected_node)
	return target_line


func seek_face(origin:Vector3, normal:Vector3):
	var target_face = DataResult.invalid_result()

	for reflected_node:Node3D in get_children():
		var face = reflected_node.seek_face(origin, normal)
		if face.valid && (!target_face.valid || target_face.reflected_node.is_parent_of(reflected_node) ||(face.distance < target_face.distance) && !reflected_node.is_parent_of(target_face.reflected_node)):
			target_face = face
			target_face.reflected_node = (reflected_node)
	return target_face
