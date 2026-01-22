@tool
extends HBoxContainer

func set_flat_by_name(node_name:String):
	for child in get_node("%Tools").get_children():
		if child.name == node_name:
			child.flat = false
		elif child is Button:
			child.flat = true

func _exit_tree() -> void:
	set_flat_by_name("SelectTool")

func _on_select_tool_pressed() -> void:
	set_flat_by_name("SelectTool")
	CSGPlusGlobals.controller.set_tool(FaceSelectTool.new())


func _on_material_painter_pressed() -> void:
	set_flat_by_name("MaterialPainter")
	CSGPlusGlobals.controller.set_tool(FacePainterTool.new())
