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

@export
var locked: bool = false

func _init(vertexes:Array[int] = [], material:Material = null, uv_offset = Vector2.ZERO, uv_scale = Vector2.ONE, uv_angle = 0, locked = false):
	self.vertexes = vertexes
	self.material = material
	self.uv_offset = uv_offset
	self.uv_scale = uv_scale
	self.uv_angle = uv_angle
	self.locked = locked

func generate_lines_from_point_path():
	var lines:Array = []
	for i in vertexes.size():
		lines.push_back(CSGPlusGlobals.Line.new(vertexes[i], vertexes[(i+1)%vertexes.size()]))
	return lines

func duplicate_full():
	return new(vertexes.duplicate(), material, uv_offset, uv_scale, uv_angle, locked)

static func array_duplicate(surfaces:Array):
	var copy:Array = []
	copy.resize(surfaces.size())
	for index in surfaces.size():
		copy[index] = surfaces[index].duplicate_full()
	return copy
