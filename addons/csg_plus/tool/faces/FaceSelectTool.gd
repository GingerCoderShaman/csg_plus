@tool
class_name FaceSelectTool
extends SelectTool

var init_click
var dragged:bool = false
var hover_points = []
var hover_lines = []
var hover_face = null
var targeted_lines = []
var targeted_face = null
var targeted_model = null

func bind_tool():
	super.bind_tool()
	CSGPlusGlobals.controller.tool_controls.on_update_callback = func(toolbar):
		if targeted_model != null:
			targeted_face.material = toolbar.current_texture
			targeted_face.uv_offset = toolbar.offset_position
			targeted_face.uv_angle = toolbar.offset_angle
			targeted_face.uv_scale = toolbar.offset_scale
			targeted_model.target_mesh.mesh.update_all()
	CSGPlusGlobals.controller.tool_controls.set_face_addons_visible(true)

func unbind_tool():
	super.unbind_tool()
	CSGPlusGlobals.controller.tool_controls.on_update_callback = null
	CSGPlusGlobals.controller.tool_controls.set_face_addons_visible(false)
	if overlay_select_area.is_inside_tree():
		overlay_area_2d.remove_child(overlay_select_area)
		init_click = null
		dragged = false
	for hover_line in hover_lines:
		if is_instance_valid(hover_line):
			hover_line.material_override = null
	for target_line in targeted_lines:
		if is_instance_valid(target_line):
			target_line.material_override = null
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
			handle_face_hover(origin,normal)
			return
	elif !calculate_gizmo_logic_on_drag(origin, normal):
		overlay_select_area.set_area(init_click, event.position)
	for hover_point in hover_points:
		hover_point.material_override = null
	for hover_line in hover_lines:
		if is_instance_valid(hover_line):
			hover_line.material_override = null
	hover_points = []
	hover_lines = []
	hover_face = null

func handle_face_hover(origin:Vector3, normal:Vector3):
	var result = node_display.seek_face(origin, normal)
	var new_face = null
	var new_lines = []
	var new_points = []
	if result.valid:
		new_face = result.face
		new_lines = result.connected_reflected_lines
		new_points = result.connected_reflected_points

	if new_face != hover_face:
		for point in hover_points:
			if is_instance_valid(point):
				point.material_override = null
		hover_points = []
		for line in hover_lines:
			if is_instance_valid(line):
				line.material_override = null
		hover_lines = []
		hover_face = new_face
		for new_point in new_points:
			if !reflected_target_points.has(new_point):
				new_point.material_override = CSGPlusGlobals.HOVER_LINE_MATERIAL
				hover_points.append(new_point)
		for new_line in new_lines:
			if !targeted_lines.has(new_line):
				new_line.material_override = CSGPlusGlobals.HOVER_LINE_MATERIAL
				hover_lines.append(new_line)

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

	var result = node_display.seek_face(origin, normal)
	var new_face = null
	var new_lines = []
	var new_points = []
	if result.valid:
		new_face = result.face
		new_lines = result.connected_reflected_lines
		new_points = result.connected_reflected_points

	if new_face != targeted_face:
		for point in hover_points:
			if is_instance_valid(point):
				point.material_override = null
		hover_points = []
		for line in hover_lines:
			if is_instance_valid(line):
				line.material_override = null
		hover_lines = []
		for point in reflected_target_points:
			if is_instance_valid(point):
				point.material_override = null
		reflected_target_points = []
		for line in targeted_lines:
			if is_instance_valid(line):
				line.material_override = null
		targeted_lines = []
		targeted_model = null
		if new_face:
			CSGPlusGlobals.controller.tool_controls.current_texture = new_face.material
			CSGPlusGlobals.controller.tool_controls.offset_position = new_face.uv_offset
			CSGPlusGlobals.controller.tool_controls.offset_angle = new_face.uv_angle
			CSGPlusGlobals.controller.tool_controls.offset_scale = new_face.uv_scale
			targeted_model = result.reflected_node
		targeted_face = new_face

		for new_point in new_points:
			new_point.material_override = CSGPlusGlobals.TARGET_POINT_MATERIAL
			reflected_target_points.append(new_point)
		for new_line in new_lines:
			new_line.material_override = CSGPlusGlobals.TARGET_POINT_MATERIAL
			targeted_lines.append(new_line)

func clear_old_lines():
	for old_line in targeted_lines:
		if is_instance_valid(old_line):
			old_line.material_override = null
	targeted_lines = []
	for old_point in reflected_target_points:
		old_point.material_override = null
	reflected_target_points = []
