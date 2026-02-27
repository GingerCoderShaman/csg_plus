class_name SpaceUtils

const LEFT_TURN = -1
const RIGHT_TURN = 1
const NO_TURN = 0;

static func generate_normal(vertexs):
	var normal = Vector3.ZERO;
	if (vertexs.size() < 3):
		return normal;
	for i in vertexs.size():
		var item = vertexs[i];
		var next = vertexs[(i+1)%vertexs.size()]
		normal.x += (next.y - item.y) * (next.z + item.z)
		normal.y += (next.z - item.z) * (next.x + item.x)
		normal.z += (next.x - item.x) * (next.y + item.y)

	return normal.normalized();

static func turn(p:Vector3, u:Vector3, n:Vector3, q:Vector3):
	var v = q-p;
	var dot = (v.cross(u)).dot(n)
	if dot > -.0001:
		return RIGHT_TURN
	if dot < -.0001:
		return LEFT_TURN
	return NO_TURN

static func points_shape_around_center(vertexs, center, normal:Vector3):
	var size = vertexs.size()
	if size < 3:
		return false
	if size == 3:
		return true
	var poly_turn = NO_TURN
	for index in size:
		var item = vertexs[(index)%size]
		var next = vertexs[(index+1)%size]

		var normal_v = (item-center).normalized()
		var item_turn = turn(center, normal_v, normal, next)
		#over lapped points
		if item_turn == NO_TURN:
			continue
		#first check should be skipped over
		if poly_turn == NO_TURN:
			poly_turn = item_turn
		#if turns are not the same, it is not convex
		if poly_turn != item_turn:
			return false
	return true

static func generate_normal_and_center(vertexs):
	var normal = Vector3.ZERO;
	if (vertexs.size() < 3):
		return [normal, (vertexs[0] + vertexs[1] ) / 2];
	#var min = vertexs[0]
	#var max = vertexs[0]
	var total = Vector3.ZERO
	for i in vertexs.size():
		var item = vertexs[i];
		var next = vertexs[(i+1)%vertexs.size()]
		normal.x += (next.y - item.y) * (next.z + item.z)
		normal.y += (next.z - item.z) * (next.x + item.x)
		normal.z += (next.x - item.x) * (next.y + item.y)
		total += vertexs[i]
	return [normal.normalized(), total/vertexs.size()];

static func fan_center(vertexs, center:Vector3):
	var result:PackedVector3Array = []
	if vertexs.size() < 3:
		return result
	if vertexs.size() == 3:
		return vertexs
	for index in vertexs.size() - 1:
		result.append_array([center, vertexs[index], vertexs[index+1]])
	result.append_array([center, vertexs[vertexs.size()-1], vertexs[0]])
	return result

static func get_center(vertexs):
	var center = Vector3.ZERO
	for vertex in vertexs:
		center += vertex
	center /= vertexs.size()
	return center

static func remove_immediate_duplicate(vertexs):
	var removes:Array = []
	var last_target = Vector3.INF
	for i in vertexs.size() + 1:
		if vertexs[i % vertexs.size()].is_equal_approx(last_target):
			removes.append(i % vertexs.size())
		else:
			last_target = vertexs[i % vertexs.size()]
	var original_length = vertexs.size()
	for i in removes.size():
		vertexs.remove_at(removes[removes.size() - i - 1])
	return vertexs

static func triangulate(vertexs):
	vertexs = remove_immediate_duplicate(vertexs)
	if(vertexs.size() < 3):
		return [];
	#if(vertexs.size() == 3):
		#return [vertexs[0], vertexs[1], vertexs[2]]

	var normal_and_center = generate_normal_and_center(vertexs)

	var normal = normal_and_center[0]
	var center = normal_and_center[1]

	#if is_convex(vertexs, normal):
		#return fan_triangulation(vertexs)
	#return cut_triangulation(vertexs, normal)
	#if is_convex(vertexs, normal):
	if points_shape_around_center(vertexs, center, normal):
		return fan_center(vertexs, center)
	CSGPlusGlobals.controller.error_panel.alert_if_empty("Polygon is malformed, point cannot reach center without overlap")
	return null

static func vectors_intersects_vectors(line_point_1:Vector3, line1_vec:Vector3, line_point_2:Vector3, line2_vec:Vector3, offset_vector:float = 0.01):
	line1_vec = line1_vec.normalized()
	line2_vec = line2_vec.normalized()
	var line3_vec:Vector3 = line_point_2-line_point_1
	var cross_vec1_cross_vec2:Vector3 = line1_vec.cross(line2_vec)
	var cross_vec2_cross_vec3:Vector3 = line3_vec.cross(line2_vec)
	var planar_factor = line3_vec.dot(cross_vec1_cross_vec2)
	if abs(planar_factor) < offset_vector:
		var s:float = cross_vec2_cross_vec3.dot(cross_vec1_cross_vec2) / cross_vec1_cross_vec2.length_squared()
		return line_point_1 + (line1_vec * s);
	return null;

static func find_lowest_common_nodes(node:Node, nodes:Array):
	var instances = 0
	for child in node.get_children():
		var result = find_lowest_common_nodes(child, nodes)
		if result is Node:
			return result
		instances += result
	instances += count_instances_in_array(node, nodes)
	if instances == nodes.size():
		return node
	return instances

static func count_instances_in_array(node:Node, nodes:Array):
	var count = 0;
	for check in nodes:
		if check == node:
			count += 1
	return count

static func plane_transform(plane:Plane):
	var transform
	var normal = plane.normal
	if (normal.is_equal_approx(Vector3.UP) || normal.is_equal_approx(Vector3.DOWN)):
		transform = Transform3D.IDENTITY.looking_at(normal, Vector3.FORWARD)
	elif normal.is_zero_approx():
		transform = Transform3D.IDENTITY
	else:
		transform = Transform3D.IDENTITY.looking_at(normal)
	transform = transform.translated_local(Vector3(0, 0, -plane.d / normal.length()))
	return transform
	#return Transform3D(Basis(plane.normal), plane.get_center())

static func plane_quaterion(plane):
	var quaternion
	var normal = plane.normal
	if (normal.is_equal_approx(Vector3.UP) || normal.is_equal_approx(Vector3.DOWN)):
		quaternion = Transform3D.IDENTITY.looking_at(normal, Vector3.FORWARD).basis.get_rotation_quaternion().inverse()
	else:
		quaternion = Transform3D.IDENTITY.looking_at(normal).basis.get_rotation_quaternion().inverse()
	return quaternion


static func unproject_points_onto_plane(plane, data):
	var transform = plane_transform(plane)

	if data is Vector3:
		var result =  transform.affine_inverse()*data
		return Vector2(result.x, result.y)
	var data_array
	if data is PackedVector3Array:
		data_array = PackedVector2Array()
	else:
		data_array = []
	data_array.resize(data.size())
	for index in data_array.size():
		var result = transform.affine_inverse()*data[index]
		data_array[index] = Vector2(result.x, result.y)
	return data_array

static func plane_to_local(plane, data):
	var transform = plane_transform(plane)

	if data is Vector3:
		return transform.affine_inverse()*data
	var data_array
	if data is PackedVector3Array:
		data_array = PackedVector3Array()
	else:
		data_array = []
	data_array.resize(data.size())
	for index in data_array.size():
		data_array[index] = transform.affine_inverse()*data[index]
	return data_array

static func project_points_from_plane(plane, data):
	var transform = plane_transform(plane)
	if data is Vector2:
		var temp = Vector3(data.x, data.y, 0)
		var result =  (transform*temp)
		return result
	var data_array
	if data is PackedVector2Array:
		data_array = PackedVector3Array()
	else:
		data_array = []
	data_array.resize(data.size())
	for index in data_array.size():
		var temp = Vector3(data[index].x, data[index].y, 0)
		var result =  transform * temp
		data_array[index] = result
	return data_array

static func plane_to_global(plane, data):
	var transform = plane_transform(plane)
	if data is Vector3:
		var result =  transform * data
		return result
	var data_array
	if data is PackedVector3Array:
		data_array = PackedVector3Array()
	else:
		data_array = []
	data_array.resize(data.size())
	for index in data_array.size():
		var result = transform * data[index]
		data_array[index] = result
	return data_array
