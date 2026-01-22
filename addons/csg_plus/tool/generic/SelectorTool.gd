@tool
class_name SelectTool
extends Tool

static var overlay_select_area = preload("res://addons/csg_plus/scene/gizmo/OverlaySelectArea.tscn").instantiate()
static var target_gizmo = preload('res://addons/csg_plus/scene/gizmo/MoveGizmo.tscn').instantiate()

var axis = null

var render_3d_overarea
var node_display
var overlay_area_2d

var reflected_target_points = []

var past_nodes:Array[MeshCommit] = []

func bind_tool():
	super.bind_tool()
	node_display = main.node_display_handler
	overlay_area_2d = main.overlay_2d
	render_3d_overarea = main.render_3d_overarea
	target_gizmo.node_display = node_display

func unbind_tool():
	super.unbind_tool()
	for target_point in reflected_target_points:
		if is_instance_valid(target_point):
			target_point.material_override = null
	reflected_target_points = []
	if target_gizmo.is_inside_tree():
		render_3d_overarea.remove_child(target_gizmo)

func refresh_tool():
	position_gizmo()
	angle_gizmo()

func angle_gizmo():
	target_gizmo.reflected_points = reflected_target_points
	if reflected_target_points.size() > 0 && !main.setting_global_positioner:
		var decompiled = []
		for node in reflected_target_points:
			decompiled.append(node.target_node)
		var common_parent = SpaceUtils.find_lowest_common_nodes(node_display.get_tree().root, decompiled)
		if common_parent is Node3D && common_parent.is_inside_tree():
			target_gizmo.rotation_offset = common_parent.global_basis.get_rotation_quaternion()
			return
	target_gizmo.rotation_offset = Quaternion.IDENTITY

func position_gizmo():
	if reflected_target_points.size() == 0:
		if target_gizmo.is_inside_tree():
			render_3d_overarea.remove_child(target_gizmo)
	elif !target_gizmo.is_inside_tree():
		render_3d_overarea.add_child(target_gizmo)

func calculate_gizmo_logic_on_click(origin:Vector3, normal:Vector3) :
	if target_gizmo.is_inside_tree():
		var axis_test = target_gizmo.get_intersection_segment(origin, normal)
		if axis_test[0] != CSGPlusGlobals.MoveGizmo.AXIS.INVALID:
			axis = axis_test
		else:
			axis = null
	return axis == null

func calculate_gizmo_logic_on_drag(origin:Vector3, normal:Vector3):
	if axis: #Mouse control version TODO, controller version
		var current_position = target_gizmo.position;
		var new_offset = current_position
		var offset = target_gizmo.get_offset_among_axis(axis[0], origin, normal)
		if offset == null:
			return
		match axis[0]:
			CSGPlusGlobals.MoveGizmo.AXIS.X:
				new_offset.x = offset.x - axis[1].x
			CSGPlusGlobals.MoveGizmo.AXIS.Y:
				new_offset.y = offset.y - axis[1].y
			CSGPlusGlobals.MoveGizmo.AXIS.Z:
				new_offset.z = offset.z - axis[1].z
			CSGPlusGlobals.MoveGizmo.AXIS.XY, CSGPlusGlobals.MoveGizmo.AXIS.XZ, CSGPlusGlobals.MoveGizmo.AXIS.YZ:
				new_offset = offset - axis[1]
		new_offset = main.snap_calculaton_3d(new_offset - current_position)
		var nodes_to_points = {}
		for target in reflected_target_points:
			if !nodes_to_points.has(target.target_node):
				nodes_to_points[target.target_node] = [target.point_position]
			else:
				nodes_to_points[target.target_node].append(target.point_position)

		var commits = []
		for target in nodes_to_points.keys():
			var deep_mesh = target.mesh
			var transform:Transform3D = target.global_transform
			var basis:Basis = transform.affine_inverse().basis

			var result = deep_mesh.prepare_point_shift_position(nodes_to_points[target],
				basis * (target_gizmo.rotation_offset * new_offset)
			)
			if !result:
				return true
			commits.append(result)
		for commit in commits:
			commit.commit()
		return true
	return false

static func commit_from_history(commits:Array[MeshCommit]):
	for commit in commits:
		commit.commit()

func calculate_gizmo_logic_on_release(origin:Vector3, normal:Vector3):
	if axis:
		axis = null
		target_gizmo.calculate_mouse_hover(origin, normal)
		if past_nodes.size() > 0:
			var past_node_reference = past_nodes
			var new_nodes = MeshCommit.target_list_to_reference_list(reflected_target_points)
			main.setup_undo_redo(
				"Move Points",
				func():
				for commit in new_nodes:
					commit.commit(),
				func():
				for commit in past_node_reference:
					commit.commit()
			)
			past_nodes = []
			return true
	return false
