@tool
extends ArrayMesh

const CENTER_OFFSET = Vector2(0, 0)

@export
var points:PackedVector3Array:
	get:
		return points_data;
	set(value):
		points_data = value
		update_all()

@export
var surfaces:Array:
	get:
		return surface_data;
	set(value):
		surface_data = value
		update_all()

@export
var line_cache:Dictionary = {}
var surface_cache:Dictionary = {}

var points_data:PackedVector3Array
var surface_data:Array
var verified_parent = null

# ******************************** NODE ALTERATIONS *************************************

func verify_parent(parent):
	if verified_parent == null:
		verified_parent = parent
		update_all()
		return self
	var new_mesh = new()
	new_mesh.points = points
	new_mesh.surfaces = surfaces
	new_mesh.verified_parent = parent
	new_mesh.update_all()
	return new_mesh

static func from_cube(scale:Vector3 = Vector3.ONE):
	var mesh = new()
	var base_material = CSGPlusGlobals.LevelDefaultMaterial

	mesh.points = [
		Vector3(0,0,0),
		Vector3(0,0,scale.z),
		Vector3(scale.x,0,0),
		Vector3(scale.x,0,scale.z),
		Vector3(0,scale.y,0),
		Vector3(0,scale.y,scale.z),
		Vector3(scale.x,scale.y,0),
		Vector3(scale.x,scale.y,scale.z),
	]

	mesh.surfaces = [
		CSGPlusGlobals.FaceInfo.new([0,1,3,2], base_material),
		CSGPlusGlobals.FaceInfo.new([6,7,5,4], base_material),
		CSGPlusGlobals.FaceInfo.new([5,1,0,4], base_material),
		CSGPlusGlobals.FaceInfo.new([3,7,6,2], base_material),
		CSGPlusGlobals.FaceInfo.new([0,2,6,4], base_material),
		CSGPlusGlobals.FaceInfo.new([5,7,3,1], base_material),
	]
	mesh.update_all()
	return mesh

# ************************* CONSTRUCT VISUALS ******************************

static func is_valid_polygon(points:Array, surfaces, line_cache):
	for surface_index in surfaces.size():
		var surface = surfaces[surface_index]
		var vertex:Array = []
		for vertex_index in surface.vertexes:
			if(points.size() <= vertex_index):
				return
			var point = points[vertex_index]# * scale;
			vertex.append(point)
		var indexed_vertex:PackedVector3Array = SpaceUtils.triangulate(vertex)
		for line in line_cache.keys():
			var line_point_1:Vector3 = points[line.vertex1]
			var line_point_2:Vector3 = points[line.vertex2]
			if !surface.vertexes.has(line.vertex1) && !surface.vertexes.has(line.vertex2):
				for index:int in indexed_vertex.size()/3:
					if Geometry3D.segment_intersects_triangle(
						line_point_1,
						line_point_2,
						indexed_vertex[index * 3],
						indexed_vertex[index * 3 + 1],
						indexed_vertex[index * 3 + 2],
					) != null:
						return false
	return true

static func build_surface(material_surface, points, surface):
	var vertex:PackedVector3Array = []
	var vertex_final:PackedVector3Array = []
	var normals:PackedVector3Array = [];
	var uv:PackedVector2Array = [];
	for vertex_index in surface.vertexes:
		if(points.size() <= vertex_index):
			return false
		vertex.append(points[vertex_index])
	var indexed_vertex = SpaceUtils.triangulate(vertex)
	if indexed_vertex == null || indexed_vertex.size() == 0:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("Surface index was not generated")
		return false;
	for index in indexed_vertex.size()/3:
		var proxy_index:int = index*3
		var sub_indexed_vertex:Array = [indexed_vertex[proxy_index], indexed_vertex[proxy_index+1], indexed_vertex[proxy_index+2]]
		for face in material_surface.keys():
			var check_points = material_surface[face][Mesh.ARRAY_VERTEX]
			for check_index in check_points.size()/3:
				var proxy_c_index = check_index * 3
				var check_triangle = [check_points[proxy_c_index],check_points[proxy_c_index + 1],check_points[proxy_c_index + 2]]
				var check_index_valid = [
					sub_indexed_vertex[0] == check_triangle[0] \
						|| sub_indexed_vertex[1] == check_triangle[0] \
						|| sub_indexed_vertex[2] == check_triangle[0], \
					sub_indexed_vertex[0] == check_triangle[1] \
						|| sub_indexed_vertex[1] == check_triangle[1] \
						|| sub_indexed_vertex[2] == check_triangle[1], \
					sub_indexed_vertex[0] == check_triangle[2] \
						|| sub_indexed_vertex[1] == check_triangle[2] \
						|| sub_indexed_vertex[2] == check_triangle[2], \
				]
				if !check_index_valid[0] && !check_index_valid[1] && Geometry3D.segment_intersects_triangle( \
					check_triangle[0], check_triangle[1], sub_indexed_vertex[0], sub_indexed_vertex[1], sub_indexed_vertex[2]
				) != null:
					CSGPlusGlobals.controller.error_panel.alert_if_empty("Surface collides with another surface 1")
					return false
				if !check_index_valid[1] && !check_index_valid[2] && Geometry3D.segment_intersects_triangle( \
					check_triangle[1], check_triangle[2], sub_indexed_vertex[0], sub_indexed_vertex[1], sub_indexed_vertex[2]
				) != null:
					CSGPlusGlobals.controller.error_panel.alert_if_empty("Surface collides with another surface 2")
					return false
				if !check_index_valid[2] && !check_index_valid[0] && Geometry3D.segment_intersects_triangle( \
					check_triangle[2], check_triangle[0], sub_indexed_vertex[0], sub_indexed_vertex[1], sub_indexed_vertex[2]
				) != null:
					CSGPlusGlobals.controller.error_panel.alert_if_empty("Surface collides with another surface 3")
					return false
		var plane = Plane(sub_indexed_vertex[0], sub_indexed_vertex[1], sub_indexed_vertex[2])
		var normal:Vector3 = plane.normal
		var indexed_uv = SpaceUtils.unproject_points_onto_plane(plane, sub_indexed_vertex)

		uv.append_array([((Vector2(indexed_uv[0].x, indexed_uv[0].y) + surface.uv_offset/100 - CENTER_OFFSET).rotated(surface.uv_angle) +  CENTER_OFFSET) * surface.uv_scale,
					((Vector2(indexed_uv[1].x, indexed_uv[1].y) + surface.uv_offset/100 - CENTER_OFFSET).rotated(surface.uv_angle) +  CENTER_OFFSET) * surface.uv_scale,
					((Vector2(indexed_uv[2].x, indexed_uv[2].y) + surface.uv_offset/100 - CENTER_OFFSET).rotated(surface.uv_angle) +  CENTER_OFFSET) * surface.uv_scale])
		normals.append_array([normal,normal,normal])
		vertex_final.append_array(sub_indexed_vertex)

		#setup final data set
	var arrays:Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertex_final
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_NORMAL] = normals
	return arrays

static func generate_surfaces(points, surfaces):
	var material_surface = {};
	var unique_normals = []
	if surfaces.size() > 50:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("cannot have over 50 surfaces")
		return false;
	for surface in surfaces:
		var result = build_surface(material_surface, points, surface)
		if !result:
			CSGPlusGlobals.controller.error_panel.alert_if_empty("Surface was not generated")
			return false
		material_surface[surface] = result
		if unique_normals.size() < 3: #we are already good, time to leave.
			for new_normal in result[Mesh.ARRAY_NORMAL]:
				if !unique_normals.any(func(existing): return new_normal.is_equal_approx(existing)):
					unique_normals.append(result[Mesh.ARRAY_NORMAL][0])
	if unique_normals.size() < 3:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("Shape could only generate flat normals")
		return false;
	return material_surface

static func make_line_cache(surfaces):
	var line_cache = {}
	for surface in surfaces:
		var lines = surface.generate_lines_from_point_path()
		for line in lines:
			var is_new = true
			for key in line_cache.keys():
				if key.equals(line):
					line_cache[key].append(surface);
					is_new = false;
					break;
			if(is_new):
				line_cache[line] = [surface]
	return line_cache

func build_line_cache():
	line_cache = make_line_cache(surfaces)

func update_all():
	build_line_cache()
	clear_surfaces();
	if points.size() == 0 || surfaces.size() == 0:
		return;
	var material_surface = generate_surfaces(points, surfaces)
	if !material_surface:
		print("INVALID POINT ISSUE ON CREATE")
		return;
	surface_cache = material_surface
	for key in material_surface.keys():
		var arrays = material_surface[key]
		add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		surface_set_material(get_surface_count()-1, key.material)

func commit(_points:PackedVector3Array, _surfaces, material_surface = null, line_cache = null):
	if _points:
		points_data = _points
	if _surfaces != null:
		surface_data = _surfaces
		if line_cache != null:
			self.line_cache = line_cache
		else:
			build_line_cache()
	if(material_surface == null):
		material_surface = generate_surfaces(points, surfaces)
	clear_surfaces();
	if material_surface:
		surface_cache = material_surface
		for key in material_surface.keys():
			var arrays = material_surface[key]
			add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			surface_set_material(get_surface_count()-1, key.material)

# ************************* POINT ALTERATIONS ******************************

func find_point(origin:Vector3, normal:Vector3, radius:float = .01):
	var closest = DataResult.invalid_result();
	for index in points.size():
		var point = points[index]
		var result = Geometry3D.segment_intersects_sphere(\
			origin,\
			origin + normal*100,\
			point,\
			((point.distance_to(origin))) / (2 / CSGPlusGlobals.TargetPoint.resource.radius)
		)
		if result:
			var distance = result[0].distance_to(origin)
			if (!closest.valid || closest.distance > distance):
				closest = DataResult.result_from_point(distance, result[0], index)
	return closest

func shift_point_position(position:int, offset:Vector3):
	points[position] += offset

func prepare_point_shift_position(positions:Array, offset:Vector3):
	var new_points = points.duplicate()
	for position:int in positions:
		new_points[position] += offset;
	var material_surface = generate_surfaces(new_points, surfaces)
	if !material_surface:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("Material Surfaces failed to generate shape")
		return false
	if !is_valid_polygon(new_points, surfaces, line_cache):
		CSGPlusGlobals.controller.error_panel.alert("Polygon overlaps itself and cannot produce shape")
		return false
	return MeshCommit.new(self, new_points, null, material_surface)

# ****************************** LINE EDITING ******************************

func get_point_on_line(origin:Vector3, normal:Vector3, offset:float = .01):
	var closest = DataResult.invalid_result()
	for line in line_cache.keys():
		var result = line.line_intersects_vectors(points, origin, normal, offset)
		if result != null:
			var distance = result.distance_to(origin)
			if !closest.valid || distance < closest.distance:
				closest = DataResult.result_from_line(distance, result, line)
	return closest

func get_lines_and_planes_from_point(point):
	var line_list1 = []
	var plane_list1 = []
	for plane in surfaces:
		if plane.vertexes.has(point):
			plane_list1.append(plane)
	for line in line_cache.keys():
		if line.vertex1 == point || line.vertex2 == point:
			line_list1.append(line)
	return [line_list1, plane_list1]

static func point_in_lines(point, lines):
	for line in lines:
		if point == line.vertex1 || point == line.vertex2:
			return true
	return false

func find_connected_singleton_lines(line):
	var depth = 0;
	var left_current = [line]
	var right_current = [line]
	var lines = [line]
	while left_current.size() == 1 && depth < 50:
		left_current = find_connected_lines_left(left_current[0])
		if left_current.size() == 1:
			lines.append(left_current[0])
		depth += 1
	while right_current.size() == 1 && depth < 50:
		right_current = find_connected_lines_right(right_current[0])
		if right_current.size() == 1:
			lines.append(right_current[0])
		depth += 1
	if depth >= 50:
		return []
	return lines;

func find_connected_lines_left(line):
	var found_left = []
	for check_line in line_cache.keys():
		if check_line == line:
			continue;
		if check_line.vertex1 == line.vertex1 || check_line.vertex2 == line.vertex1:
			found_left.append(check_line)
	return found_left

func find_connected_lines_right(line):
	var found_right = []
	for check_line in line_cache.keys():
		if check_line == line:
			continue;
		if check_line.vertex1 == line.vertex2 || check_line.vertex2 == line.vertex2:
			found_right.append(check_line)
	return found_right

static func find_line_in_cache(line_cache:Dictionary, line):
	var value = line_cache.get(line)
	if value:
		return value
	for check_line in line_cache:
		if line.equals(check_line):
			return line_cache[check_line]
	return null

func is_valid_line_creation(point1, line1, point2, line2):
	var data1
	var data2
	if line1 == null:
		data1 = get_lines_and_planes_from_point(point1)
	else:
		data1 = [[line1], line_cache[line1]]
	if line2 == null:
		data2 = get_lines_and_planes_from_point(point2)
	else:
		data2 = [[line2], line_cache[line2]]
	for check_line1 in data1[0]:
		for check_line2 in data2[0]:
			if check_line1.equals(check_line2):
				return false #shared line, cannot create
	for check_plane1 in data1[1]:
		for check_plane2 in data2[1]:
			if check_plane1 == check_plane2:
				return true #plane is in common after no lines are in common, valid!
	return false #no planes in common

func create_line(point1, line1, point2, line2):
	var target_point1_split
	var target_point2_split
	var new_points = points.duplicate()
	var new_surfaces = CSGPlusGlobals.FaceInfo.array_duplicate(surfaces)
	if line1 != null:
		var l1point1:int = line1.vertex1
		var l1point2:int = line1.vertex2
		new_points.append(point1)
		var new_point:int = new_points.size() - 1
		target_point1_split = new_point
		for face_index in line_cache[line1]:
			var face = new_surfaces[surfaces.find(face_index)]
			for index in face.vertexes.size():
				var target_point1 = face.vertexes[index]
				var target_point2 = face.vertexes[(index+1)%face.vertexes.size()]
				if (target_point1 == l1point1 && target_point2 == l1point2) || \
					(target_point2 == l1point1 && target_point1 == l1point2):
					face.vertexes.insert(index+1, new_point)
	else:
		target_point1_split = point1

	if line2 != null:
		var l1point1:int = line2.vertex1
		var l1point2:int = line2.vertex2
		new_points.append(point2)
		var new_point:int = new_points.size() - 1
		target_point2_split = new_point
		for face_index in line_cache[line2]:
			var face = new_surfaces[surfaces.find(face_index)]
			for index in face.vertexes.size():
				var target_point1 = face.vertexes[index]
				var target_point2 = face.vertexes[(index+1)%face.vertexes.size()]
				if (target_point1 == l1point1 && target_point2 == l1point2) || \
					(target_point2 == l1point1 && target_point1 == l1point2):
					face.vertexes.insert(index+1, new_point)
	else:
		target_point2_split = point2

	for surface_index in new_surfaces.size():
		var surface = new_surfaces[surface_index]
		if surface.vertexes.has(target_point1_split) && surface.vertexes.has(target_point2_split):
			var split_index = 0
			var indexed_left:Array[int] = []
			var indexed_right:Array[int] = []
			while surface.vertexes[split_index] != target_point1_split && surface.vertexes[split_index] != target_point2_split:
				split_index = (split_index + 1) % surface.vertexes.size()
			indexed_left.append(surface.vertexes[split_index])
			split_index = (split_index + 1) % surface.vertexes.size()
			while surface.vertexes[split_index] != target_point1_split && surface.vertexes[split_index] != target_point2_split:
				indexed_left.append(surface.vertexes[split_index])
				split_index = (split_index + 1) % surface.vertexes.size()
			indexed_left.append(surface.vertexes[split_index])
			indexed_right.append(surface.vertexes[split_index])
			split_index = (split_index + 1) % surface.vertexes.size()
			while surface.vertexes[split_index] != target_point1_split && surface.vertexes[split_index] != target_point2_split:
				indexed_right.append(surface.vertexes[split_index])
				split_index = (split_index + 1) % surface.vertexes.size()
			indexed_right.append(surface.vertexes[split_index])
			new_surfaces.append(CSGPlusGlobals.FaceInfo.new(indexed_right, new_surfaces[surface_index].material))
			new_surfaces[surface_index] = CSGPlusGlobals.FaceInfo.new(indexed_left, new_surfaces[surface_index].material)
			break

	var material_surface = generate_surfaces(new_points, new_surfaces)
	if !material_surface:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("Material Surfaces failed to generate shape")
		return false
	if !is_valid_polygon(new_points, new_surfaces, make_line_cache(new_surfaces)):
		CSGPlusGlobals.controller.errlookat_basisor_panel.alert("Polygon overlaps itself and cannot produce shape")
		return false
	return [
		MeshCommit.new(self, new_points, new_surfaces, material_surface),
		MeshCommit.new(self, points.duplicate(), CSGPlusGlobals.FaceInfo.array_duplicate(surfaces))
	]

func insert_point_at_line(position:Vector3, line):
	var point1:int = line.vertex1
	var point2:int = line.vertex2
	var new_points = points.duplicate()
	var new_surfaces = CSGPlusGlobals.FaceInfo.array_duplicate(surfaces)
	new_points.append(position)
	var new_point:int = new_points.size() - 1
	for face_index in line_cache[line]:
		var face = new_surfaces[surfaces.find(face_index)]
		for index in face.vertexes.size():
			var target_point1 = face.vertexes[index]
			var target_point2 = face.vertexes[(index+1)%face.vertexes.size()]
			if (target_point1 == point1 && target_point2 == point2) || \
				(target_point2 == point1 && target_point1 == point2):
				face.vertexes.insert(index+1, new_point)
	var material_surface = generate_surfaces(new_points, new_surfaces)
	if !material_surface:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("Material Surfaces failed to generate shape")
		return false
	if !is_valid_polygon(new_points, new_surfaces, make_line_cache(new_surfaces)):
		CSGPlusGlobals.controller.error_panel.alert("Polygon overlaps itself and cannot produce shape")
		return false
	return [
		MeshCommit.new(self, new_points, new_surfaces, material_surface),
		MeshCommit.new(self, points.duplicate(), CSGPlusGlobals.FaceInfo.array_duplicate(surfaces))
	]

func remove_point_at_across_line(point:int, line):
	var other_point:int = line.vertex1
	if other_point == point:
		other_point = line.vertex2

	var new_points = points.duplicate()
	var new_surfaces = CSGPlusGlobals.FaceInfo.array_duplicate(surfaces)

	#move last element to the new hole. N(1) time :)
	new_points[point] = new_points[new_points.size()-1]
	new_points.resize(new_points.size()-1)
	for surface in new_surfaces:
		var surface_vertexes:Array[int] = []
		for vertex in surface.vertexes:
			if vertex == point:
				vertex = other_point
			if vertex == new_points.size():
				vertex = point
			if surface_vertexes.size() == 0 || surface_vertexes[surface_vertexes.size()-1] != vertex:
				surface_vertexes.append(vertex)
		if surface_vertexes[0] == surface_vertexes[surface_vertexes.size()-1]:
			surface_vertexes.resize(surface_vertexes.size()-1)
		surface.vertexes = surface_vertexes
	new_surfaces = new_surfaces.filter(
		func(surface): return surface.vertexes.size() > 2
	)
	var material_surface = generate_surfaces(new_points, new_surfaces)
	if !material_surface:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("Material Surfaces failed to generate shape")
		return false
	if !is_valid_polygon(new_points, new_surfaces, make_line_cache(new_surfaces)):
		CSGPlusGlobals.controller.error_panel.alert("Polygon overlaps itself and cannot produce shape")
		return false
	return [
		MeshCommit.new(self, new_points, new_surfaces, material_surface),
		MeshCommit.new(self, points.duplicate(), CSGPlusGlobals.FaceInfo.array_duplicate(surfaces))
	]

func delete_lines_clear_loose_points(lines):
	var altered_surfaces = []
	var plane_indexs = []

	for index in surfaces.size():
		var plane = surfaces[index]
		if !plane_contains_lines(plane.vertexes,lines):
			continue

		altered_surfaces.append(plane)
		plane_indexs.append(index)

	if plane_indexs.size() != 2:
		CSGPlusGlobals.controller.error_panel.alert("Plane count for connect lines is incorrect, expected 2. could be caused by multiple points")
		return
	var line_cache_new = line_cache.keys()
	var delete_lines = []
	for index in line_cache_new.size():
		var line_target = line_cache_new[index]
		for line_destory in lines:
			if line_destory.equals(line_target):
				delete_lines.append(index)
	for index in delete_lines.size():
		var index_delete = delete_lines[delete_lines.size()-index-1]
		var last_index = line_cache_new.size() - index - 1
		line_cache_new[index_delete] = line_cache_new[last_index]
	line_cache_new.resize(line_cache_new.size() - delete_lines.size())

	var delete_points = []
	delete_points.resize(points.size())
	for index in points.size():
		delete_points[index] = index

	for point_index in points.size():
		if point_in_lines(point_index, line_cache_new):
			delete_points.erase(point_index)

	var new_surfaces = CSGPlusGlobals.FaceInfo.array_duplicate(surfaces)
	var new_points = points.duplicate()

	for delete_points_index in delete_points.size():
		var delete_point_index = delete_points[delete_points.size() - delete_points_index - 1]
		var moved_index = new_points.size()-1
		new_points[delete_point_index] = new_points[new_points.size()-1]
		new_points.resize(new_points.size()-1)
		for surface in new_surfaces:
			var surface_vertexes:Array[int] = surface.vertexes
			surface_vertexes.erase(delete_point_index)
			for index_swap in surface_vertexes.size():
				if surface_vertexes[index_swap] == moved_index:
					surface_vertexes[index_swap] = delete_point_index
			surface.vertexes = surface_vertexes
	var points_in_common_left = []
	var left_surface = new_surfaces[plane_indexs[0]]
	var right_surface = new_surfaces[plane_indexs[1]]
	for left_point_index in left_surface.vertexes.size():
		var left_point = left_surface.vertexes[left_point_index]
		for right_point in right_surface.vertexes:
			if left_point == right_point:
				points_in_common_left.append(left_point_index)
	if points_in_common_left.size() != 2:
		CSGPlusGlobals.controller.error_panel.alert("surface parsing error, only expected 2 points in common.")
		return;

	var points_in_common = null
	if (points_in_common_left[0] == 0 && points_in_common_left[1] == left_surface.vertexes.size()-1):
		points_in_common = [left_surface.vertexes[points_in_common_left[1]], left_surface.vertexes[points_in_common_left[0]]]
	else:
		points_in_common = [left_surface.vertexes[points_in_common_left[0]], left_surface.vertexes[points_in_common_left[1]]]

	var final_index = 0
	var final_vertex:Array[int] = []
	final_vertex.resize(left_surface.vertexes.size()+right_surface.vertexes.size()-2)
	for left in left_surface.vertexes:
		final_vertex[final_index] = left
		final_index += 1
		if left == points_in_common[0]:
			var right_index = 0
			if (right_surface.vertexes[0] == points_in_common[0] && right_surface.vertexes[right_surface.vertexes.size()-1]  == points_in_common[1])\
				|| (right_surface.vertexes[0] == points_in_common[1] && right_surface.vertexes[right_surface.vertexes.size()-1] == points_in_common[0]):
				right_index = right_surface.vertexes.size()-1
			while right_index < right_surface.vertexes.size() \
				&& !(right_surface.vertexes[right_index] == points_in_common[0] \
				|| right_surface.vertexes[right_index] == points_in_common[1]):
				right_index+=1
			if right_surface.vertexes[right_index] == points_in_common[1] && right_surface.vertexes[(right_index + 1)%right_surface.vertexes.size()] == points_in_common[0]:
				right_index += 2 #skip over the next two points
				while right_surface.vertexes[right_index%right_surface.vertexes.size()] != points_in_common[1]:
					final_vertex[final_index] = right_surface.vertexes[right_index%right_surface.vertexes.size()]
					final_index += 1
					right_index += 1
			elif right_surface.vertexes[right_index] == points_in_common[0] && right_surface.vertexes[(right_index + 1)%right_surface.vertexes.size()] == points_in_common[1]:
				right_index += 2
				while right_surface.vertexes[right_index%right_surface.vertexes.size()] != points_in_common[0]:
					final_vertex[final_index] = right_surface.vertexes[right_index%right_surface.vertexes.size()]
					final_index += 1
					right_index -= 1
			else:
				CSGPlusGlobals.controller.error_panel.alert("unexpected math error, common points cannot be connected with right aligned surface.")
				return;
	var new_surface_add = CSGPlusGlobals.FaceInfo.new(final_vertex, new_surfaces[plane_indexs[0]].material)
	new_surfaces[plane_indexs[0]] = new_surface_add
	new_surfaces[plane_indexs[1]] = new_surfaces[new_surfaces.size() - 1]
	new_surfaces.resize(new_surfaces.size() - 1)
	var material_surface = generate_surfaces(new_points, new_surfaces)
	if !material_surface:
		CSGPlusGlobals.controller.error_panel.alert_if_empty("Material Surfaces failed to generate shape")
		return false
	if !is_valid_polygon(new_points, new_surfaces, make_line_cache(new_surfaces)):
		CSGPlusGlobals.controller.error_panel.alert("Polygon overlaps itself and cannot produce shape")
		return false
	return [
		MeshCommit.new(self, new_points, new_surfaces, material_surface),
		MeshCommit.new(self, points.duplicate(), CSGPlusGlobals.FaceInfo.array_duplicate(surfaces))
	]

# ******************************* PLANE ALTERATIONS ************************************
func get_point_on_plane(origin: Vector3, normal:Vector3):
	var closest = DataResult.invalid_result()
	var far = origin+normal*1000
	for face in surface_cache.keys():
		var vertexes = surface_cache[face][Mesh.ARRAY_VERTEX]
		for index in vertexes.size()/3:
			var vertex1 = vertexes[index*3]
			var vertex2 = vertexes[index*3 + 1]
			var vertex3 = vertexes[index*3 + 2]
			var result = Geometry3D.segment_intersects_triangle(origin, far, vertex1, vertex2, vertex3)
			if result != null:
				var distance = result.distance_to(origin)
				if !closest.valid || closest.distance > distance:
					closest = DataResult.result_from_plame(distance, result, Plane(vertex1, vertex2, vertex3), face)
	return closest

func get_face_normal(plane):
	var plane_vertex = []
	plane_vertex.resize(plane.vertexes.size())
	for index in plane_vertex.size():
		plane_vertex[index] = points[plane.vertexes[index]]
	var result = SpaceUtils.generate_normal_and_center(plane_vertex)
	return Plane(result[0], result[1])

func find_closest_point_on_face(face, point: Vector3):
	var closest_point = null
	for position in face.vertexes:
		var check_point = points[position]
		if closest_point == null || closest_point.distance_to(point) > check_point.distance_to(point):
			closest_point = check_point
	return closest_point

static func plane_contains_lines(vertexes, lines):
	for line in lines:
		if !vertexes.has(line.vertex1) || !vertexes.has(line.vertex2):
			return false
	return true