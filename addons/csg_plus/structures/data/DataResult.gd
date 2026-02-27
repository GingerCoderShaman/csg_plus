class_name DataResult

var valid = true
var data_type = null
var distance = null # array 0 for point & line & plane
var intersection_point = null # array 1 for point & line & plane
var point_index = null # array 2 for point
var reflected_point = null # array 3 for point
var reflected_node = null # array 4 for point and array 5 for line & 6 for plane

var cached_line = null# array 2 for line
var reflected_line = null # array 3 for line && array
var vertex_indexes = null # array 4 for line

var connected_cache_lines = null # special case for lines
var connected_reflected_lines = null # special case for lines, and 5 for plane
var connected_reflected_points = null #and 6 for plane

var plane = null # array 2 for plane
var face = null # array 3 for plane

var reflected_plane = null

var visual_object = null #used in line creator tool for hover tracking (node or line)

var accessible_points = []

var reflected_object:
    get():
        match data_type:
            'point':
                return reflected_point
            'line':
                return reflected_line
            'plane':
                return [connected_reflected_points, connected_reflected_lines]

static func invalid_result():
    var result = DataResult.new()
    result.valid = false
    return result

static func result_from_point(distance, interaction_point, point_index, is_point_disabled):
    var result = DataResult.new()
    result.data_type = 'point'
    result.distance = distance
    result.intersection_point = interaction_point
    result.point_index = point_index
    if is_point_disabled:
        result.valid = false
    else:
        result.accessible_points = [point_index]
    return result

static func result_from_line(distance, interaction_point, cached_line, accessible_points):
    var result = DataResult.new()
    result.data_type = 'line'
    result.distance = distance
    result.intersection_point = interaction_point
    result.cached_line = cached_line;
    result.accessible_points = accessible_points
    if result.accessible_points.size() == 0:
        result.valid = false
    return result

static func result_from_plame(distance, interaction_point, plane, face, accessible_points):
    var result = DataResult.new()
    result.data_type = 'plane'
    result.distance = distance
    result.intersection_point = interaction_point
    result.plane = plane
    result.face = face
    result.accessible_points = accessible_points
    return result