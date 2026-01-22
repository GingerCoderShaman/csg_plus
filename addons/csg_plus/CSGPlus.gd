@tool
extends EditorPlugin

static var plugin_undo_redo

var main_toolbar
var point_toolbar
var line_toolbar
var face_toolbar
var creator_toolbar
var tool_controls

var selection = get_editor_interface().get_selection()

func _enter_tree() -> void:
	var scene_adder = func(node, parent = null):
		if parent == null || !parent.is_inside_tree():
			parent = get_editor_interface().get_edited_scene_root()
		if parent:
			CSGPlusGlobals.controller.setup_undo_redo(
				"Create Cube Into Scene",
				func():
				parent.add_child(node)
				node.owner = parent.get_tree().edited_scene_root
				,
				func():
				parent.remove_child(node)
				,
			)
			return
		CSGPlusGlobals.controller.error_panel.alert_if_empty("No Root node found in scene")
	CSGPlusGlobals.create_controller(get_editor_interface().get_editor_viewport_3d(), Callable(self, "switch_mode_callback"), get_undo_redo(),\
		func(): return get_editor_interface().get_edited_scene_root(),
		scene_adder,
		EditorInterface.get_editor_viewport_3d()
	)
	main_toolbar = load("res://addons/csg_plus/scene/toolbars/UpperToolbar.tscn").instantiate()
	point_toolbar = load("res://addons/csg_plus/scene/toolbars/PointToolbar.tscn").instantiate()
	line_toolbar = load("res://addons/csg_plus/scene/toolbars/LineToolbar.tscn").instantiate()
	face_toolbar = load('res://addons/csg_plus/scene/toolbars/FaceToolbar.tscn').instantiate()
	creator_toolbar = load('res://addons/csg_plus/scene/toolbars/CreatorToolbar.tscn').instantiate()
	tool_controls = CSGPlusGlobals.controller.tool_controls
	#setup selection
	selection.connect("selection_changed", _on_selection_changed)

	get_editor_interface().get_inspector().add_child(tool_controls)

	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, main_toolbar)

	#escape/unselect nodes
	if !InputMap.has_action(CSGPlusGlobals.NODE_UNSELECT):
		InputMap.add_action(CSGPlusGlobals.NODE_UNSELECT)
	var unselect_targets = InputEventKey.new()
	unselect_targets.keycode = KEY_ESCAPE
	InputMap.action_add_event(CSGPlusGlobals.NODE_UNSELECT, unselect_targets)

	#primaryClick
	var click = InputEventMouseButton.new()
	if !InputMap.has_action(CSGPlusGlobals.NODE_SELECTED):
		InputMap.add_action(CSGPlusGlobals.NODE_SELECTED)
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event(CSGPlusGlobals.NODE_SELECTED, click)

	#hold onto nodes action
	var hold = InputEventKey.new()
	if !InputMap.has_action(CSGPlusGlobals.NODE_HOLD):
		InputMap.add_action(CSGPlusGlobals.NODE_HOLD)
	hold.keycode = KEY_CTRL
	InputMap.action_add_event(CSGPlusGlobals.NODE_HOLD, hold)

func _exit_tree() -> void:
	switch_mode_callback(CSGPlusGlobals.MODE.DEFAULT, CSGPlusGlobals.controller.mode)
	CSGPlusGlobals.destroy_controller(get_editor_interface().get_editor_viewport_3d())
	selection.disconnect("selection_changed", _on_selection_changed)
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, main_toolbar)
	InputMap.action_erase_events(CSGPlusGlobals.NODE_UNSELECT)
	InputMap.action_erase_events(CSGPlusGlobals.NODE_SELECTED)
	InputMap.action_erase_events(CSGPlusGlobals.NODE_HOLD)
	get_editor_interface().get_inspector().remove_child(tool_controls)

func _handles(changed_object: Object) -> bool:
	#setting the targets to nothing in godot will retrigger this, this is a stop gap
	get_editor_interface().get_inspector().get_child(0).visible = !changed_object == self
	tool_controls.visible = changed_object == self

	var panel = get_editor_interface().get_inspector().get_parent().get_parent()
	if panel is TabContainer:
		for tab_index in panel.get_tab_count():
			if panel.get_tab_title(tab_index) != 'Inspector':
				panel.set_tab_hidden(tab_index, changed_object == self)
				panel.set_tab_disabled(tab_index, changed_object == self)
	else:
		print("Invalid inspect panel, plugin needs an update")
	if !(changed_object == self || (selection.get_selected_nodes().size() && selection.get_selected_nodes()[0] != self)):
		CSGPlusGlobals.controller.switch_mode(CSGPlusGlobals.MODE.DEFAULT)
		main_toolbar.set_flat_by_name("DefaultMode")
	return changed_object is Node

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	return CSGPlusGlobals.controller._forward_3d_gui_input(viewport_camera, event)

func undo_mode_changes(mode:CSGPlusGlobals.MODE):
	match mode:
		CSGPlusGlobals.MODE.POINT:
			var interface = get_editor_interface()
			remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, point_toolbar)
		CSGPlusGlobals.MODE.LINE:
			var interface = get_editor_interface()
			remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, line_toolbar)
		CSGPlusGlobals.MODE.FACE:
			var interface = get_editor_interface()
			remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, face_toolbar)
		CSGPlusGlobals.MODE.CREATE:
			var interface = get_editor_interface()
			remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, creator_toolbar)

func switch_mode_callback(mode:CSGPlusGlobals.MODE, old_mode:CSGPlusGlobals.MODE):
	undo_mode_changes(old_mode)
	match mode:
		CSGPlusGlobals.MODE.DEFAULT:
			selection.clear()
			for target in CSGPlusGlobals.controller.global_targets:
				selection.add_node(target)
		CSGPlusGlobals.MODE.POINT:
			selection.clear()
			selection.add_node(self)
			add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, point_toolbar)
		CSGPlusGlobals.MODE.LINE:
			selection.clear()
			selection.add_node(self)
			add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, line_toolbar)
		CSGPlusGlobals.MODE.FACE:
			selection.clear()
			selection.add_node(self)
			add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, face_toolbar)
		CSGPlusGlobals.MODE.CREATE:
			selection.clear()
			selection.add_node(self)
			add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, creator_toolbar)

func _on_selection_changed():
	var checkglobal_targets = selection.get_selected_nodes()
	#setting the targets to nothing in godot will retrigger this, this is a stop gap
	if checkglobal_targets.size() == 1 && checkglobal_targets[0] == self:
		return
	undo_mode_changes(CSGPlusGlobals.controller.mode)
	CSGPlusGlobals.controller.set_targets(checkglobal_targets)
	main_toolbar.set_flat_by_name("DefaultMode")
