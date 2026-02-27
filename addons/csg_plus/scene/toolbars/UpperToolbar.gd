@tool
extends HBoxContainer

var enabled_default_mode:
	get:
		return %DefaultMode.visible
	set(value):
		%DefaultMode.visible = value

var enabled_upgrade_node:
	get:
		return %UpgradeNode.visible
	set(value):
		%UpgradeNode.visible = value

var enabled_point_node:
	get:
		return %PointMode.visible
	set(value):
		%PointMode.visible = value

var enabled_linenode:
	get:
		return %LineMode.visible
	set(value):
		%LineMode.visible = value

var enabled_face_node:
	get:
		return %FaceMode.visible
	set(value):
		%FaceMode.visible = value

var enabled_create_node:
	get:
		return %CreateMode.visible
	set(value):
		%CreateMode.visible = value


func _ready():
	var popup = %UpgradeNode.get_popup()
	popup.connect("id_pressed", _upgrade_menu_selected.bind())

func set_default_mode():
	set_flat_by_name("DefaultMode")
	CSGPlusGlobals.controller.switch_mode(CSGPlusGlobals.MODE.DEFAULT)

func set_node_mode():
	set_flat_by_name("NodeMode")
	CSGPlusGlobals.controller.switch_mode(CSGPlusGlobals.MODE.POINT)

func set_flat_by_name(node_name:String):
	for child in get_node("%ModeSelector").get_children():
		if child.name == node_name:
			child.flat = false
		elif child is Button:
			child.flat = true
func update_mode(mode):
	%UpgradeNode.visible = (mode == CSGPlusGlobals.MODE.DEFAULT)

func _on_line_mode_pressed() -> void:
	set_flat_by_name("LineMode")
	CSGPlusGlobals.controller.switch_mode(CSGPlusGlobals.MODE.LINE)

func _on_face_mode_pressed() -> void:
	set_flat_by_name("FaceMode")
	CSGPlusGlobals.controller.switch_mode(CSGPlusGlobals.MODE.FACE)


func _on_create_mode_pressed() -> void:
	set_flat_by_name("CreateMode")
	CSGPlusGlobals.controller.switch_mode(CSGPlusGlobals.MODE.CREATE)

func _upgrade_menu_selected(id):
	CSGPlusGlobals.controller.upgrade_node_in_scene(id == 1)
