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
	set_flat_by_name("SelectTool");
	CSGPlusGlobals.controller.set_tool(PointSelectTool.new())

func _on_node_creator_tool_pressed() -> void:
	set_flat_by_name("NodeCreatorTool")
	CSGPlusGlobals.controller.set_tool(PointCreatorTool.new())

func _on_node_deletor_tool_pressed() -> void:
	set_flat_by_name("NodeDeletorTool")
	CSGPlusGlobals.controller.set_tool(PointDeleteTool.new())
