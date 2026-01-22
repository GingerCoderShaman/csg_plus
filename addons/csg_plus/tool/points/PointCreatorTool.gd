@tool
class_name PointCreatorTool
extends Tool

var node_display
var line_display
var render_preview_node

var targeted_line = null

var visual_node = CSGPlusGlobals.VisualPoint.new()

func bind_tool():
	super.bind_tool()
	node_display = main.node_display_handler
	render_preview_node = main.miscellaneous
	visual_node.visible = false
	render_preview_node.add_child(visual_node)

func unbind_tool():
	render_preview_node.remove_child(visual_node)

func handle_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		handle_motion_event(viewport_camera, event)
	if event.is_action(CSGPlusGlobals.NODE_SELECTED):
		if event.is_released():
			handle_event_pressed(viewport_camera, event)
		return true
	return false

func handle_motion_event(viewport_camera: Camera3D, event: InputEventMouseMotion):
	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)
	var target_line = node_display.seek_line(origin, normal)

	targeted_line = target_line
	if target_line.valid:
		visual_node.visible = true
		var transform = target_line.reflected_line.target_node.get_global_transform()
		visual_node.position =  transform * target_line.intersection_point
		visual_node.update_visuals(viewport_camera)
	else:
		visual_node.visible = false

func handle_event_pressed(_viewport_camera: Camera3D, _event: InputEvent):
	if !targeted_line.valid:
		CSGPlusGlobals.controller.error_panel.alert("Target Line not found")
		return
	var result = targeted_line.reflected_line.target_node.mesh.insert_point_at_line((targeted_line.intersection_point), targeted_line.cached_line)
	if !result:
		return
	main.setup_undo_redo(
		"Create Point",
		func():
		result[0].commit()
		CSGPlusGlobals.controller.node_display_handler.refresh_nodes(),
		func():
		result[1].commit()
		CSGPlusGlobals.controller.node_display_handler.refresh_nodes(),
)
