@tool
class_name AbstractCreatorTool
extends Tool

var base_plane_interaction:Plane = Plane.PLANE_XZ
var node_display
var creator_display

var start_point_display
var start_point = null
var start_plane = null
var start_transform = null
var start_parent = null

func bind_tool():
	super.bind_tool()
	node_display = CSGPlusGlobals.controller.node_display_handler
	creator_display = CSGPlusGlobals.controller.miscellaneous
	start_point_display = create_point()

func unbind_tool():
	super.unbind_tool()
	destroy_node(start_point_display)

func create_point():
	var new_node = CSGPlusGlobals.VisualPoint.new()
	new_node.visible = false
	creator_display.add_child(new_node)
	return new_node

func create_line():
	var new_node = CSGPlusGlobals.VisualLine.new()
	new_node.visible = false
	creator_display.add_child(new_node)
	return new_node

func destroy_node(node):
	node.queue_free()

func get_targetable_nodes():
	var domain = CSGPlusGlobals.controller.get_scene()
	return explore_targetable_nodes(domain)

func explore_targetable_nodes(parent: Node):
	var targetable_nodes = []
	if (parent == null):
		return null
	for node in parent.get_children():
		var property_mesh = node.get('mesh')
		if property_mesh is CSGPlusGlobals.DynamicMesh:
			targetable_nodes.append(node)
		targetable_nodes.append_array(explore_targetable_nodes(node))
	return targetable_nodes

func find_plane_point( origin:Vector3, normal:Vector3):
	var point_on_plane = DataResult.invalid_result()
	var targetable_nodes = get_targetable_nodes()
	if targetable_nodes == null:
		return point_on_plane
	for target in targetable_nodes:
		if target.global_transform.is_finite():
			var instance_mesh = target.mesh
			var local_transform = target.global_transform.affine_inverse()
			var local_origin = local_transform * origin
			var local_normal = local_transform.basis * normal
			var plane_point = instance_mesh.get_point_on_plane(local_origin, local_normal)
			if plane_point.valid && (!point_on_plane.valid|| point_on_plane.distance > plane_point.distance):
				point_on_plane = plane_point
				point_on_plane.reflected_node = target
	return point_on_plane

func find_start_point_and_plane(viewport_camera: Camera3D, event: InputEvent, override_material = true):
	var origin:Vector3 = viewport_camera.project_ray_origin(event.position)
	var normal:Vector3 = viewport_camera.project_ray_normal(event.position)
	var point_on_plane = find_plane_point(origin, normal)
	if point_on_plane.valid:
		var transform = point_on_plane.reflected_node.global_transform
		start_plane = point_on_plane.plane
		var nearest_point = point_on_plane.reflected_node.mesh.find_closest_point_on_face(point_on_plane.face, point_on_plane.intersection_point)
		start_point = CSGPlusGlobals.controller.snap_along_plane(point_on_plane.intersection_point, nearest_point, start_plane)
		if CSGPlusGlobals.controller.setting_global_positioner:
			start_parent = null
			start_transform = Transform3D.IDENTITY
			start_point = transform * start_point
			start_plane = transform * start_plane
		else:
			start_parent = point_on_plane.reflected_node
			start_transform = transform
	else:
		var target_point = base_plane_interaction.intersects_ray(origin, normal)
		start_parent = null
		if target_point == null:
			start_point_display.visible = false
			start_point = null
			start_plane = null
			start_transform = null
			return false
		start_plane = base_plane_interaction
		start_point = CSGPlusGlobals.controller.snap_along_plane(target_point, Vector3.ZERO, start_plane)
		start_transform = Transform3D.IDENTITY #TODO if offsets are added to base interaction, ADD that here as well!!
	if start_point_display.material_override == null && override_material:
		start_point_display.material_override = CSGPlusGlobals.HOVER_POINT_MATERIAL
	if start_point_display.material_override != null && !override_material:
		start_point_display.material_override = null
	start_point_display.visible = true
	start_point_display.global_position = start_transform * start_point

	start_point_display.update_visuals(viewport_camera)
	return true
