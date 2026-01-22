@tool
class_name PointDeleteTool
extends Tool

var node_display_handler
var hover_target
var hover_line

var target_point = null
var targeted_lines = []

func bind_tool():
	node_display_handler = CSGPlusGlobals.controller.node_display_handler
	super.bind_tool()
	target_point = null

func unbind_tool():
	super.unbind_tool()
	if target_point:
		target_point.material_override = null
		target_point = null
	undo_delete_selection()

func refresh_tool():
	if is_instance_valid(target_point):
		target_point.material_override = null
		target_point = null

func undo_delete_selection():
	if is_instance_valid(target_point):
		target_point.material_override = null
		target_point = null

	for target_line in targeted_lines:
		if is_instance_valid(target_line):
			target_line.material_override = null
	targeted_lines = []

	if is_instance_valid(hover_line):
		hover_line.material_override = null
		hover_line = null
	if is_instance_valid(hover_target):
		hover_target.material_override = null
		hover_target = null

func handle_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	if event.is_action(CSGPlusGlobals.NODE_UNSELECT):
		undo_delete_selection()
		return true
	if event is InputEventMouseMotion:
		handle_motion_event(viewport_camera, event)
	if event.is_action(CSGPlusGlobals.NODE_SELECTED):
		if event.pressed == true:
			pass
			#handle_node_selection_press(viewport_camera, event)
		if event.pressed == false:
			handle_selection_release(viewport_camera, event)
		return true
	return false

func handle_selection_release(viewport_camera: Camera3D, event: InputEvent):
	if target_point == null:
		handle_node_selection_release(viewport_camera, event)
		return;
	handle_line_selection_release(viewport_camera, event)

func handle_node_selection_release(viewport_camera: Camera3D, event: InputEvent):
	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)
	var new_target = node_display_handler.seek_point(origin, normal)

	if !new_target.valid:
		return
	target_point = new_target.reflected_point
	for line in new_target.reflected_node.lines.get_children():
		if (line.line.vertex1 == target_point.point_position || line.line.vertex2 == target_point.point_position):
			targeted_lines.append(line)
			line.material_override = CSGPlusGlobals.HOVER_LINE_MATERIAL

func handle_line_selection_release(_viewport_camera: Camera3D, _event: InputEvent):
	if hover_line:
		var result = hover_line.target_node.mesh.remove_point_at_across_line(
			target_point.point_position,
			hover_line.line
		)
		if !result:
			return
		main.setup_undo_redo(
			"Delete Point",
			func():
			result[0].commit()
			CSGPlusGlobals.controller.node_display_handler.refresh_nodes(),
			func():
			result[1].commit()
			CSGPlusGlobals.controller.node_display_handler.refresh_nodes()
		)

func handle_motion_event(viewport_camera: Camera3D, event: InputEvent):
	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)

	if target_point != null:
		handle_line_hover(origin, normal)
		return;
	handle_node_hover(origin, normal)

func handle_node_hover(origin:Vector3, normal:Vector3):
	var new_target
	var new_target_point = node_display_handler.seek_point(origin, normal)
	if !new_target_point.valid:
		new_target = null
	else:
		new_target = new_target_point.reflected_point

	if new_target != hover_target:
		if hover_target != null:
			hover_target.material_override = null
		hover_target = new_target
		if hover_target:
			hover_target.material_override = CSGPlusGlobals.TARGET_POINT_MATERIAL

func handle_line_hover(origin:Vector3, normal:Vector3):
	var target_line = node_display_handler.seek_line(origin, normal)

	if target_line.valid && !(target_line.reflected_line.line.vertex1 == target_point.point_position || target_line.reflected_line.line.vertex2 == target_point.point_position):
		target_line = null

	if target_line == null:
		if hover_line != null:
			hover_line.material_override = CSGPlusGlobals.HOVER_LINE_MATERIAL
			hover_line = null
		return
	var line = target_line.reflected_line
	if hover_line != line:
		if hover_line != null:
			hover_line.material_override = CSGPlusGlobals.HOVER_LINE_MATERIAL
		hover_line = line
		if hover_line:
			hover_line.material_override = CSGPlusGlobals.TARGET_POINT_MATERIAL
