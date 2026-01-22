@tool
extends Resource

@export
var vertexes:Array[int]

@export
var material:Material

@export
var uv_offset:Vector2 = Vector2.ZERO

@export
var uv_scale:Vector2 = Vector2.ONE

@export
var uv_angle = 0

func _init(vertexes:Array[int] = [], material:Material = null):
	self.vertexes = vertexes
	self.material = material

func generate_lines_from_point_path():
	var lines:Array = []
	for i in vertexes.size():
		lines.push_back(CSGPlusGlobals.Line.new(vertexes[i], vertexes[(i+1)%vertexes.size()]))
	return lines

func duplicate_full():
	return new(vertexes.duplicate(), material)

static func array_duplicate(surfaces:Array):
	var copy:Array = []
	copy.resize(surfaces.size())
	for index in surfaces.size():
		copy[index] = surfaces[index].duplicate_full()
	return copy
