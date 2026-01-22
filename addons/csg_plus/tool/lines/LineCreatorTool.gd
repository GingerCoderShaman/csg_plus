@tool
class_name LineCreatorTool
extends Tool

var node_display
var line_display
var render_preview_node

var visual_node1 = CSGPlusGlobals.VisualPoint.new()
var visual_node2 = CSGPlusGlobals.VisualPoint.new()

var visual_line = CSGPlusGlobals.VisualLine.new()

var hover_target
var init_target

func bind_tool():
	hover_target = DataResult.invalid_result()
	init_target = DataResult.invalid_result()
	super.bind_tool()
	node_display = main.node_display_handler
	render_preview_node = main.miscellaneous
	visual_node1.visible = false
	render_preview_node.add_child(visual_node1)
	visual_node2.visible = false
	render_preview_node.add_child(visual_node2)
	visual_line.visible = false
	render_preview_node.add_child(visual_line)

func unbind_tool():
	clear_hover_target()
	render_preview_node.remove_child(visual_node1)
	render_preview_node.remove_child(visual_node2)
	render_preview_node.remove_child(visual_line)

func handle_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	if event.is_action(CSGPlusGlobals.NODE_UNSELECT):
		clear_hover_target()
		return true
	if event is InputEventMouseMotion:
		handle_motion_event(viewport_camera, event)
	if event.is_action(CSGPlusGlobals.NODE_SELECTED):
		if event.is_released():
			handle_event_pressed(viewport_camera, event)
		return true
	return false

func handle_event_pressed(_viewport_camera: Camera3D, _event: InputEvent):
	if !init_target.valid:
		accept_input()
	else:
		accept_new_line()
		#handle_hover2(viewport_camera, event)

func handle_motion_event(viewport_camera: Camera3D, event: InputEventMouseMotion):
	if !init_target.valid:
		handle_hover1(viewport_camera, event)
	else:
		handle_hover2(viewport_camera, event)

func clear_hover_target():
	if hover_target.valid && hover_target.data_type == 'point':
		hover_target.visual_object.material_override = null
	hover_target = DataResult.invalid_result()
	if init_target.valid && init_target.data_type == 'point':
		init_target.visual_object.material_override = null
	init_target = DataResult.invalid_result()
	visual_node1.visible = false
	visual_node2.visible = false
	visual_line.visible = false

func refresh_tool():
	clear_hover_target()

func accept_input():
	if hover_target.valid:
		init_target = hover_target
		hover_target = DataResult.invalid_result()
	else:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("Initial target is not setup yet")

func accept_new_line():
	if hover_target.valid:
		var check1
		var check2
		if hover_target.data_type == 'point':
			check1 = [hover_target.point_index, null]
		else:
			check1 = [hover_target.intersection_point, hover_target.cached_line]
		if init_target.data_type == 'point':
			check2 = [init_target.point_index, null]
		else:
			check2 = [init_target.intersection_point, init_target.cached_line]
		var result = hover_target.reflected_object.target_node.mesh.create_line(check1[0], check1[1], check2[0], check2[1])
		if (result):
			main.setup_undo_redo(
				"Create Line",
				func():
				result[0].commit()
				CSGPlusGlobals.controller.node_display_handler.refresh_nodes(),
				func():
				result[1].commit()
				CSGPlusGlobals.controller.node_display_handler.refresh_nodes()
		)
		clear_hover_target()
	else:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("Line is not setup properly")

func handle_hover1(viewport_camera: Camera3D, event: InputEventMouseMotion):
	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)
	var result = find_node_or_line(origin, normal)

	var desire = DataResult.invalid_result()
	if result.valid:
		if result.data_type == 'line':
			var transform = result.reflected_line.target_node.get_global_transform()
			visual_node1.position = (transform * result.intersection_point)
			visual_node1.update_visuals(viewport_camera)
			desire = result
			desire.visual_object = visual_node1
			visual_node1.visible = true
		elif result.data_type == 'point':
			result.reflected_point.material_override = CSGPlusGlobals.HOVER_POINT_MATERIAL
			result.visual_object = result.reflected_point
			desire = result

	if hover_target.valid:
		if hover_target.data_type == 'point':
			if desire.visual_object != hover_target.visual_object:
				hover_target.visual_object.material_override = null
		else:
			if desire.visual_object != hover_target.visual_object:
				visual_node1.visible = false
	hover_target = desire

func handle_hover2(viewport_camera: Camera3D, event: InputEventMouseMotion):
	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)

	var point1
	if init_target.data_type == 'line':# line
		var transform = init_target.reflected_line.target_node.get_global_transform()
		visual_node1.position = (transform*init_target.intersection_point)
		visual_node1.update_visuals(viewport_camera)
		visual_node1.visible = true
		point1 = transform * init_target.intersection_point
	else: #point
		var transform = init_target.reflected_point.target_node.get_global_transform()
		point1 = transform * init_target.intersection_point

	var result = find_node_or_line(origin, normal)

	var desire = DataResult.invalid_result()
	if result.valid:
		var check1
		var check2
		if result.data_type == 'point':
			check1 = [result.point_index, null]
		else:
			check1 = [result.intersection_point, result.cached_line]
		if init_target.data_type == 'point':
			check2 = [init_target.point_index, null]
		else:
			check2 = [init_target.intersection_point, init_target.cached_line]
		if (result.reflected_object.target_node != init_target.reflected_object.target_node \
			|| !init_target.reflected_object.target_node.mesh.is_valid_line_creation(check1[0], check1[1], check2[0], check2[1])):
				pass
		elif result.data_type == 'line':
			var transform = result.reflected_line.target_node.get_global_transform()
			visual_node2.position = (transform*result.intersection_point)
			visual_node2.update_visuals(viewport_camera)
			visual_node2.visible = true
			desire.visual_object = visual_node2
			desire = result
		elif result.data_type == 'point' && (init_target.point_index != null || result.intersection_point != init_target.intersection_point): #is node, not same node
			result.reflected_point.material_override = CSGPlusGlobals.HOVER_POINT_MATERIAL
			result.visual_object = result.reflected_point
			desire = result

	if hover_target.valid:
		if hover_target.data_type == 'point':
			if desire.reflected_point != hover_target.reflected_point:
				hover_target.reflected_point.material_override = null
		elif hover_target.data_type == 'line':
			if desire.data_type != 'line':
				visual_node2.visible = false
	hover_target = desire
	if !hover_target.valid:
		visual_line.visible = false
		return

	var point2
	if hover_target.data_type == 'line':
		var transform = hover_target.reflected_line.target_node.get_global_transform()
		point2 = transform * hover_target.intersection_point
	else: #point
		point2 = hover_target.reflected_point.global_position
	if point1.is_equal_approx(point2):
		visual_line.visible = false
		return
	visual_line.update_position(point1, point2)
	visual_line.visible = true


func find_node_or_line(origin:Vector3, normal:Vector3):
	var target = DataResult.invalid_result()
	var target_line = node_display.seek_line(origin, normal)
	var target_point = node_display.seek_point(origin, normal)
	if(target_line.valid && target_point.valid):
		if target_line.distance > target_point.distance:
			target = target_point
		else:
			target = target_line
	if target_line.valid:
		target = target_line
	if target_point.valid:
		target = target_point
	if target.valid:
		return target
	return DataResult.invalid_result()
