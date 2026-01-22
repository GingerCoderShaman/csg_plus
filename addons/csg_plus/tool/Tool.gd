@tool
class_name Tool
extends RefCounted


var main

func handle_input(_viewport_camera: Camera3D, _event: InputEvent) -> bool:
	return false

func bind_tool():
	self.main = CSGPlusGlobals.controller

func unbind_tool():
	pass

func refresh_tool():
	pass
