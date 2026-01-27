@tool
class_name PointSelectTool
extends SelectTool

var init_click
var dragged:bool = false
var hover_target = null

func unbind_tool():
	super.unbind_tool()
	if overlay_select_area.is_inside_tree():
		overlay_area_2d.remove_child(overlay_select_area)
		init_click = null
		dragged = false
	if hover_target:
		hover_target.material_override = null


func handle_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	if event.is_action(CSGPlusGlobals.NODE_UNSELECT):
		clear_old_nodes()
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
			handle_node_hover(origin,normal)
			return
	elif !calculate_gizmo_logic_on_drag(origin, normal):
		overlay_select_area.set_area(init_click, event.position)
	if hover_target:
		hover_target.material_override = null

func handle_node_hover(origin:Vector3, normal:Vector3):
	var new_target = node_display.seek_point(origin, normal)
	if !new_target.valid:
		if hover_target != null:
			hover_target.material_override = null
			hover_target = null
	elif new_target.reflected_point != hover_target:
		if hover_target != null:
			hover_target.material_override = null
		hover_target = new_target.reflected_point
		if hover_target:
			if !reflected_target_points.has(hover_target):
				hover_target.material_override = CSGPlusGlobals.HOVER_POINT_MATERIAL
			else:
				hover_target = null

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
		clear_old_nodes()

	if dragged:
		select_area(viewport_camera, init_click, event.position)
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
	var new_target = node_display.seek_point(origin, normal)

	if !new_target.valid:
		return
	var model = new_target.reflected_point
	if model == hover_target:
		hover_target.material_override = null
		hover_target = null
	var index = reflected_target_points.find(model)
	if index == -1:
		model.material_override = CSGPlusGlobals.TARGET_POINT_MATERIAL
		reflected_target_points.append(model)
	else:
		model.material_override = null;
		reflected_target_points.remove_at(index)

func select_area(viewport_camera: Camera3D, left_pos:Vector2, right_pos:Vector2):
	var left:float = min(left_pos.x, right_pos.x)
	var right:float = max(left_pos.x, right_pos.x)
	var down:float = min(left_pos.y, right_pos.y)
	var up:float = max(left_pos.y, right_pos.y)
	for child in node_display.get_children():
		for target_point_node in child.points.get_children():
			var screen_local:Vector2 = viewport_camera.unproject_position(target_point_node.global_position)
			if left < screen_local.x && screen_local.x < right && \
					down < screen_local.y && screen_local.y < up:
						var target_loc:int = reflected_target_points.find(target_point_node)
						if target_loc != -1:
							continue
						target_point_node.material_override = CSGPlusGlobals.TARGET_POINT_MATERIAL
						reflected_target_points.append(target_point_node)

func clear_old_nodes():
	for old_node in reflected_target_points:
		if is_instance_valid(old_node):
			old_node.material_override = null
	reflected_target_points = []
