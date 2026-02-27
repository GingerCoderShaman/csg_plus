@tool
class_name LineSelectTool
extends SelectTool

var init_click
var dragged:bool = false
var hover_line = null
var targeted_lines = []

func bind_tool():
	super.bind_tool()

func unbind_tool():
	super.unbind_tool()
	if overlay_select_area.is_inside_tree():
		overlay_area_2d.remove_child(overlay_select_area)
		init_click = null
		dragged = false
	if hover_line:
		hover_line.material_override = null
	clear_old_lines()

func handle_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	if event.is_action(CSGPlusGlobals.NODE_UNSELECT):
		clear_old_lines()
		position_gizmo()
		return true
	if event is InputEventMouseMotion:
		handle_motion_event(viewport_camera, event)
	if event.is_action(CSGPlusGlobals.NODE_SELECTED):
		if event.pressed == true:
			handle_node_selection_press(viewport_camera, event)
		if event.pressed == false:
			handle_node_selection_release(viewport_camera, event)
		position_gizmo()
		return true
	return false

func handle_motion_event(viewport_camera: Camera3D, event: InputEvent):
	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)
	#check if we are now dragging
	if !dragged && init_click != null && event.position.distance_to(init_click) > 10:
		dragged = true
		if !axis && !overlay_select_area.is_inside_tree():
			overlay_area_2d.add_child(overlay_select_area)
		else:
			past_nodes = MeshCommit.target_list_to_reference_list_basic(reflected_target_points)
	#calculate if target gizmo is glowing
	if !dragged:
		if !target_gizmo.calculate_mouse_hover(origin, normal):
			handle_line_hover(origin,normal)
			return
	elif !calculate_gizmo_logic_on_drag(origin, normal):
		overlay_select_area.set_area(init_click, event.position)
	if hover_line:
		hover_line.material_override = null

func handle_line_hover(origin:Vector3, normal:Vector3):
	var target_line = node_display.seek_line(origin, normal)
	var line = null
	if target_line != null:
		line = target_line.reflected_line

	if targeted_lines.has(line):
		line = null

	if hover_line != line:
		if hover_line != null:
			hover_line.material_override = null
		hover_line = line
		if hover_line:
			hover_line.material_override = CSGPlusGlobals.HOVER_LINE_MATERIAL

func handle_node_selection_press(viewport_camera: Camera3D, event: InputEvent):
	#area selection
	init_click = event.position
	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)
	calculate_gizmo_logic_on_click(origin, normal)
	#axis logic (if needed)

func handle_node_selection_release(viewport_camera: Camera3D, event: InputEvent):
	#gizmo logic

	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)
	if calculate_gizmo_logic_on_release(origin, normal):
		dragged = false
		init_click = null
		return
	#standard selection logic
	if !Input.is_action_pressed(CSGPlusGlobals.NODE_HOLD):
		clear_old_lines()

	if dragged:
		#select_area(viewport_camera, init_click, event.position)
		angle_gizmo()
		if overlay_select_area.is_inside_tree():
			overlay_area_2d.remove_child(overlay_select_area)
	else:
		select_single(viewport_camera, event.position)
		angle_gizmo()
	init_click = null
	dragged = false

func select_single(viewport_camera: Camera3D, position:Vector2):
	var origin:Vector3 = viewport_camera.project_ray_origin(position)
	var normal:Vector3 = viewport_camera.project_ray_normal(position)

	var target_line = node_display.seek_line(origin, normal)
	var line = null
	if target_line != null:
		line = target_line.reflected_line
	if hover_line == line:
		hover_line = null
	if line:
		line.material_override = CSGPlusGlobals.TARGET_POINT_MATERIAL
		targeted_lines.append(line)
		for node in target_line.vertex_indexes:
			if !reflected_target_points.has(node) && !node.target_node.mesh.is_point_in_disabled_face(node.point_position):
				reflected_target_points.append(node)
				node.material_override = CSGPlusGlobals.TARGET_POINT_MATERIAL

func clear_old_lines():
	for old_line in targeted_lines:
		if is_instance_valid(old_line):
			old_line.material_override = null
	targeted_lines = []
	for old_point in reflected_target_points:
		old_point.material_override = null
	reflected_target_points = []
