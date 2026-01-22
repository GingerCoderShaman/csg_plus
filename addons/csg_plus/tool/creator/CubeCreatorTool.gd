@tool
class_name CubeCreatorTool
extends AbstractCreatorTool

const STAGE_NODE_INIT = 0
const STAGE_SQUARE_ON_PLANE = 1
const STAGE_CUBE_INFLATE = 2

var stage = STAGE_NODE_INIT

var square_zero_point = null
var square_vector = null
var height_inflate = null

var square_point_primary = null

var square_render_point_primary
var square_render_point_extra_1
var square_render_point_extra_2

var lines_bottom = []
var lines_height = []
var lines_top = []

var cube_bottom_points
var cube_top_points = []

func bind_tool():
	super.bind_tool()
	square_render_point_primary = create_point()
	square_render_point_extra_1 = create_point()
	square_render_point_extra_2 = create_point()

	cube_top_points.resize(4)
	for index in 4:
		cube_top_points[index] = create_point()
	lines_bottom.resize(4)
	lines_height.resize(4)

	lines_top.resize(4)
	for index in 4:
		cube_top_points[index] = create_point()
		lines_bottom[index] = create_line()
		lines_height[index] = create_line()
		lines_top[index] = create_line()

	cube_bottom_points = [
		square_render_point_primary,
		square_render_point_extra_1,
		start_point_display,
		square_render_point_extra_2
	]

func unbind_tool():
	super.unbind_tool()

	destroy_node(square_render_point_primary)
	destroy_node(square_render_point_extra_1)
	destroy_node(square_render_point_extra_2)

	for index in 4:
		destroy_node(cube_top_points[index])
		destroy_node(lines_bottom[index])
		destroy_node(lines_height[index])
		destroy_node(lines_top[index])

func reset():
	stage = STAGE_NODE_INIT

	start_point_display.visible = false
	square_render_point_primary.visible = false
	square_render_point_extra_1.visible = false
	square_render_point_extra_2.visible = false

	for index in 4:
		cube_top_points[index].visible = false
		lines_bottom[index].visible = false
		lines_height[index].visible = false
		lines_top[index].visible = false


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
		STAGE_SQUARE_ON_PLANE:
			handle_other_point_on_plane(viewport_camera, event)
		STAGE_CUBE_INFLATE:
			handle_inflation_point(viewport_camera, event)

func handle_click(viewport_camera: Camera3D, event: InputEvent):
	match stage:
		STAGE_NODE_INIT:
			if find_start_point_and_plane(viewport_camera, event):
				stage = STAGE_SQUARE_ON_PLANE
				square_zero_point = SpaceUtils.unproject_points_onto_plane(start_plane, start_point)
		STAGE_SQUARE_ON_PLANE:
			if handle_other_point_on_plane(viewport_camera, event):
				stage = STAGE_CUBE_INFLATE
		STAGE_CUBE_INFLATE:
			if handle_inflation_point(viewport_camera, event):
				create_cube()
				reset()

func handle_other_point_on_plane(viewport_camera: Camera3D, event: InputEvent):
	var inverse_transform = start_transform.affine_inverse()
	var origin:Vector3 =  inverse_transform * viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = inverse_transform.basis * viewport_camera.project_ray_normal(event.position)
	var point = start_plane.intersects_ray(origin, normal)
	if !point:
		square_render_point_primary.visible = false
		square_render_point_extra_1.visible = false
		square_render_point_extra_2.visible = false
		for line in lines_bottom:
			line.visible = false
		return false

	square_vector = CSGPlusGlobals.controller.snap_calculaton_2d(
		SpaceUtils.unproject_points_onto_plane(start_plane, point) - square_zero_point
	)

	if is_zero_approx(square_vector.x) || is_zero_approx(square_vector.y):
		square_render_point_primary.visible = false
		square_render_point_extra_1.visible = false
		square_render_point_extra_2.visible = false
		for line in lines_bottom:
			line.visible = false
		return false

	square_point_primary = SpaceUtils.project_points_from_plane(start_plane,
		square_vector + square_zero_point
	)
	var extra_point_1 = SpaceUtils.project_points_from_plane(start_plane,
		Vector2(square_vector.x, 0) + square_zero_point
	)
	var extra_point_2 = SpaceUtils.project_points_from_plane(start_plane,
		Vector2(0, square_vector.y) + square_zero_point
	)
	square_render_point_primary.global_position = start_transform * square_point_primary

	square_render_point_extra_1.global_position = start_transform * extra_point_1
	square_render_point_extra_2.global_position = start_transform * extra_point_2

	for index in 4:
		lines_bottom[index].update_position(cube_bottom_points[index].global_position, cube_bottom_points[(index+1)%4].global_position)
		lines_bottom[index].visible = true
		cube_bottom_points[index].update_visuals(viewport_camera)
		cube_bottom_points[index].visible = true

	return true

func handle_inflation_point(viewport_camera: Camera3D, event: InputEvent):
	var inverse_transform = start_transform.affine_inverse()
	var origin:Vector3 =  inverse_transform * viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = inverse_transform.basis * viewport_camera.project_ray_normal(event.position)

	var point_on_plane = SpaceUtils.project_points_from_plane(start_plane, SpaceUtils.unproject_points_onto_plane(start_plane, origin))
	var direction = start_point.direction_to(point_on_plane)
	var cube_position_upward_plane = Plane(direction, square_point_primary)

	var point = cube_position_upward_plane.intersects_ray(origin, normal)
	if !point:
		for index in 4:
			cube_top_points[index].visible = false
			lines_height[index].visible = false
			lines_top[index].visible = false
		return false

	var relative_to_plane = SpaceUtils.plane_to_local(start_plane, point)

	height_inflate = CSGPlusGlobals.controller.snap_calculaton_1d(relative_to_plane.z)

	if is_zero_approx(height_inflate):
		for index in 4:
			cube_top_points[index].visible = false
			lines_height[index].visible = false
			lines_top[index].visible = false
		return false

	cube_top_points[0].global_position = start_transform * SpaceUtils.plane_to_global(start_plane,Vector3(square_vector.x + square_zero_point.x, square_vector.y + square_zero_point.y, height_inflate))
	cube_top_points[3].global_position = start_transform * SpaceUtils.plane_to_global(start_plane,Vector3(square_zero_point.x, square_vector.y + square_zero_point.y, height_inflate))
	cube_top_points[2].global_position = start_transform * SpaceUtils.plane_to_global(start_plane,Vector3(square_zero_point.x,square_zero_point.y, height_inflate))
	cube_top_points[1].global_position = start_transform * SpaceUtils.plane_to_global(start_plane,Vector3(square_vector.x + square_zero_point.x, square_zero_point.y, height_inflate))

	for index in 4:
		lines_bottom[index].update_position(cube_bottom_points[index].global_position, cube_bottom_points[(index+1)%4].global_position)
		cube_bottom_points[index].update_visuals(viewport_camera)

		lines_top[index].update_position(cube_top_points[index].global_position, cube_top_points[(index+1)%4].global_position)
		lines_top[index].visible = true
		cube_top_points[index].update_visuals(viewport_camera)
		cube_top_points[index].visible = true

		lines_height[index].update_position(cube_top_points[index].global_position, cube_bottom_points[index].global_position)
		lines_height[index].visible = true

	square_render_point_primary.update_visuals(viewport_camera)
	start_point_display.update_visuals(viewport_camera)
	return true

func create_cube():
	var cube = CSGPlusMesh.new()
	var new_zero = square_zero_point
	var offset_vector = Vector3.ZERO
	if square_vector.x < 0:
		offset_vector.x = square_vector.x
	if square_vector.y < 0:
		offset_vector.y = square_vector.y
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
	var cube_scale = Vector3(abs(square_vector.x),  abs(square_vector.y), abs(height_inflate))

	cube.mesh = CSGPlusGlobals.DynamicMesh.from_cube(cube_scale)

	cube.global_transform = transform
	CSGPlusGlobals.controller.add_node_to_scene(cube, start_parent)
