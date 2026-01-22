@tool
extends Resource

@export
var vertex1:int
@export
var vertex2:int

func _init(vertex1:int = 0, vertex2:int = 0):
	self.vertex1 = vertex1;
	self.vertex2 = vertex2;

func equals(other):
	if other.vertex1 == vertex1 && other.vertex2 == vertex2:
		return true
	return other.vertex2 == vertex1 && other.vertex1 == vertex2

func line_intersects_line(points: PackedVector3Array, line):
	var line_diff:Vector3 = points[line.vertex1].direction_to(points[line.vertex2])
	var result = line_intersects_vectors(
		points,
		points[line.vertex1],
		line_diff
	)
	if(result != null):
		var line_sqrt_magnitude = line_diff.length_squared()
		if (result - points[line.vertex1]).length_squared() <= line_sqrt_magnitude\
			&& (result - points[line.vertex2]).length_squared() <= line_sqrt_magnitude:
			return result
	return null

	return self.line_intersects_vectors(points, points[line.vertex1], points[line.vertex1].direction_to(points[line.vertex2]))

func line_intersects_vectors(points: PackedVector3Array, line_point:Vector3, line_vec:Vector3, offset:float = .01):
	var line_diff:Vector3 = points[vertex1] - points[vertex2]
	var result = SpaceUtils.vectors_intersects_vectors(
		points[vertex1],
		line_diff,
		line_point,
		line_vec,
		offset
	)
	if(result != null):
		var line_sqrt_magnitude = line_diff.length_squared()
		if (result - points[vertex1]).length_squared() <= line_sqrt_magnitude\
			&& (result - points[vertex2]).length_squared() <= line_sqrt_magnitude:
			return result
	return null
