@tool
class_name FacePainterTool
extends Tool

var init_click
var dragged:bool = false
var hover_points = []
var hover_lines = []
var hover_face = null
var node_display

func bind_tool():
	super.bind_tool()
	node_display = CSGPlusGlobals.controller.node_display_handler
	CSGPlusGlobals.controller.tool_controls.set_face_addons_visible(true)

func unbind_tool():
	super.unbind_tool()
	CSGPlusGlobals.controller.tool_controls.set_face_addons_visible(false)
	for point in hover_points:
		if is_instance_valid(point):
			point.material_override = null
	hover_points = []
	for line in hover_lines:
		if is_instance_valid(line):
			line.material_override = null
	hover_lines = []

func handle_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		handle_motion_event(viewport_camera, event)
	if event.is_action(CSGPlusGlobals.NODE_SELECTED):
		if event.pressed == true:
			select_single(viewport_camera, event.position)
		return true
	return false

func handle_motion_event(viewport_camera: Camera3D, event: InputEvent):
	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)
	#check if we are now dragging
	handle_face_hover(origin, normal)

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
			new_point.material_override = CSGPlusGlobals.HOVER_LINE_MATERIAL
			hover_points.append(new_point)
		for new_line in new_lines:
			new_line.material_override = CSGPlusGlobals.HOVER_LINE_MATERIAL
			hover_lines.append(new_line)


	#axis logic (if needed)
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
		new_face.material = CSGPlusGlobals.controller.tool_controls.current_texture
		new_face.uv_offset = CSGPlusGlobals.controller.tool_controls.offset_position
		new_face.uv_angle = CSGPlusGlobals.controller.tool_controls.offset_angle
		new_face.uv_scale = CSGPlusGlobals.controller.tool_controls.offset_scale
		if new_face.locked != CSGPlusGlobals.controller.tool_controls.locked_face:
			new_face.locked = CSGPlusGlobals.controller.tool_controls.locked_face
			CSGPlusGlobals.controller.refresh_deep_mesh()
		result.reflected_node.target_mesh.mesh.update_all()
