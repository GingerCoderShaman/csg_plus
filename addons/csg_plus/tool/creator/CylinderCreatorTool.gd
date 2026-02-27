@tool
class_name CylinderCreatorTool
extends AbstractCreatorTool

const STAGE_NODE_INIT = 0
const STAGE_ON_PLANE = 1
const STAGE_INFLATE = 2

var stage = STAGE_NODE_INIT

var square_zero_point = null
var square_vector = null
var height_inflate = null

var square_point_primary = null

var lines_bottom = []
var lines_height = []
var lines_top = []

var bottom_points = []
var top_points = []

func bind_tool():
	super.bind_tool()
	setup_visual()

func unbind_tool():
	super.unbind_tool()
	destroy_visual()

func refresh_tool():
	destroy_visual()
	setup_visual()
	process_visual(CSGPlusGlobals.controller.editor_camera)

func destroy_visual():
	while lines_bottom.size():
		destroy_node(lines_bottom.pop_back())
	while lines_top.size():
		destroy_node(lines_top.pop_back())
	while lines_height.size():
		destroy_node(lines_height.pop_back())
	while bottom_points.size():
		destroy_node(bottom_points.pop_back())
	while top_points.size():
		destroy_node(top_points.pop_back())

func setup_visual():
	var size = main.cylinder_points
	for index in size:
		lines_bottom.push_back(create_line())
		lines_height.push_back(create_line())
		lines_top.push_back(create_line())
		bottom_points.push_back(create_point())
		top_points.push_back(create_point())

func process_visual(viewport_camera:Camera3D):
	var size = main.cylinder_points
	var distance_on_plane = null

	start_point_display.update_visuals(viewport_camera)

	if square_vector:
		distance_on_plane = square_vector.distance_to(Vector2.ZERO)
		for index in bottom_points.size():
			var angle = float(index) / size
			var point  = bottom_points[index]
			point.update_visuals(viewport_camera)
			var point_location_on_plane = Vector2(cos(angle * PI * 2) * distance_on_plane, sin(angle * PI * 2) * distance_on_plane)
			
			var point_location = SpaceUtils.project_points_from_plane(start_plane,
				point_location_on_plane + square_zero_point
			)
					
			point.global_position = start_transform * (point_location)
			point.visible = true;
		
		for index in lines_bottom.size():
			var line = lines_bottom[index]
			#line.update_visuals(viewport_camera)
			line.update_position(bottom_points[index].global_position, bottom_points[index-1].global_position)
			line.visible = true
	else:
		for point in bottom_points:
			point.visible = false
		
		for line in lines_bottom:
			line.visible = false

	if height_inflate:
		for index in top_points.size():			
			var angle = float(index) / size
			var point  = top_points[index]
			point.update_visuals(viewport_camera)
			var point_location_on_plane = Vector2(cos(angle * PI * 2) * distance_on_plane, sin(angle * PI * 2) * distance_on_plane)

			var point_location = SpaceUtils.plane_to_global(start_plane,
				Vector3(point_location_on_plane.x + square_zero_point.x, point_location_on_plane.y + square_zero_point.y, height_inflate)
			)
			point.global_position = start_transform * (point_location)
			point.visible = true;

		
		for index in lines_height.size():
			var line = lines_height[index]
			line.update_position(top_points[index].global_position, top_points[index-1].global_position)
			line.visible = true
		
		
		for index in lines_top.size():
			var line = lines_top[index]
			line.update_position(bottom_points[index].global_position, top_points[index].global_position)
			line.visible = true

		pass
	else:
		for point in top_points:
			point.visible = false
		for line in lines_height:
			line.visible = false
		for line in lines_top:
			line.visible = false

func reset():
	square_vector = null
	height_inflate = null
	stage = STAGE_NODE_INIT
	for line in lines_bottom:
		line.visible = false
	for line in lines_height:
		line.visible = false
	for line in lines_top:
		line.visible = false

	for point in bottom_points:
		point.visible = false
	for point in top_points:
		point.visible = false

func handle_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	if event.is_action(CSGPlusGlobals.NODE_UNSELECT):
		reset()
		return true
	if event is InputEventMouseMotion:
		handle_hover(viewport_camera, event)
	if event.is_action(CSGPlusGlobals.NODE_SELECTED) && event.is_released():
		handle_click(viewport_camera, event)
		return true
	return false

func handle_hover(viewport_camera: Camera3D, event: InputEvent):
	match stage:
		STAGE_NODE_INIT:
			find_start_point_and_plane(viewport_camera, event)
		STAGE_ON_PLANE:
			find_plane_layout(viewport_camera, event)
		STAGE_INFLATE:
			find_inflate_point(viewport_camera, event)

func handle_click(viewport_camera: Camera3D, event: InputEvent):
	match stage:
		STAGE_NODE_INIT:
			if find_start_point_and_plane(viewport_camera, event):
				stage = STAGE_ON_PLANE
				square_zero_point = SpaceUtils.unproject_points_onto_plane(start_plane, start_point)
		STAGE_ON_PLANE:
			if find_plane_layout(viewport_camera, event):
				stage = STAGE_INFLATE
		STAGE_INFLATE:
			create_cylinder()


func find_plane_layout(viewport_camera:Camera3D, event: InputEvent):
	var inverse_transform = start_transform.affine_inverse()
	var origin:Vector3 =  inverse_transform * viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = inverse_transform.basis * viewport_camera.project_ray_normal(event.position)
	var point = start_plane.intersects_ray(origin, normal)
	if point && !(is_zero_approx(point.x) && is_zero_approx(point.y)):
		square_vector = CSGPlusGlobals.controller.snap_calculaton_2d(
			SpaceUtils.unproject_points_onto_plane(start_plane, point) - square_zero_point
		)
		square_point_primary = SpaceUtils.project_points_from_plane(start_plane,
			square_vector + square_zero_point
		)
	else:
		square_vector = null
	process_visual(viewport_camera)

	return square_vector != null


func find_inflate_point(viewport_camera:Camera3D, event: InputEvent):
	var inverse_transform = start_transform.affine_inverse()
	var origin:Vector3 =  inverse_transform * viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = inverse_transform.basis * viewport_camera.project_ray_normal(event.position)

	var point_on_plane = SpaceUtils.project_points_from_plane(start_plane, SpaceUtils.unproject_points_onto_plane(start_plane, origin))
	var direction = start_point.direction_to(point_on_plane)
	var cube_position_upward_plane = Plane(direction, square_point_primary)
	var point = cube_position_upward_plane.intersects_ray(origin, normal)
	var relative_to_plane = SpaceUtils.plane_to_local(start_plane, point)
	height_inflate = CSGPlusGlobals.controller.snap_calculaton_1d(relative_to_plane.z)
	process_visual(viewport_camera)

	return  !is_zero_approx(height_inflate)

func create_cylinder():
	var cylinder = CSGPlusMesh.new()
	var new_zero = square_zero_point
	var offset_vector = Vector3.ZERO
	#if square_vector.x < 0:
		#offset_vector.x = square_vector.x
	#if square_vector.y < 0:
		#offset_vector.y = square_vector.y
	if height_inflate < 0:
		offset_vector.z = height_inflate
	var translated = SpaceUtils.plane_transform(start_plane)
	#var transform = start_transform * (\ ### START TRANSFORM IS HANDLED IN PARENTING
	var transform = (\
		translated
			.translated(-translated.origin)
			.translated(SpaceUtils.project_points_from_plane(start_plane, new_zero))\
			.translated_local(offset_vector)
		)
	var cylinder_scale = square_vector.distance_to(Vector2.ZERO)

	cylinder.mesh = CSGPlusGlobals.DynamicMesh.from_cylinder(cylinder_scale, abs(height_inflate), CSGPlusGlobals.controller.cylinder_points)

	cylinder.global_transform = transform
	CSGPlusGlobals.controller.add_node_to_scene(cylinder, start_parent)
	reset()