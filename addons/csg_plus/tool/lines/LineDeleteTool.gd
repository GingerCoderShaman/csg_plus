@tool
class_name LineDeleteTool
extends Tool

var node_display
var line_display
var render_preview_node

var hover_lines = null

func bind_tool():
	super.bind_tool()
	hover_lines = DataResult.invalid_result()
	node_display = main.node_display_handler
	render_preview_node = main.miscellaneous

func refresh_tool():
	clear_hover_target()

func unbind_tool():
	clear_hover_target()

func clear_hover_target():
	if !hover_lines.valid:
		return
	for hover in hover_lines.connected_reflected_lines:
		if is_instance_valid(hover):
			hover.material_override = null
	hover_lines = DataResult.invalid_result()

func handle_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		handle_motion_event(viewport_camera, event)
	if event.is_action(CSGPlusGlobals.NODE_SELECTED):
		if event.is_released():
			handle_event_pressed(viewport_camera, event)
		return true
	return false


func handle_event_pressed(_viewport_camera: Camera3D, _event: InputEvent):
	if hover_lines && hover_lines.reflected_node && hover_lines.reflected_node.target_mesh:
		var result = hover_lines.reflected_node.target_mesh.mesh.delete_lines_clear_loose_points(hover_lines.connected_cache_lines)
		if (result):
			main.setup_undo_redo(
				"Delete Line(s)",
				func():
				result[0].commit()
				CSGPlusGlobals.controller.node_display_handler.refresh_nodes(),
				func():
				result[1].commit()
				CSGPlusGlobals.controller.node_display_handler.refresh_nodes()
		)
	else:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("Line is not selected")

func handle_motion_event(viewport_camera: Camera3D, event: InputEventMouseMotion):
	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)
	var new_hover_lines = node_display.seek_line_with_connected_singletons(origin, normal)
	if hover_lines.valid:
		for hover in hover_lines.connected_reflected_lines:
			if is_instance_valid(hover):
				hover.material_override = null
	hover_lines = new_hover_lines
	if hover_lines.valid:
		for hover in hover_lines.connected_reflected_lines:
			hover.material_override = CSGPlusGlobals.HOVER_LINE_MATERIAL
