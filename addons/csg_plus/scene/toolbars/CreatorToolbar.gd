@tool
extends Control

func set_flat_by_name(node_name:String):
	for child in get_node("%Tools").get_children():
		if child.name == node_name:
			child.flat = false
		elif child is Button:
			child.flat = true

func _exit_tree() -> void:
	set_flat_by_name("CubeCreatorTool")

func _on_cube_creator_tool_pressed() -> void:
	set_flat_by_name("CubeCreatorTool")
	CSGPlusGlobals.controller.set_tool(CubeCreatorTool.new())


func _on_cylindar_creator_tool_pressed() -> void:
	#print("code is not finished!!!!!")
	#CSGPlusGlobals.controller.error_panel.alert("Code not complete, tool is placeholder")
	set_flat_by_name("CylindarCreatorTool")
	CSGPlusGlobals.controller.set_tool(CylinderCreatorTool.new())
