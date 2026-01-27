@tool
extends Node

var tool
var mode = CSGPlusGlobals.MODE.DEFAULT
var mode_has_changed_callback
var global_targets = []
var is_built = true

var setting_global_positioner = false
var snap = true
var snap_distance = 1
var edit_children = true

var undo_redo
var tool_controls


var selectable_scene
var scene_adder
var scene_viewport
var editor_camera:Camera3D

@onready var node_display_handler = %NodesHandler
@onready var overlay_2d:Node = %"2DOverlay"
@onready var render_over_3d_panel = %"Render3DOver"
@onready var render_3d_overarea:SubViewport = %"render_3d_overarea"
@onready var miscellaneous:Node = %"Miscellaneous"
@onready var error_panel = %"ErrorPanel"
@onready var material_renderer = %"MaterialRenderer"

static func init_controller(mode_has_changed_callback, undo_redo, selectable_scene, scene_adder, scene_viewport):
	var singleton = load("res://addons/csg_plus/global/MainScene.tscn").instantiate()
	singleton.setup(mode_has_changed_callback)
	singleton.is_built = true
	singleton.selectable_scene = selectable_scene
	singleton.scene_adder = scene_adder
	singleton.scene_viewport = scene_viewport
	if Engine.is_editor_hint():
		singleton.undo_redo = undo_redo
	else:
		print('Add Editor Hint API to Ingame controls')
	return singleton

func setup(mode_has_changed_callback) -> void:
	self.mode_has_changed_callback = mode_has_changed_callback
	tool_controls = load('res://addons/csg_plus/scene/toolbars/ToolControls.tscn').instantiate()

func _ready() -> void:
	if render_over_3d_panel:
		render_over_3d_panel.texture = render_3d_overarea.get_texture()
	if scene_viewport:
		editor_camera = scene_viewport.get_camera_3d()

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if tool != null && tool.handle_input(viewport_camera, event):
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func set_tool(tool):
	if(self.tool != null):
		self.tool.unbind_tool()
	self.tool = tool
	if(tool != null):
		self.tool.bind_tool()

func switch_mode(mode:CSGPlusGlobals.MODE):
	var old_mode = self.mode
	self.mode = mode
	refresh_targeting()
	match mode:
		CSGPlusGlobals.MODE.DEFAULT:
			set_tool(null)
		CSGPlusGlobals.MODE.POINT:
			set_tool(PointSelectTool.new())
		CSGPlusGlobals.MODE.LINE:
			set_tool(LineSelectTool.new())
		CSGPlusGlobals.MODE.FACE:
			set_tool(FaceSelectTool.new())
		CSGPlusGlobals.MODE.CREATE:
			set_tool(CubeCreatorTool.new())
	if mode_has_changed_callback:
		mode_has_changed_callback.call(mode, old_mode)

func refresh_tool():
	if tool:
		tool.refresh_tool()

func refresh_targeting():
	node_display_handler.make_target([])
	match self.mode:
		CSGPlusGlobals.MODE.DEFAULT,\
		CSGPlusGlobals.MODE.POINT,\
		CSGPlusGlobals.MODE.LINE,\
		CSGPlusGlobals.MODE.FACE:
			node_display_handler.make_target(global_targets)

func set_targets(targets_models):
	global_targets = targets_models
	mode = CSGPlusGlobals.MODE.DEFAULT
	node_display_handler.make_target([])
	set_tool(null)

func snap_calculaton_3d(current_shift: Vector3):
	if !snap:
		return current_shift
	current_shift /= snap_distance
	return Vector3(roundf(current_shift.x), roundf(current_shift.y), roundf(current_shift.z)) * snap_distance

func snap_calculation_difference_3d(target_point: Vector3, center:Vector3):
	return snap_calculaton_3d(target_point-center)+center

func snap_calculaton_2d(current_shift: Vector2):
	if !snap:
		return current_shift
	current_shift /= snap_distance
	return Vector2(roundf(current_shift.x), roundf(current_shift.y)) * snap_distance

func snap_calculation_difference_2d(target_point: Vector2, center:Vector2):
	return snap_calculaton_2d(target_point-center)+center

func snap_along_plane(target_point:Vector3, center:Vector3, plane:Plane):
	return SpaceUtils.project_points_from_plane(plane,
		snap_calculation_difference_2d(
			SpaceUtils.unproject_points_onto_plane(plane, target_point),
			SpaceUtils.unproject_points_onto_plane(plane, center)
		)
	)

func snap_calculaton_1d(current_shift: float):
	if !snap:
		return current_shift
	current_shift /= snap_distance
	return roundf(current_shift) * snap_distance

func call_history_editor(callback):
	callback.call()

func get_scene():
	if selectable_scene is Callable:
		return selectable_scene.call()
	return selectable_scene

func add_node_to_scene(node, parent = null):
	if scene_adder is Callable:
		scene_adder.call(node, parent)
		return
	if parent:
		parent.add_child(parent)
		return
	scene_adder.add_child(node)

func setup_undo_redo(name:String, redo_command, undo_command):
	if Engine.is_editor_hint():
		undo_redo.create_action(name)
		undo_redo.add_do_method(self, 'call_history_editor', redo_command)
		undo_redo.add_undo_method(self, 'call_history_editor', undo_command)
		undo_redo.commit_action()
	else:
		pass
