@tool
class_name MeshCommit
extends RefCounted

var mesh
var points
var surfaces = null
var final_mesh
var line_cache

func _init(_mesh, _points:PackedVector3Array, _surfaces = null, _final_mesh = null, _line_cache = null) -> void:
	mesh = _mesh
	points = _points.duplicate()
	if _surfaces:
		surfaces = CSGPlusGlobals.FaceInfo.array_duplicate(_surfaces)
	final_mesh = _final_mesh
	line_cache = _line_cache

func commit():
	mesh.commit(points, surfaces, final_mesh, line_cache)
	CSGPlusGlobals.controller.refresh_tool()

static func target_list_to_reference_list_basic(points):
	var nodes_to_points = []
	for target in points:
		if !nodes_to_points.has(target.target_node.mesh):
			nodes_to_points.append(target.target_node.mesh)

	var node_mesh:Array[MeshCommit] = []
	for node in nodes_to_points:
		node_mesh.append(MeshCommit.new(node, node.points))
	return node_mesh

static func target_list_to_reference_list(points):
	var nodes_to_points = []
	for target in points:
		if !nodes_to_points.has(target.target_node.mesh):
			nodes_to_points.append(target.target_node.mesh)

	var node_mesh:Array[MeshCommit] = []
	for node in nodes_to_points:
		node_mesh.append(MeshCommit.new(node, node.points, node.surfaces, null, node.line_cache))
	return node_mesh
